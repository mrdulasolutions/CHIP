# Models on the drive

Place **GGUF** weights here. Filenames must match what the launchers expect:

| File | Role |
|------|------|
| `tiny.gguf` | Weak hosts (~8 GB RAM): ~1B–4B instruct, Q4_K_M |
| `chip.gguf` | **CHIP default chat** (~8 GB RAM): Hermes 3 Llama 3.2 **3B** Q4_K_M (~1.9 GB). Run `./download-chip-model.sh` |
| `chat.gguf` | Daily driver (**16 GB+ RAM**): ~7B–8B instruct, Q4_K_M (~4.5–5 GB) |
| `embed.gguf` | RAG embeddings: **bge-small-en-v1.5** Q4_K_M (~30 MB). Run `./download-embed-model.sh` |

You can rename any downloaded `.gguf` to match a profile, or use `./start.sh tiny|chip|chat` / `start.bat` equivalents.

## CHIP model (`chip.gguf`)

| Item | Value |
|------|--------|
| Default download | [bartowski/Hermes-3-Llama-3.2-3B-GGUF](https://huggingface.co/bartowski/Hermes-3-Llama-3.2-3B-GGUF) → `Hermes-3-Llama-3.2-3B-Q4_K_M.gguf` |
| Install | `./download-chip-model.sh` → `models/chip.gguf` |
| Size | ~1.9 GB on disk |
| RAM | **8 GB** host: leave headroom for OS + browser; prefer **`chip`** or **`tiny`**. |
| Behavior | Hermes 3 is a **reduced-refusal instruct** fine-tune (fewer “I can’t help” blocks on preparedness topics). You are responsible for lawful, safe use offline. |

**16 GB+ hosts:** keep or add `chat.gguf` with an **8B** instruct (e.g. Hermes-3-Llama-3.1-8B Q4_K_M from `bartowski`, ~4.9 GB) and run `./start.sh chat`.

Other community “uncensored” builds (Dolphin, abliterated Qwen/Llama) may work in llamafile if you download GGUF Q4_K_M yourself and save as `chip.gguf` or a custom name (then symlink/rename to `chip.gguf`).

## Where to download (online, once)

Use **instruct** models in **GGUF Q4_K_M** (or Q4_K_S) from Hugging Face. Common publishers: `bartowski`, `unsloth`, `Qwen`, `Meta`.

Examples (search for current GGUF builds; URLs change):

- **Tiny:** Qwen3.5 0.8B/1.5B, Llama 3.2 3B Instruct, Gemma 2/3 4B IT
- **Chat:** Llama 3.1 8B Instruct, Qwen3 8B Instruct, Mistral 7B Instruct v0.3, Hermes-3-Llama-3.1-8B Q4_K_M

## Size vs RAM

- Free **host** RAM should be **larger than the GGUF file size**.
- Do not commit `.gguf` files to git; they stay on the X10 Pro only.

## Windows note

Keep weights as separate `.gguf` files. Do not bundle multi-GB models into a single `.exe` (4 GB executable limit on Windows).

## Embedding model (RAG)

Default file: **`embed.gguf`** (symlink or rename from download).

| Item | Value |
|------|--------|
| Model | [BAAI/bge-small-en-v1.5](https://huggingface.co/BAAI/bge-small-en-v1.5) |
| GGUF (Q4_K_M) | [CompendiumLabs/bge-small-en-v1.5-gguf](https://huggingface.co/CompendiumLabs/bge-small-en-v1.5-gguf) → `bge-small-en-v1.5-q4_k_m.gguf` (also: [bartowski](https://huggingface.co/bartowski/bge-small-en-v1.5-GGUF)) |
| Install | `./download-embed-model.sh` copies to `models/embed.gguf` |
| Server | `./start-embed.sh` → `127.0.0.1:8081` with `--embedding` |

Use the **same** `embed.gguf` for `./scripts/ingest-corpus.sh` and `./scripts/rag-query.sh`. See [docs/RAG.md](../docs/RAG.md).
