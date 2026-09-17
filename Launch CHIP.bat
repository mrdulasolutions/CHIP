@echo off
setlocal EnableExtensions
cd /d "%~dp0"
if exist "rag\index\knowledge.db" (
  if exist "start-embed.bat" start "CHIP embed" cmd /k start-embed.bat
  timeout /t 5 /nobreak >nul
  if exist "start.bat" start "CHIP chat" cmd /k start.bat chip
  echo Open http://127.0.0.1:8080 in your browser.
  goto :eof
)
if exist "start.bat" (
  call start.bat chip
  goto :eof
)
echo CHIP launchers not found. Copy the kit from https://github.com/mrdulasolutions/CHIP
pause
