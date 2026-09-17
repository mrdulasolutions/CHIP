#!/usr/bin/env bash
set -euo pipefail
CHIP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$CHIP_ROOT/setup/download-chip-model.sh" "$@"
