# Bedrock / Stackonomics dev launcher (PowerShell)
#
# Usage:
#   .\dev.ps1                  # start web + tailwind watcher on PORT 3000
#   .\dev.ps1 -Port 4000       # override the port
#
# This is a thin wrapper around `ruby bin/dev`. The real launcher logic lives
# in bin/dev so it stays cross-platform with Mac/Linux teammates.

[CmdletBinding()]
param(
    [int]$Port = 3000
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

if (-not (Get-Command ruby -ErrorAction SilentlyContinue)) {
    Write-Host "Ruby was not found on PATH." -ForegroundColor Red
    Write-Host "Install Ruby 4.0+ (https://rubyinstaller.org) and reopen your terminal." -ForegroundColor Yellow
    exit 1
}

$env:PORT = "$Port"

Write-Host "Starting Bedrock dev server on http://localhost:$Port ..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop both the web server and the Tailwind watcher." -ForegroundColor DarkGray
Write-Host ""

ruby bin/dev
exit $LASTEXITCODE
