@echo off
setlocal EnableExtensions

set "ROOT=%~dp0.."
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
if not defined CORPUS set "CORPUS=%ROOT%\rag\corpus"
set "PDFBIN=%ROOT%\bin\pdf\windows\pdftotext.exe"

if /I "%~1"=="-h" goto usage
if /I "%~1"=="--help" goto usage

if not exist "%PDFBIN%" (
  echo Bundled pdftotext not found:
  echo   %PDFBIN%
  echo.
  echo While online, from the kit root run:
  echo   download-pdf-tools.sh   ^(Git Bash or WSL^)
  echo   or copy bin\pdf\windows from another machine after download.
  exit /b 1
)

if not exist "%CORPUS%" mkdir "%CORPUS%"

set "PATH=%ROOT%\bin\pdf\windows;%PATH%"

set "FOUND=0"
for %%F in ("%CORPUS%\*.pdf") do (
  set "FOUND=1"
  echo Converting %%~nxF -^> %%~nF.txt
  "%PDFBIN%" -layout "%%F" "%%~dpnF.txt"
)

if "%FOUND%"=="0" (
  echo No PDF files in: %CORPUS%
  exit /b 0
)

echo Done. Start the server and ask the model to read the new .txt files.
exit /b 0

:usage
echo Usage: pdf-to-text.bat
echo Converts every *.pdf in rag\corpus\ using bundled Poppler in bin\pdf\windows\
exit /b 0
