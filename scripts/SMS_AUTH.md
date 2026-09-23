# SMS authentication rollout

The app uses Cognito's native `USER_AUTH` / `SMS_OTP` flow. New registrations omit a password and verify a Cognito SMS code. Existing accounts keep their pool and `sub`; their next app sign-in requires a code. The old authentication Lambdas and app client are removed. This document describes a planned rollout. SMS delivery, account quotas, and live infrastructure have **not** been configured or verified by these code changes.

## Why the migration has a maintenance stage

Cognito's current CDK implementation requires `PASSWORD` alongside `SMS_OTP` in the pool policy. `ALLOW_USER_AUTH` can therefore offer password authentication even when `ALLOW_USER_PASSWORD_AUTH` is absent. Older FinPal accounts used a shared development password; enabling the new flow before retiring it would expose those accounts. See the [CDK implementation](https://github.com/aws/aws-cdk/blob/main/packages/aws-cdk-lib/aws-cognito/lib/user-pool.ts) and [choice-based authentication](https://docs.aws.amazon.com/cognito/latest/developerguide/authentication-flows-selection-sdk.html).

The rollout uses two explicit stages:

| Stage | Signup | Replacement client | Existing credentials |
| --- | --- | --- | --- |
| `locked` | Disabled | Refresh only; has never issued tokens | Old client deleted; old API audience removed |
| `otp` | Enabled | Native sign-in and refresh | Legacy passwords randomized and sessions revoked first |

`AUTH_STAGE` has no default. Synthesis refuses to continue without `locked` or `otp`. Activation also requires a migration receipt matching the AWS account, region, and pool. The receipt is an operator deployment guard, not an AWS attestation; generate it only with the migration utility. Keep the receipt for later deployments of the same pool. Do not fabricate or edit it.

The app exposes only SMS sign-in. Cognito still permits an account owner to set a private password through its API after obtaining an authenticated session; this implementation does not claim to disable that AWS capability.

## SMS prerequisites

1. Use the existing AWS account, stack environment (`APP_ENV`), and Mumbai region. Preserve the current environment value: changing it can rename unrelated infrastructure. Review the CloudFormation changes before applying them; `UserPoolPhone8BB2D86D` must remain the same pool, with no pool or database replacement.
2. The stack selects Cognito **Essentials**, enables a Cognito SMS IAM role, and sets SNS delivery to the stack region. Account charges and SMS delivery quotas apply. In the SNS / AWS End User Messaging SMS sandbox, only verified destination numbers can receive messages. Verify a test phone, test delivery, and obtain production access and an appropriate spending quota before a public rollout. Configure delivery logging, alarms, and SMS fraud protection for the account. See [Cognito SMS settings](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-sms-settings.html).
3. India supports international and local delivery routes. International delivery uses generic numeric origination; local sender IDs require DLT registration and an approved entity, template, and telemarketer chain. Do not assume that an arbitrary sender ID works. See [India route selection](https://docs.aws.amazon.com/sms-voice/latest/userguide/registrations-sms-senderid-india-routes.html) and [India registration](https://docs.aws.amazon.com/sms-voice/latest/userguide/registrations-sms-senderid-india.html).
4. This stack uses Cognito's **SNS** integration, which does not expose India entity/template fields. If registered local routes are required, configure and validate Cognito's supported direct AWS End User Messaging integration with the registered origination identity and `InEntityId` / `InTemplateId` before release; that optional integration is not provisioned here. Ensure both signup and sign-in messages match the approved templates. Do not mark SMS ready until a real device receives both messages.

## Controlled cutover

Schedule a maintenance window: the locked stage intentionally stops sign-in. Keep administrators from creating users or changing credentials during migration. Keep the OTP web deployment gated until the backend and real-device checks pass. Do not use the older release workflow's web-first/CDK-second sequence for this cutover.

1. Build and test this branch. Review a change set for **FinpalFoundation only**, using the existing account, region, and environment. Set `AUTH_STAGE=locked`. Apply this stage only as a deliberate deployment action. Wait for `UPDATE_COMPLETE` and verify `AuthStageOutput=locked`. It removes the unsafe triggers and client, disables signup, and updates the API audience. Confirm the replacement client was newly created; never use `locked` as an ordinary rollback after OTP activation.
2. Record `UserPoolIdOutput` and `UserPoolClientIdOutput` from the deployed stack. Run the read-only migration preview from the repository root, with the actual account and pool IDs:

   ```bash
   node scripts/migrate-sms-auth.mjs \
     --account 123456789012 --region ap-south-1 --pool-id ap-south-1_REPLACE
   ```

   The utility checks the account, completed stack stage, disabled signup, removed bypass triggers, and absence of any other app client. Unmanaged or retained old clients cause it to stop; review and retire them deliberately before proceeding. It lists every page of users without printing phone numbers.
3. After reviewing the target and count, retire the old credentials:

   ```bash
   node scripts/migrate-sms-auth.mjs \
     --account 123456789012 --region ap-south-1 --pool-id ap-south-1_REPLACE \
     --apply --receipt "$PWD/auth-migration-receipt.json"
   ```

   This action changes credentials. For each account it generates a unique random password, sets it permanently, and revokes sessions. It does not delete users, change their `sub`, set `phone_number_verified`, or alter application data. Cognito can change an unconfirmed account's status to `CONFIRMED` when its password is set; its next app sign-in still requires SMS ownership proof. Passwords are never printed or saved, and AWS CLI JSON is passed through stdin. The executing principal needs the read operations used by the preview plus `cognito-idp:AdminSetUserPassword` and `cognito-idp:AdminUserGlobalSignOut`, scoped to the target pool where supported. `sts:GetCallerIdentity` and stack/client inspection are also required.

   A failure produces no new readiness receipt. Keep the stack locked and rerun after resolving it. Rerunning randomizes credentials again; it does not duplicate accounts. Receipt files cannot be overwritten. After migration the utility rechecks the lock and pool membership; concurrent changes prevent completion.
4. Synthesize and review the activation change set with `AUTH_STAGE=otp`, `AUTH_USER_POOL_ID` set to the existing pool ID, and `AUTH_MIGRATION_RECEIPT` set to the absolute receipt path. `CDK_DEFAULT_ACCOUNT`, `CDK_DEFAULT_REGION`, and `APP_ENV` must still match the deployed stack. Apply the activation stage, verify the same pool and replacement client IDs, and confirm only `ALLOW_USER_AUTH` and `ALLOW_REFRESH_TOKEN_AUTH` are enabled. Keep the receipt with deployment configuration for future synth/deploy operations; it contains no passwords or tokens. A different pool requires its own migration.
5. On a real test device, verify new signup, existing-user SMS sign-in, wrong/expired code rejection, resend, sign-out, and refresh after token expiry. Use an existing test account to confirm the old shared password cannot authenticate through `USER_AUTH`; old-client refresh and API tokens must also fail. Verify the authenticated `sub` equals the previous user's `sub` and saved local records remain available. Restore no shared password while testing.
6. Update the gated web build's `OTP_COGNITO_CLIENT_ID` to the **replacement** `UserPoolClientIdOutput`, retain `COGNITO_POOL_ID`, and retain `API_BASE_URL`. Rebuild/redeploy the app only after step 5. Mobile builds must pass the same identifiers through `--dart-define`. Existing installs must update; stale code cannot authenticate with the deleted client. Clear the web deployment gate if SMS configuration or live checks fail.

If the cutover fails, remain in maintenance or fix forward. Recreating the old no-verification client or triggers would restore the vulnerability. The old client deletion is intentional and cannot preserve old sessions.

## API contract

- **New account:** `SignUp` with `ClientId`, E.164 `Username`, and `phone_number`; omit `Password`. Confirm with `ConfirmSignUp` and its SMS code. Pass the returned confirmation `Session` to `InitiateAuth` with `AuthFlow=USER_AUTH`; only this already-verified session may result in immediate tokens. See [SignUp](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_SignUp.html) and [ConfirmSignUp](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_ConfirmSignUp.html).
- **Existing account:** `InitiateAuth` with `AuthFlow=USER_AUTH`, `AuthParameters.USERNAME`, and `PREFERRED_CHALLENGE=SMS_OTP`. Complete the returned challenge with `RespondToAuthChallenge`, `ChallengeName=SMS_OTP`, its `Session`, and `ChallengeResponses` containing `USERNAME` and `SMS_OTP_CODE`. Preserve any canonical username returned by Cognito. See [RespondToAuthChallenge](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_RespondToAuthChallenge.html).
- **Refresh:** use `REFRESH_TOKEN_AUTH` with the replacement client and its refresh token. Never use a legacy token as proof of phone ownership.

## Local checks (no AWS mutations)

```bash
node --test scripts/migrate-sms-auth.test.mjs
dotnet build infrastructure/cdk/src/Cdk/Cdk.csproj --configuration Release
node --test infrastructure/cdk/test/auth-migration-guard.test.mjs
cd infrastructure/cdk
AUTH_STAGE=locked CDK_OUTDIR=cdk.out CDK_DEFAULT_ACCOUNT=123456789012 \
  CDK_DEFAULT_REGION=ap-south-1 dotnet run --project src/Cdk/Cdk.csproj \
  --configuration Release --no-build
node --test test/auth-template.test.mjs
```

Template tests check the retained pool identity, removed bypass triggers/client, replacement API audience, explicit SMS configuration, and stage-specific signup/auth flows. Repeat against an OTP-stage synthesis using a **test-only** receipt for a dummy account in an isolated output directory; never use a test receipt to deploy. These checks do not prove SMS delivery or deployed CloudFormation compatibility.
