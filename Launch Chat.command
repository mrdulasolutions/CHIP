#!/bin/bash
cd "$(dirname "$0")"
if [[ -x ./start.sh ]]; then
  exec ./start.sh chip
fi
echo "CHIP start.sh not found. Run ./build-chip.sh from the repo first." >&2
read -r -p "Press Enter to close."
