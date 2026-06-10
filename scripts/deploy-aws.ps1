<#
.SYNOPSIS
    FinPal Pro AWS CDK deployment (PowerShell)

.DESCRIPTION
    Bootstraps CDK (idempotent) and deploys both stacks to ap-south-1.

.PARAMETER Env
    APP_ENV override: dev | staging | production (default: dev)

.PARAMETER Region
    AWS region override (default: ap-south-1)

.PARAMETER Account
    AWS account ID override

.PARAMETER BootstrapOnly
    Only bootstrap CDK, don't deploy

.PARAMETER SkipBootstrap
    Skip bootstrap (already done)

.PARAMETER Stack
    Deploy a single stack: FinpalDistribution or FinpalFoundation

.PARAMETER DryRun
    Run cdk synth only, no deploy

.EXAMPLE
    .\scripts\deploy-aws.ps1
    .\scripts\deploy-aws.ps1 -Env production -SkipBootstrap
    .\scripts\deploy-aws.ps1 -Stack FinpalFoundation
    .\scripts\deploy-aws.ps1 -DryRun
#>
param(
    [string] $Env          = ($env:APP_ENV        -ne "" ? $env:APP_ENV        : "dev"),
    [string] $Region       = ($env:AWS_DEFAULT_REGION -ne "" ? $env:AWS_DEFAULT_REGION : "ap-south-1"),
    [string] $Account      = ($env:CDK_DEFAULT_ACCOUNT -ne "" ? $env:CDK_DEFAULT_ACCOUNT : ""),
    [switch] $BootstrapOnly,
    [switch] $SkipBootstrap,
    [string] $Stack        = "",
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot   = Resolve-Path "$PSScriptRoot\.."
$CdkDir     = Join-Path $RepoRoot "infrastructure\cdk"

function Write-Step   { param($msg) Write-Host "`n== $msg ==" -ForegroundColor Green }
function Write-Info   { param($msg) Write-Host "[INFO] $msg"  -ForegroundColor Cyan }
function Write-Warn   { param($msg) Write-Host "[WARN] $msg"  -ForegroundColor Yellow }
function Invoke-Step  {
    param($Cmd)
    & $Cmd[0] $Cmd[1..($Cmd.Length-1)]
    if ($LASTEXITCODE -ne 0) { throw "Command failed (exit $LASTEXITCODE): $($Cmd -join ' ')" }
}

# ── Step 1: Validate prerequisites ───────────────────────────
Write-Step "1/5 — Validate prerequisites"

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw "AWS CLI not found. Install from https://aws.amazon.com/cli/"
}
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw ".NET SDK not found. Install from https://dot.net"
}

# Locate CDK binary
$CdkCmd = $null
$CdkCandidates = @(
    "cdk",
    "$env:APPDATA\npm\cdk",
    "$env:APPDATA\npm\cdk.cmd",
    "$($env:USERPROFILE)\.npm-global\bin\cdk"
)
foreach ($c in $CdkCandidates) {
    if (Get-Command $c -ErrorAction SilentlyContinue) { $CdkCmd = $c; break }
}
if (-not $CdkCmd) { throw "CDK CLI not found. Install: npm install -g aws-cdk" }

$cdkVersion = (& $CdkCmd --version 2>&1) | Select-Object -First 1
Write-Info "CDK: $CdkCmd ($cdkVersion)"

# ── Step 2: Resolve AWS identity ─────────────────────────────
Write-Step "2/5 — Resolve AWS identity"

$callerJson = aws sts get-caller-identity --output json 2>&1
if ($LASTEXITCODE -ne 0) { throw "Cannot reach AWS. Check AWS CLI credentials." }
$caller = $callerJson | ConvertFrom-Json

if (-not $Account) { $Account = $caller.Account }
Write-Info "Account : $Account"
Write-Info "Identity: $($caller.Arn)"
Write-Info "Region  : $Region"
Write-Info "App env : $Env"

if ($caller.Arn -match ":root$") {
    Write-Warn "Deploying with ROOT credentials — create a least-privilege IAM role before production."
}

# ── Step 3: Build CDK project ─────────────────────────────────
Write-Step "3/5 — Build CDK project (dotnet build)"

Push-Location (Join-Path $CdkDir "src")
try { Invoke-Step @("dotnet","build","--configuration","Release","--nologo","-q") }
finally { Pop-Location }
Write-Info "dotnet build: SUCCESS"

# ── Step 4: CDK bootstrap ─────────────────────────────────────
if (-not $SkipBootstrap) {
    Write-Step "4/5 — CDK bootstrap aws://${Account}/${Region}"
    $env:CDK_DEFAULT_ACCOUNT = $Account
    $env:CDK_DEFAULT_REGION  = $Region
    $env:APP_ENV             = $Env

    Push-Location $CdkDir
    try { Invoke-Step @($CdkCmd,"bootstrap","aws://${Account}/${Region}") }
    finally { Pop-Location }
    Write-Info "Bootstrap: COMPLETE"
} else {
    Write-Step "4/5 — CDK bootstrap skipped (--SkipBootstrap)"
}

if ($BootstrapOnly) { Write-Info "Bootstrap-only mode — done."; exit 0 }

# ── Step 5: CDK synth + deploy ────────────────────────────────
Write-Step "5/5 — CDK deploy"

$env:CDK_DEFAULT_ACCOUNT = $Account
$env:CDK_DEFAULT_REGION  = $Region
$env:APP_ENV             = $Env

$OutputsFile = Join-Path $RepoRoot "cdk-outputs.json"

Push-Location $CdkDir
try {
    if ($DryRun) {
        Write-Info "Dry-run mode — running cdk synth only"
        Invoke-Step @($CdkCmd,"synth")
        Write-Info "Synth: SUCCESS — no resources deployed"
    } else {
        $deployArgs = @($CdkCmd,"deploy","--require-approval","never","--outputs-file",$OutputsFile)
        if ($Stack) { $deployArgs += $Stack } else { $deployArgs += "--all" }
        Invoke-Step $deployArgs
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Info "════════════════════════════════════════════════════════"
Write-Info "  CDK deployment complete"
Write-Info "  Outputs written to: $OutputsFile"
Write-Info "  Environment: $Env | Region: $Region | Account: $Account"
Write-Info "════════════════════════════════════════════════════════"
