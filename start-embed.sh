#!/usr/bin/env bash
# Embedding server (llamafile 0.10.6) — bge-small on port 8081.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$ROOT/bin/llamafile"
MODEL="$ROOT/models/embed.gguf"
TMPDIR_ON_DRIVE="$ROOT/tmp"
PORT="${EMBED_PORT:-8081}"

if [[ ! -f "$MODEL" ]]; then
  echo "Missing $MODEL — run ./download-embed-model.sh while online." >&2
  exit 1
fi

if [[ ! -x "$BIN" ]]; then
  [[ -f "$BIN" ]] && chmod +x "$BIN" || {
    echo "Missing $BIN — run ./download-runtime.sh first." >&2
    exit 1
  }
fi

if [[ "$(uname -s)" == "Darwin" ]] && xattr -l "$BIN" 2>/dev/null | grep -q com.apple.quarantine; then
  xattr -d com.apple.quarantine "$BIN" 2>/dev/null || true
fi

mkdir -p "$TMPDIR_ON_DRIVE"
export TMPDIR="$TMPDIR_ON_DRIVE"

GPU_ARGS=()
if [[ -n "${LLAMA_NGL:-}" ]]; then
  GPU_ARGS=(-ngl "$LLAMA_NGL")
elif command -v nvidia-smi >/dev/null 2>&1; then
  GPU_ARGS=(-ngl 999)
fi

run_llamafile() {
  if [[ -x "$BIN" ]]; then
    exec "$BIN" "$@"
  fi
  exec sh -c '"$0" "$@"' "$BIN" "$@"
}

echo "Embedding server: http://127.0.0.1:${PORT} (OpenAI /v1/embeddings)"
# Larger ubatch avoids "input too large" on long chunks during ingest
run_llamafile -m "$MODEL" ${GPU_ARGS[@]+"${GPU_ARGS[@]}"} \
  --server --host 127.0.0.1 --port "$PORT" --embedding \
  --ubatch-size 512
