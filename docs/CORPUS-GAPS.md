# Corpus gaps and substitutes

Some prepper topics have **weak or no** public-domain coverage that matches what people expect from commercial books. This file lists gaps, copyright risks, and practical substitutes for offline RAG.

## Vehicle repair (modern passenger cars)

| Gap | Why | Substitutes |
|-----|-----|-------------|
| Haynes / Chilton / OEM service manuals | Copyrighted; publisher-licensed | User-owned PDFs you legally purchased; **generic** PD military TMs (e.g. TM 9-2320-289-20 for CUCV) teach PMCS, fluids, electrical basics—not your daily driver |
| OBD-II, CAN bus, hybrid/EV high voltage | Mostly proprietary scan data and OEM procedures | FM 21-76 / survival corpus for **improvised** field fixes; print your vehicle’s **owner manual** (often free from manufacturer) while online |
| YouTube / forum threads | Not redistributable; ephemeral URLs | Copy **your own notes** into `rag/corpus/vehicle/notes/` as `.md` |

**Script default:** `rag/corpus/vehicle/tm-9-2320-289-20-cucv-unit-maintenance.pdf` (~14 MB). Add vehicle-specific material manually.

## Reloading / handloading

| Gap | Why | Substitutes |
|-----|-----|-------------|
| Modern handloading manuals (Speer, Hornady, Lee, etc.) | Copyrighted | None for redistribution—buy print/PDF and store **locally** if licensed for personal use |
| Load data spreadsheets / community PDFs | Often ARR or unknown license | Do not bulk-ingest |
| Army “reloading” procedures | **No** standard PD handloading manual | TM 9-1300-200 (**ammunition identification, storage, safety**)—script fetches this; not a recipe book |

**Safety:** RAG must not be treated as authoritative for pressure/safe loads. Prefer manufacturer data you own.

## Amateur radio (beyond rules)

| Gap | Why | Substitutes |
|-----|-----|-------------|
| ARRL Handbook, license study guides | **ARRL copyrighted** | **47 CFR Part 97** (govinfo PDF)—script fetches; FCC question pools are public but change |
| Club repeater directories | Local / permission | Copy your club’s **permission-granted** CSV into `rag/corpus/comms/local/` |

## Physicians / clinical depth

| Gap | Why | Substitutes |
|-----|-----|-------------|
| *Where There Is No Doctor* (Hesperian) | **Not PD** in US | FM 4-25.11, CDC wound care (script); older **PD** military medical TMs on archive.org (verify edition) |
| Merck Manual, UpToDate | Licensed | Not for corpus redistribution |

## Foraging / wild food

| Gap | Why | Substitutes |
|-----|-----|-------------|
| *Peterson* / *National Audubon* field guides | Copyrighted | USFS/USDA guides (script); FM 21-76 plant chapters; **regional** extension PDFs you download per state |
| Photo-heavy apps | License / size | MIT **Urban-Forager** (optional manual clone); CC0 **materia-medica** (script) |

## Orthodox religion

| Gap | Why | Substitutes |
|-----|-----|-------------|
| Popular modern catechisms (e.g. some parish booklets) | Publisher copyright | St. Philaret **Longer Catechism** (CCEL HTML, PD translation); OCA web pages—**check** per-page terms; Wikisource / historical councils |
| Proprietary Orthodox publishers | Scraping ToS risk | Do not scrape; use PD historical texts only |

## NBC / CBRN (civilian depth)

| Gap | Why | Substitutes |
|-----|-----|-------------|
| Latest classified-adjacent TTPs | Distribution controlled | FM 3-11 (2011 mirror), FEMA *Are You Ready?*, EPA radiological comms tool (script) |
| Industrial MSDS for every chemical | Too large / site-specific | SDS for **your** household chemicals copied manually |

## What to add manually (highest value)

1. **Your** vehicle year/make owner manual + torque specs you care about.
2. **Your** region: state fish & game regulations (often free PDF), native plant extension bulletins.
3. **Your** orthodox parish / jurisdiction: materials explicitly marked for free distribution.
4. **Your** ham: programmed radio cheat sheet, local net frequencies (if allowed).

See [CORPUS-SOURCES.md](CORPUS-SOURCES.md) for fetch commands and licenses.
