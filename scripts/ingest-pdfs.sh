#!/usr/bin/env bash
# Convenience wrapper: convert all PDFs in rag/corpus/ using bundled bin/pdf/pdftotext.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/scripts/pdf-to-text.sh" "$@"
