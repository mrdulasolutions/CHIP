#!/usr/bin/env bash
# Download bundled Poppler pdftotext into bin/pdf/ (run once while online).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PDF_ROOT="$ROOT/bin/pdf"

POPPLER_WINDOWS_TAG="v26.09.0-0"
POPPLER_WINDOWS_ZIP="https://github.com/oschwartz10612/poppler-windows/releases/download/${POPPLER_WINDOWS_TAG}/Release-${POPPLER_WINDOWS_TAG#v}.zip"

DO_MAC=0
DO_LINUX=0
DO_WIN=0

usage() {
  cat <<'EOF'
Usage: ./download-pdf-tools.sh [--mac] [--linux] [--windows] [--all]

Fetches drive-local Poppler pdftotext binaries (not committed to git).

Sources (documented URLs):
  Windows: https://github.com/oschwartz10612/poppler-windows/releases
  macOS:   conda-forge poppler (via micromamba) or Homebrew poppler bottle
  Linux:   Debian bookworm amd64 poppler-utils + runtime libs (Docker build)

Default: --all (every platform this host can populate).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mac|--macos) DO_MAC=1 ;;
    --linux) DO_LINUX=1 ;;
    --windows|--win) DO_WIN=1 ;;
    --all) DO_MAC=1; DO_LINUX=1; DO_WIN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [[ "$DO_MAC" == 0 && "$DO_LINUX" == 0 && "$DO_WIN" == 0 ]]; then
  DO_MAC=1
  DO_LINUX=1
  DO_WIN=1
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Need $1 on PATH." >&2; exit 1; }
}

fetch() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar -o "$dest" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$dest" "$url"
  else
    echo "Need curl or wget." >&2
    exit 1
  fi
}

install_windows() {
  need_cmd unzip
  local dest="$PDF_ROOT/windows"
  local tmp zip staging
  tmp="$(mktemp -d)"
  zip="$tmp/poppler-windows.zip"
  echo "Windows: $POPPLER_WINDOWS_ZIP"
  fetch "$POPPLER_WINDOWS_ZIP" "$zip"
  unzip -q "$zip" -d "$tmp"
  staging="$(find "$tmp" -type d -path '*/Library/bin' | head -1)"
  [[ -n "$staging" ]] || { echo "Unexpected poppler-windows zip layout." >&2; exit 1; }
  mkdir -p "$dest"
  rm -rf "$dest"/*
  cp -a "$staging"/. "$dest/"
  share="$(find "$tmp" -type d -path '*/Library/share/poppler' | head -1 || true)"
  if [[ -n "$share" ]]; then
    mkdir -p "$dest/share"
    cp -a "$share" "$dest/share/"
  fi
  chmod +x "$dest/pdftotext.exe" 2>/dev/null || true
  rm -rf "$tmp"
  echo "  -> $dest/pdftotext.exe"
}

install_macos_micromamba() {
  local dest="$PDF_ROOT/macos"
  local mm="$tmp/mm"
  mkdir -p "$mm"
  local arch url
  arch="$(uname -m)"
  case "$arch" in
    arm64) url="https://micro.mamba.pm/api/micromamba/osx-arm64/latest" ;;
    x86_64) url="https://micro.mamba.pm/api/micromamba/osx-64/latest" ;;
    *) echo "Unsupported macOS arch: $arch" >&2; return 1 ;;
  esac
  echo "macOS: conda-forge poppler via micromamba ($arch)"
  fetch "$url" "$tmp/micromamba.tar.bz2"
  tar -xjf "$tmp/micromamba.tar.bz2" -C "$mm" bin/micromamba
  "$mm/bin/micromamba" create -y -p "$tmp/prefix" -c conda-forge poppler
  mkdir -p "$dest/lib"
  cp -f "$tmp/prefix/bin/pdftotext" "$dest/pdftotext"
  chmod +x "$dest/pdftotext"
  if [[ -d "$tmp/prefix/lib" ]]; then
    cp -a "$tmp/prefix/lib"/. "$dest/lib/"
  fi
  if [[ -d "$tmp/prefix/share/poppler" ]]; then
    mkdir -p "$dest/share"
    cp -a "$tmp/prefix/share/poppler" "$dest/share/"
  fi
  echo "  -> $dest/pdftotext"
}

install_macos_brew() {
  local dest="$PDF_ROOT/macos"
  echo "macOS: Homebrew poppler bottle"
  brew fetch --force poppler >/dev/null
  local bottle link
  link="$(find "$(brew --cache)" -maxdepth 1 -name 'poppler--*' 2>/dev/null | head -1)"
  if [[ -L "$link" ]]; then
    bottle="$(readlink "$link")"
    [[ "$bottle" != /* ]] && bottle="$(brew --cache)/downloads/$bottle"
  else
    bottle="$(find "$(brew --cache)/downloads" -name '*poppler*--*.tar.gz' 2>/dev/null | head -1)"
  fi
  [[ -f "$bottle" ]] || { echo "Could not locate poppler bottle after brew fetch." >&2; return 1; }
  mkdir -p "$tmp/bottle" "$dest/lib"
  tar -xzf "$bottle" -C "$tmp/bottle"
  local prefix
  prefix="$(find "$tmp/bottle" -type f -path '*/bin/pdftotext' | head -1)"
  prefix="$(dirname "$(dirname "$prefix")")"
  cp -f "$prefix/bin/pdftotext" "$dest/pdftotext"
  chmod +x "$dest/pdftotext"
  cp -a "$prefix/lib"/. "$dest/lib/"
  if [[ -d "$prefix/share/poppler" ]]; then
    mkdir -p "$dest/share"
    cp -a "$prefix/share/poppler" "$dest/share/"
  fi
  echo "  -> $dest/pdftotext"
}

install_macos() {
  tmp="$(mktemp -d)"
  if command -v brew >/dev/null 2>&1; then
    install_macos_brew || install_macos_micromamba
  else
    install_macos_micromamba
  fi
  rm -rf "$tmp"
}

install_linux_amd64_docker() {
  local dest="$PDF_ROOT/linux-x86_64"
  need_cmd docker
  echo "Linux x86_64: Debian bookworm poppler-utils (Docker)"
  mkdir -p "$dest"
  docker run --rm --platform linux/amd64 \
    -v "$dest:/out" \
    debian:bookworm-slim bash -euxc '
      apt-get update -qq
      apt-get install -y -qq poppler-utils
      cp -f /usr/bin/pdftotext /out/pdftotext
      chmod +x /out/pdftotext
      mkdir -p /out/lib /out/share
      if [[ -d /usr/share/poppler ]]; then cp -a /usr/share/poppler /out/share/; fi
      ldd /usr/bin/pdftotext | awk "/=> \//{print \$3}" | sort -u | while read -r lib; do
        [[ -n "$lib" && -f "$lib" ]] || continue
        base=$(basename "$lib")
        case "$base" in
          ld-linux-x86-64.so.2|linux-vdso.so.1|libc.so.6|libm.so.6|libpthread.so.0|libdl.so.2|librt.so.1|libresolv.so.2) continue ;;
          libnss_*) continue ;;
        esac
        cp -L "$lib" /out/lib/
      done
    '
  echo "  -> $dest/pdftotext"
}

install_linux_amd64() {
  if command -v docker >/dev/null 2>&1; then
    install_linux_amd64_docker
    return
  fi
  echo "Linux x86_64: skipped (install Docker to build the bundled libs on this host, or run this script on Linux)." >&2
}

mkdir -p "$PDF_ROOT"

[[ "$DO_WIN" == 1 ]] && install_windows
[[ "$DO_MAC" == 1 && "$(uname -s)" == "Darwin" ]] && install_macos
[[ "$DO_LINUX" == 1 ]] && install_linux_amd64

echo ""
echo "Done. Convert PDFs with: ./scripts/pdf-to-text.sh"
