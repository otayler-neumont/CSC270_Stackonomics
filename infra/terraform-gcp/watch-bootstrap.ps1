# Poll the GCE serial console every 60s until we see the cloud-init
# `final_message` (or an obvious failure). Conservative cadence so we
# never hit a GCP API rate limit.

$ErrorActionPreference = "Continue"

while ($true) {
    $output = & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "serial-tail.ps1") 2>&1 | Out-String

    $ts = Get-Date -Format 'HH:mm:ss'
    if ($output -match 'Stackonomics bootstrap finished after') {
        Write-Host "[$ts] DONE -> bootstrap finished. App should be live in <30s." -ForegroundColor Green
        break
    }
    if ($output -match 'cloud-init.*FAIL|Failed to (clone|pull|build)|fatal:') {
        Write-Host "[$ts] FAILURE detected in serial output:" -ForegroundColor Red
        ($output -split "`n") | Select-Object -Last 30 | Write-Host
        break
    }

    # Show the most recent "interesting" line so we have a heartbeat.
    $heartbeat = ($output -split "`n") |
        Where-Object { $_ -match 'Extracting|Pulling|Building|Setting up|Step \d+/\d+|swap on|Cloning into' } |
        Select-Object -Last 1
    if ($heartbeat) { Write-Host "[$ts] $heartbeat" } else { Write-Host "[$ts] (still bootstrapping)" }

    Start-Sleep -Seconds 60
}
