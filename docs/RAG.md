# Offline RAG (prepper knowledge)

Semantic search over `rag/corpus/` using the **same llamafile 0.10.6 binary** as chat:

| Service | Port | Model |
|---------|------|--------|
| Chat | 8080 | `models/chat.gguf`, `models/chip.gguf`, or `models/tiny.gguf` |
| Embeddings | 8081 | `models/embed.gguf` (bge-small-en-v1.5 Q4_K_M) |

Index: single file **`rag/index/knowledge.db`** (SQLite, float32 blobs + Python cosine search). No Chroma, no Ollama, no encoderfile.

**Important:** The embedding model at ingest and query must match. If you change `embed.gguf`, run **`./scripts/ingest-corpus.sh`** again.

## Prep at home (online)

1. **Runtime & chat model** (if not done): `./download-runtime.sh`, add `models/chat.gguf`.
2. **Embedding model:** `./download-embed-model.sh` → `models/embed.gguf` (~30 MB).
3. **Corpus:**
   ```bash
   chmod +x scripts/*.sh download-embed-model.sh start-embed.sh start-rag.sh
   ./scripts/fetch-corpus.sh
   ```
   Add your own `.md` / `.txt` under `rag/corpus/`. For PDFs:
   ```bash
   ./download-pdf-tools.sh
   ./scripts/pdf-to-text.sh
   ```
4. **Index** (embedding server must be running):
   ```bash
   ./start-embed.sh &    # or second terminal
   ./scripts/ingest-corpus.sh
   ```
   Large corpus: test first with `RAG_LIMIT_FILES=5 ./scripts/ingest-corpus.sh`.
   Chunks are split to ~900 characters so they fit llamafile’s default **512-token** embed slot.

   Full index (all `.md` under `rag/corpus/`): `./scripts/ingest-corpus.sh` (may take 30+ minutes).

5. Copy the whole drive folder to the SSD. **Do not commit** `knowledge.db`, `embed.gguf`, or cloned repos to git.

## Grid-down (offline)

**Option A — one command (background):**
```bash
./start-rag.sh
./scripts/rag-query.sh "how do I disinfect water?"
./scripts/rag-query.sh "signs of hypothermia" --chat
./start-rag.sh stop
```

**Option B — two terminals:**
```bash
# Terminal 1
./start-embed.sh

# Terminal 2
./start.sh chat
```

Then query context only (embed server required):
```bash
./scripts/rag-query.sh "escape vehicle fire"
```

Or RAG-augmented chat (`--chat` needs chat on 8080):
```bash
./scripts/rag-query.sh "tourniquet when to use" --chat
```

Browser UI at http://127.0.0.1:8080 still has **read/grep tools** on `rag/corpus/`; RAG adds **semantic** retrieval from the index.

## RAM (8 GB hosts)

- Run **ingest** at home, then you can stop the embed server and use only chat + prebuilt `knowledge.db` for queries (embed server still needed at query time for semantic search).
- For tight RAM: query with `./scripts/rag-query.sh` (context only), paste into chat manually, or use file tools instead of `--chat`.

## Prompting

System instructions for `--chat`: `rag/prompts/system-rag.txt` (cite sources, medical caution).

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Embedding server not reachable` | `./start-embed.sh` on 8081 |
| Empty / weak answers | Re-run ingest; add corpus; increase `RAG_TOP_K` |
| Wrong facts | Model may hallucinate — prefer context-only output; verify against source files |
| `python3` missing | Ingest/query need Python 3 (common on macOS/Linux; install once on Windows for prep) |

## What we deliberately skip

See [CORPUS-SOURCES.md](CORPUS-SOURCES.md): SurvivalRAG pre-indexes, waycore vectors, encoderfile, Ollama stacks.
