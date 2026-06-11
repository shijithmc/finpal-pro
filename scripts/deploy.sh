#!/usr/bin/env bash
# ============================================================
# deploy.sh  —  FinPal Pro Flutter Web build script
# ============================================================
# Builds the Flutter Web app and optionally deploys to S3.
#
# Usage:
#   ./scripts/deploy.sh [OPTIONS]
#
# Options:
#   --skip-tests       Skip flutter test (tests already ran in CI)
#   --clean            Run flutter clean before build
#   --deploy           Also sync build/web/ to S3 + invalidate CloudFront
#   --bucket <name>    S3 bucket override (default: read from SSM)
#   --dist-id <id>     CloudFront distribution ID override (default: read from SSM)
#
# Prerequisites:
#   - Flutter SDK in PATH
#   - For --deploy: AWS CLI configured + SSM params at /finpal-pro/distribution/*
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
step()  { echo -e "\n${GREEN}══ $* ══${NC}"; }

SKIP_TESTS=false
CLEAN=false
DEPLOY=false
BUCKET=""
DIST_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-tests) SKIP_TESTS=true; shift ;;
    --clean)      CLEAN=true;      shift ;;
    --deploy)     DEPLOY=true;     shift ;;
    --bucket)     BUCKET="$2";    shift 2 ;;
    --dist-id)    DIST_ID="$2";   shift 2 ;;
    *) error "Unknown option: $1" ;;
  esac
done

cd "$REPO_ROOT"

# ── Step 1: Validate ─────────────────────────────────────────
step "1 — Validate"
command -v flutter &>/dev/null || error "flutter not found in PATH"
info "Flutter: $(flutter --version 2>&1 | head -1)"

# ── Step 2: Clean (optional) ──────────────────────────────────
if [[ "$CLEAN" == "true" ]]; then
  step "2 — flutter clean"
  flutter clean
fi

# ── Step 3: Dependencies ──────────────────────────────────────
step "3 — flutter pub get"
flutter pub get

# ── Step 4: Code generation ───────────────────────────────────
step "4 — build_runner"
dart run build_runner build --delete-conflicting-outputs

# ── Step 5: Format check ──────────────────────────────────────
step "5 — dart format check"
dart format --set-exit-if-changed lib/ test/ || {
  warn "Format check failed — run: dart format lib/ test/"
  exit 1
}

# ── Step 6: Analyze ───────────────────────────────────────────
step "6 — dart analyze"
flutter analyze --fatal-infos

# ── Step 7: Tests ─────────────────────────────────────────────
if [[ "$SKIP_TESTS" == "false" ]]; then
  step "7 — flutter test"
  flutter test test/ --reporter=compact
else
  info "Step 7 — tests skipped (--skip-tests)"
fi

# ── Step 8: Flutter Web build ─────────────────────────────────
step "8 — flutter build web"
flutter build web \
  --release \
  --dart-define=APP_ENV=production \
  --dart-define=COGNITO_POOL_ID="${COGNITO_POOL_ID:-}" \
  --dart-define=COGNITO_CLIENT_ID="${COGNITO_CLIENT_ID:-}"

WEB_OUT="$REPO_ROOT/build/web"
info "Web output: $WEB_OUT"
info "Size: $(du -sh "$WEB_OUT" | cut -f1)"

# ── Step 9: Deploy to S3 (optional) ──────────────────────────
if [[ "$DEPLOY" == "true" ]]; then
  step "9 — Deploy to S3 + CloudFront"
  command -v aws &>/dev/null || error "aws CLI not found — required for --deploy"

  if [[ -z "$BUCKET" ]]; then
    BUCKET=$(aws ssm get-parameter \
      --name "/finpal-pro/distribution/bucket-name" \
      --query "Parameter.Value" --output text) || \
      error "Cannot read bucket from SSM. Pass --bucket <name>."
  fi

  if [[ -z "$DIST_ID" ]]; then
    DIST_ID=$(aws ssm get-parameter \
      --name "/finpal-pro/distribution/id" \
      --query "Parameter.Value" --output text) || \
      error "Cannot read distribution ID from SSM. Pass --dist-id <id>."
  fi

  info "Bucket    : s3://$BUCKET"
  info "CloudFront: $DIST_ID"

  # Content-hashed assets (JS, WASM, fonts, images) — immutable, 1 year.
  aws s3 sync "$WEB_OUT" "s3://$BUCKET" \
    --delete \
    --exclude "*.html" \
    --exclude "flutter_service_worker.js" \
    --cache-control "public, max-age=31536000, immutable"

  # HTML + service worker — no-cache so app updates surface immediately.
  aws s3 sync "$WEB_OUT" "s3://$BUCKET" \
    --exclude "*" \
    --include "*.html" \
    --include "flutter_service_worker.js" \
    --cache-control "no-cache, no-store, must-revalidate"

  INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$DIST_ID" \
    --paths "/*" \
    --query "Invalidation.Id" --output text)

  info "Invalidation: $INVALIDATION_ID (propagating ~30-60s)"
fi

echo ""
info "════════════════════════════════════════════════════════"
info "  Flutter Web build complete — output: build/web/"
if [[ "$DEPLOY" == "true" ]]; then
  info "  Deployed → s3://$BUCKET"
  CF_DOMAIN=$(aws cloudfront get-distribution \
    --id "$DIST_ID" \
    --query "Distribution.DomainName" \
    --output text 2>/dev/null) || CF_DOMAIN=""
  [[ -n "$CF_DOMAIN" ]] && info "  App URL   : https://$CF_DOMAIN" || \
    warn "  Could not resolve CloudFront domain — check distribution $DIST_ID"
else
  info "  Run with --deploy to push to S3"
fi
info "════════════════════════════════════════════════════════"
