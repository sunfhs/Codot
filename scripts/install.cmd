@echo off
setlocal
cd /d "%~dp0"
set "APP_SHA256="
for /f "tokens=1" %%H in (codex-usage.exe.sha256) do set "APP_SHA256=%%H"
if not defined APP_SHA256 (
  echo Missing SHA256 checksum file.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -SourcePath "%~dp0codex-usage.exe" -ExpectedSha256 "%APP_SHA256%" -Version "1.0.0"
if errorlevel 1 (
  echo Installation failed. See the message above.
  pause
  exit /b 1
)
echo Codex Usage Compact is installed and will start with Windows.
