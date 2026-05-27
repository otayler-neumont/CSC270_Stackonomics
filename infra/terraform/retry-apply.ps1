# Retry `terraform apply` every 3 minutes until OCI gives us ARM capacity.
# Logs each attempt to retry.log and exits early on any non-capacity error
# so we can debug.
$ErrorActionPreference = "Continue"
$attempt = 0
$log = Join-Path $PSScriptRoot "retry.log"
"===== retry-apply.ps1 started $(Get-Date -Format 'u') =====" | Tee-Object -FilePath $log -Append | Write-Host
while ($true) {
    $attempt++
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "----- Attempt $attempt at $ts -----" | Tee-Object -FilePath $log -Append | Write-Host
    $output = & terraform apply -auto-approve -compact-warnings 2>&1 | Out-String
    Add-Content -Path $log -Value $output
    if ($output -match 'Apply complete') {
        "===== SUCCESS on attempt $attempt at $(Get-Date -Format 'u') =====" |
            Tee-Object -FilePath $log -Append | Write-Host
        break
    }
    if ($output -notmatch 'Out of host capacity') {
        "===== UNEXPECTED ERROR on attempt $attempt at $(Get-Date -Format 'u') - stopping =====" |
            Tee-Object -FilePath $log -Append | Write-Host
        exit 1
    }
    "Out of host capacity. Sleeping 180s before attempt $($attempt + 1)..." |
        Tee-Object -FilePath $log -Append | Write-Host
    Start-Sleep -Seconds 180
}
