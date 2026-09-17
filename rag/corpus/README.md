# Document corpus

Reference files for **chat tools** (`start.sh` read/grep) and **RAG** (`scripts/ingest-corpus.sh`).

## Layout (prepper bundle)

| Path | Source |
|------|--------|
| `doctrine/survivalmanual/` | [survivalmanual.github.io](https://github.com/survivalmanual/survivalmanual.github.io) |
| `doctrine/fm/`, `doctrine/nbc/` | Army / USMC / FEMA / EPA PDFs — `./scripts/fetch-corpus.sh` |
| `comms/` | FCC Part 97, Navy morse/signalman |
| `medical/`, `water/` | FM 4-25.11, CDC, EPA, TB MED 577 |
| `food/`, `wildlife/`, `sustainability/` | USFS/USDA/extension PDFs + CC0 foraging notes |
| `faith/orthodox/` | PD catechism HTML (CCEL) |
| `vehicle/`, `reloading/` | Sample PD military TMs — see gaps doc |
| `playbooks/shtf/` | [SHTF](https://github.com/XyraSinclair/SHTF) playbooks `*.md` only |
| `playbooks/prepared.md` | Community checklist |
| Your files | `.md`, `.txt`, or `.txt` from PDFs |

Full source list: [docs/CORPUS-SOURCES.md](../../docs/CORPUS-SOURCES.md). Gaps: [docs/CORPUS-GAPS.md](../../docs/CORPUS-GAPS.md).

## Supported formats

| Format | How to use |
|--------|------------|
| `.md`, `.txt` | Drop files here. RAG: re-run `./scripts/ingest-corpus.sh`. |
| `.pdf` | Run **`./scripts/pdf-to-text.sh`** (bundled Poppler in `bin/pdf/`). |
| `.html` | Readable by chat tools; for RAG, convert to `.txt` or ingest as-is if plain enough. |

## Fetch while online

```bash
./scripts/fetch-corpus.sh
# Subset: FETCH_TOPICS=medical,water ./scripts/fetch-corpus.sh
# Big FM 3-05.70 scan: FETCH_LARGE=1 ./scripts/fetch-corpus.sh
```

Cloned trees and large PDF dirs are gitignored; they live on the portable drive.

## Privacy

Files stay on the portable drive. Nothing is uploaded unless you paste content into the chat yourself.
