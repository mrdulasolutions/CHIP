#!/usr/bin/env bash
# Idempotent fetch of prepper corpus into rag/corpus/ (run while online).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORPUS="$ROOT/rag/corpus"

# Comma-separated: all | legacy | comms | doctrine | nbc | medical | water | food |
# wildlife | sustainability | faith | vehicle | reloading | playbooks
FETCH_TOPICS="${FETCH_TOPICS:-all}"
# Set FETCH_LARGE=1 to pull multi-hundred-MB items (e.g. FM 3-05.70 scan).
FETCH_LARGE="${FETCH_LARGE:-0}"
# Auto-sync corpus + docs to /Volumes/CHIP when repo is not already on that volume.
SYNC_CHIP="${SYNC_CHIP:-auto}"
# Legacy env names (still honored):
SYNC_PORTABLEAI="${SYNC_PORTABLEAI:-$SYNC_CHIP}"

DOCTRINE_DIR="$CORPUS/doctrine/survivalmanual"
SHTF_DIR="$CORPUS/playbooks/shtf"
PREPARED="$CORPUS/playbooks/prepared.md"

topic_enabled() {
  local t="$1"
  [[ "$FETCH_TOPICS" == "all" ]] && return 0
  [[ ",$FETCH_TOPICS," == *",$t,"* ]] && return 0
  return 1
}

stamp_fetched() {
  date -u +"%Y-%m-%dT%H:%M:%SZ" >"$1"
}

fetch_url() {
  local url="$1" dest="$2"
  if [[ -s "$dest" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  echo "  GET $url"
  if ! curl -fL --retry 3 --connect-timeout 30 --max-time 600 -o "$dest.tmp" "$url"; then
    rm -f "$dest.tmp"
    echo "  Warning: failed $url" >&2
    return 1
  fi
  mv "$dest.tmp" "$dest"
}

ia_download() {
  local identifier="$1" filename="$2" dest="$3"
  local url="https://archive.org/download/${identifier}/${filename}"
  fetch_url "$url" "$dest"
}

clone_md_only() {
  local repo_url="$1" dest_dir="$2" path_prefix="${3:-}"
  local marker="$dest_dir/.fetched"
  if [[ -f "$marker" ]]; then
    echo "$(basename "$dest_dir"): already fetched"
    return 0
  fi
  local tmp
  tmp="$(mktemp -d)"
  echo "Cloning $(basename "$dest_dir") (shallow, *.md only)..."
  git clone --depth 1 "$repo_url" "$tmp/repo"
  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"
  local search_root="$tmp/repo"
  [[ -n "$path_prefix" && -d "$tmp/repo/$path_prefix" ]] && search_root="$tmp/repo/$path_prefix"
  find "$search_root" -name '*.md' -print0 | while IFS= read -r -d '' f; do
    rel="${f#"$search_root"/}"
    mkdir -p "$dest_dir/$(dirname "$rel")"
    cp "$f" "$dest_dir/$rel"
  done
  stamp_fetched "$marker"
  rm -rf "$tmp"
  echo "$(basename "$dest_dir"): done -> $dest_dir"
}

# --- Legacy playbooks (original kit) ---

clone_survivalmanual() {
  if [[ -f "$DOCTRINE_DIR/.fetched" ]]; then
    echo "survivalmanual: already fetched at $DOCTRINE_DIR"
    return 0
  fi
  echo "Cloning survivalmanual (shallow) and copying *.md only..."
  local tmp
  tmp="$(mktemp -d)"
  git clone --depth 1 https://github.com/survivalmanual/survivalmanual.github.io.git "$tmp/repo"
  rm -rf "$DOCTRINE_DIR"
  mkdir -p "$DOCTRINE_DIR"
  find "$tmp/repo" -name '*.md' -print0 | while IFS= read -r -d '' f; do
    rel="${f#"$tmp/repo"/}"
    mkdir -p "$DOCTRINE_DIR/$(dirname "$rel")"
    cp "$f" "$DOCTRINE_DIR/$rel"
  done
  stamp_fetched "$DOCTRINE_DIR/.fetched"
  rm -rf "$tmp"
  echo "survivalmanual: done -> $DOCTRINE_DIR"
}

copy_shtf_playbooks() {
  if [[ -f "$SHTF_DIR/.fetched" ]]; then
    echo "SHTF playbooks: already fetched ($SHTF_DIR)"
    return 0
  fi
  local tmp
  tmp="$(mktemp -d)"
  echo "Cloning SHTF (shallow) for playbooks/**/*.md only..."
  git clone --depth 1 https://github.com/XyraSinclair/SHTF.git "$tmp/repo"
  rm -rf "$SHTF_DIR"
  mkdir -p "$SHTF_DIR"
  if [[ -d "$tmp/repo/playbooks" ]]; then
    find "$tmp/repo/playbooks" -name '*.md' -print0 | while IFS= read -r -d '' f; do
      rel="${f#"$tmp/repo/playbooks/"}"
      mkdir -p "$SHTF_DIR/$(dirname "$rel")"
      cp "$f" "$SHTF_DIR/$rel"
    done
  else
    echo "Warning: no playbooks/ in SHTF repo" >&2
  fi
  stamp_fetched "$SHTF_DIR/.fetched"
  rm -rf "$tmp"
  echo "SHTF playbooks: done -> $SHTF_DIR"
}

fetch_prepared() {
  local urls=(
    "https://gist.githubusercontent.com/raw/prepared.md"
    "https://raw.githubusercontent.com/wiki/preparedness/prepared.md"
  )
  if [[ -s "$PREPARED" ]]; then
    echo "prepared.md: already present"
    return 0
  fi
  for url in "${urls[@]}"; do
    if curl -fsSL -o "$PREPARED.tmp" "$url" 2>/dev/null && [[ -s "$PREPARED.tmp" ]]; then
      mv "$PREPARED.tmp" "$PREPARED"
      echo "prepared.md: fetched from $url"
      return 0
    fi
  done
  rm -f "$PREPARED.tmp"
  cat >"$PREPARED" <<'EOF'
# Prepared playbook (placeholder)

This file was not auto-downloaded. While online, add your own `prepared.md` here
or set PREPARED_URL when running fetch-corpus.sh.

Sources to check: community prepper checklists and local copies of public-domain guides.
EOF
  echo "prepared.md: placeholder written (no remote found)"
}

# --- Topic bundles ---

fetch_comms() {
  local dir="$CORPUS/comms"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "comms: skip ($marker)" && return 0
  mkdir -p "$dir/ham" "$dir/morse"
  echo "comms: FCC Part 97 + Morse references..."
  fetch_url \
    "https://www.govinfo.gov/content/pkg/CFR-2025-title47-vol5/pdf/CFR-2025-title47-vol5-part97.pdf" \
    "$dir/ham/cfr-47-part97-amateur-radio.pdf"
  fetch_url \
    "https://maritime.org/doc/pdf/signalman.pdf" \
    "$dir/morse/navedtra-14243-signalman-morse.pdf"
  fetch_url \
    "https://archive.org/stream/USNavyCourseAviationMaintenanceRatingsNAVEDTRA14022/US%20Navy%20course%20-%20Signalman%201%20&%20C%20NAVEDTRA%2014243_djvu.txt" \
    "$dir/morse/navedtra-14243-signalman.txt"
  stamp_fetched "$marker"
  echo "comms: done -> $dir"
}

fetch_doctrine_fm() {
  local dir="$CORPUS/doctrine/fm"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "doctrine/fm: skip" && return 0
  mkdir -p "$dir"
  echo "doctrine/fm: core Army/USMC survival field manuals..."
  fetch_url \
    "https://www.bits.de/NRANEU/others/amd-us-archive/FM21-76%2892%29.pdf" \
    "$dir/fm-21-76-survival-1992.pdf"
  ia_download \
    "milmanual-mcrp-3-02f-fm-21-76-survival" \
    "mcrp_3-02f_fm_21-76_survival.pdf" \
    "$dir/mcrp-3-02f-usmc-survival.pdf"
  ia_download \
    "milmanual-mcrp-3-02h-survival-evasion-and-recovery" \
    "mcrp_3-02h_survival_evasion_and_recovery.pdf" \
    "$dir/mcrp-3-02h-survival-evasion-recovery.pdf"
  if [[ "$FETCH_LARGE" == "1" ]]; then
    ia_download \
      "FM_3_05_70_S_2002" \
      "FM%203-05-70%20Survial%20%282002%29.pdf" \
      "$dir/fm-3-05-70-survival-2002.pdf"
  else
    echo "  (skip fm-3-05-70; set FETCH_LARGE=1 to download ~280MB scan)"
  fi
  stamp_fetched "$marker"
  echo "doctrine/fm: done -> $dir"
}

fetch_nbc() {
  local dir="$CORPUS/doctrine/nbc"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "doctrine/nbc: skip" && return 0
  mkdir -p "$dir"
  echo "doctrine/nbc: CBRN + citizen radiological prep..."
  fetch_url \
    "https://www.globalsecurity.org/wmd/library/policy/army/fm/3-11/fm3-11_2011.pdf" \
    "$dir/fm-3-11-cbrn-operations-2011.pdf"
  fetch_url \
    "https://www.ready.gov/sites/default/files/2021-11/are-you-ready-guide.pdf" \
    "$dir/fema-are-you-ready-citizen-preparedness.pdf"
  fetch_url \
    "https://www.epa.gov/system/files/documents/2024-06/pags_comm_tool_2023.pdf" \
    "$dir/epa-radiological-protective-actions-2023.pdf"
  stamp_fetched "$marker"
  echo "doctrine/nbc: done -> $dir"
}

fetch_medical() {
  local dir="$CORPUS/medical"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "medical: skip" && return 0
  mkdir -p "$dir"
  echo "medical: field first aid + disaster wound care..."
  ia_download "FM4-25x11" "FM4-25x11.pdf" "$dir/fm-4-25-11-first-aid.pdf"
  fetch_url \
    "https://www.cdc.gov/disasters/hurricanes/pdf/woundcare.pdf" \
    "$dir/cdc-emergency-wound-care.pdf"
  stamp_fetched "$marker"
  echo "medical: done -> $dir"
}

fetch_water() {
  local dir="$CORPUS/water"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "water: skip" && return 0
  mkdir -p "$dir"
  echo "water: purification + field water surveillance..."
  fetch_url \
    "https://www.epa.gov/sites/default/files/2017-09/documents/emergency_disinfection_of_drinking_water_sept2017.pdf" \
    "$dir/epa-emergency-disinfection-drinking-water.pdf"
  fetch_url \
    "https://armypubs.army.mil/epubs/DR_pubs/DR_a/pdf/web/tbmed577.pdf" \
    "$dir/tbmed577-field-water-sanitary-control.pdf"
  fetch_url \
    "https://nnty.fun/downloads/books/survivorlibrary/library-sanitation/fm_4-25-12_unit_field_sanitation_team_2002.pdf" \
    "$dir/fm-4-25-12-unit-field-sanitation.pdf"
  stamp_fetched "$marker"
  echo "water: done -> $dir"
}

fetch_food() {
  local dir="$CORPUS/food"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "food: skip" && return 0
  mkdir -p "$dir/foraging" "$dir/hunting" "$dir/fishing"
  echo "food: foraging + game/fish handling..."
  fetch_url \
    "https://research.fs.usda.gov/download/treesearch/3075.pdf" \
    "$dir/foraging/usfs-pnw-gtr-513-special-forest-products.pdf"
  fetch_url \
    "https://ucanr.edu/sites/default/files/2020-09/335728.pdf" \
    "$dir/hunting/ucanr-deer-elk-field-to-table.pdf"
  fetch_url \
    "https://animalrangeextension.montana.edu/wildlife/documents/field-care-big-game.pdf" \
    "$dir/hunting/msu-field-care-big-game.pdf"
  if [[ ! -f "$dir/foraging/materia-medica/.fetched" ]]; then
    local tmp mf
    tmp="$(mktemp -d)"
    git clone --depth 1 https://github.com/aubrel/materia-medica.git "$tmp/repo"
    mkdir -p "$dir/foraging/materia-medica"
    find "$tmp/repo" \( -name '*.txt' -o -name '*.md' \) -print0 | while IFS= read -r -d '' f; do
      rel="${f#"$tmp/repo"/}"
      mkdir -p "$dir/foraging/materia-medica/$(dirname "$rel")"
      cp "$f" "$dir/foraging/materia-medica/$rel"
    done
    stamp_fetched "$dir/foraging/materia-medica/.fetched"
    rm -rf "$tmp"
  fi
  stamp_fetched "$marker"
  echo "food: done -> $dir"
}

fetch_wildlife() {
  local dir="$CORPUS/wildlife"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "wildlife: skip" && return 0
  mkdir -p "$dir"
  echo "wildlife: plant identification (USFS)..."
  fetch_url \
    "https://www.fs.usda.gov/rm/pubs_series/rmrs/gtr/rmrs_gtr414.pdf" \
    "$dir/usfs-rmrs-gtr-414-forest-plants-northern-idaho.pdf"
  stamp_fetched "$marker"
  echo "wildlife: done -> $dir"
}

fetch_sustainability() {
  local dir="$CORPUS/sustainability"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "sustainability: skip" && return 0
  mkdir -p "$dir"
  echo "sustainability: home food preservation (USDA)..."
  fetch_url \
    "https://nchfp.uga.edu/publications/usda/GUIDE%20TO%20HOME%20CANNING%20-%20Complete%20Guide%20to%20Home%20Canning.pdf" \
    "$dir/usda-complete-guide-home-canning.pdf" || true
  stamp_fetched "$marker"
  echo "sustainability: done -> $dir"
}

fetch_faith() {
  local dir="$CORPUS/faith/orthodox"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "faith/orthodox: skip" && return 0
  mkdir -p "$dir"
  echo "faith/orthodox: public-domain catechism (CCEL)..."
  local base="https://ccel.org/ccel/schaff/creeds2.vi.iii"
  local i
  for i in i ii iii iv v vi vii viii ix x; do
    fetch_url "${base}.${i}.html" "$dir/philaret-longer-catechism-${i}.html" || true
  done
  fetch_url \
    "https://www.oca.org/orthodoxy/the-orthodox-faith" \
    "$dir/oca-orthodox-faith-index.html" || true
  stamp_fetched "$marker"
  echo "faith/orthodox: done -> $dir (HTML; run pdf-to-text or ingest as-is)"
}

fetch_vehicle() {
  local dir="$CORPUS/vehicle"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "vehicle: skip" && return 0
  mkdir -p "$dir"
  echo "vehicle: sample PD military wheeled-vehicle maintenance (not modern OBD-II)..."
  fetch_url \
    "https://www.radionerds.com/images/c/cd/TM_9-2320-289-20.pdf" \
    "$dir/tm-9-2320-289-20-cucv-unit-maintenance.pdf"
  stamp_fetched "$marker"
  echo "vehicle: done -> $dir"
}

fetch_reloading() {
  local dir="$CORPUS/reloading"
  local marker="$dir/.fetched"
  [[ -f "$marker" ]] && echo "reloading: skip" && return 0
  mkdir -p "$dir"
  echo "reloading: ammunition identification/handling (not handloading)..."
  ia_download \
    "TM91300200AmmunitionGeneral" \
    "TM%209-1300-200%2C%20Ammunition%2C%20General.pdf" \
    "$dir/tm-9-1300-200-ammunition-general.pdf"
  stamp_fetched "$marker"
  echo "reloading: done -> $dir"
}

sync_chip_drive() {
  local kit="${CHIP_ROOT:-${PORTABLEAI_ROOT:-/Volumes/CHIP}}"
  if [[ "$SYNC_CHIP" == "0" ]] || [[ "$SYNC_PORTABLEAI" == "0" ]]; then
    return 0
  fi
  if [[ "$SYNC_CHIP" == "auto" ]] || [[ "$SYNC_PORTABLEAI" == "auto" ]]; then
    case "$ROOT" in
      /Volumes/CHIP/* | /Volumes/CHIP) return 0 ;;
    esac
  fi
  if [[ ! -d "$kit" ]]; then
    echo "CHIP: $kit not mounted; skip sync"
    return 0
  fi
  echo "Syncing to $kit ..."
  mkdir -p "$kit/rag/corpus" "$kit/scripts" "$kit/docs"
  rsync -a "$CORPUS/" "$kit/rag/corpus/"
  rsync -a "$ROOT/scripts/fetch-corpus.sh" "$kit/scripts/"
  rsync -a "$ROOT/docs/CORPUS-SOURCES.md" "$ROOT/docs/CORPUS-GAPS.md" "$kit/docs/" 2>/dev/null || true
  echo "CHIP sync complete."
}

# --- Main ---

mkdir -p \
  "$CORPUS/doctrine" "$CORPUS/playbooks" "$CORPUS/comms" "$CORPUS/medical" \
  "$CORPUS/water" "$CORPUS/food" "$CORPUS/wildlife" "$CORPUS/sustainability" \
  "$CORPUS/faith" "$CORPUS/vehicle" "$CORPUS/reloading"

if [[ -n "${PREPARED_URL:-}" ]]; then
  curl -fsSL -o "$PREPARED" "$PREPARED_URL" && echo "prepared.md: from PREPARED_URL"
fi

if topic_enabled legacy || topic_enabled playbooks || [[ "$FETCH_TOPICS" == "all" ]]; then
  clone_survivalmanual
  copy_shtf_playbooks
  fetch_prepared
fi

if topic_enabled comms || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_comms; fi
if topic_enabled doctrine || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_doctrine_fm; fi
if topic_enabled nbc || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_nbc; fi
if topic_enabled medical || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_medical; fi
if topic_enabled water || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_water; fi
if topic_enabled food || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_food; fi
if topic_enabled wildlife || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_wildlife; fi
if topic_enabled sustainability || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_sustainability; fi
if topic_enabled faith || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_faith; fi
if topic_enabled vehicle || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_vehicle; fi
if topic_enabled reloading || [[ "$FETCH_TOPICS" == "all" ]]; then fetch_reloading; fi

sync_chip_drive

echo ""
echo "Corpus fetch complete under $CORPUS"
echo "PDFs: ./scripts/pdf-to-text.sh   RAG: ./start-embed.sh & ./scripts/ingest-corpus.sh"
echo "Topics: FETCH_TOPICS=$FETCH_TOPICS  Large scans: FETCH_LARGE=$FETCH_LARGE"
