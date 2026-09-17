#!/usr/bin/env bash
# Retrieve top-k chunks for a question; optional chat completion on :8080.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/rag_common.sh
source "$ROOT/scripts/lib/rag_common.sh"

DB="$ROOT/rag/index/knowledge.db"
PY="$ROOT/scripts/lib/rag_query.py"
PROMPT="$ROOT/rag/prompts/system-rag.txt"
TOP_K="${RAG_TOP_K:-5}"
CHAT_PORT="${PORT:-8080}"
CHAT=0

usage() {
  cat <<'EOF'
Usage: ./scripts/rag-query.sh "your question" [--chat]

  --chat   Call chat server on 127.0.0.1:8080 with retrieved context (needs ./start.sh)

Environment:
  RAG_TOP_K        Number of chunks (default: 5)
  RAG_EMBED_PORT   Embedding server port (default: 8081)
EOF
}

ARGS=()
for arg in "$@"; do
  case "$arg" in
    --chat) CHAT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) ARGS+=("$arg") ;;
  esac
done

[[ ${#ARGS[@]} -ge 1 ]] || { usage >&2; exit 1; }
QUESTION="${ARGS[*]}"
[[ -f "$DB" ]] || { echo "Missing $DB — run ./scripts/ingest-corpus.sh first." >&2; exit 1; }

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required." >&2
  exit 1
fi

rag_wait_embed_server "${RAG_EMBED_WAIT:-30}" || exit 1

export PYTHONPATH="${ROOT}/scripts/lib${PYTHONPATH:+:$PYTHONPATH}"

if [[ "$CHAT" -eq 1 ]]; then
  python3 "$PY" "$QUESTION" --db "$DB" \
    --base "http://${RAG_EMBED_HOST}:${RAG_EMBED_PORT}" \
    -k "$TOP_K" --chat --chat-port "$CHAT_PORT" --prompt "$PROMPT"
else
  python3 "$PY" "$QUESTION" --db "$DB" \
    --base "http://${RAG_EMBED_HOST}:${RAG_EMBED_PORT}" \
    -k "$TOP_K"
fi
