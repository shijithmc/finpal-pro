#!/usr/bin/env bash
# ============================================================
# deploy-aws.sh  —  FinPal Pro AWS CDK deployment
# ============================================================
# Bootstraps CDK (idempotent) and deploys both stacks to ap-south-1.
#
# Usage:
#   ./scripts/deploy-aws.sh [OPTIONS]
#
# Options:
#   --env <dev|staging|production>   APP_ENV override (default: dev)
#   --region <region>                AWS region override (default: ap-south-1)
#   --account <id>                   AWS account ID override
#   --bootstrap-only                 Only bootstrap CDK, don't deploy
#   --skip-bootstrap                 Skip bootstrap (already done)
#   --stack <name>                   Deploy a single stack (FinpalDistribution|FinpalFoundation)
#   --dry-run                        Run cdk synth only, no deploy
#
# Prerequisites:
#   - AWS CLI configured (aws configure or env vars AWS_ACCESS_KEY_ID etc.)
#   - .NET 8 SDK installed
#   - AWS CDK CLI installed (npm install -g aws-cdk)
#
# Environment variables (override defaults):
#   APP_ENV               dev | staging | production
#   AWS_DEFAULT_REGION    AWS region
#   CDK_DEFAULT_ACCOUNT   AWS account ID
#   CDK_DEFAULT_REGION    CDK region (falls back to AWS_DEFAULT_REGION)
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CDK_DIR="$REPO_ROOT/infrastructure/cdk"

# ── Defaults ─────────────────────────────────────────────────
APP_ENV="${APP_ENV:-dev}"
REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT="${CDK_DEFAULT_ACCOUNT:-}"
BOOTSTRAP_ONLY=false
SKIP_BOOTSTRAP=false
STACK_FILTER=""
DRY_RUN=false

# ── Colours ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
step()    { echo -e "\n${GREEN}══ $* ══${NC}"; }

# ── Argument parsing ─────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --env)             APP_ENV="$2";       shift 2 ;;
    --region)          REGION="$2";        shift 2 ;;
    --account)         ACCOUNT="$2";       shift 2 ;;
    --bootstrap-only)  BOOTSTRAP_ONLY=true; shift ;;
    --skip-bootstrap)  SKIP_BOOTSTRAP=true; shift ;;
    --stack)           STACK_FILTER="$2";  shift 2 ;;
    --dry-run)         DRY_RUN=true;       shift ;;
    *) error "Unknown option: $1. Run with --help to see usage." ;;
  esac
done

# ── Step 1: Validate prerequisites ───────────────────────────
step "1/5 — Validate prerequisites"

if ! command -v aws &>/dev/null; then
  error "AWS CLI not found. Install from https://aws.amazon.com/cli/"
fi

if ! command -v dotnet &>/dev/null; then
  error ".NET SDK not found. Install from https://dot.net"
fi

# Locate CDK binary — handles npm global installs on Windows/Unix
CDK_CMD=""
for candidate in cdk \
    "$HOME/.npm-global/bin/cdk" \
    "$HOME/AppData/Roaming/npm/cdk" \
    "/c/Users/$USERNAME/AppData/Roaming/npm/cdk" \
    "$(npm root -g 2>/dev/null)/.bin/cdk"; do
  if command -v "$candidate" &>/dev/null 2>&1; then
    CDK_CMD="$candidate"
    break
  fi
done

if [[ -z "$CDK_CMD" ]]; then
  error "CDK CLI not found. Install: npm install -g aws-cdk"
fi

info "CDK: $CDK_CMD ($(${CDK_CMD} --version 2>&1 | head -1))"

# ── Step 2: Resolve AWS identity ─────────────────────────────
step "2/5 — Resolve AWS identity"

CALLER=$(aws sts get-caller-identity --query '{Account:Account,Arn:Arn}' --output json 2>&1) || \
  error "Cannot reach AWS. Check AWS CLI credentials (aws configure or env vars)."

RESOLVED_ACCOUNT=$(echo "$CALLER" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
CALLER_ARN=$(echo "$CALLER" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)

if [[ -z "$ACCOUNT" ]]; then
  ACCOUNT="$RESOLVED_ACCOUNT"
fi

info "Account : $ACCOUNT"
info "Identity: $CALLER_ARN"
info "Region  : $REGION"
info "App env : $APP_ENV"

# Warn if using root credentials
if echo "$CALLER_ARN" | grep -q ":root"; then
  warn "Deploying with ROOT credentials — create a least-privilege CDK IAM role before production."
fi

# ── Step 3: Build CDK project ─────────────────────────────────
step "3/5 — Build CDK project (dotnet build)"

cd "$CDK_DIR/src"
dotnet build --configuration Release --nologo -q || error "dotnet build failed"
info "dotnet build: SUCCESS"
cd "$CDK_DIR"

# ── Step 4: CDK bootstrap ─────────────────────────────────────
if [[ "$SKIP_BOOTSTRAP" == "false" ]]; then
  step "4/5 — CDK bootstrap aws://${ACCOUNT}/${REGION}"
  export CDK_DEFAULT_ACCOUNT="$ACCOUNT"
  export CDK_DEFAULT_REGION="$REGION"
  export APP_ENV="$APP_ENV"
  "$CDK_CMD" bootstrap "aws://${ACCOUNT}/${REGION}" || error "CDK bootstrap failed"
  info "Bootstrap: COMPLETE"
else
  step "4/5 — CDK bootstrap skipped (--skip-bootstrap)"
fi

if [[ "$BOOTSTRAP_ONLY" == "true" ]]; then
  info "Bootstrap-only mode — done."
  exit 0
fi

# ── Step 5: CDK synth + deploy ────────────────────────────────
step "5/5 — CDK deploy"

export CDK_DEFAULT_ACCOUNT="$ACCOUNT"
export CDK_DEFAULT_REGION="$REGION"
export APP_ENV="$APP_ENV"

if [[ "$DRY_RUN" == "true" ]]; then
  info "Dry-run mode — running cdk synth only"
  "$CDK_CMD" synth
  info "Synth: SUCCESS — no resources deployed"
  exit 0
fi

DEPLOY_ARGS=(deploy --require-approval never --outputs-file "$REPO_ROOT/cdk-outputs.json")

if [[ -n "$STACK_FILTER" ]]; then
  DEPLOY_ARGS+=("$STACK_FILTER")
else
  DEPLOY_ARGS+=(--all)
fi

"$CDK_CMD" "${DEPLOY_ARGS[@]}"

echo ""
info "════════════════════════════════════════════════════════"
info "  CDK deployment complete"
info "  Environment: $APP_ENV | Region: $REGION | Account: $ACCOUNT"
info "  Outputs: $REPO_ROOT/cdk-outputs.json"

OUTPUTS_FILE="$REPO_ROOT/cdk-outputs.json"
if command -v python3 &>/dev/null && [[ -f "$OUTPUTS_FILE" ]]; then
  _get() { python3 -c "import json,sys; d=json.load(open('$OUTPUTS_FILE')); print(d.get('$1',{}).get('$2',''))" 2>/dev/null; }
  APP_URL=$(_get "FinpalDistributionStack" "DistributionDomainOutput")
  API_URL=$(_get "FinpalFoundationStack"   "ApiEndpointOutput")
  POOL_ID=$(_get "FinpalFoundationStack"   "UserPoolIdOutput")
  CLIENT_ID=$(_get "FinpalFoundationStack" "UserPoolClientIdOutput")
  TABLE=$(_get "FinpalFoundationStack"     "TableNameOutput")
  echo ""
  [[ -n "$APP_URL"   ]] && info "  App URL         : $APP_URL"
  [[ -n "$API_URL"   ]] && info "  API Endpoint    : $API_URL"
  [[ -n "$POOL_ID"   ]] && info "  Cognito Pool ID : $POOL_ID"
  [[ -n "$CLIENT_ID" ]] && info "  Cognito Client  : $CLIENT_ID"
  [[ -n "$TABLE"     ]] && info "  DynamoDB Table  : $TABLE"
else
  warn "  python3 not found or cdk-outputs.json missing — check file for URLs"
fi

info "════════════════════════════════════════════════════════"
