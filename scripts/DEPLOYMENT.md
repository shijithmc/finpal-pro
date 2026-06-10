# FinPal Pro — Deployment Runbook

## Quick start

### Windows (PowerShell)
```powershell
# Full build: pull latest, test, APK + AAB
.\scripts\deploy.ps1

# Skip tests (CI already ran them)
.\scripts\deploy.ps1 -SkipTests

# APK only (faster, for sideload distribution)
.\scripts\deploy.ps1 -ApkOnly

# Clean build
.\scripts\deploy.ps1 -Clean
```

### Linux / macOS (Bash)
```bash
# Make executable once
chmod +x scripts/deploy.sh

# Full build: pull latest, test, APK + AAB
./scripts/deploy.sh

# Skip tests
./scripts/deploy.sh --skip-tests

# APK only
./scripts/deploy.sh --apk-only

# Clean build
./scripts/deploy.sh --clean
```

### Output
Both scripts produce artifacts in `dist/`:
```
dist/
  finpal-pro-1.0.0-release.apk        ← direct install / sideload
  finpal-pro-1.0.0-release.aab        ← Google Play Store upload
  finpal-pro-1.0.0-checksums.sha256   ← SHA-256 hashes for both
```

---

## Setting up release signing

### Option A — Local dev: `android/key.properties`

1. **Generate a keystore** (run once — keep the .jks file safe):
   ```bash
   keytool -genkey -v \
     -keystore android/finpal-pro-release.jks \
     -alias finpal-pro \
     -keyalg RSA -keysize 4096 \
     -validity 10000
   ```

2. **Create `android/key.properties`** (copy the template):
   ```bash
   cp android/key.properties.template android/key.properties
   # Edit the file and fill in real passwords
   ```

3. `android/key.properties` and `*.jks` are in `.gitignore` — never commit them.

### Option B — CI: GitHub Secrets

Add these four secrets in **GitHub → Settings → Secrets → Actions**:

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | `base64 -w 0 android/finpal-pro-release.jks` output |
| `KEY_ALIAS` | Key alias (e.g. `finpal-pro`) |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Keystore password |

The `build-release` CI job only runs on a **GitHub Release** (tag push). PRs and branches build a debug APK only.

---

## Triggering a release

1. Bump `version` in `pubspec.yaml` — e.g. `1.0.1+2`
2. Commit and merge to `main`
3. Create a GitHub Release:
   ```bash
   gh release create v1.0.1 \
     --title "FinPal Pro v1.0.1" \
     --notes "Bug fixes and performance improvements"
   ```
4. CI runs `build-release` job → attaches APK, AAB, and checksums to the release.

---

## Environment-variable overrides

| Variable | Default | Description |
|----------|---------|-------------|
| `OUTPUT_DIR` | `dist/` | Where artifacts are written |
| `KEYSTORE_PATH` | `android/finpal-pro-release.jks` | Path to `.jks` (env-var signing only) |
| `KEY_ALIAS` | — | Keystore key alias |
| `KEY_PASSWORD` | — | Key password |
| `STORE_PASSWORD` | — | Keystore password |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `keytool not found` | Install JDK 17: `sudo apt install openjdk-17-jdk` |
| `flutter: command not found` | Add Flutter to PATH; see [flutter.dev/install](https://flutter.dev/install) |
| `Format check failed` | Run `dart format lib/ test/` then re-run deploy script |
| `Signing config not found` | Check `android/key.properties` exists and `storeFile` path is correct |
| Build uses debug key | No `key.properties` and no signing env vars — see "Setting up release signing" above |
| `sha256sum: command not found` (macOS) | `brew install coreutils` |
