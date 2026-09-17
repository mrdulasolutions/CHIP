@echo off
setlocal
cd /d "%~dp0"
if not exist "models\embed.gguf" (
  echo Missing models\embed.gguf — run download-embed-model.sh while online.
  exit /b 1
)
if not exist "bin\llamafile.exe" (
  echo Missing bin\llamafile.exe — run download-runtime.sh first.
  exit /b 1
)
if not defined EMBED_PORT set EMBED_PORT=8081
echo Embedding server: http://127.0.0.1:%EMBED_PORT%
bin\llamafile.exe -m models\embed.gguf --server --host 127.0.0.1 --port %EMBED_PORT% --embedding
