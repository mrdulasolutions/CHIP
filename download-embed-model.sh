#!/usr/bin/env bash
# Download bge-small-en-v1.5 Q4_K_M for llamafile --embedding (run once while online).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/models/embed.gguf"
# CompendiumLabs GGUF (public resolve); override with EMBED_MODEL_URL if needed
URL="${EMBED_MODEL_URL:-https://huggingface.co/CompendiumLabs/bge-small-en-v1.5-gguf/resolve/main/bge-small-en-v1.5-q4_k_m.gguf}"

mkdir -p "$ROOT/models"
if [[ -f "$OUT" ]]; then
  echo "Already present: $OUT"
  exit 0
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Downloading embedding model to models/embed.gguf ..."
if command -v curl >/dev/null 2>&1; then
  curl -fL --progress-bar -o "$TMP" "$URL"
elif command -v wget >/dev/null 2>&1; then
  wget -q --show-progress -O "$TMP" "$URL"
else
  echo "Need curl or wget." >&2
  exit 1
fi

mv "$TMP" "$OUT"
echo "Installed: $OUT"
echo "Start embeddings: ./start-embed.sh"
