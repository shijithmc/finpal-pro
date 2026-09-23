using System.Collections.Generic;
using Amazon.CDK;
using Amazon.CDK.AWS.Cognito;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.Apigatewayv2;
using Amazon.CDK.AwsApigatewayv2Authorizers;
using Amazon.CDK.AwsApigatewayv2Integrations;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.SecretsManager;
using Amazon.CDK.AWS.SSM;
using Constructs;

namespace FinpalPro.Cdk
{
    /// <summary>
    /// Foundation infrastructure for FinPal Pro backend:
    ///   - Cognito User Pool (native SMS one-time-password authentication)
    ///   - DynamoDB single-table (primary datastore)
    ///   - HTTP API Gateway (Lambda integration point, routes added per Sprint)
    /// </summary>
    public class FinpalFoundationStack : Stack
    {
        public CfnOutput UserPoolId      { get; }
        public CfnOutput UserPoolClientId { get; }
        public CfnOutput TableName       { get; }
        public CfnOutput ApiEndpoint     { get; }

        public FinpalFoundationStack(Construct scope, string id, IStackProps props = null)
            : base(scope, id, props)
        {
            var env = System.Environment.GetEnvironmentVariable("APP_ENV") ?? "dev";
            var authStage = AuthMigrationGuard.Validate(Account, Region);
            var otpEnabled = authStage == "otp";

            // Keep this construct id and schema: existing users retain their sub.
            // Cognito sends and verifies the SMS codes; no custom auth or
            // auto-confirm/auto-verify Lambda can bypass proof of phone ownership.
            var userPool = new UserPool(this, "UserPoolPhone", new UserPoolProps
            {
                UserPoolName      = $"finpal-pro-users-phone-{env}",
                SelfSignUpEnabled = otpEnabled,
                FeaturePlan       = FeaturePlan.ESSENTIALS,
                // Cognito requires PASSWORD in this policy. Legacy passwords
                // must be randomized during the locked stage before USER_AUTH.
                SignInPolicy = new SignInPolicy
                {
                    AllowedFirstAuthFactors = new AllowedFirstAuthFactors
                    {
                        Password = true,
                        SmsOtp   = true,
                    },
                },

                // Phone number is the only sign-in identifier.
                SignInAliases = new SignInAliases { Phone = true, Username = false },
                AutoVerify    = new AutoVerifiedAttrs { Phone = true },
                KeepOriginal  = new KeepOriginalAttrs { Phone = true },
                EnableSmsRole = true,
                SnsRegion     = Region,

                StandardAttributes = new StandardAttributes
                {
                    PhoneNumber = new StandardAttribute { Required = true, Mutable = true },
                },

                // Preserve the existing pool policy. New app registrations omit
                // Password; legacy shared passwords are retired before cutover.
                PasswordPolicy = new PasswordPolicy
                {
                    MinLength        = 8,
                    RequireUppercase = true,
                    RequireLowercase = true,
                    RequireDigits    = true,
                    RequireSymbols   = false,
                },

                // SMS is the first factor. Required MFA is incompatible with OTP.
                Mfa             = Mfa.OFF,
                AccountRecovery = AccountRecovery.NONE,
                RemovalPolicy   = RemovalPolicy.RETAIN,
            });

            // Rotate the app client to invalidate legacy refresh credentials and
            // remove old client tokens from the HTTP API's accepted audience.
            // The user pool, and therefore every existing user's sub, stays intact.
            var userPoolClient = new UserPoolClient(this, "MobileOtpClient", new UserPoolClientProps
            {
                UserPool           = userPool,
                UserPoolClientName = $"finpal-pro-flutter-sms-otp-{env}",
                GenerateSecret     = false,   // Public client (Flutter app)
                AuthFlows          = new AuthFlow
                {
                    User         = otpEnabled,
                    UserPassword = false,
                    UserSrp      = false,
                    Custom       = false,
                },
                DisableOAuth               = true,
                PreventUserExistenceErrors = true,
                AuthSessionValidity        = Duration.Minutes(3),
                AccessTokenValidity        = Duration.Hours(1),
                IdTokenValidity            = Duration.Hours(1),
                RefreshTokenValidity       = Duration.Days(30),
                EnableTokenRevocation      = true,
                ReadAttributes = new ClientAttributes().WithStandardAttributes(
                    new StandardAttributesMask
                    {
                        PhoneNumber = true, PhoneNumberVerified = true,
                    }),
                WriteAttributes = new ClientAttributes().WithStandardAttributes(
                    new StandardAttributesMask { PhoneNumber = true }),
            });

            // In the locked stage the replacement client cannot start sign-in.
            // It has never issued refresh credentials. Keep its logical id stable
            // so the OTP stage enables this same client after the migration.
            if (!otpEnabled)
            {
                var cfnClient = (CfnUserPoolClient)userPoolClient.Node.DefaultChild;
                cfnClient.AddPropertyOverride("ExplicitAuthFlows",
                    new[] { "ALLOW_REFRESH_TOKEN_AUTH" });
            }

            // ── DynamoDB Single-Table ──────────────────────────────────────────
            var table = new Table(this, "MainTable", new TableProps
            {
                TableName    = $"finpal-pro-{env}",
                BillingMode  = BillingMode.PAY_PER_REQUEST,
                PartitionKey = new Attribute { Name = "PK", Type = AttributeType.STRING },
                SortKey      = new Attribute { Name = "SK", Type = AttributeType.STRING },
                PointInTimeRecoverySpecification = new PointInTimeRecoverySpecification
                {
                    PointInTimeRecoveryEnabled = true,
                },
                DeletionProtection  = env == "production",
                RemovalPolicy       = env == "production" ? RemovalPolicy.RETAIN : RemovalPolicy.DESTROY,
                TimeToLiveAttribute = "TTL",
            });

            table.AddGlobalSecondaryIndex(new GlobalSecondaryIndexProps
            {
                IndexName      = "GSI1",
                PartitionKey   = new Attribute { Name = "GSI1PK", Type = AttributeType.STRING },
                SortKey        = new Attribute { Name = "GSI1SK", Type = AttributeType.STRING },
                ProjectionType = ProjectionType.ALL,
            });

            table.AddGlobalSecondaryIndex(new GlobalSecondaryIndexProps
            {
                IndexName      = "GSI2",
                PartitionKey   = new Attribute { Name = "GSI2PK", Type = AttributeType.STRING },
                SortKey        = new Attribute { Name = "GSI2SK", Type = AttributeType.STRING },
                ProjectionType = ProjectionType.ALL,
            });

            // ── HTTP API Gateway ───────────────────────────────────────────────
            var httpApi = new HttpApi(this, "HttpApi", new HttpApiProps
            {
                ApiName     = $"finpal-pro-api-{env}",
                Description = "FinPal Pro backend HTTP API",
                CorsPreflight = new CorsPreflightOptions
                {
                    AllowOrigins = new[] { "*" },
                    AllowMethods = new[] { CorsHttpMethod.GET, CorsHttpMethod.POST,
                                          CorsHttpMethod.PUT, CorsHttpMethod.DELETE,
                                          CorsHttpMethod.OPTIONS },
                    AllowHeaders = new[] { "Content-Type", "Authorization", "X-Api-Key" },
                    MaxAge       = Duration.Days(1),
                },
                DisableExecuteApiEndpoint = false,
            });

            // ── AI Bill Scan (PBI-016, issues #61–#64) ─────────────────────────
            // Gemini API key lives ONLY in Secrets Manager — never in the client.
            // Created with a generated placeholder; set the real key post-deploy:
            //   aws secretsmanager put-secret-value \
            //     --secret-id finpal-pro/gemini-api-key-<env> \
            //     --secret-string "<GEMINI_API_KEY>"
            var geminiSecret = new Secret(this, "GeminiApiKeySecret", new SecretProps
            {
                SecretName  = $"finpal-pro/gemini-api-key-{env}",
                Description = "Google Gemini API key for the AI bill scan proxy. " +
                              "Placeholder until manually set — scans return 503 until then.",
            });

            // Scan proxy Lambda: authenticates via the JWT authorizer below,
            // enforces the free-tier quota server-side, relays the image to
            // Gemini, and never persists the image.
            var scanFn = new Function(this, "AiScanFn", new FunctionProps
            {
                FunctionName = $"finpal-ai-scan-{env}",
                Runtime      = Runtime.NODEJS_20_X,
                Handler      = "index.handler",
                Code         = Code.FromAsset("lambda/scan"),
                MemorySize   = 512,
                Timeout      = Duration.Seconds(30),
                Description  = "AI bill scan proxy: quota enforcement + Gemini Vision relay (PBI-016).",
                Environment  = new Dictionary<string, string>
                {
                    ["TABLE_NAME"]              = table.TableName,
                    ["GEMINI_SECRET_ARN"]       = geminiSecret.SecretArn,
                    ["GEMINI_MODEL"]            = "gemini-2.5-flash",
                    ["FREE_SCAN_LIMIT"]         = "10",
                    ["GLOBAL_MONTHLY_SCAN_CAP"] = "5000",
                },
            });

            table.GrantReadWriteData(scanFn);
            geminiSecret.GrantRead(scanFn);

            // Cognito access tokens carry client_id (not aud) — the HTTP API JWT
            // authorizer validates client_id against this audience list.
            var scanAuthorizer = new HttpJwtAuthorizer(
                "ScanJwtAuthorizer",
                $"https://cognito-idp.{Region}.amazonaws.com/{userPool.UserPoolId}",
                new HttpJwtAuthorizerProps
                {
                    JwtAudience = new[] { userPoolClient.UserPoolClientId },
                });

            var scanIntegration = new HttpLambdaIntegration("ScanIntegration", scanFn);

            httpApi.AddRoutes(new AddRoutesOptions
            {
                Path        = "/v1/scan",
                Methods     = new[] { Amazon.CDK.AWS.Apigatewayv2.HttpMethod.POST },
                Integration = scanIntegration,
                Authorizer  = scanAuthorizer,
            });

            httpApi.AddRoutes(new AddRoutesOptions
            {
                Path        = "/v1/scan/quota",
                Methods     = new[] { Amazon.CDK.AWS.Apigatewayv2.HttpMethod.GET },
                Integration = scanIntegration,
                Authorizer  = scanAuthorizer,
            });

            httpApi.AddRoutes(new AddRoutesOptions
            {
                Path        = "/v1/scan/feedback",
                Methods     = new[] { Amazon.CDK.AWS.Apigatewayv2.HttpMethod.POST },
                Integration = scanIntegration,
                Authorizer  = scanAuthorizer,
            });

            // ── SSM Parameters ─────────────────────────────────────────────────
            new StringParameter(this, "UserPoolIdParam", new StringParameterProps
            {
                ParameterName = "/finpal-pro/cognito/user-pool-id",
                StringValue   = userPool.UserPoolId,
                Description   = "FinPal Pro Cognito User Pool ID (SMS OTP)",
            });

            new StringParameter(this, "UserPoolClientIdParam", new StringParameterProps
            {
                ParameterName = "/finpal-pro/cognito/client-id",
                StringValue   = userPoolClient.UserPoolClientId,
                Description   = "FinPal Pro Cognito App Client ID",
            });

            new StringParameter(this, "TableNameParam", new StringParameterProps
            {
                ParameterName = "/finpal-pro/dynamodb/table-name",
                StringValue   = table.TableName,
                Description   = "FinPal Pro DynamoDB table name",
            });

            new StringParameter(this, "ApiEndpointParam", new StringParameterProps
            {
                ParameterName = "/finpal-pro/api/endpoint",
                StringValue   = httpApi.ApiEndpoint,
                Description   = "FinPal Pro HTTP API Gateway endpoint",
            });

            // ── Outputs ────────────────────────────────────────────────────────
            new CfnOutput(this, "AuthStageOutput", new CfnOutputProps
            {
                Value       = authStage,
                Description = "Auth migration stage: locked or otp",
            });

            UserPoolId = new CfnOutput(this, "UserPoolIdOutput", new CfnOutputProps
            {
                Value       = userPool.UserPoolId,
                Description = "Cognito User Pool ID (SMS OTP)",
                ExportName  = "FinpalUserPoolId",
            });

            UserPoolClientId = new CfnOutput(this, "UserPoolClientIdOutput", new CfnOutputProps
            {
                Value       = userPoolClient.UserPoolClientId,
                Description = "Cognito App Client ID (Flutter app)",
                ExportName  = "FinpalUserPoolClientId",
            });

            TableName = new CfnOutput(this, "TableNameOutput", new CfnOutputProps
            {
                Value       = table.TableName,
                Description = "DynamoDB single-table name",
                ExportName  = "FinpalTableName",
            });

            ApiEndpoint = new CfnOutput(this, "ApiEndpointOutput", new CfnOutputProps
            {
                Value       = httpApi.ApiEndpoint,
                Description = "HTTP API Gateway endpoint",
                ExportName  = "FinpalApiEndpoint",
            });
        }
    }
}
