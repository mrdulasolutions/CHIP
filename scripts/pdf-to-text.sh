#!/usr/bin/env bash
# Convert PDFs in rag/corpus/ to .txt using bundled Poppler pdftotext on the drive.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORPUS="${CORPUS:-$ROOT/rag/corpus}"
# shellcheck source=lib/pdf-tools.sh
source "$ROOT/scripts/lib/pdf-tools.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0")

Converts every *.pdf under rag/corpus/ (recursive) to a same-named .txt using bundled
Poppler (bin/pdf/...). Run ./download-pdf-tools.sh once while online.

Override corpus directory: CORPUS=/path/to/dir $0
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

pdf_pdftotext_setup "$ROOT"
PDFTOTEXT="$PDFTOTEXT_BIN"
case "$(uname -s)" in
  Darwin)
    if [[ -d "$ROOT/bin/pdf/macos/share/poppler" ]]; then
      _poppler_share="$ROOT/bin/pdf/macos/share/poppler"
    else
      _poppler_share="$ROOT/bin/pdf/darwin-arm64/share/poppler"
    fi
    ;;
  Linux)
    case "$(uname -m)" in
      x86_64|amd64)
        if [[ -d "$ROOT/bin/pdf/linux-x86_64/share/poppler" ]]; then
          _poppler_share="$ROOT/bin/pdf/linux-x86_64/share/poppler"
        else
          _poppler_share="$ROOT/bin/pdf/linux-x64/share/poppler"
        fi
        ;;
      aarch64|arm64) _poppler_share="$ROOT/bin/pdf/linux-aarch64/share/poppler" ;;
      *) _poppler_share="" ;;
    esac
    ;;
  *) _poppler_share="" ;;
esac
if [[ -n "${_poppler_share:-}" && -d "$_poppler_share" ]]; then
  export POPPLER_DATADIR="$_poppler_share"
fi
unset _poppler_share

mkdir -p "$CORPUS"

found=0
while IFS= read -r pdf; do
  [[ -z "$pdf" ]] && continue
  found=1
  out="${pdf%.pdf}.txt"
  echo "Converting ${pdf#$CORPUS/} -> ${out#$CORPUS/}"
  "$PDFTOTEXT" -layout "$pdf" "$out"
done < <(find "$CORPUS" -type f -name '*.pdf' ! -name '._*' 2>/dev/null | sort)

if [[ "$found" -eq 0 ]]; then
  echo "No PDF files under: $CORPUS"
  exit 0
fi

echo "Done. Start the server and ask the model to read the new .txt files."
