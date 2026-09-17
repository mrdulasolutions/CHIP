@echo off
setlocal EnableExtensions
cd /d "%~dp0"
if exist "start.bat" (
  call start.bat chip
  goto :eof
)
echo CHIP start.bat not found. Copy the kit from https://github.com/mrdulasolutions/CHIP
pause
