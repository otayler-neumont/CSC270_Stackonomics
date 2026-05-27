# Fetch the GCP serial console output (boot/cloud-init log) via the
# Compute Engine REST API. Uses Ruby (already on the box) for JWT signing
# because Windows PowerShell 5.1's RSA class can't ImportFromPem.

$ErrorActionPreference = "Stop"

$keyPath  = "C:\Users\TKoAdmin\.gcp\helical-crowbar-437420-b5-31354050b457.json"
$project  = "helical-crowbar-437420-b5"
$zone     = "us-central1-a"
$instance = "stackonomics"

$accessToken = & ruby (Join-Path $PSScriptRoot "_mint_token.rb") `
    $keyPath "https://www.googleapis.com/auth/cloud-platform"

if (-not $accessToken) { throw "Failed to mint access token" }

$url = "https://compute.googleapis.com/compute/v1/projects/$project/zones/$zone/instances/$instance/serialPort?port=1"
$serial = Invoke-RestMethod -Method Get -Uri $url `
    -Headers @{ Authorization = "Bearer $accessToken" }

($serial.contents -split "`r?`n") | Select-Object -Last 80 | ForEach-Object { $_ }
