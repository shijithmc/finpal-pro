using Amazon.CDK;
using Amazon.CDK.AWS.Cognito;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.Apigatewayv2;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.SSM;
using Constructs;

namespace FinpalPro.Cdk
{
    /// <summary>
    /// Foundation infrastructure for FinPal Pro backend:
    ///   - Cognito User Pool (phone number + 6-digit PIN via USER_PASSWORD_AUTH — no OTP)
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
            // Identity = phone number; credential = 6-digit PIN (Cognito password).
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

            // ── Cognito User Pool (Phone + PIN) ────────────────────────────────
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

                // The user's 6-digit PIN IS the Cognito password. MinLength 6 is
                // the Cognito policy floor — the app enforces exactly 6 digits.
                PasswordPolicy = new PasswordPolicy
                {
                    MinLength        = 6,
                    RequireUppercase = false,
                    RequireLowercase = false,
                    RequireDigits    = true,
                    RequireSymbols   = false,
                },

                // No SMS MFA (no-OTP product requirement); PIN recovery is a
                // follow-up — no recovery channel exists without SMS/email.
                Mfa             = Mfa.OFF,
                AccountRecovery = AccountRecovery.NONE,
                RemovalPolicy   = RemovalPolicy.RETAIN,

                // Attach trigger Lambdas.
                LambdaTriggers = new UserPoolTriggers
                {
                    PreSignUp = preSignUpFn,
                },
            });

            // App client — Flutter app (public client, no secret).
            // USER_PASSWORD_AUTH carries the PIN; Cognito verifies it server-side
            // with built-in escalating lockout on repeated failures.
            var userPoolClient = new UserPoolClient(this, "MobileAppClientV2", new UserPoolClientProps
            {
                UserPool           = userPool,
                UserPoolClientName = $"finpal-pro-flutter-phone-{env}",
                GenerateSecret     = false,   // Public client (Flutter app)
                AuthFlows          = new AuthFlow
                {
                    UserPassword = true,   // PIN sign-in (over TLS to Cognito)
                    UserSrp      = false,  // SRP not used by the REST client
                    Custom       = false,  // CUSTOM_AUTH retired with the TOFU flow
                },
                // OFF so the app can tell "no account" (UserNotFoundException →
                // confirm-PIN registration) from "wrong PIN". SignUp already
                // reveals existence via UsernameExistsException, so this adds
                // no new enumeration surface.
                PreventUserExistenceErrors = false,
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
                Description = "Cognito User Pool ID (phone + PIN, USER_PASSWORD_AUTH)",
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
