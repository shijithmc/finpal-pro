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

## AWS cloud deployment (CDK)

Infrastructure is defined in `infrastructure/cdk/` as AWS CDK v2 C# — two stacks deployed to `ap-south-1` (Mumbai).

| Stack | Resources | Purpose |
|-------|-----------|---------|
| `FinpalDistribution` | S3 + CloudFront | APK/AAB artifact hosting |
| `FinpalFoundation` | Cognito + DynamoDB + API Gateway | Backend auth, data, API |

### Prerequisites

- AWS CLI installed and configured (`aws configure`)
- .NET 8 SDK installed
- CDK CLI: `npm install -g aws-cdk`

### First-time setup (bootstrap)

Bootstrap creates a CDK toolkit S3 bucket + IAM roles in the target account/region. Run once per account/region:

```bash
./scripts/deploy-aws.sh --bootstrap-only
```

```powershell
.\scripts\deploy-aws.ps1 -BootstrapOnly
```

### Deploy all stacks

```bash
./scripts/deploy-aws.sh                        # dev env
./scripts/deploy-aws.sh --env production       # production
./scripts/deploy-aws.sh --skip-bootstrap       # skip if already bootstrapped
```

```powershell
.\scripts\deploy-aws.ps1                        # dev env
.\scripts\deploy-aws.ps1 -Env production        # production
.\scripts\deploy-aws.ps1 -SkipBootstrap         # skip if already bootstrapped
```

### Deploy a single stack

```bash
./scripts/deploy-aws.sh --stack FinpalFoundation
```

```powershell
.\scripts\deploy-aws.ps1 -Stack FinpalFoundation
```

### Dry run (synth only, no AWS changes)

```bash
./scripts/deploy-aws.sh --dry-run
```

```powershell
.\scripts\deploy-aws.ps1 -DryRun
```

### Outputs

Deployment outputs are written to `cdk-outputs.json` at repo root:

```json
{
  "FinpalDistribution": {
    "DistributionDomainOutput": "https://d1j6gya33wydw7.cloudfront.net",
    "ArtifactBucketOutput": "finpal-pro-artifacts-018535004303"
  },
  "FinpalFoundation": {
    "ApiEndpointOutput": "https://4gkbne88ck.execute-api.ap-south-1.amazonaws.com",
    "TableNameOutput": "finpal-pro-dev",
    "UserPoolIdOutput": "ap-south-1_KeUl8KcN1",
    "UserPoolClientIdOutput": "2rj64mabqu4bar9997gipoh0c9"
  }
}
```

All resource IDs are also stored as SSM parameters under `/finpal-pro/...`.

### AWS deploy environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ENV` | `dev` | Environment tag applied to all resources |
| `AWS_DEFAULT_REGION` | `ap-south-1` | Deployment region |
| `CDK_DEFAULT_ACCOUNT` | resolved from `aws sts` | AWS account ID |
| `AWS_ACCESS_KEY_ID` | — | AWS credentials (or use `aws configure`) |
| `AWS_SECRET_ACCESS_KEY` | — | AWS credentials |

### CI/CD automatic deployment

CDK deploys automatically when a **GitHub Release** is created (same trigger as the signed APK/AAB build). The CI job:
1. Installs CDK CLI
2. Runs `dotnet build` on the CDK project
3. Runs `cdk deploy --all` with `APP_ENV=production`

Required GitHub Secrets for AWS deployment:

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | `finpal-cdk-deployer` IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | `finpal-cdk-deployer` IAM user secret key |
| `AWS_ACCOUNT_ID` | `018535004303` |

### IAM deployer — least-privilege setup

CI credentials belong to the **`finpal-cdk-deployer`** IAM user:

```
ARN: arn:aws:iam::018535004303:user/finpal-cdk-deployer
```

The user has a single inline policy (`FinpalCdkDeployPolicy`) with **only `sts:AssumeRole`** on the three CDK bootstrap roles. No direct resource permissions are granted to the user.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AssumeBootstrappedCdkRoles",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "arn:aws:iam::018535004303:role/cdk-hnb659fds-deploy-role-018535004303-ap-south-1",
        "arn:aws:iam::018535004303:role/cdk-hnb659fds-file-publishing-role-018535004303-ap-south-1",
        "arn:aws:iam::018535004303:role/cdk-hnb659fds-lookup-role-018535004303-ap-south-1"
      ]
    }
  ]
}
```

**Why this works:** CDK bootstrap creates scoped execution roles in the account. The CI user assumes the deploy role → CDK assumes the cfn-exec role → CloudFormation creates/updates resources. Resource-creation permissions (Cognito, DynamoDB, API Gateway, S3, CloudFront, SSM) live inside the cfn-exec role, not in the CI user.

**Key rotation:** Rotate the `finpal-cdk-deployer` access key every 90 days. To rotate:
```bash
aws iam create-access-key --user-name finpal-cdk-deployer
# update GitHub Secrets AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
aws iam delete-access-key --user-name finpal-cdk-deployer --access-key-id <old-key-id>
```

See [CDK bootstrap permissions](https://docs.aws.amazon.com/cdk/v2/guide/bootstrapping-env.html) for the full bootstrap role trust model.

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
