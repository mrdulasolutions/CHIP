#!/usr/bin/env bash
# One-shot installer: copy CHIP kit to a portable drive and optionally fetch runtime/models/corpus.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="1.0.0"
MARKER=".chip-installed"

MODE="kit"
ONLINE_DEFAULT=0
TARGET=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./build-chip.sh [TARGET_DIR] [options]

  TARGET_DIR          USB or folder root (default: /Volumes/CHIP if mounted, else prompt)

Options:
  --full              Download runtime, embed + chip models, PDF tools, fetch corpus,
                      pdf-to-text, ingest RAG index (requires network + python3)
  --minimal           Copy launchers and scripts only (no docs/corpus tree)
  --online-default    If target has no install marker, behave like --full when online
  --dry-run           Show rsync plan only
  -h, --help          This help

Examples:
  ./build-chip.sh /Volumes/CHIP
  ./build-chip.sh /Volumes/CHIP --full
  ./build-chip.sh . --minimal
EOF
}

online() {
  if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    return 0
  fi
  if curl -fsS --max-time 3 https://github.com >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

detect_target() {
  if [[ -d "/Volumes/CHIP" ]]; then
    echo "/Volumes/CHIP"
    return 0
  fi
  if [[ -d "/media/$USER/CHIP" ]]; then
    echo "/media/$USER/CHIP"
    return 0
  fi
  local win_hint="${CHIP_DRIVE:-}"
  if [[ -n "$win_hint" && -d "$win_hint" ]]; then
    echo "$win_hint"
    return 0
  fi
  read -r -p "Target directory (portable drive root): " tgt
  [[ -n "$tgt" ]] || { echo "No target directory." >&2; exit 1; }
  echo "$tgt"
}

RSYNC_EXCLUDES=(
  --exclude '.git/'
  --exclude '.cursor/'
  --exclude 'models/*.gguf'
  --exclude 'bin/llamafile'
  --exclude 'bin/llamafile.exe'
  --exclude 'bin/pdf/'
  --exclude 'rag/index/knowledge.db'
  --exclude 'rag/index/*.db'
  --exclude 'tmp/*'
  --exclude '._*'
  --exclude '.DS_Store'
)

ROOT_LAUNCHERS=(
  "Launch CHIP.command" "Launch CHIP.bat" "Launch CHIP.sh"
  "Launch Chat.command" "Launch Chat.bat" "Launch Chat.sh"
  "Stop CHIP.command" "Stop CHIP.bat" "Stop CHIP.sh"
)

ROOT_WRAPPERS=(
  build-chip.sh
  download-runtime.sh
  download-embed-model.sh
  download-chip-model.sh
  download-pdf-tools.sh
)

copy_minimal() {
  local dest="$1"
  mkdir -p "$dest/scripts" "$dest/models" "$dest/rag/index" "$dest/tmp" "$dest/setup"
  rsync -a "${RSYNC_EXCLUDES[@]}" "$ROOT/scripts/" "$dest/scripts/"
  rsync -a "${RSYNC_EXCLUDES[@]}" "$ROOT/setup/" "$dest/setup/"
  for w in "${ROOT_WRAPPERS[@]}"; do
    [[ -f "$ROOT/$w" ]] && cp -f "$ROOT/$w" "$dest/$w"
  done
  rsync -a "${RSYNC_EXCLUDES[@]}" \
    "$ROOT/start.sh" "$ROOT/start.bat" \
    "$ROOT/start-embed.sh" "$ROOT/start-embed.bat" \
    "$ROOT/start-rag.sh" \
    "$dest/"
  for f in QUICKSTART.md 00-READ-ME-FIRST.txt; do
    [[ -f "$ROOT/$f" ]] && cp -f "$ROOT/$f" "$dest/$f"
  done
  [[ -f "$ROOT/models/README.md" ]] && cp -f "$ROOT/models/README.md" "$dest/models/"
  [[ -f "$ROOT/rag/index/.gitkeep" ]] && cp -f "$ROOT/rag/index/.gitkeep" "$dest/rag/index/"
  [[ -f "$ROOT/rag/prompts/system-rag.txt" ]] && mkdir -p "$dest/rag/prompts" && cp -f "$ROOT/rag/prompts/system-rag.txt" "$dest/rag/prompts/"
  for f in "${ROOT_LAUNCHERS[@]}"; do
    [[ -f "$ROOT/$f" ]] && cp -f "$ROOT/$f" "$dest/$f"
  done
}

copy_kit() {
  local dest="$1"
  mkdir -p "$dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    rsync -avn "${RSYNC_EXCLUDES[@]}" "$ROOT/" "$dest/" | head -200
    return 0
  fi
  # No --delete: never remove existing models, corpus, or indexes on the target drive.
  rsync -a "${RSYNC_EXCLUDES[@]}" "$ROOT/" "$dest/"
}

chmod_kit() {
  local dest="$1"
  chmod +x "$dest/build-chip.sh" "$dest/download-"*.sh "$dest/start"*.sh "$dest/start-rag.sh" 2>/dev/null || true
  chmod +x "$dest/setup/"*.sh 2>/dev/null || true
  chmod +x "$dest/scripts/"*.sh 2>/dev/null || true
  for f in "${ROOT_LAUNCHERS[@]}"; do
    chmod +x "$dest/$f" 2>/dev/null || true
  done
}

run_full_pipeline() {
  local dest="$1"
  echo "==> Online setup in $dest"
  (
    cd "$dest"
    ./download-runtime.sh
    ./download-embed-model.sh
    ./download-chip-model.sh
    ./download-pdf-tools.sh
    ./scripts/fetch-corpus.sh
    if [[ -x ./scripts/pdf-to-text.sh ]]; then
      ./scripts/pdf-to-text.sh || echo "Note: pdf-to-text had warnings (missing PDFs is OK)." >&2
    fi
    if command -v python3 >/dev/null 2>&1; then
      mkdir -p tmp
      nohup ./start-embed.sh >tmp/embed-build.log 2>&1 &
      embed_pid=$!
      sleep 8
      ./scripts/ingest-corpus.sh || echo "Ingest failed; run manually after embed server is up." >&2
      kill "$embed_pid" 2>/dev/null || true
    else
      echo "python3 not found; skip ingest. Run ./start-embed.sh then ./scripts/ingest-corpus.sh later." >&2
    fi
  )
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full) MODE="full" ;;
    --minimal) MODE="minimal" ;;
    --online-default) ONLINE_DEFAULT=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
  shift
done

[[ -n "$TARGET" ]] || TARGET="$(detect_target)"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"

if [[ "$MODE" == "kit" && "$ONLINE_DEFAULT" -eq 1 && ! -f "$TARGET/$MARKER" ]]; then
  if online; then
    echo "==> --online-default: first install detected, running --full pipeline."
    MODE="full"
  else
    echo "==> Offline; copying kit only. Re-run with --full when online."
  fi
fi

echo "CHIP build $VERSION → $TARGET (mode: $MODE)"

case "$MODE" in
  minimal) copy_minimal "$TARGET" ;;
  kit|full) copy_kit "$TARGET" ;;
esac

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run complete."
  exit 0
fi

chmod_kit "$TARGET"
date -u +"%Y-%m-%dT%H:%M:%SZ" >"$TARGET/$MARKER"
echo "$VERSION" >>"$TARGET/$MARKER"

if [[ "$MODE" == "full" ]]; then
  if ! online; then
    echo "No network; kit copied. Run downloads manually when online." >&2
  else
    run_full_pipeline "$TARGET"
  fi
fi

cat <<EOF

╔══════════════════════════════════════════════════════════════════╗
║  CHIP is ready on: $TARGET
╚══════════════════════════════════════════════════════════════════╝

Start here: QUICKSTART.md  (or 00-READ-ME-FIRST.txt on Windows)

Grid-down on a new computer:
  • macOS:   double-click "Launch CHIP.command" (RAG if built) or "Launch Chat.command"
  • Windows: double-click "Launch CHIP.bat" or "Launch Chat.bat"
  • Linux:   ./Launch\ CHIP.sh  or ./start-rag.sh

Browser UI: http://127.0.0.1:8080  (localhost only)

See README.md and docs/user/AUTOSTART.md for shortcuts and troubleshooting.
EOF
