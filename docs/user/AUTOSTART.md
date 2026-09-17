# Autostart and easy launch

Modern operating systems **block USB autorun** for security. CHIP does not rely on `autorun.inf` or macOS login items bundled on the drive.

## What works

| Goal | macOS | Windows | Linux |
|------|--------|---------|--------|
| **RAG + chat** (if index built) | **Launch CHIP.command** | **Launch CHIP.bat** | `./Launch CHIP.sh` |
| **Chat only** (lighter) | **Launch Chat.command** | **Launch Chat.bat** | `./Launch Chat.sh` |
| **Stop servers** | **Stop CHIP.command** | **Stop CHIP.bat** | `./Stop CHIP.sh` |
| Terminal | `./start-rag.sh` / `./start.sh chip` | `start.bat chip` | same as macOS |

If RAG was built (`rag/index/knowledge.db` exists), **Launch CHIP** prefers **`start-rag.sh`** (embedding + chat). **Launch Chat** always runs **`./start.sh chip`** (no embed server).

See also: [QUICKSTART.md](../../QUICKSTART.md) · [00-READ-ME-FIRST.txt](../../00-READ-ME-FIRST.txt) (plain text for Windows).

## Desktop shortcut (recommended)

1. Plug in the SSD (volume label **`CHIP`** helps).
2. Open the drive in the file manager.
3. Drag **`Launch CHIP.command`** (Mac) or **`Launch CHIP.bat`** (Windows) to the desktop while holding **Option** (Mac) or **Alt** (Windows) to create a shortcut/alias.
4. On first run, approve the llamafile binary (macOS Gatekeeper / Windows SmartScreen). See [README.md](../../README.md) troubleshooting.

## Windows “Open folder” once

You can set Explorer to open the CHIP folder when the drive is inserted (Settings → Devices → AutoPlay → “Open folder to view files” for removable drives). That is **not** the same as running CHIP automatically; you still double-click the launcher.

## What does not work

- **USB autorun** executing CHIP without user action (disabled on Windows 10+, macOS, most Linux desktops).
- **Silent background service** from a removable drive without admin install (by design).
- **iOS / Android / ChromeOS** hosts (no supported llamafile target).

## Optional: login item (advanced)

If the drive is always at the same mount path, power users may add a login item or scheduled task that runs the launcher script. Paths change when drive letters or volume names differ; prefer a desktop shortcut to the launcher on the SSD itself.
