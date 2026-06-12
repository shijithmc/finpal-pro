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
    ///   - Cognito User Pool (phone-number CUSTOM_AUTH — no OTP, no password)
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

            // ── Lambda: PreSignUp trigger ──────────────────────────────────────
            // Auto-confirms every new Cognito user without sending an OTP.
            // Enables trust-on-first-use (TOFU): mobile number = identity.
            var preSignUpFn = new Function(this, "PreSignUpFn", new FunctionProps
            {
                FunctionName = $"finpal-pre-signup-{env}",
                Runtime      = Runtime.NODEJS_20_X,
                Handler      = "index.handler",
                Code         = Code.FromInline(
                    "exports.handler = async (event) => {\n" +
                    "  event.response.autoConfirmUser = true;\n" +
                    "  event.response.autoVerifyPhone = true;\n" +
                    "  return event;\n" +
                    "};"
                ),
                Timeout     = Duration.Seconds(5),
                Description = "Auto-confirm Cognito users on sign-up without OTP verification.",
            });

            // ── Lambda: DefineAuthChallenge trigger ────────────────────────────
            // Issues tokens immediately on the first CUSTOM_AUTH call.
            // No challenge is issued — mobile number alone authenticates.
            var defineAuthChallengeFn = new Function(this, "DefineAuthChallengeFn", new FunctionProps
            {
                FunctionName = $"finpal-define-auth-challenge-{env}",
                Runtime      = Runtime.NODEJS_20_X,
                Handler      = "index.handler",
                Code         = Code.FromInline(
                    "exports.handler = async (event) => {\n" +
                    "  if (event.request.session.length === 0) {\n" +
                    "    event.response.issueTokens = true;\n" +
                    "    event.response.failAuthentication = false;\n" +
                    "  } else {\n" +
                    "    event.response.issueTokens = false;\n" +
                    "    event.response.failAuthentication = true;\n" +
                    "  }\n" +
                    "  return event;\n" +
                    "};"
                ),
                Timeout     = Duration.Seconds(5),
                Description = "CUSTOM_AUTH: issue tokens immediately without a challenge.",
            });

            // ── Cognito User Pool (Phone-based, TOFU) ──────────────────────────
            // NOTE: construct id changed "UserPool" → "UserPoolPhone" because
            // SignInAliases is an immutable CloudFormation property. CloudFormation
            // will create this new pool and retain the old one (RemovalPolicy.RETAIN).
            // After a successful CDK deploy, manually delete the old email-based
            // pool from the AWS Console — it is no longer referenced by any stack.
            var userPool = new UserPool(this, "UserPoolPhone", new UserPoolProps
            {
                UserPoolName      = $"finpal-pro-users-phone-{env}",
                SelfSignUpEnabled = true,

                // Phone number is the only sign-in identifier.
                SignInAliases = new SignInAliases { Phone = true, Username = false },
                AutoVerify    = new AutoVerifiedAttrs { Phone = true },

                StandardAttributes = new StandardAttributes
                {
                    PhoneNumber = new StandardAttribute { Required = true, Mutable = true },
                },

                // Password policy kept to satisfy the signUp API contract.
                // The password is never used for authentication (CUSTOM_AUTH only).
                PasswordPolicy = new PasswordPolicy
                {
                    MinLength        = 8,
                    RequireUppercase = true,
                    RequireLowercase = true,
                    RequireDigits    = true,
                    RequireSymbols   = false,
                },

                // MFA and account recovery are irrelevant with CUSTOM_AUTH.
                Mfa             = Mfa.OFF,
                AccountRecovery = AccountRecovery.NONE,
                RemovalPolicy   = RemovalPolicy.RETAIN,

                // Attach trigger Lambdas.
                LambdaTriggers = new UserPoolTriggers
                {
                    PreSignUp           = preSignUpFn,
                    DefineAuthChallenge = defineAuthChallengeFn,
                },
            });

            // App client — Flutter app (public client, no secret).
            // Only CUSTOM_AUTH is enabled; all password-based flows are disabled.
            var userPoolClient = new UserPoolClient(this, "MobileAppClientV2", new UserPoolClientProps
            {
                UserPool           = userPool,
                UserPoolClientName = $"finpal-pro-flutter-phone-{env}",
                GenerateSecret     = false,   // Public client (Flutter app)
                AuthFlows          = new AuthFlow
                {
                    UserPassword = false,  // Never allow plain-text password auth
                    UserSrp      = false,  // SRP not used — CUSTOM_AUTH only
                    Custom       = true,   // DefineAuthChallenge issues tokens immediately
                },
                PreventUserExistenceErrors = true,
                AccessTokenValidity        = Duration.Hours(1),
                IdTokenValidity            = Duration.Hours(1),
                RefreshTokenValidity       = Duration.Days(30),
                EnableTokenRevocation      = true,
                ReadAttributes = new ClientAttributes().WithStandardAttributes(
                    new StandardAttributesMask
                    {
                        PhoneNumber = true, PhoneNumberVerified = true,
                    }),
            });

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
                Description   = "FinPal Pro Cognito User Pool ID (phone-based CUSTOM_AUTH)",
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
            UserPoolId = new CfnOutput(this, "UserPoolIdOutput", new CfnOutputProps
            {
                Value       = userPool.UserPoolId,
                Description = "Cognito User Pool ID (phone-based CUSTOM_AUTH)",
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
