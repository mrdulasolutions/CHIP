@echo off
setlocal EnableExtensions
cd /d "%~dp0"
where bash >nul 2>&1
if %errorlevel%==0 (
  bash "./start-rag.sh" stop
  goto :done
)
echo Close the "CHIP embed" and "CHIP chat" command windows if they are open.
echo Or install Git Bash and run:  ./start-rag.sh stop
:done
pause
