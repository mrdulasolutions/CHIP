#!/usr/bin/env bash
# Grid-down helper: embedding server + chat server (two processes).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMBED_PID_FILE="$ROOT/tmp/embed.pid"
CHAT_PID_FILE="$ROOT/tmp/chat.pid"
CHAT_PORT="${PORT:-8080}"
EMBED_PORT="${EMBED_PORT:-8081}"
CHAT_BASE="http://127.0.0.1:${CHAT_PORT}"
START_TIMEOUT="${RAG_START_TIMEOUT:-180}"
RAG_CHAT_MODEL="${RAG_CHAT_MODEL:-chip}"
# Large chat.gguf models often advertise 100k+ ctx; with embed on :8081 that can OOM 16 GB hosts
# and stall the browser SSE stream ("Stream resume produced no new bytes").
export CHIP_CTX_SIZE="${CHIP_CTX_SIZE:-8192}"
export CHIP_PARALLEL="${CHIP_PARALLEL:-1}"
mkdir -p "$ROOT/tmp"

# shellcheck source=scripts/lib/rag_common.sh
source "$ROOT/scripts/lib/rag_common.sh"
RAG_EMBED_PORT="$EMBED_PORT"
RAG_EMBED_BASE="http://${RAG_EMBED_HOST}:${RAG_EMBED_PORT}"

listener_pids_on_port() {
  lsof -t -iTCP:"$1" -sTCP:LISTEN 2>/dev/null || true
}

is_chip_listener() {
  local pid="$1"
  local args
  args="$(ps -p "$pid" -o args= 2>/dev/null)" || return 1
  [[ "$args" == *"$ROOT"* ]] && { [[ "$args" == *"llamafile"* ]] || [[ "$args" == *".ape"* ]]; }
}

kill_chip_on_port() {
  local port="$1" pid
  for pid in $(listener_pids_on_port "$port"); do
    if is_chip_listener "$pid"; then
      kill "$pid" 2>/dev/null || true
    fi
  done
}

port_holder_outside_chip() {
  local port="$1" pid
  for pid in $(listener_pids_on_port "$port"); do
    if ! is_chip_listener "$pid"; then
      echo "$pid"
      return 0
    fi
  done
  return 1
}

assert_port_free_or_chip() {
  local port="$1" label="$2" holder
  if holder="$(port_holder_outside_chip "$port")"; then
    echo "Error: $label port $port is already in use (PID $holder):" >&2
    ps -p "$holder" -o args= 2>/dev/null >&2 || true
    echo "Stop that process, or set PORT / EMBED_PORT to unused ports." >&2
    exit 1
  fi
}

stop_bg() {
  for f in "$EMBED_PID_FILE" "$CHAT_PID_FILE"; do
    if [[ -f "$f" ]]; then
      pid="$(cat "$f")"
      kill "$pid" 2>/dev/null || true
      rm -f "$f"
    fi
  done
  # start.sh exec's llamafile — PID files often point at a dead shell; kill by port + path
  kill_chip_on_port "$EMBED_PORT"
  kill_chip_on_port "$CHAT_PORT"
  pkill -f "${ROOT}/bin/llamafile" 2>/dev/null || true
  for port in "$EMBED_PORT" "$CHAT_PORT"; do
    for pid in $(listener_pids_on_port "$port"); do
      kill -9 "$pid" 2>/dev/null || true
    done
  done
  sleep 2
}

tail_log() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "--- last lines of ${path#$ROOT/} ---" >&2
    tail -n 25 "$path" >&2
  fi
}

wait_chat_server() {
  local tries="${1:-$START_TIMEOUT}" i=0
  while (( i < tries )); do
    if curl -fsS -o /dev/null "${CHAT_BASE}/health" 2>/dev/null \
      || curl -fsS -o /dev/null "${CHAT_BASE}/v1/models" 2>/dev/null; then
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  echo "Chat server not reachable at ${CHAT_BASE}" >&2
  return 1
}

case "${1:-start}" in
  stop)
    stop_bg
    echo "Stopped background RAG servers (if any)."
    exit 0
    ;;
  -h|--help)
    cat <<'EOF'
Usage: ./start-rag.sh [start|stop]

  start (default)  Run embed server on :8081 and chat on :8080 in background
  stop             Kill servers started by this script

Manual (two terminals):
  Terminal 1: ./start-embed.sh
  Terminal 2: ./start.sh chip   # or: RAG_CHAT_MODEL=chat ./start-rag.sh

Query:
  ./scripts/rag-query.sh "how do I purify water?"
  ./scripts/rag-query.sh "tourniquet steps" --chat

Environment:
  PORT / EMBED_PORT       Chat and embed ports (default 8080 / 8081)
  RAG_START_TIMEOUT       Seconds to wait for servers (default 180)
  RAG_CHAT_MODEL          Profile for chat server (default: chip; use chat on 16 GB+ only)
  CHIP_CTX_SIZE           Passed to start.sh --ctx-size (default: 8192 for RAG)
  CHIP_PARALLEL           Passed to start.sh --parallel (default: 1 for RAG)
EOF
    exit 0
    ;;
esac

if [[ ! -f "$ROOT/rag/index/knowledge.db" ]]; then
  echo "Warning: rag/index/knowledge.db not found. Build at home with ./scripts/ingest-corpus.sh" >&2
fi

if [[ ! -x "$ROOT/bin/llamafile" ]]; then
  echo "Missing $ROOT/bin/llamafile — run ./download-runtime.sh" >&2
  exit 1
fi
if [[ ! -f "$ROOT/models/embed.gguf" ]]; then
  echo "Missing $ROOT/models/embed.gguf — run ./download-embed-model.sh" >&2
  exit 1
fi

stop_bg
assert_port_free_or_chip "$EMBED_PORT" "Embedding"
assert_port_free_or_chip "$CHAT_PORT" "Chat"

echo "Starting embed server (${EMBED_PORT})..."
nohup "$ROOT/start-embed.sh" >"$ROOT/tmp/embed.log" 2>&1 &
echo $! >"$EMBED_PID_FILE"

echo "Starting chat server (${CHAT_PORT}, model: ${RAG_CHAT_MODEL}, ctx: ${CHIP_CTX_SIZE}, parallel: ${CHIP_PARALLEL})..."
nohup "$ROOT/start.sh" "$RAG_CHAT_MODEL" >"$ROOT/tmp/chat.log" 2>&1 &
echo $! >"$CHAT_PID_FILE"

echo "Waiting for embed server (up to ${START_TIMEOUT}s)..."
if ! rag_wait_embed_server "$START_TIMEOUT"; then
  tail_log "$ROOT/tmp/embed.log"
  stop_bg
  exit 1
fi
echo "Embed server ready."

echo "Waiting for chat server (up to ${START_TIMEOUT}s; large models can be slow)..."
if ! wait_chat_server "$START_TIMEOUT"; then
  tail_log "$ROOT/tmp/chat.log"
  stop_bg
  exit 1
fi
echo "Chat server ready."

echo "Logs: tmp/embed.log, tmp/chat.log"
echo "Open ${CHAT_BASE} or: ./scripts/rag-query.sh \"your question\" [--chat]"
echo "Stop: ./start-rag.sh stop"
