<#
.SYNOPSIS
    FinPal Pro Flutter Web build script (PowerShell)

.PARAMETER SkipTests   Skip flutter test
.PARAMETER Clean       Run flutter clean before build
.PARAMETER Deploy      Sync build/web/ to S3 + invalidate CloudFront
.PARAMETER Bucket      S3 bucket override (default: read from SSM)
.PARAMETER DistId      CloudFront distribution ID override (default: read from SSM)

.EXAMPLE
    .\scripts\deploy.ps1
    .\scripts\deploy.ps1 -SkipTests -Deploy
    .\scripts\deploy.ps1 -Clean -Deploy -Bucket my-bucket -DistId E1ABCD1234
#>
param(
    [switch] $SkipTests,
    [switch] $Clean,
    [switch] $Deploy,
    [string] $Bucket  = "",
    [string] $DistId  = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path "$PSScriptRoot\.."

function Write-Step { param($msg) Write-Host "`n== $msg ==" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Warn { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Invoke-Step {
    param([string[]]$Cmd)
    & $Cmd[0] $Cmd[1..($Cmd.Length-1)]
    if ($LASTEXITCODE -ne 0) { throw "Failed (exit $LASTEXITCODE): $($Cmd -join ' ')" }
}

Set-Location $RepoRoot

# ── Step 1: Validate ─────────────────────────────────────────
Write-Step "1 — Validate"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "flutter not found in PATH" }
$flutterVer = (flutter --version 2>&1 | Select-Object -First 1)
Write-Info "Flutter: $flutterVer"

# ── Step 2: Clean ────────────────────────────────────────────
if ($Clean) {
    Write-Step "2 — flutter clean"
    Invoke-Step @("flutter","clean")
}

# ── Step 3: Dependencies ─────────────────────────────────────
Write-Step "3 — flutter pub get"
Invoke-Step @("flutter","pub","get")

# ── Step 4: Code generation ───────────────────────────────────
Write-Step "4 — build_runner"
Invoke-Step @("dart","run","build_runner","build","--delete-conflicting-outputs")

# ── Step 5: Format check ─────────────────────────────────────
Write-Step "5 — dart format check"
dart format --set-exit-if-changed lib/ test/
if ($LASTEXITCODE -ne 0) { throw "Format check failed — run: dart format lib/ test/" }

# ── Step 6: Analyze ──────────────────────────────────────────
Write-Step "6 — dart analyze"
Invoke-Step @("flutter","analyze","--fatal-infos")

# ── Step 7: Tests ────────────────────────────────────────────
if (-not $SkipTests) {
    Write-Step "7 — flutter test"
    Invoke-Step @("flutter","test","test/","--reporter=compact")
} else {
    Write-Info "Step 7 — tests skipped (-SkipTests)"
}

# ── Step 8: Flutter Web build ─────────────────────────────────
Write-Step "8 — flutter build web"
Invoke-Step @("flutter","build","web","--release","--dart-define=APP_ENV=production","--web-renderer","canvaskit")

$WebOut = Join-Path $RepoRoot "build\web"
Write-Info "Web output: $WebOut"

# ── Step 9: Deploy to S3 (optional) ──────────────────────────
if ($Deploy) {
    Write-Step "9 — Deploy to S3 + CloudFront"
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) { throw "aws CLI not found — required for -Deploy" }

    if (-not $Bucket) {
        $Bucket = aws ssm get-parameter --name "/finpal-pro/distribution/bucket-name" --query "Parameter.Value" --output text
        if ($LASTEXITCODE -ne 0) { throw "Cannot read bucket from SSM. Pass -Bucket <name>." }
    }
    if (-not $DistId) {
        $DistId = aws ssm get-parameter --name "/finpal-pro/distribution/id" --query "Parameter.Value" --output text
        if ($LASTEXITCODE -ne 0) { throw "Cannot read distribution ID from SSM. Pass -DistId <id>." }
    }

    Write-Info "Bucket    : s3://$Bucket"
    Write-Info "CloudFront: $DistId"

    # Content-hashed assets — immutable 1 year
    aws s3 sync $WebOut "s3://$Bucket" --delete `
        --exclude "*.html" --exclude "flutter_service_worker.js" `
        --cache-control "public, max-age=31536000, immutable"
    if ($LASTEXITCODE -ne 0) { throw "s3 sync (assets) failed" }

    # HTML + service worker — no-cache
    aws s3 sync $WebOut "s3://$Bucket" `
        --exclude "*" --include "*.html" --include "flutter_service_worker.js" `
        --cache-control "no-cache, no-store, must-revalidate"
    if ($LASTEXITCODE -ne 0) { throw "s3 sync (html) failed" }

    $InvalidationId = aws cloudfront create-invalidation `
        --distribution-id $DistId --paths "/*" `
        --query "Invalidation.Id" --output text
    Write-Info "Invalidation: $InvalidationId (propagating ~30-60s)"
}

Write-Host ""
Write-Info "════════════════════════════════════════════════════════"
Write-Info "  Flutter Web build complete — output: build\web\"
if ($Deploy) { Write-Info "  Deployed → s3://$Bucket" } else { Write-Info "  Run with -Deploy to push to S3" }
Write-Info "════════════════════════════════════════════════════════"
