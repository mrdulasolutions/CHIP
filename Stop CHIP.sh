#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"
if [[ -x ./start-rag.sh ]]; then
  exec ./start-rag.sh stop
fi
echo "CHIP start-rag.sh not found." >&2
exit 1
