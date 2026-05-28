# Hard-reset the GCE instance via the REST API (virtual power-cycle).
# Faster than stop+start and survives the SSH-stuck-after-OOM scenario.

$ErrorActionPreference = "Stop"

$keyPath  = "C:\Users\TKoAdmin\.gcp\helical-crowbar-437420-b5-31354050b457.json"
$project  = "helical-crowbar-437420-b5"
$zone     = "us-central1-a"
$instance = "stackonomics"

$accessToken = & ruby (Join-Path $PSScriptRoot "_mint_token.rb") `
    $keyPath "https://www.googleapis.com/auth/cloud-platform"
if (-not $accessToken) { throw "Failed to mint access token" }

$url = "https://compute.googleapis.com/compute/v1/projects/$project/zones/$zone/instances/$instance/reset"
$resp = Invoke-RestMethod -Method Post -Uri $url `
    -Headers @{ Authorization = "Bearer $accessToken" } `
    -ContentType "application/json"

Write-Host "Reset issued. Operation: $($resp.name)"
Write-Host "Status: $($resp.status)"
Write-Host "VM should be back in ~30-60 seconds."
