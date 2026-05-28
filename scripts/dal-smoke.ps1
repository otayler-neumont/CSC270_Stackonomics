# DAL smoke test for the Phase 4 persistence layer.
#
# Round-trips a specimen through every CRUD endpoint of the API. Each
# endpoint hits SpecimenRepository under the hood (see
# app/repositories/specimen_repository.rb), so a passing run proves the
# whole controller -> repository -> ActiveRecord -> Postgres chain works
# end to end.
#
# Usage:
#   .\scripts\dal-smoke.ps1                                  # localhost:3000
#   .\scripts\dal-smoke.ps1 -BaseUrl http://35.223.220.115   # production VM

param(
    [string]$BaseUrl = "http://localhost:3000"
)

$ErrorActionPreference = "Stop"
$base = $BaseUrl.TrimEnd('/')
$created = $null

function Assert-Equal($expected, $actual, $label) {
    if ($expected -ne $actual) {
        Write-Host "  [FAIL] $label expected=$expected actual=$actual" -ForegroundColor Red
        exit 1
    }
    Write-Host "  [ ok ] $label = $actual" -ForegroundColor Green
}

function Call($method, $path, $body = $null) {
    $uri = "$base$path"
    $headers = @{ "Accept" = "application/json" }
    if ($body) {
        $headers["Content-Type"] = "application/json"
        return Invoke-WebRequest -Method $method -Uri $uri -Headers $headers -Body ($body | ConvertTo-Json -Depth 5) -UseBasicParsing
    } else {
        return Invoke-WebRequest -Method $method -Uri $uri -Headers $headers -UseBasicParsing
    }
}

Write-Host ""
Write-Host "=== DAL smoke test against $base ==="
Write-Host ""

try {
    # 1. INDEX (repository.all)
    Write-Host "[1/6] GET /api/specimens   (SpecimenRepository.all)"
    $resp = Call GET "/api/specimens"
    Assert-Equal 200 $resp.StatusCode "status"
    $initialCount = ($resp.Content | ConvertFrom-Json).Count
    Write-Host "  initial row count = $initialCount"

    # 2. CREATE (repository.create)
    Write-Host ""
    Write-Host "[2/6] POST /api/specimens  (SpecimenRepository.create)"
    $payload = @{
        specimen = @{
            name   = "Smoke Test Stone $((Get-Date).Ticks)"
            color  = "Indigo"
            mohs   = 8.5
            origin = "Smoke Test Range"
            fact   = "Created by dal-smoke.ps1 - safe to delete."
            tint   = "indigo"
        }
    }
    $resp = Call POST "/api/specimens" $payload
    Assert-Equal 201 $resp.StatusCode "status"
    $created = $resp.Content | ConvertFrom-Json
    Write-Host "  created id = $($created.id), name = '$($created.name)'"

    # 3. SHOW (repository.find)
    Write-Host ""
    Write-Host "[3/6] GET /api/specimens/$($created.id)  (SpecimenRepository.find)"
    $resp = Call GET "/api/specimens/$($created.id)"
    Assert-Equal 200 $resp.StatusCode "status"
    $fetched = $resp.Content | ConvertFrom-Json
    Assert-Equal $created.name $fetched.name "name persisted"
    Assert-Equal $created.color $fetched.color "color persisted"
    Assert-Equal 8.5 $fetched.mohs "mohs persisted as decimal"

    # 4. UPDATE (repository.update)
    Write-Host ""
    Write-Host "[4/6] PATCH /api/specimens/$($created.id)  (SpecimenRepository.update)"
    $update = @{ specimen = @{ color = "Bright Orange"; fact = "Edited by dal-smoke.ps1." } }
    $resp = Call PATCH "/api/specimens/$($created.id)" $update
    Assert-Equal 200 $resp.StatusCode "status"
    $updated = $resp.Content | ConvertFrom-Json
    Assert-Equal "Bright Orange" $updated.color "color updated"

    # 5. INDEX again (count should be initial + 1)
    Write-Host ""
    Write-Host "[5/6] GET /api/specimens   (count check)"
    $resp = Call GET "/api/specimens"
    $newCount = ($resp.Content | ConvertFrom-Json).Count
    Assert-Equal ($initialCount + 1) $newCount "row count grew by 1"

    # 6. DESTROY (repository.destroy)
    Write-Host ""
    Write-Host "[6/6] DELETE /api/specimens/$($created.id)  (SpecimenRepository.destroy)"
    $resp = Call DELETE "/api/specimens/$($created.id)"
    Assert-Equal 204 $resp.StatusCode "status"

    # Verify 404 on subsequent GET
    Write-Host ""
    Write-Host "[bonus] GET /api/specimens/$($created.id)  (should be 404)"
    try {
        Call GET "/api/specimens/$($created.id)" | Out-Null
        Write-Host "  [FAIL] expected 404, got 2xx" -ForegroundColor Red
        exit 1
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        Assert-Equal 404 $code "deleted row returns 404"
    }

    Write-Host ""
    Write-Host "=== DAL smoke test PASSED ===" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "=== DAL smoke test FAILED ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    if ($created -and $created.id) {
        Write-Host "Attempting to clean up test record id=$($created.id)..." -ForegroundColor Yellow
        try { Call DELETE "/api/specimens/$($created.id)" | Out-Null } catch {}
    }
    exit 1
}
