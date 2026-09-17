# Corpus sources (prepper RAG)

Offline corpus for **llamafile** chat tools and **RAG** (`scripts/ingest-corpus.sh`). Embedding model: `models/embed.gguf` (bge-small-en-v1.5). Do not reuse indexes built with other embedding models.

## Folder layout (`rag/corpus/`)

| Path | Topics |
|------|--------|
| `doctrine/survivalmanual/` | General survival (GitHub markdown) |
| `doctrine/fm/` | Army / USMC field manuals (PDF) |
| `doctrine/nbc/` | CBRN + citizen nuclear/radiological (PDF) |
| `comms/ham/` | Amateur radio regulations (PDF) |
| `comms/morse/` | Morse / visual signaling (PDF + txt) |
| `medical/` | First aid, disaster wound care (PDF) |
| `water/` | Disinfection, field water, sanitation (PDF) |
| `food/foraging/`, `food/hunting/` | Wild plants, game care (PDF + text) |
| `wildlife/` | Plant ID (USFS PDF) |
| `sustainability/` | Food preservation (USDA PDF) |
| `faith/orthodox/` | PD / historical catechism (HTML) |
| `vehicle/` | Military vehicle maintenance sample (PDF) |
| `reloading/` | Ammunition safety/ID—not handloading (PDF) |
| `playbooks/` | Community checklists (markdown) |

## Fetch script

```bash
./scripts/fetch-corpus.sh
```

| Variable | Default | Meaning |
|----------|---------|---------|
| `FETCH_TOPICS` | `all` | Comma list: `legacy`, `comms`, `doctrine`, `nbc`, `medical`, `water`, `food`, `wildlife`, `sustainability`, `faith`, `vehicle`, `reloading`, `playbooks` |
| `FETCH_LARGE` | `0` | Set `1` to download FM 3-05.70 (~280 MB archive scan) |
| `SYNC_CHIP` | `auto` | If repo is not on `/Volumes/CHIP`, `rsync` corpus + docs to `CHIP_ROOT` (legacy: `SYNC_PORTABLEAI`, `PORTABLEAI_ROOT`) |
| `PREPARED_URL` | — | Override URL for `playbooks/prepared.md` |

After PDFs: `./scripts/pdf-to-text.sh` then `./scripts/ingest-corpus.sh`.

## Firecrawl (online prep only)

| Use Firecrawl when | Skip Firecrawl when |
|--------------------|---------------------|
| You need **clean markdown** from a **small allowlist** of HTML pages (extension sites, single wiki articles) | Source is already a **PDF** on gov/archive — use `curl` + `pdf-to-text.sh` |
| Site has heavy JS and `curl` returns empty chrome | Bulk manual libraries — use archive.org **item** URLs, not site crawls |
| You will **self-host once**, export `.md` to the USB, and **not** depend on Firecrawl at runtime | Entire domains (orthodox publishers, ARRL, Haynes) — copyright/ToS risk |

**Verdict:** For this kit, **self-hosted Firecrawl is overkill** for 90% of sources. Prefer `fetch-corpus.sh` (`curl` + archive.org) + bundled `pdftotext`. Optional Firecrawl pass: 5–10 extension HTML pages you list in a local `scripts/firecrawl-allowlist.txt` (not shipped)—run once online, save `.md` into `rag/corpus/`.

## Source table

License key: **PD** = US government work / public domain mark; **CC** = Creative Commons (verify version); **⚠** = copyright or redistribution risk.

| Topic | Source | Format | License | Fetch command | Notes |
|-------|--------|--------|---------|---------------|-------|
| **Morse** | NAVEDTRA 14243 Signalman (maritime.org) | PDF | PD (US Navy) | `./scripts/fetch-corpus.sh` → `comms/morse/` | Morse + semaphore drills; not ham-only |
| **Morse** | Archive.org OCR text (same manual) | TXT | PD | (in script) | Smaller; good for RAG without PDF |
| **Ham** | 47 CFR Part 97 (GovInfo) | PDF | PD (US law) | (in script) | Prefer GovInfo over **⚠ ARRL** Part 97 PDF |
| **Ham** | ARRL Handbook / license manuals | Book | **⚠ ARRL** | Do not fetch | Buy for personal shelf; not for corpus |
| **NBC** | FM 3-11 CBRN (2011, GlobalSecurity mirror) | PDF | PD (US govt) | `FETCH_TOPICS=nbc ./scripts/fetch-corpus.sh` | Mirror; also on archive.org |
| **NBC** | FEMA *Are You Ready?* | PDF | PD | (in script) | Nuclear/bio/chem citizen sections |
| **NBC** | EPA radiological protective actions comms tool | PDF | PD | (in script) | Shelter, food/water after radiation |
| **Field manuals** | FM 21-76 Survival (1992, bits.de) | PDF | PD | `FETCH_TOPICS=doctrine` | Core survival doctrine |
| **Field manuals** | MCRP 3-02F / 3-02H (archive.org) | PDF | PD | (in script) | USMC survival / evasion |
| **Field manuals** | FM 3-05.70 (archive.org) | PDF | PD | `FETCH_LARGE=1` | Large scan; optional |
| **USMC** | Same as MCRP 3-02F/H | PDF | PD | (in script) | See `doctrine/fm/` |
| **Water** | EPA emergency disinfection | PDF | PD | `FETCH_TOPICS=water` | Bleach, boiling, Ca(OCl)₂ |
| **Water** | TB MED 577 (armypubs.army.mil) | PDF | PD | (in script) | Official field water surveillance |
| **Water** | FM 4-25.12 field sanitation | PDF | PD | (in script) | Mirror host; water treatment chapter |
| **Medical** | FM 4-25.11 First Aid (archive.org) | PDF | PD | `FETCH_TOPICS=medical` | Buddy aid; not a hospital textbook |
| **Medical** | CDC emergency wound care | PDF | PD | (in script) | Disaster / flood wound hygiene |
| **Medical** | Hesperian *Where There Is No Doctor* | Book | **⚠** | Do not fetch | See [CORPUS-GAPS.md](CORPUS-GAPS.md) |
| **Foraging** | USFS PNW-GTR-513 special forest products | PDF | PD | `FETCH_TOPICS=food` | Edible/medicinal plants, mushrooms |
| **Foraging** | materia-medica (GitHub) | TXT/MD | CC0 | (in script) | Herbal notes; not survival-first |
| **Hunting** | UC ANR deer/elk field-to-table | PDF | Extension (check) | (in script) | Field dressing, food safety |
| **Hunting** | MSU extension big-game field care | PDF | Extension (check) | (in script) | |
| **Fishing** | (no dedicated fetch) | — | — | Add state DNR PDFs manually | FM 21-76 / survival manuals cover basic traps |
| **Wildlife** | USFS RMRS-GTR-414 plant ID | PDF | PD | `FETCH_TOPICS=wildlife` | Northern Idaho; useful ID patterns |
| **Sustainability** | USDA Complete Guide to Home Canning | PDF | PD | `FETCH_TOPICS=sustainability` | URL may change; see nchfp.uga.edu |
| **Vehicle** | TM 9-2320-289-20 CUCV maintenance | PDF | PD | `FETCH_TOPICS=vehicle` | **Not** modern cars — see gaps doc |
| **Vehicle** | Haynes / Chilton | Book | **⚠** | Do not fetch | User-purchased only |
| **Reloading** | TM 9-1300-200 Ammunition General | PDF | PD | `FETCH_TOPICS=reloading` | Safety/ID — **not** load recipes |
| **Reloading** | Speer / Hornady manuals | Book | **⚠** | Do not fetch | See gaps doc |
| **Orthodox** | St. Philaret Longer Catechism (CCEL / Schaff) | HTML | PD translation | `FETCH_TOPICS=faith` | Multi-page HTML |
| **Orthodox** | OCA *The Orthodox Faith* index | HTML | OCA site terms | (in script) | Link page only; do not scrape publishers |
| **Orthodox** | Wikisource / historical councils | Wiki | PD/CC | Manual export | Prefer Wikisource `action=render` |
| **General** | survivalmanual.github.io | MD | Check repo LICENSE | `FETCH_TOPICS=legacy` | Shallow clone |
| **General** | XyraSinclair/SHTF playbooks | MD | Check repo LICENSE | (in script) | Markdown only |
| **General** | Your PDFs / notes | any | Your responsibility | `cp` → `rag/corpus/` | `pdf-to-text.sh` for PDFs |

### Manual archive.org examples (not all in script)

```bash
# FM 4-25.11 — same as script uses
curl -fL -o rag/corpus/medical/fm-4-25-11-first-aid.pdf \
  'https://archive.org/download/FM4-25x11/FM4-25x11.pdf'

# TM 9-1300-200
curl -fL -o rag/corpus/reloading/tm-9-1300-200.pdf \
  'https://archive.org/download/TM91300200AmmunitionGeneral/TM%209-1300-200%2C%20Ammunition%2C%20General.pdf'
```

## Kit integration (unchanged)

| Source | In default fetch? | Location |
|--------|-------------------|----------|
| Survival Manual (GitHub) | Yes | `doctrine/survivalmanual/` |
| SHTF playbooks | Yes | `playbooks/shtf/` |
| Prepared checklist | Optional | `playbooks/prepared.md` |
| SurvivalRAG / Ollama / encoderfile | **No** | Wrong stack for this kit |

## Licenses

You are responsible for compliance when copying third-party material onto a shared drive. US government works are generally PD; university extension PDFs vary—often free for personal/educational use. **Never** commit copyrighted repair, reloading, or ARRL books to a public git repo.

Weak PD areas: [CORPUS-GAPS.md](CORPUS-GAPS.md).
