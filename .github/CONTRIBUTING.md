# Contributing to CHIP

Thank you for helping improve Crisis Host-Independent Preparedness (CHIP).

## Before you open a PR

1. Keep changes focused (scripts, docs, small corpus samples).
2. Do **not** commit `models/*.gguf`, `bin/llamafile`, `bin/pdf/`, or large `rag/corpus/` trees.
3. Run shellcheck-friendly bash where possible; test on macOS or Linux if you touch `*.sh`.
4. Update [README.md](../README.md) or [AGENTS.md](../AGENTS.md) when behavior changes.

## Development flow

```bash
git clone https://github.com/mrdulasolutions/CHIP.git
cd CHIP
./build-chip.sh ./staging --minimal   # fast iteration
./build-chip.sh /Volumes/CHIP         # sync to hardware (no --delete)
```

## License

Contributions are licensed under the same [Apache License 2.0](../LICENSE) as the project.

## Security

Do not open issues with secrets, personal documents, or live credentials. Report sensitive security concerns privately to the repository owner.
