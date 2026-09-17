#!/usr/bin/env bash
# Grid-down helper: embedding server + chat server (two processes).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMBED_PID_FILE="$ROOT/tmp/embed.pid"
CHAT_PID_FILE="$ROOT/tmp/chat.pid"
mkdir -p "$ROOT/tmp"

stop_bg() {
  for f in "$EMBED_PID_FILE" "$CHAT_PID_FILE"; do
    if [[ -f "$f" ]]; then
      pid="$(cat "$f")"
      kill "$pid" 2>/dev/null || true
      rm -f "$f"
    fi
  done
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
  Terminal 2: ./start.sh chat

Query:
  ./scripts/rag-query.sh "how do I purify water?"
  ./scripts/rag-query.sh "tourniquet steps" --chat
EOF
    exit 0
    ;;
esac

if [[ ! -f "$ROOT/rag/index/knowledge.db" ]]; then
  echo "Warning: rag/index/knowledge.db not found. Build at home with ./scripts/ingest-corpus.sh" >&2
fi

stop_bg

echo "Starting embed server (8081)..."
nohup "$ROOT/start-embed.sh" >"$ROOT/tmp/embed.log" 2>&1 &
echo $! >"$EMBED_PID_FILE"

echo "Starting chat server (8080)..."
nohup "$ROOT/start.sh" chat >"$ROOT/tmp/chat.log" 2>&1 &
echo $! >"$CHAT_PID_FILE"

echo "Logs: tmp/embed.log, tmp/chat.log"
echo "Open http://127.0.0.1:8080 or: ./scripts/rag-query.sh \"your question\" [--chat]"
echo "Stop: ./start-rag.sh stop"
