# CHIP quick start (1 page)

**C**risis **H**ost-**I**ndependent **P**reparedness — offline AI on your USB SSD. Everything runs on **127.0.0.1** only (no cloud).

## Grid-down (new computer, already built drive)

| Do this | macOS | Windows | Linux |
|---------|--------|---------|--------|
| **Best default** | Double-click **Launch CHIP** | **Launch CHIP.bat** | `./Launch CHIP.sh` |
| Chat only (no RAG) | **Launch Chat** | **Launch Chat.bat** | `./Launch Chat.sh` |
| Stop servers | **Stop CHIP** | **Stop CHIP.bat** | `./Stop CHIP.sh` |
| Browser | http://127.0.0.1:8080 | same | same |

**Launch CHIP** starts RAG (embed + chat) when `rag/index/knowledge.db` exists; otherwise chat only.

First run: approve **llamafile** (Gatekeeper / SmartScreen). See [README.md](README.md) troubleshooting.

## First-time build (online, at home)

From a clone or copy of this kit:

```bash
chmod +x build-chip.sh start*.sh scripts/*.sh
./build-chip.sh /Volumes/CHIP --full    # or your drive path
```

That copies the kit, downloads runtime/models/tools, fetches corpus, and builds the RAG index.

Manual steps (same result): root wrappers call **`setup/`** — e.g. `./download-runtime.sh` → `setup/download-runtime.sh`.

## Where things live

| Path | Purpose |
|------|---------|
| **Launch CHIP / Chat / Stop** | Double-click entry points (drive root) |
| `start-rag.sh`, `start.sh` | Terminal launch (same as launchers) |
| `setup/` | Install & downloads (`build-chip.sh`, `download-*.sh`) |
| `scripts/` | Corpus fetch, PDF→text, RAG ingest & query |
| `models/` | `.gguf` models (on drive, not in git) |
| `bin/` | llamafile + PDF tools (on drive) |
| `rag/corpus/` | Your documents |
| `rag/index/` | `knowledge.db` (built at home) |
| `docs/user/` | Short guides (autostart, shortcuts) |
| `docs/` | RAG, corpus sources, technical notes |
| `README.md` | Full manual |
| `AGENTS.md` | Coding-agent playbook |

## Ask the corpus (terminal)

```bash
./scripts/rag-query.sh "how do I purify water?"
./scripts/rag-query.sh "your question" --chat    # needs chat running
```

More: [docs/user/AUTOSTART.md](docs/user/AUTOSTART.md) · [docs/RAG.md](docs/RAG.md)
