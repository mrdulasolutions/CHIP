#!/usr/bin/env bash
# CHIP — Crisis Host-Independent Preparedness (llamafile kit on external SSD).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$ROOT/bin/llamafile"
MODELS="$ROOT/models"
CORPUS="$ROOT/rag/corpus"
TMPDIR_ON_DRIVE="$ROOT/tmp"
PORT="${PORT:-8080}"
# Safe local document tools (server mode only): reads confined to CORPUS via --media-path
DOC_TOOL_ARGS=(--tools read_file,grep_search,file_glob_search --confine-reads --media-path "$CORPUS")

usage() {
  cat <<'EOF'
Usage: ./start.sh [tiny|chat|chip] [tui]

  tiny|chat|chip   Model to load (default: chat if present, else chip, else tiny)
  tui         Terminal chat instead of browser UI

Environment:
  PORT        HTTP port for --server (default: 8080)
  LLAMA_NGL   GPU layers, e.g. 999 for NVIDIA/AMD offload (unset = llamafile default)
EOF
}

MODE="server"
PROFILE=""

for arg in "$@"; do
  case "$arg" in
    tiny|chat|chip) PROFILE="$arg" ;;
    tui) MODE="tui" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage >&2; exit 1 ;;
  esac
done

pick_model() {
  local tiny="$MODELS/tiny.gguf"
  local chat="$MODELS/chat.gguf"
  local chip="$MODELS/chip.gguf"
  if [[ -n "$PROFILE" ]]; then
    case "$PROFILE" in
      tiny)
        [[ -f "$tiny" ]] || { echo "Missing $tiny" >&2; exit 1; }
        echo "$tiny"
        ;;
      chip)
        [[ -f "$chip" ]] || { echo "Missing $chip — run ./download-chip-model.sh" >&2; exit 1; }
        echo "$chip"
        ;;
      chat)
        [[ -f "$chat" ]] || { echo "Missing $chat" >&2; exit 1; }
        echo "$chat"
        ;;
    esac
    return
  fi
  if [[ -f "$chat" ]]; then
    echo "$chat"
  elif [[ -f "$chip" ]]; then
    echo "$chip"
  elif [[ -f "$tiny" ]]; then
    echo "$tiny"
  else
    echo "No model found. Add models/chip.gguf, tiny.gguf, or chat.gguf (see models/README.md)." >&2
    exit 1
  fi
}

MODEL="$(pick_model)"

if [[ ! -x "$BIN" ]]; then
  if [[ -f "$BIN" ]]; then
    chmod +x "$BIN" || true
  else
    echo "Missing $BIN — run ./download-runtime.sh first." >&2
    exit 1
  fi
fi

# macOS: allow running from external volume when possible
if [[ "$(uname -s)" == "Darwin" ]] && xattr -l "$BIN" 2>/dev/null | grep -q com.apple.quarantine; then
  xattr -d com.apple.quarantine "$BIN" 2>/dev/null || true
fi

mkdir -p "$TMPDIR_ON_DRIVE" "$CORPUS"
export TMPDIR="$TMPDIR_ON_DRIVE"

GPU_ARGS=()
if [[ -n "${LLAMA_NGL:-}" ]]; then
  GPU_ARGS=(-ngl "$LLAMA_NGL")
elif command -v nvidia-smi >/dev/null 2>&1; then
  GPU_ARGS=(-ngl 999)
fi

run_llamafile() {
  if [[ -x "$BIN" ]]; then
    exec "$BIN" "$@"
  fi
  # Linux: some mounts break direct execution of APE binaries
  exec sh -c '"$0" "$@"' "$BIN" "$@"
}

cd "$ROOT"

if [[ "$MODE" == "tui" ]]; then
  echo "CHIP — loading $(basename "$MODEL") (terminal)..."
  run_llamafile -m "$MODEL" ${GPU_ARGS[@]+"${GPU_ARGS[@]}"}
else
  echo "CHIP — Crisis Host-Independent Preparedness"
  echo "Loading $(basename "$MODEL")..."
  echo "Open http://127.0.0.1:${PORT} when ready (Ctrl+C to stop)."
  echo "Documents: rag/corpus/ (.md/.txt; PDF: download-pdf-tools.sh then scripts/pdf-to-text.sh)."
  run_llamafile -m "$MODEL" ${GPU_ARGS[@]+"${GPU_ARGS[@]}"} --server --host 127.0.0.1 --port "$PORT" ${DOC_TOOL_ARGS[@]+"${DOC_TOOL_ARGS[@]}"}
fi
