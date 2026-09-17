#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")"
if [[ -x ./start.sh ]]; then
  exec ./start.sh chip
fi
echo "CHIP start.sh not found." >&2
exit 1
