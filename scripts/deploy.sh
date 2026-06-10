#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# FinPal Pro — Release Deployment Script (Bash)
# Produces:  dist/finpal-pro-<version>-release.apk
#            dist/finpal-pro-<version>-release.aab
#
# Usage:
#   ./scripts/deploy.sh [--skip-tests] [--apk-only] [--aab-only] [--clean]
#
# Required env vars (if no android/key.properties exists):
#   KEY_ALIAS      — keystore key alias
#   KEY_PASSWORD   — key password
#   STORE_PASSWORD — keystore store password
#   KEYSTORE_PATH  — absolute path to .jks file (default: android/finpal-pro-release.jks)
#
# Flags:
#   --skip-tests   Skip flutter test (useful when CI already ran tests)
#   --apk-only     Build APK only (skip AAB)
#   --aab-only     Build AAB only (skip APK)
#   --clean        Run flutter clean before building
# ════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Flags ─────────────────────────────────────────────────────────────────────
SKIP_TESTS=false
BUILD_APK=true
BUILD_AAB=true
DO_CLEAN=false

for arg in "$@"; do
  case $arg in
    --skip-tests) SKIP_TESTS=true ;;
    --apk-only)   BUILD_AAB=false ;;
    --aab-only)   BUILD_APK=false ;;
    --clean)      DO_CLEAN=true ;;
    *) warn "Unknown flag: $arg" ;;
  esac
done

# ── Resolve repo root ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# ── Step 0: Pull latest from origin/main ─────────────────────────────────────
info "Step 0: Syncing with origin/main …"
git fetch origin
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse origin/"$CURRENT_BRANCH")
  if [ "$LOCAL" != "$REMOTE" ]; then
    info "Fast-forwarding $CURRENT_BRANCH → origin/$CURRENT_BRANCH"
    git merge --ff-only origin/"$CURRENT_BRANCH"
  else
    info "Already up to date with origin/$CURRENT_BRANCH"
  fi
else
  warn "Not on main/master (on '$CURRENT_BRANCH') — skipping pull. Run from main to get latest."
fi
success "Step 0 complete"

# ── Step 1: Validate signing config ──────────────────────────────────────────
info "Step 1: Checking signing config …"
KEY_PROPS="$REPO_ROOT/android/key.properties"
if [ -f "$KEY_PROPS" ]; then
  info "Using android/key.properties for signing"
elif [ -n "${KEY_ALIAS:-}" ] && [ -n "${KEY_PASSWORD:-}" ] && [ -n "${STORE_PASSWORD:-}" ]; then
  info "Using environment variables for signing"
  KS_PATH="${KEYSTORE_PATH:-$REPO_ROOT/android/finpal-pro-release.jks}"
  if [ ! -f "$KS_PATH" ]; then
    die "KEYSTORE_PATH='$KS_PATH' not found. Provide the .jks file or set KEYSTORE_PATH."
  fi
else
  warn "No android/key.properties and no signing env vars — build will use debug key."
  warn "Resulting APK/AAB will NOT be accepted by Google Play."
fi
success "Step 1 complete"

# ── Step 2: Read version from pubspec.yaml ────────────────────────────────────
info "Step 2: Reading version …"
VERSION=$(grep '^version:' "$REPO_ROOT/pubspec.yaml" | awk '{print $2}' | tr -d '\r')
if [ -z "$VERSION" ]; then
  die "Could not read version from pubspec.yaml"
fi
VERSION_NAME="${VERSION%%+*}"   # e.g. 1.0.0
VERSION_CODE="${VERSION##*+}"   # e.g. 1
info "Version: $VERSION_NAME (build $VERSION_CODE)"
success "Step 2 complete"

# ── Step 3: Optional clean ────────────────────────────────────────────────────
if [ "$DO_CLEAN" = true ]; then
  info "Step 3: Running flutter clean …"
  flutter clean
  success "Step 3 complete"
else
  info "Step 3: Skipping flutter clean (pass --clean to force)"
fi

# ── Step 4: Install dependencies ─────────────────────────────────────────────
info "Step 4: Installing dependencies …"
flutter pub get
success "Step 4 complete"

# ── Step 5: Drift code generation ────────────────────────────────────────────
info "Step 5: Generating Drift database code …"
dart run build_runner build --delete-conflicting-outputs
success "Step 5 complete"

# ── Step 6: Format check ─────────────────────────────────────────────────────
info "Step 6: Checking code formatting …"
dart format --set-exit-if-changed lib/ test/ || die "Format check failed. Run: dart format lib/ test/"
success "Step 6 complete"

# ── Step 7: Static analysis ───────────────────────────────────────────────────
info "Step 7: Running static analysis …"
flutter analyze --fatal-infos
success "Step 7 complete"

# ── Step 8: Unit tests ────────────────────────────────────────────────────────
if [ "$SKIP_TESTS" = false ]; then
  info "Step 8: Running unit tests …"
  flutter test test/ --reporter=compact
  success "Step 8 complete"
else
  warn "Step 8: Unit tests skipped (--skip-tests)"
fi

# ── Step 9: Create output directory ──────────────────────────────────────────
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/dist}"
mkdir -p "$OUTPUT_DIR"
info "Step 9: Artifacts → $OUTPUT_DIR"

# ── Step 10: Build release APK ───────────────────────────────────────────────
if [ "$BUILD_APK" = true ]; then
  info "Step 10: Building release APK (arm64) …"
  flutter build apk \
    --release \
    --target-platform android-arm64 \
    --dart-define=APP_ENV=production

  APK_SRC="$REPO_ROOT/build/app/outputs/flutter-apk/app-release.apk"
  APK_DEST="$OUTPUT_DIR/finpal-pro-${VERSION_NAME}-release.apk"
  cp "$APK_SRC" "$APK_DEST"
  APK_SIZE=$(du -sh "$APK_DEST" | cut -f1)
  success "Step 10: APK built → $APK_DEST ($APK_SIZE)"
else
  info "Step 10: APK build skipped (--aab-only)"
fi

# ── Step 11: Build release AAB ────────────────────────────────────────────────
if [ "$BUILD_AAB" = true ]; then
  info "Step 11: Building release AAB (Play Store) …"
  flutter build appbundle \
    --release \
    --dart-define=APP_ENV=production

  AAB_SRC="$REPO_ROOT/build/app/outputs/bundle/release/app-release.aab"
  AAB_DEST="$OUTPUT_DIR/finpal-pro-${VERSION_NAME}-release.aab"
  cp "$AAB_SRC" "$AAB_DEST"
  AAB_SIZE=$(du -sh "$AAB_DEST" | cut -f1)
  success "Step 11: AAB built → $AAB_DEST ($AAB_SIZE)"
else
  info "Step 11: AAB build skipped (--apk-only)"
fi

# ── Step 12: Generate SHA-256 checksums ──────────────────────────────────────
info "Step 12: Generating checksums …"
CHECKSUM_FILE="$OUTPUT_DIR/finpal-pro-${VERSION_NAME}-checksums.sha256"
(cd "$OUTPUT_DIR" && sha256sum finpal-pro-"${VERSION_NAME}"-*.apk finpal-pro-"${VERSION_NAME}"-*.aab 2>/dev/null > "$CHECKSUM_FILE" || true)
success "Step 12: Checksums → $CHECKSUM_FILE"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  FinPal Pro $VERSION_NAME — Release build complete${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
ls -lh "$OUTPUT_DIR"/finpal-pro-"${VERSION_NAME}"-* 2>/dev/null || true
