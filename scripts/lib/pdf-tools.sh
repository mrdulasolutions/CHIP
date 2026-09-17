#!/usr/bin/env bash
# Resolve bundled pdftotext for this kit (sourced by pdf-to-text.sh).
set -euo pipefail

pdf_tools_root() {
  local here="${BASH_SOURCE[0]}"
  while [[ -L "$here" ]]; do
    here="$(readlink "$here")"
  done
  cd "$(dirname "$here")/../.." && pwd
}

# Sets PDFTOTEXT_BIN and library paths. Call in the current shell (not $(...)).
pdf_pdftotext_setup() {
  local root="${1:-$(pdf_tools_root)}"
  local os arch bin lib
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin)
      if [[ -x "$root/bin/pdf/macos/pdftotext" || -f "$root/bin/pdf/macos/pdftotext" ]]; then
        bin="$root/bin/pdf/macos/pdftotext"
        lib="$root/bin/pdf/macos/lib"
      else
        bin="$root/bin/pdf/darwin-arm64/bin/pdftotext"
        lib="$root/bin/pdf/darwin-arm64/lib"
      fi
      ;;
    Linux)
      case "$arch" in
        x86_64|amd64)
          if [[ -x "$root/bin/pdf/linux-x86_64/pdftotext" || -f "$root/bin/pdf/linux-x86_64/pdftotext" ]]; then
            bin="$root/bin/pdf/linux-x86_64/pdftotext"
            lib="$root/bin/pdf/linux-x86_64/lib"
          else
            bin="$root/bin/pdf/linux-x64/bin/pdftotext"
            lib="$root/bin/pdf/linux-x64/lib"
          fi
          ;;
        aarch64|arm64) bin="$root/bin/pdf/linux-aarch64/pdftotext" ;;
        *) echo "Unsupported Linux architecture: $arch" >&2; return 1 ;;
      esac
      if [[ -z "${lib:-}" ]]; then
        lib="$(dirname "$bin")/lib"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      bin="$root/bin/pdf/windows/pdftotext.exe"
      lib="$root/bin/pdf/windows"
      ;;
    *)
      echo "Unsupported OS for bundled pdftotext: $os" >&2
      return 1
      ;;
  esac

  if [[ ! -x "$bin" && ! -f "$bin" ]]; then
    cat >&2 <<EOF
Bundled pdftotext not found at:
  $bin

While online, from the kit root run:
  ./download-pdf-tools.sh

See README.md (Documents / PDFs).
EOF
    return 1
  fi

  if [[ -d "$lib" ]]; then
    case "$os" in
      Darwin) export DYLD_LIBRARY_PATH="$lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" ;;
      Linux) export LD_LIBRARY_PATH="$lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
    esac
  fi

  PDFTOTEXT_BIN="$bin"
  export PDFTOTEXT_BIN
}
