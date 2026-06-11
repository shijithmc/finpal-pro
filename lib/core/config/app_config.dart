/// Application-level configuration.
///
/// Values are injected at build time via `--dart-define`:
///
///   flutter build web --release \
///     --dart-define=COGNITO_POOL_ID=ap-south-1_xxx \
///     --dart-define=COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
///
/// For local development add a VS Code launch configuration or run:
///   flutter run \
///     --dart-define=COGNITO_POOL_ID=ap-south-1_xxx \
///     --dart-define=COGNITO_CLIENT_ID=xxx
///
/// After CDK deploy, read the values from CDK outputs:
///   cat cdk-outputs.json | jq '.FinpalFoundation'
abstract final class AppConfig {
  /// Cognito User Pool ID (e.g. "ap-south-1_KeUl8KcN1").
  /// Passed as --dart-define=COGNITO_POOL_ID=...
  static const cognitoUserPoolId = String.fromEnvironment(
    'COGNITO_POOL_ID',
    defaultValue: '', // Empty → auth will fail with a clear Cognito error
  );

  /// Cognito App Client ID (no secret — public client).
  /// Passed as --dart-define=COGNITO_CLIENT_ID=...
  static const cognitoClientId = String.fromEnvironment(
    'COGNITO_CLIENT_ID',
    defaultValue: '',
  );
}
