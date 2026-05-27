# Retry `terraform apply` until OCI gives us ARM capacity. Cycles through
# all 3 ADs in us-phoenix-1 (AD-1, AD-2, AD-3) on each attempt so we hit
# whichever AD currently has a free slot.
#
# Logs every attempt to retry.log. Exits early on any non-capacity error
# so we notice unrelated problems (auth, quota, etc.).
$ErrorActionPreference = "Continue"
$attempt = 0
$ad_count = 3   # us-phoenix-1
$log = Join-Path $PSScriptRoot "retry.log"
"===== retry-apply.ps1 started $(Get-Date -Format 'u') =====" |
    Tee-Object -FilePath $log -Append | Write-Host

while ($true) {
    $attempt++
    $ad_index = ($attempt - 1) % $ad_count
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "----- Attempt $attempt at $ts (AD index $ad_index / AD-$($ad_index + 1)) -----" |
        Tee-Object -FilePath $log -Append | Write-Host

    $output = & terraform apply -auto-approve -compact-warnings `
        -var "availability_domain_index=$ad_index" 2>&1 | Out-String
    Add-Content -Path $log -Value $output

    if ($output -match 'Apply complete') {
        "===== SUCCESS on attempt $attempt (AD-$($ad_index + 1)) at $(Get-Date -Format 'u') =====" |
            Tee-Object -FilePath $log -Append | Write-Host
        break
    }
    if ($output -notmatch 'Out of host capacity') {
        "===== UNEXPECTED ERROR on attempt $attempt - stopping for review =====" |
            Tee-Object -FilePath $log -Append | Write-Host
        exit 1
    }

    # Conservative pacing (~27 attempts/hour) to stay well clear of
    # Oracle's free-tier soft policy on aggressive LaunchInstance polling.
    # 60s between ADs in a cycle, 8 min cooldown after touching all 3.
    $next_ad_index = $attempt % $ad_count
    if ($next_ad_index -eq 0) {
        $sleep = 480
        $msg = "All 3 ADs out of capacity. Sleeping ${sleep}s (8 min) before next full cycle..."
    } else {
        $sleep = 60
        $msg = "AD-$($ad_index + 1) full. Trying AD-$($next_ad_index + 1) in ${sleep}s..."
    }
    $msg | Tee-Object -FilePath $log -Append | Write-Host

    Start-Sleep -Seconds $sleep
}
