# Bedrock / Stackonomics smart launcher.
#
# This script is invoked by start-dev.bat with -ExecutionPolicy Bypass.
# It is fully idempotent: every step short-circuits when the work is
# already done, so re-running it just relaunches the dev server.
#
# Cold-machine first run (Ruby missing) takes ~10-15 minutes:
#   1. Network preflight (fail fast if offline)
#   2. Install Ruby 4.0.3 + DevKit (winget preferred, direct download fallback)
#   3. Run `ridk install 1 3` to set up the MSYS2 build toolchain
#   4. Install Bundler if missing, then `bundle install`
#   5. `bin/rails db:prepare` if the SQLite DB is missing or pending migrations
#   6. `bin/rails tailwindcss:build` if the compiled CSS is missing
#   7. Hand off to `ruby bin/dev` (which runs web + tailwind watcher together)
#
# Warm-machine subsequent runs skip 2-6 and go straight to step 7.

[CmdletBinding()]
param(
    [int]$Port = 3000
)

# We rely on explicit $LASTEXITCODE checks for native commands (ruby, gem,
# bundle, rails, winget, ridk). Stop mode here would turn harmless stderr
# output (e.g. Ruby's RDoc version warning) into a terminating error, so
# we keep this Continue and check exit codes ourselves.
$ErrorActionPreference = "Continue"

# --------------------------------------------------------------------------
# Constants & helpers
# --------------------------------------------------------------------------

$RepoRoot         = Split-Path -Parent $PSScriptRoot
$RubyVersionFile  = Join-Path $RepoRoot ".ruby-version"
$ExpectedRuby     = (Get-Content $RubyVersionFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim() -replace "^ruby-", ""
if (-not $ExpectedRuby) { $ExpectedRuby = "4.0.3" }

$WingetPackageId  = "RubyInstallerTeam.RubyWithDevKit.4.0"
$DirectInstallerUrl = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-$ExpectedRuby-1/rubyinstaller-devkit-$ExpectedRuby-1-x64.exe"
$ManualInstallUrl = "https://rubyinstaller.org/downloads/"

$LabelWidth = 9

function Write-Step {
    param([string]$Label, [string]$Message, [string]$Color = "Cyan")
    $stamp = (Get-Date).ToString("HH:mm:ss")
    $tag   = "[" + $Label.PadRight($LabelWidth) + "]"
    Write-Host "$stamp $tag $Message" -ForegroundColor $Color
}

function Write-Ok       { param([string]$L,[string]$M) Write-Step $L $M "Green"  }
function Write-Info     { param([string]$L,[string]$M) Write-Step $L $M "Cyan"   }
function Write-WarnStep { param([string]$L,[string]$M) Write-Step $L $M "Yellow" }
function Write-ErrStep  { param([string]$L,[string]$M) Write-Step $L $M "Red"    }

function Refresh-Path {
    # Pull the current Machine + User PATH from the registry so this session
    # picks up Ruby (or anything else) we just installed without needing a
    # new shell.
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user    = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = ($machine, $user | Where-Object { $_ }) -join ";"
}

function Test-Internet {
    try {
        $r = Invoke-WebRequest -Uri "https://github.com" -Method Head -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-RubyVersion {
    $cmd = Get-Command ruby -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }
    try {
        $line = & ruby -v 2>$null | Select-Object -First 1
        if ($line -match "ruby (\d+\.\d+\.\d+)") { return $Matches[1] }
    } catch { return $null }
    return $null
}

# --------------------------------------------------------------------------
# Step 0: banner + preflight
# --------------------------------------------------------------------------

Write-Host ""
Write-Host "=================================================================" -ForegroundColor DarkCyan
Write-Host "  Bedrock / Stackonomics dev launcher" -ForegroundColor White
Write-Host "  Repo: $RepoRoot" -ForegroundColor DarkGray
Write-Host "  Target Ruby: $ExpectedRuby   |   Port: $Port" -ForegroundColor DarkGray
Write-Host "=================================================================" -ForegroundColor DarkCyan
Write-Host ""

Set-Location $RepoRoot

# --------------------------------------------------------------------------
# Step 1: network preflight (fail fast if offline)
# --------------------------------------------------------------------------

Write-Info "preflight" "Checking internet connectivity..."
if (-not (Test-Internet)) {
    $rubyHere = Get-RubyVersion
    if ($rubyHere) {
        Write-WarnStep "preflight" "No internet, but Ruby $rubyHere is already installed - continuing on the warm path."
    } else {
        Write-ErrStep "preflight" "No internet connection and Ruby is not installed."
        Write-Host ""
        Write-Host "  This launcher needs internet on first run to download:" -ForegroundColor Yellow
        Write-Host "    - Ruby $ExpectedRuby (~150 MB)" -ForegroundColor Yellow
        Write-Host "    - The MSYS2 build toolchain (~100 MB)" -ForegroundColor Yellow
        Write-Host "    - Rails and friends (~100 MB of gems)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Connect to the internet and double-click start-dev.bat again." -ForegroundColor Yellow
        Write-Host ""
        exit 2
    }
} else {
    Write-Ok "preflight" "Internet OK."
}

# --------------------------------------------------------------------------
# Step 2: ensure Ruby
# --------------------------------------------------------------------------

function Install-RubyViaWinget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        return $false
    }
    Write-Info "ruby" "Installing Ruby $ExpectedRuby via winget (this can take 5-10 minutes)..."
    try {
        & winget install --id $WingetPackageId -e --silent `
            --accept-package-agreements --accept-source-agreements `
            --scope user 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        if ($LASTEXITCODE -ne 0) {
            Write-WarnStep "ruby" "winget exited with code $LASTEXITCODE - falling back to direct download."
            return $false
        }
        Refresh-Path
        return [bool](Get-Command ruby -ErrorAction SilentlyContinue)
    } catch {
        Write-WarnStep "ruby" "winget install failed: $($_.Exception.Message)"
        return $false
    }
}

function Install-RubyViaDirectDownload {
    Write-Info "ruby" "Downloading RubyInstaller from $DirectInstallerUrl ..."
    $installer = Join-Path $env:TEMP "rubyinstaller-devkit-$ExpectedRuby-1-x64.exe"
    try {
        Invoke-WebRequest -Uri $DirectInstallerUrl -OutFile $installer -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-ErrStep "ruby" "Download failed: $($_.Exception.Message)"
        return $false
    }
    Write-Info "ruby" "Running installer silently (per-user, no admin needed)..."
    try {
        # /SILENT  - no UI prompts
        # /CURRENTUSER - install to %LOCALAPPDATA%, no UAC elevation
        # /TASKS=modpath - add Ruby to PATH for the current user
        # /NORESTART - never reboot
        $proc = Start-Process -FilePath $installer `
            -ArgumentList "/SILENT","/CURRENTUSER","/TASKS=`"modpath`"","/NORESTART" `
            -Wait -PassThru
        if ($proc.ExitCode -ne 0) {
            Write-ErrStep "ruby" "Installer exited with code $($proc.ExitCode)."
            return $false
        }
    } catch {
        Write-ErrStep "ruby" "Installer launch failed: $($_.Exception.Message)"
        return $false
    } finally {
        Remove-Item $installer -ErrorAction SilentlyContinue
    }
    Refresh-Path
    return [bool](Get-Command ruby -ErrorAction SilentlyContinue)
}

$installedRuby = Get-RubyVersion
if ($installedRuby) {
    Write-Ok "ruby" "Ruby $installedRuby already installed - skipping install."
} else {
    Write-Info "ruby" "Ruby not found on PATH. Installing $ExpectedRuby ..."
    $ok = Install-RubyViaWinget
    if (-not $ok) { $ok = Install-RubyViaDirectDownload }
    if (-not $ok) {
        Write-ErrStep "ruby" "Could not install Ruby automatically."
        Write-Host ""
        Write-Host "  Please install Ruby+DevKit $ExpectedRuby manually from:" -ForegroundColor Yellow
        Write-Host "    $ManualInstallUrl" -ForegroundColor Yellow
        Write-Host "  Then double-click start-dev.bat again." -ForegroundColor Yellow
        Write-Host ""
        exit 3
    }
    $installedRuby = Get-RubyVersion
    Write-Ok "ruby" "Ruby $installedRuby is now on PATH."
}

# --------------------------------------------------------------------------
# Step 3a: ensure the MSYS2 pacman keyring is initialized
#
# Without this, every native-extension compile that goes through MSYS2 fails
# with "public keyring not found, have you run pacman init". 'ridk version'
# happily reports a working toolchain even when the keyring is broken, so we
# always verify + repair it ourselves before touching anything that compiles
# C code (sqlite3, bindex/web-console, nokogiri-style gems, etc.).
# --------------------------------------------------------------------------

function Invoke-Msys2 {
    # ridk exec doesn't put /usr/bin on PATH for the subshell, so bare
    # invocations of pacman-key, pacman, etc. fail with "not recognized".
    # Wrapping the command in `bash -lc "..."` loads MSYS2's login env.
    param([string]$Cmd)
    & ridk exec bash -lc $Cmd 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    return $LASTEXITCODE
}

function Test-Keyring {
    if (-not (Get-Command ridk -ErrorAction SilentlyContinue)) { return $true }
    try {
        $out = & ridk exec bash -lc "pacman-key --list-keys 2>/dev/null" 2>&1 | Out-String
        # An initialized + populated keyring lists at least one "pub" entry.
        return ($out -match "(?m)^pub\s")
    } catch {
        return $false
    }
}

if (-not (Get-Command ridk -ErrorAction SilentlyContinue)) {
    Write-WarnStep "keyring" "ridk not available yet - skipping keyring init."
} elseif (Test-Keyring) {
    Write-Ok "keyring" "MSYS2 pacman keyring already initialized."
} else {
    Write-Info "keyring" "Initializing MSYS2 pacman keyring (one-time, ~30s)..."
    [void](Invoke-Msys2 "pacman-key --init")
    $code = Invoke-Msys2 "pacman-key --populate msys2"
    if ($code -ne 0) {
        Write-WarnStep "keyring" "pacman-key --populate exited with $code - continuing, but native gem compiles may fail."
    } elseif (Test-Keyring) {
        Write-Ok "keyring" "Keyring initialized."
    } else {
        Write-WarnStep "keyring" "Keyring still empty after init - native gem compiles may fail."
    }
}

# --------------------------------------------------------------------------
# Step 3b: ensure MSYS2 build toolchain (needed by sqlite3, bindex, etc.)
# --------------------------------------------------------------------------

function Test-Toolchain {
    if (-not (Get-Command ridk -ErrorAction SilentlyContinue)) { return $false }
    try {
        $out = & ridk version 2>&1 | Out-String
        return $out -match "MSYS2" -and $out -match "(MINGW|UCRT)"
    } catch {
        return $false
    }
}

function Invoke-RidkInstall {
    # 1 = MSYS2 base, 3 = MSYS2 + MINGW dev toolchain. The non-interactive
    # form takes a space-separated list as positional args.
    & ridk install 1 3 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    return $LASTEXITCODE
}

if (Test-Toolchain) {
    Write-Ok "toolchain" "MSYS2 build toolchain already configured - skipping."
} else {
    Write-Info "toolchain" "Installing MSYS2 build toolchain via 'ridk install 1 3' (a few minutes)..."
    try {
        $code = Invoke-RidkInstall

        # If the install hit a keyring error mid-flight (e.g. partial earlier
        # install left it inconsistent), repair the keyring and retry once.
        if ($code -ne 0) {
            Write-WarnStep "toolchain" "ridk exited with code $code - repairing keyring and retrying once..."
            [void](Invoke-Msys2 "pacman-key --init")
            [void](Invoke-Msys2 "pacman-key --populate msys2")
            $code = Invoke-RidkInstall
        }

        if ($code -ne 0) {
            Write-WarnStep "toolchain" "ridk still exited with code $code - continuing anyway, native gem builds may fail."
        } else {
            Write-Ok "toolchain" "Toolchain installed."
        }
    } catch {
        Write-WarnStep "toolchain" "ridk install failed: $($_.Exception.Message) - continuing anyway."
    }
}

# --------------------------------------------------------------------------
# Step 4: ensure Bundler
# --------------------------------------------------------------------------

$bundlerInstalled = $false
try {
    & gem list bundler -i --silent 2>$null | Out-Null
    $bundlerInstalled = ($LASTEXITCODE -eq 0)
} catch { $bundlerInstalled = $false }

if ($bundlerInstalled) {
    Write-Ok "bundler" "Bundler already installed."
} else {
    Write-Info "bundler" "Installing Bundler..."
    & gem install bundler --no-document 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    if ($LASTEXITCODE -ne 0) {
        Write-ErrStep "bundler" "Bundler install failed (exit $LASTEXITCODE)."
        exit 4
    }
    Write-Ok "bundler" "Bundler installed."
}

# --------------------------------------------------------------------------
# Step 5: ensure gems are installed
# --------------------------------------------------------------------------

function Invoke-BundleInstall {
    # Captures stdout+stderr so we can scan for keyring errors. Also tees the
    # output to the user's window in real time.
    $captured = New-Object System.Text.StringBuilder
    & bundle install 2>&1 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor DarkGray
        [void]$captured.AppendLine([string]$_)
    }
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $captured.ToString()
    }
}

Write-Info "gems" "Checking gem dependencies (bundle check)..."
& bundle check 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Ok "gems" "All gems already satisfied."
} else {
    Write-Info "gems" "Running bundle install (this can take a few minutes the first time)..."
    $result = Invoke-BundleInstall

    # Self-heal on the classic MSYS2 keyring failure. If the install died
    # because pacman couldn't verify a package, repair the keyring and retry
    # bundle install exactly once.
    $keyringHit = $result.Output -match "public keyring not found" -or `
                  $result.Output -match "pacman-key --init" -or `
                  $result.Output -match "signature from .* is unknown trust"
    if ($result.ExitCode -ne 0 -and $keyringHit) {
        Write-WarnStep "gems" "Hit an MSYS2 keyring error - repairing pacman keyring and retrying bundle install."
        [void](Invoke-Msys2 "pacman-key --init")
        [void](Invoke-Msys2 "pacman-key --populate msys2")
        $result = Invoke-BundleInstall
    }

    if ($result.ExitCode -ne 0) {
        Write-ErrStep "gems" "bundle install failed (exit $($result.ExitCode))."
        Write-Host ""
        Write-Host "  This usually means a native extension (sqlite3, bindex, etc.) couldn't compile." -ForegroundColor Yellow
        Write-Host "  Try the following in a fresh PowerShell window, then re-run start-dev.bat:" -ForegroundColor Yellow
        Write-Host "    ridk exec bash -lc `"pacman-key --init`"" -ForegroundColor Yellow
        Write-Host "    ridk exec bash -lc `"pacman-key --populate msys2`"" -ForegroundColor Yellow
        Write-Host "    ridk install 3" -ForegroundColor Yellow
        Write-Host "    bundle install" -ForegroundColor Yellow
        Write-Host ""
        exit 5
    }
    Write-Ok "gems" "Gems installed."
}

# --------------------------------------------------------------------------
# Step 6: ensure database is prepared
# --------------------------------------------------------------------------

$dbPath = Join-Path $RepoRoot "storage\development.sqlite3"
$needDb = -not (Test-Path $dbPath)
if ($needDb) {
    Write-Info "database" "Creating + migrating development database..."
} else {
    Write-Info "database" "Running db:prepare (idempotent - applies any pending migrations)..."
}
& ruby bin\rails db:prepare 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
if ($LASTEXITCODE -ne 0) {
    Write-ErrStep "database" "db:prepare failed (exit $LASTEXITCODE)."
    exit 6
}
Write-Ok "database" "Database ready."

# --------------------------------------------------------------------------
# Step 7: ensure Tailwind CSS is built (so the first browser hit is styled)
# --------------------------------------------------------------------------

$cssPath = Join-Path $RepoRoot "app\assets\builds\tailwind.css"
if ((Test-Path $cssPath) -and ((Get-Item $cssPath).Length -gt 0)) {
    Write-Ok "css" "Tailwind CSS already built."
} else {
    Write-Info "css" "Building Tailwind CSS for the first time..."
    & ruby bin\rails tailwindcss:build 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    if ($LASTEXITCODE -ne 0) {
        Write-WarnStep "css" "tailwindcss:build exited with $LASTEXITCODE - continuing; the watcher will retry."
    } else {
        Write-Ok "css" "Tailwind CSS built."
    }
}

# --------------------------------------------------------------------------
# Step 8: launch the dev server
# --------------------------------------------------------------------------

Write-Host ""
Write-Host "=================================================================" -ForegroundColor DarkCyan
Write-Host "  Setup complete. Starting dev server on http://localhost:$Port" -ForegroundColor Green
Write-Host "  Press Ctrl+C in this window to stop the server." -ForegroundColor DarkGray
Write-Host "=================================================================" -ForegroundColor DarkCyan
Write-Host ""

$env:PORT = "$Port"

# Hand off to the cross-platform launcher (spawns web + tailwind watcher
# with colored [web]/[css] prefixes; handles Ctrl+C cleanly on Windows).
& ruby bin\dev
exit $LASTEXITCODE
