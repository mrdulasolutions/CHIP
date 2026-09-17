@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "BIN=%ROOT%\bin\llamafile.exe"
set "MODELS=%ROOT%\models"
set "CORPUS=%ROOT%\rag\corpus"
set "TMPDIR_ON_DRIVE=%ROOT%\tmp"
if not defined PORT set "PORT=8080"

set "PROFILE="
set "MODE=server"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="tiny" set "PROFILE=tiny" & shift & goto parse_args
if /I "%~1"=="chat" set "PROFILE=chat" & shift & goto parse_args
if /I "%~1"=="chip" set "PROFILE=chip" & shift & goto parse_args
if /I "%~1"=="tui" set "MODE=tui" & shift & goto parse_args
if /I "%~1"=="-h" goto usage
if /I "%~1"=="--help" goto usage
echo Unknown argument: %~1
goto usage

:args_done

if not exist "%BIN%" (
  if exist "%ROOT%\bin\llamafile" (
    copy /Y "%ROOT%\bin\llamafile" "%BIN%" >nul
  ) else (
    echo Missing %BIN% — run download-runtime.sh on Mac/Linux or download llamafile from GitHub into bin\
    exit /b 1
  )
)

if not exist "%TMPDIR_ON_DRIVE%" mkdir "%TMPDIR_ON_DRIVE%"
if not exist "%CORPUS%" mkdir "%CORPUS%"
set "TMP=%TMPDIR_ON_DRIVE%"
set "TEMP=%TMPDIR_ON_DRIVE%"
set "TMPDIR=%TMPDIR_ON_DRIVE%"

set "MODEL="
if /I "%PROFILE%"=="tiny" (
  if exist "%MODELS%\tiny.gguf" set "MODEL=%MODELS%\tiny.gguf"
) else if /I "%PROFILE%"=="chip" (
  if exist "%MODELS%\chip.gguf" set "MODEL=%MODELS%\chip.gguf"
) else if /I "%PROFILE%"=="chat" (
  if exist "%MODELS%\chat.gguf" set "MODEL=%MODELS%\chat.gguf"
) else (
  if exist "%MODELS%\chat.gguf" set "MODEL=%MODELS%\chat.gguf"
  if not defined MODEL if exist "%MODELS%\chip.gguf" set "MODEL=%MODELS%\chip.gguf"
  if not defined MODEL if exist "%MODELS%\tiny.gguf" set "MODEL=%MODELS%\tiny.gguf"
)

if not defined MODEL (
  echo No model found. Add models\chip.gguf, tiny.gguf, or chat.gguf ^(see models\README.md^).
  exit /b 1
)

set "GPU_ARGS="
if defined LLAMA_NGL (
  set "GPU_ARGS=-ngl %LLAMA_NGL%"
) else (
  where nvidia-smi >nul 2>&1 && set "GPU_ARGS=-ngl 999"
)

cd /d "%ROOT%"

if /I "%MODE%"=="tui" (
  echo CHIP — loading model ^(terminal^)...
  if defined GPU_ARGS (
    "%BIN%" -m "%MODEL%" %GPU_ARGS%
  ) else (
    "%BIN%" -m "%MODEL%"
  )
) else (
  echo CHIP — Crisis Host-Independent Preparedness
  echo Loading model...
  echo Open http://127.0.0.1:%PORT% when ready ^(Ctrl+C to stop^).
  echo Documents: place .md/.txt in rag\corpus\ ^(PDF: scripts\pdf-to-text.bat^).
  if defined GPU_ARGS (
    "%BIN%" -m "%MODEL%" %GPU_ARGS% --server --host 127.0.0.1 --port %PORT% --tools read_file,grep_search,file_glob_search --confine-reads --media-path "%CORPUS%"
  ) else (
    "%BIN%" -m "%MODEL%" --server --host 127.0.0.1 --port %PORT% --tools read_file,grep_search,file_glob_search --confine-reads --media-path "%CORPUS%"
  )
)
exit /b %ERRORLEVEL%

:usage
echo Usage: start.bat [tiny^|chat^|chip] [tui]
exit /b 0
