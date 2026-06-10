<#
.SYNOPSIS
    FinPal Pro — Release Deployment Script (PowerShell / Windows)

.DESCRIPTION
    Produces:
      dist\finpal-pro-<version>-release.apk
      dist\finpal-pro-<version>-release.aab

.PARAMETER SkipTests
    Skip flutter test (useful when tests already ran).

.PARAMETER ApkOnly
    Build APK only (skip AAB).

.PARAMETER AabOnly
    Build AAB only (skip APK).

.PARAMETER Clean
    Run flutter clean before building.

.EXAMPLE
    .\scripts\deploy.ps1
    .\scripts\deploy.ps1 -SkipTests -ApkOnly
    .\scripts\deploy.ps1 -Clean

.NOTES
    Required env vars when android\key.properties is absent:
      $env:KEY_ALIAS      — keystore key alias
      $env:KEY_PASSWORD   — key password
      $env:STORE_PASSWORD — keystore store password
      $env:KEYSTORE_PATH  — absolute path to .jks (default: android\finpal-pro-release.jks)
#>
[CmdletBinding()]
param(
    [switch]$SkipTests,
    [switch]$ApkOnly,
    [switch]$AabOnly,
    [switch]$Clean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ───────────────────────────────────────────────────────────────────
function Write-Step  { param($n, $msg) Write-Host "[STEP $n]  $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg)     Write-Host "[OK]      $msg" -ForegroundColor Green }
function Write-Warn  { param($msg)     Write-Host "[WARN]    $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg)     Write-Host "[ERROR]   $msg" -ForegroundColor Red; exit 1 }

function Invoke-Cmd {
    param([string]$cmd, [string[]]$args)
    & $cmd @args
    if ($LASTEXITCODE -ne 0) { Write-Fail "Command failed: $cmd $args" }
}

# ── Resolve repo root ─────────────────────────────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent $ScriptDir
Set-Location $RepoRoot

# ── Step 0: Pull latest from origin/main ─────────────────────────────────────
Write-Step 0 "Syncing with origin/main …"
git fetch origin
$CurrentBranch = git rev-parse --abbrev-ref HEAD
if ($CurrentBranch -eq 'main' -or $CurrentBranch -eq 'master') {
    $local  = git rev-parse HEAD
    $remote = git rev-parse "origin/$CurrentBranch"
    if ($local -ne $remote) {
        Write-Host "  Fast-forwarding $CurrentBranch → origin/$CurrentBranch"
        git merge --ff-only "origin/$CurrentBranch"
        if ($LASTEXITCODE -ne 0) { Write-Fail "Merge fast-forward failed — uncommitted changes?" }
    } else {
        Write-Host "  Already up to date with origin/$CurrentBranch"
    }
} else {
    Write-Warn "Not on main/master (on '$CurrentBranch') — skipping pull."
}
Write-Ok "Step 0 complete"

# ── Step 1: Validate signing config ──────────────────────────────────────────
Write-Step 1 "Checking signing config …"
$KeyProps = Join-Path $RepoRoot 'android\key.properties'
if (Test-Path $KeyProps) {
    Write-Host "  Using android\key.properties"
} elseif ($env:KEY_ALIAS -and $env:KEY_PASSWORD -and $env:STORE_PASSWORD) {
    Write-Host "  Using environment variables for signing"
    $KsPath = if ($env:KEYSTORE_PATH) { $env:KEYSTORE_PATH } else { Join-Path $RepoRoot 'android\finpal-pro-release.jks' }
    if (-not (Test-Path $KsPath)) {
        Write-Fail "KEYSTORE_PATH='$KsPath' not found. Provide the .jks file."
    }
} else {
    Write-Warn "No key.properties and no signing env vars — build will use debug key."
    Write-Warn "Resulting APK/AAB will NOT be accepted by Google Play."
}
Write-Ok "Step 1 complete"

# ── Step 2: Read version from pubspec.yaml ────────────────────────────────────
Write-Step 2 "Reading version …"
$PubspecPath = Join-Path $RepoRoot 'pubspec.yaml'
$VersionLine = (Get-Content $PubspecPath | Where-Object { $_ -match '^version:' } | Select-Object -First 1)
if (-not $VersionLine) { Write-Fail "Could not read version from pubspec.yaml" }
$FullVersion = ($VersionLine -split ':\s*')[1].Trim()
$VersionName = ($FullVersion -split '\+')[0]
$VersionCode = if ($FullVersion -match '\+(\d+)$') { $Matches[1] } else { '1' }
Write-Host "  Version: $VersionName (build $VersionCode)"
Write-Ok "Step 2 complete"

# ── Step 3: Optional clean ────────────────────────────────────────────────────
if ($Clean) {
    Write-Step 3 "Running flutter clean …"
    Invoke-Cmd flutter @('clean')
    Write-Ok "Step 3 complete"
} else {
    Write-Step 3 "Skipping flutter clean (pass -Clean to force)"
}

# ── Step 4: Install dependencies ─────────────────────────────────────────────
Write-Step 4 "Installing dependencies …"
Invoke-Cmd flutter @('pub', 'get')
Write-Ok "Step 4 complete"

# ── Step 5: Drift code generation ────────────────────────────────────────────
Write-Step 5 "Generating Drift database code …"
Invoke-Cmd dart @('run', 'build_runner', 'build', '--delete-conflicting-outputs')
Write-Ok "Step 5 complete"

# ── Step 6: Format check ─────────────────────────────────────────────────────
Write-Step 6 "Checking code formatting …"
& dart format --set-exit-if-changed lib/ test/
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Format check failed. Run: dart format lib/ test/"
}
Write-Ok "Step 6 complete"

# ── Step 7: Static analysis ───────────────────────────────────────────────────
Write-Step 7 "Running static analysis …"
Invoke-Cmd flutter @('analyze', '--fatal-infos')
Write-Ok "Step 7 complete"

# ── Step 8: Unit tests ────────────────────────────────────────────────────────
if (-not $SkipTests) {
    Write-Step 8 "Running unit tests …"
    Invoke-Cmd flutter @('test', 'test/', '--reporter=compact')
    Write-Ok "Step 8 complete"
} else {
    Write-Warn "Step 8: Unit tests skipped (-SkipTests)"
}

# ── Step 9: Create output directory ──────────────────────────────────────────
$OutputDir = if ($env:OUTPUT_DIR) { $env:OUTPUT_DIR } else { Join-Path $RepoRoot 'dist' }
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
Write-Step 9 "Artifacts → $OutputDir"

# ── Step 10: Build release APK ───────────────────────────────────────────────
if (-not $AabOnly) {
    Write-Step 10 "Building release APK (arm64) …"
    Invoke-Cmd flutter @(
        'build', 'apk',
        '--release',
        '--target-platform', 'android-arm64',
        '--dart-define=APP_ENV=production'
    )
    $ApkSrc  = Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-release.apk'
    $ApkDest = Join-Path $OutputDir "finpal-pro-$VersionName-release.apk"
    Copy-Item $ApkSrc $ApkDest -Force
    $ApkSize = (Get-Item $ApkDest).Length / 1MB
    Write-Ok ("Step 10: APK built → $ApkDest ({0:N1} MB)" -f $ApkSize)
} else {
    Write-Host "[STEP 10] APK build skipped (-AabOnly)"
}

# ── Step 11: Build release AAB ────────────────────────────────────────────────
if (-not $ApkOnly) {
    Write-Step 11 "Building release AAB (Play Store) …"
    Invoke-Cmd flutter @(
        'build', 'appbundle',
        '--release',
        '--dart-define=APP_ENV=production'
    )
    $AabSrc  = Join-Path $RepoRoot 'build\app\outputs\bundle\release\app-release.aab'
    $AabDest = Join-Path $OutputDir "finpal-pro-$VersionName-release.aab"
    Copy-Item $AabSrc $AabDest -Force
    $AabSize = (Get-Item $AabDest).Length / 1MB
    Write-Ok ("Step 11: AAB built → $AabDest ({0:N1} MB)" -f $AabSize)
} else {
    Write-Host "[STEP 11] AAB build skipped (-ApkOnly)"
}

# ── Step 12: SHA-256 checksums ───────────────────────────────────────────────
Write-Step 12 "Generating checksums …"
$ChecksumFile = Join-Path $OutputDir "finpal-pro-$VersionName-checksums.sha256"
$artifacts = Get-ChildItem -Path $OutputDir -Filter "finpal-pro-$VersionName-release.*" -ErrorAction SilentlyContinue
$checksumLines = $artifacts | ForEach-Object {
    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    "$hash  $($_.Name)"
}
$checksumLines | Set-Content $ChecksumFile -Encoding UTF8
Write-Ok "Step 12: Checksums → $ChecksumFile"

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  FinPal Pro $VersionName — Release build complete"      -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Get-ChildItem -Path $OutputDir -Filter "finpal-pro-$VersionName-*" |
    ForEach-Object { Write-Host ("  {0,-50} {1,8:N1} MB" -f $_.Name, ($_.Length / 1MB)) }
