@echo off
REM Bedrock / Stackonomics one-click dev launcher.
REM Double-click this file in File Explorer to start the Rails server and the
REM Tailwind watcher together. Closing the window stops both processes.

setlocal
cd /d "%~dp0"

where ruby >nul 2>nul
if errorlevel 1 (
    echo.
    echo [start-dev] Ruby was not found on PATH.
    echo [start-dev] Install Ruby 4.0+ from https://rubyinstaller.org and reopen this window.
    echo.
    pause
    exit /b 1
)

if "%PORT%"=="" set PORT=3000

echo.
echo === Starting Bedrock dev server on http://localhost:%PORT% ===
echo Press Ctrl+C in this window to stop the server.
echo.

ruby bin\dev
set EXITCODE=%ERRORLEVEL%

echo.
echo === Server stopped (exit code %EXITCODE%) ===
pause
exit /b %EXITCODE%
