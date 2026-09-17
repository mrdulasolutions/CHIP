#!/bin/bash
cd "$(dirname "$0")"
if [[ -f ./rag/index/knowledge.db ]] && [[ -x ./start-rag.sh ]]; then
  exec ./start-rag.sh
fi
if [[ -x ./start.sh ]]; then
  exec ./start.sh chip
fi
echo "CHIP launchers not found. Run ./build-chip.sh from the repo first." >&2
read -r -p "Press Enter to close."
