using Amazon.CDK;
using Amazon.CDK.AWS.Cognito;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.Apigatewayv2;
using Amazon.CDK.AWS.SSM;
using Constructs;

namespace FinpalPro.Cdk
{
    /// <summary>
    /// Foundation infrastructure for FinPal Pro backend:
    ///   - Cognito User Pool (auth)
    ///   - DynamoDB single-table (primary datastore)
    ///   - HTTP API Gateway (Lambda integration point, routes added per Sprint)
    /// </summary>
    public class FinpalFoundationStack : Stack
    {
        public CfnOutput UserPoolId     { get; }
        public CfnOutput UserPoolClientId { get; }
        public CfnOutput TableName      { get; }
        public CfnOutput ApiEndpoint    { get; }

        public FinpalFoundationStack(Construct scope, string id, IStackProps props = null)
            : base(scope, id, props)
        {
            var env = System.Environment.GetEnvironmentVariable("APP_ENV") ?? "dev";

            // ── Cognito User Pool ──────────────────────────────────────────────
            var userPool = new UserPool(this, "UserPool", new UserPoolProps
            {
                UserPoolName      = $"finpal-pro-users-{env}",
                SelfSignUpEnabled = true,
                SignInAliases     = new SignInAliases { Email = true, Username = false },
                AutoVerify        = new AutoVerifiedAttrs { Email = true },
                StandardAttributes = new StandardAttributes
                {
                    Email = new StandardAttribute { Required = true, Mutable = false },
                    GivenName  = new StandardAttribute { Required = false, Mutable = true },
                    FamilyName = new StandardAttribute { Required = false, Mutable = true },
                },
                PasswordPolicy = new PasswordPolicy
                {
                    MinLength        = 8,
                    RequireUppercase = true,
                    RequireLowercase = true,
                    RequireDigits    = true,
                    RequireSymbols   = false,
                },
                AccountRecovery   = AccountRecovery.EMAIL_ONLY,
                RemovalPolicy     = RemovalPolicy.RETAIN,

                // MFA: OPTIONAL — user chooses TOTP in Sprint 5.
                Mfa               = Mfa.OPTIONAL,
                MfaSecondFactor   = new MfaSecondFactor { Otp = true, Sms = false },
            });

            // App client — Flutter mobile app (no client secret for public client).
            var userPoolClient = new UserPoolClient(this, "MobileAppClient", new UserPoolClientProps
            {
                UserPool          = userPool,
                UserPoolClientName = $"finpal-pro-flutter-{env}",
                GenerateSecret    = false,   // Public client (Flutter app)
                AuthFlows         = new AuthFlow
                {
                    UserPassword   = false,  // Avoid plain-text password flows
                    UserSrp        = true,   // SRP (Secure Remote Password) — recommended
                    Custom         = false,
                },
                PreventUserExistenceErrors = true,
                AccessTokenValidity  = Duration.Hours(1),
                IdTokenValidity      = Duration.Hours(1),
                RefreshTokenValidity = Duration.Days(30),
                EnableTokenRevocation = true,
                ReadAttributes = new ClientAttributes().WithStandardAttributes(
                    new StandardAttributesMask
                    {
                        Email = true, GivenName = true, FamilyName = true, EmailVerified = true,
                    }),
            });

            // ── DynamoDB Single-Table ──────────────────────────────────────────
            // Partition key: PK (string) — entity prefix#id (e.g. USER#uuid, TXN#uuid)
            // Sort key:      SK (string) — entity type + date (e.g. TXN#2026-06#txn-id)
            //
            // GSI-1: GSI1PK / GSI1SK — inverted index for reverse lookups
            // GSI-2: GSI2PK / GSI2SK — category/budget queries by month
            var table = new Table(this, "MainTable", new TableProps
            {
                TableName     = $"finpal-pro-{env}",
                BillingMode   = BillingMode.PAY_PER_REQUEST,  // No capacity planning needed for Sprint 3
                PartitionKey  = new Attribute { Name = "PK", Type = AttributeType.STRING },
                SortKey       = new Attribute { Name = "SK", Type = AttributeType.STRING },
                PointInTimeRecoverySpecification = new PointInTimeRecoverySpecification
                {
                    PointInTimeRecoveryEnabled = true,
                },
                DeletionProtection  = env == "production",
                RemovalPolicy       = env == "production" ? RemovalPolicy.RETAIN : RemovalPolicy.DESTROY,

                // Time-to-live for soft-deleted / ephemeral records (Sprint 5).
                TimeToLiveAttribute = "TTL",
            });

            // GSI-1: reverse lookup (SK → PK pattern for category items etc.)
            table.AddGlobalSecondaryIndex(new GlobalSecondaryIndexProps
            {
                IndexName     = "GSI1",
                PartitionKey  = new Attribute { Name = "GSI1PK", Type = AttributeType.STRING },
                SortKey       = new Attribute { Name = "GSI1SK", Type = AttributeType.STRING },
                ProjectionType = ProjectionType.ALL,
            });

            // GSI-2: date range queries (monthly analytics, budget queries)
            table.AddGlobalSecondaryIndex(new GlobalSecondaryIndexProps
            {
                IndexName     = "GSI2",
                PartitionKey  = new Attribute { Name = "GSI2PK", Type = AttributeType.STRING },
                SortKey       = new Attribute { Name = "GSI2SK", Type = AttributeType.STRING },
                ProjectionType = ProjectionType.ALL,
            });

            // ── HTTP API Gateway ───────────────────────────────────────────────
            // Empty API created now; Lambda integrations added in Sprint 4+.
            var httpApi = new HttpApi(this, "HttpApi", new HttpApiProps
            {
                ApiName     = $"finpal-pro-api-{env}",
                Description = "FinPal Pro backend HTTP API",
                CorsPreflight = new CorsPreflightOptions
                {
                    AllowOrigins = new[] { "*" },   // Tightened per-origin in production (Sprint 5)
                    AllowMethods = new[] { CorsHttpMethod.GET, CorsHttpMethod.POST,
                                          CorsHttpMethod.PUT, CorsHttpMethod.DELETE,
                                          CorsHttpMethod.OPTIONS },
                    AllowHeaders = new[] { "Content-Type", "Authorization", "X-Api-Key" },
                    MaxAge       = Duration.Days(1),
                },
                // Disable default endpoint in production; use custom domain (Sprint 5).
                DisableExecuteApiEndpoint = false,
            });

            // NOTE: Lambda integrations and routes added in Sprint 4.
            // Health-check route deferred — requires HttpUrlIntegration from integrations sub-package.

            // ── SSM Parameters (consumed by Lambda functions and CI) ───────────
            new StringParameter(this, "UserPoolIdParam", new StringParameterProps
            {
                ParameterName = "/finpal-pro/cognito/user-pool-id",
                StringValue   = userPool.UserPoolId,
                Description   = "FinPal Pro Cognito User Pool ID",
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
                Description = "Cognito User Pool ID",
                ExportName  = "FinpalUserPoolId",
            });

            UserPoolClientId = new CfnOutput(this, "UserPoolClientIdOutput", new CfnOutputProps
            {
                Value       = userPoolClient.UserPoolClientId,
                Description = "Cognito App Client ID (Flutter mobile)",
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
