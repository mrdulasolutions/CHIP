# setup/

**Online-only** install and download scripts. Run from the **drive root** via thin wrappers (exFAT does not reliably support symlinks).

| Script | Purpose |
|--------|---------|
| `build-chip.sh` | Copy kit to USB; optional `--full` pipeline |
| `download-runtime.sh` | `bin/llamafile` |
| `download-embed-model.sh` | `models/embed.gguf` |
| `download-chip-model.sh` | `models/chip.gguf` |
| `download-pdf-tools.sh` | `bin/pdf/` Poppler |

Examples (from drive root):

```bash
./build-chip.sh /Volumes/CHIP --full
./download-chip-model.sh
```

Grid-down users normally **do not** open this folder — use **Launch CHIP** at the root and [QUICKSTART.md](../QUICKSTART.md).
