# Shared RAG helpers (source from other scripts; not executable alone).
rag_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

RAG_EMBED_HOST="${RAG_EMBED_HOST:-127.0.0.1}"
RAG_EMBED_PORT="${RAG_EMBED_PORT:-8081}"
RAG_EMBED_BASE="http://${RAG_EMBED_HOST}:${RAG_EMBED_PORT}"

rag_wait_embed_server() {
  local tries="${1:-60}"
  local i=0
  while (( i < tries )); do
    if curl -fsS -o /dev/null "${RAG_EMBED_BASE}/health" 2>/dev/null \
      || curl -fsS -o /dev/null "${RAG_EMBED_BASE}/v1/models" 2>/dev/null; then
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  echo "Embedding server not reachable at ${RAG_EMBED_BASE}" >&2
  echo "Start: ./start-embed.sh" >&2
  return 1
}

# Prints discovered embeddings path (e.g. /v1/embeddings) to stdout.
rag_discover_embed_path() {
  if [[ -n "${RAG_EMBED_PATH:-}" ]]; then
    echo "$RAG_EMBED_PATH"
    return 0
  fi
  local paths=("/v1/embeddings" "/embedding" "/embeddings")
  local p body
  for p in "${paths[@]}"; do
    body='{"input":"ping"}'
    if curl -fsS -X POST "${RAG_EMBED_BASE}${p}" \
      -H 'Content-Type: application/json' \
      -d "$body" 2>/dev/null | grep -q '"data"'; then
      echo "$p"
      return 0
    fi
  done
  echo "/v1/embeddings"
}
