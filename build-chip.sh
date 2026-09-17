#!/usr/bin/env bash
# Wrapper: real installer lives in setup/ (exFAT-safe; no symlinks).
set -euo pipefail
CHIP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$CHIP_ROOT/setup/build-chip.sh" "$@"
