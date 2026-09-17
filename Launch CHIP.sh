#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"
if [[ -f ./rag/index/knowledge.db ]] && [[ -x ./start-rag.sh ]]; then
  exec ./start-rag.sh
fi
if [[ -x ./start.sh ]]; then
  exec ./start.sh chip
fi
echo "CHIP launchers not found." >&2
exit 1
