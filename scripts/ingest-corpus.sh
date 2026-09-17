#!/usr/bin/env bash
# Chunk rag/corpus, embed via llamafile on 8081, store rag/index/knowledge.db
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORPUS="$ROOT/rag/corpus"
DB="$ROOT/rag/index/knowledge.db"
PY="$ROOT/scripts/lib/rag_ingest.py"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for ingest (vector storage)." >&2
  exit 1
fi

export PYTHONPATH="${ROOT}/scripts/lib${PYTHONPATH:+:$PYTHONPATH}"

python3 "$PY" \
  --corpus "$CORPUS" \
  --db "$DB" \
  --base "http://${RAG_EMBED_HOST:-127.0.0.1}:${RAG_EMBED_PORT:-8081}" \
  --overlap "${RAG_CHUNK_OVERLAP:-200}" \
  --limit-files "${RAG_LIMIT_FILES:-0}" \
  --model "${RAG_EMBED_MODEL:-bge-small-en-v1.5-Q4_K_M}" \
  --wait "${RAG_EMBED_WAIT:-60}"
