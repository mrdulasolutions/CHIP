#!/usr/bin/env bash
# Download the llamafile runtime into bin/ (run once while online).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/bin"
VERSION="0.10.6"
URL="https://github.com/mozilla-ai/llamafile/releases/download/${VERSION}/llamafile-${VERSION}"

mkdir -p "$BIN"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Downloading llamafile ${VERSION}..."
if command -v curl >/dev/null 2>&1; then
  curl -fL --progress-bar -o "$TMP" "$URL"
elif command -v wget >/dev/null 2>&1; then
  wget -q --show-progress -O "$TMP" "$URL"
else
  echo "Need curl or wget." >&2
  exit 1
fi

mv "$TMP" "$BIN/llamafile"
chmod +x "$BIN/llamafile"
cp -f "$BIN/llamafile" "$BIN/llamafile.exe"

echo "Installed:"
echo "  $BIN/llamafile"
echo "  $BIN/llamafile.exe  (same binary; Windows expects .exe)"
echo ""
echo "Next: add GGUF files under models/ (see models/README.md)."
