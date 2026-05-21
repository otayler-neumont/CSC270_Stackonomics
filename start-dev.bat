@echo off
REM Bedrock / Stackonomics one-click setup + launcher.
REM
REM On a cold machine this installs Ruby + the build toolchain + gems + the
REM database (migrate + seed) the first time it runs (10-15 minutes), then
REM starts the server. Every run applies pending migrations and db:seed.
REM Subsequent runs skip everything that's already done and launch in seconds.
REM
REM If Windows SmartScreen warns "Windows protected your PC", click
REM "More info" and then "Run anyway" - this batch file is just a wrapper
REM around scripts\setup-and-run.ps1, both of which are plain text and
REM readable in any editor.

setlocal
cd /d "%~dp0"

if "%PORT%"=="" set PORT=3000

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-and-run.ps1" -Port %PORT%
set EXITCODE=%ERRORLEVEL%

if not "%EXITCODE%"=="0" (
    echo.
    echo === Setup/launcher exited with code %EXITCODE% ===
    pause
)

exit /b %EXITCODE%
