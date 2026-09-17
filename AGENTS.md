# AGENTS.md — CHIP build and verify (coding agents)

**CHIP** = **C**risis **H**ost-**I**ndependent **P**reparedness: portable offline chat + RAG on a USB SSD. This file is the one-shot path for agents. **Never commit secrets, API keys, or `.gguf` / `bin/llamafile` binaries.**

Repository: [github.com/mrdulasolutions/CHIP](https://github.com/mrdulasolutions/CHIP)

## 1. Clone

```bash
git clone https://github.com/mrdulasolutions/CHIP.git
cd CHIP
chmod +x build-chip.sh download-*.sh start*.sh scripts/*.sh setup/*.sh
```

## 2. Detect USB target

| OS | Typical mount |
|----|----------------|
| macOS | `/Volumes/CHIP` |
| Linux | `/media/$USER/CHIP` or `/run/media/$USER/CHIP` |
| Windows (Git Bash) | `/d/CHIP` or set `CHIP_DRIVE='D:/CHIP'` |

If nothing is mounted, pass an explicit path or folder (e.g. `./build-chip.sh ./chip-staging`).

## 3. Install to drive (one command)

```bash
./build-chip.sh /Volumes/CHIP              # kit only (scripts, docs, prompts)
./build-chip.sh /Volumes/CHIP --full       # + runtime, models, PDF tools, corpus, ingest
./build-chip.sh /Volumes/CHIP --online-default   # first install → --full if online
./build-chip.sh /Volumes/CHIP --minimal    # launchers + scripts only
```

`build-chip.sh` uses `rsync` **without** `--delete` so existing models, corpus, and `rag/index/knowledge.db` on the drive are preserved.

## 4. Optional downloads (manual, if not `--full`)

Run from the **target** directory (or repo root if developing in place):

```bash
./download-runtime.sh          # bin/llamafile + llamafile.exe
./download-embed-model.sh      # models/embed.gguf (~30 MB)
./download-chip-model.sh       # models/chip.gguf (~1.9 GB)
./download-pdf-tools.sh        # bin/pdf/ Poppler pdftotext
```

## 5. Corpus and PDFs

```bash
./scripts/fetch-corpus.sh                    # prepper markdown/PDFs (online)
./scripts/pdf-to-text.sh                     # PDF → .txt under rag/corpus/
# Windows: scripts\pdf-to-text.bat
```

Subset: `FETCH_TOPICS=medical,water ./scripts/fetch-corpus.sh`

## 6. RAG ingest (online, once)

Requires `python3`, embed model, and llamafile runtime:

```bash
./start-embed.sh &                           # or: nohup ./start-embed.sh >tmp/embed.log 2>&1 &
sleep 5
./scripts/ingest-corpus.sh                   # → rag/index/knowledge.db
```

## 7. Smoke test

```bash
./start-embed.sh &                           # terminal 1 if not running
./scripts/rag-query.sh "purify water"        # retrieval only
./scripts/rag-query.sh "purify water" --chat # needs ./start.sh chat on :8080
```

Grid-down launcher: `./start-rag.sh` (embed + chat in background).

## 8. What not to do

- Do not add Hugging Face tokens, passwords, or personal documents to git.
- Do not `git add` `models/*.gguf`, `bin/llamafile*`, `bin/pdf/`, or large `rag/corpus/` trees (see `.gitignore`).
- Do not run `rsync --delete` against a user’s `/Volumes/CHIP` without explicit instruction.

## 9. Human docs

- End users: [README.md](README.md)
- RAG details: [docs/RAG.md](docs/RAG.md)
- Human quick start: [QUICKSTART.md](QUICKSTART.md) · autostart: [docs/user/AUTOSTART.md](docs/user/AUTOSTART.md)
- Install scripts live in `setup/`; root `build-chip.sh` and `download-*.sh` are exFAT-safe wrappers.
