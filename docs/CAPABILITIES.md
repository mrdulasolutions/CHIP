# What this kit enables vs full llamafile

`start.sh` / `start.bat` start **text instruct** chat with a **local document corpus** in server mode:

```text
llamafile -m models/tiny.gguf|chat.gguf --server --host 127.0.0.1 --port 8080 \
  --tools read_file,grep_search,file_glob_search \
  --confine-reads --media-path rag/corpus
```

Terminal-only mode (`./start.sh tui`) does **not** pass document tools (llamafile applies read confinement only in `--server` mode).

## Why not encoderfile?

[encoderfile](https://github.com/mozilla-ai/encoderfile) is a **separate** Mozilla.ai project for running **ONNX embedding models** only. It is **not** a document reader: no PDF parsing, no markdown corpus tools, no chunking or search UI. This kit also targets **one portable tree on the drive**; encoderfile does **not** ship Windows prebuilts and expects per-OS ONNX runtime binaries. For markdown/text we use **llamafile’s built-in read tools**; for PDFs we bundle **Poppler `pdftotext`** on the drive; for future semantic search see [RAG.md](RAG.md) (planned **llamafile `--embedding`**, not encoderfile).

## Web UI (llamafile 0.10.6)

| Feature | With this kit |
|---------|----------------|
| Text chat | Yes |
| Paste text | Yes |
| Upload **`.txt`** (paperclip / drag-drop) | Yes — content goes into the **prompt** (not a search index). Watch context size on large files. |
| **`.md` / `.txt` on the drive** | Yes — put files in **`rag/corpus/`** and ask the model to read or grep them (built-in tools). |
| Upload **PDF** | **Not reliable** in the UI — convert on the drive with `scripts/pdf-to-text.sh` / `.bat`, then use the `.txt` in `rag/corpus/`. |
| Images / vision | No — needs a **multimodal** GGUF + `mmproj`, not `tiny`/`chat`. |
| RAG over many files (embeddings index) | Yes — [RAG.md](RAG.md) (`embed.gguf` + `knowledge.db`). |

## Markdown and plain text (self-contained)

1. Copy **`.md`** / **`.txt`** into **`rag/corpus/`** on the portable drive.
2. Start **`./start.sh`** or **`start.bat`** (HTTP server, not `tui`).
3. Ask in chat, e.g. “Read `manual.md`” or “grep for `warranty` in the corpus.”

The server enables only **`read_file`**, **`grep_search`**, and **`file_glob_search`**, with **`--confine-reads`** and **`--media-path rag/corpus`**, so tool reads stay under the corpus (plus llamafile’s weights dirs). Bind stays **`127.0.0.1`**.

**How to ask:** Use clear filenames. Smaller models may need: “Use the read_file tool on `rag/corpus/notes.md`.”

## PDF workflow (self-contained on the drive)

The model does **not** read PDF bytes directly. Poppler runs **from the kit**, not from the host OS:

| Step | Action |
|------|--------|
| 1 | While online once: **`./download-pdf-tools.sh`** → fills **`bin/pdf/`** (macOS, Linux x86_64, Windows). Binaries are **gitignored**; they live on the SSD. |
| 2 | Copy PDFs into **`rag/corpus/`**. |
| 3 | Run **`./scripts/pdf-to-text.sh`** (macOS/Linux) or **`scripts\pdf-to-text.bat`** (Windows). Scripts pick **`bin/pdf/<platform>/pdftotext`** and set library paths as needed. |
| 4 | Or run **`./scripts/ingest-pdfs.sh`** (same as step 3). |
| 5 | Chat about the generated **`.txt`** files (tools or UI paste/upload). |

**Download sources** (see `download-pdf-tools.sh`):

- **Windows:** [oschwartz10612/poppler-windows](https://github.com/oschwartz10612/poppler-windows/releases) → `bin/pdf/windows/`
- **macOS:** Homebrew poppler bottle or conda-forge poppler via micromamba → `bin/pdf/macos/`
- **Linux x86_64:** Debian bookworm `poppler-utils` + bundled `.so` deps (built via Docker when you run the downloader on a Mac) → `bin/pdf/linux-x86_64/`

## Not enabled in v1 (available in llamafile with extra setup)

| Capability | How |
|------------|-----|
| `--embedding` | Second server + `models/embed.gguf` on another port |
| Full `--tools all` | Includes write/shell tools — not used by this kit |
| Terminal `/upload` | Combined TUI+server modes; default `./start.sh` is HTTP UI only |
| Whisper / diffusion | Separate `whisperfile` / `diffusionfile` binaries |

For a permanent library across reboots and large corpora with semantic search, use the planned **RAG** path in [RAG.md](RAG.md) (embeddings + SQLite — **not** encoderfile).
