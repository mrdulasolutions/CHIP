#!/bin/bash
cd "$(dirname "$0")"
if [[ -x ./start-rag.sh ]]; then
  ./start-rag.sh stop
  read -r -p "Stopped (if running). Press Enter to close."
  exit 0
fi
echo "CHIP start-rag.sh not found." >&2
read -r -p "Press Enter to close."
exit 1
