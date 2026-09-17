#!/usr/bin/env bash
# Download Hermes 3 Llama 3.2 3B Q4_K_M for ./start.sh chip (run once while online).
# Reduced-refusal instruct fine-tune — you are responsible for lawful, safe use offline.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/models/chip.gguf"
# Public resolve (verified curl -I → HTTP 200). Override with CHIP_MODEL_URL if needed.
URL="${CHIP_MODEL_URL:-https://huggingface.co/bartowski/Hermes-3-Llama-3.2-3B-GGUF/resolve/main/Hermes-3-Llama-3.2-3B-Q4_K_M.gguf}"

mkdir -p "$ROOT/models"
if [[ -f "$OUT" ]]; then
  echo "Already present: $OUT"
  exit 0
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Downloading CHIP chat model (~1.9 GB) to models/chip.gguf ..."
echo "Model: Hermes-3-Llama-3.2-3B Q4_K_M (llamafile-compatible GGUF)"
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
echo "Run: ./start.sh chip   # browser UI on http://127.0.0.1:8080"
