using Amazon.CDK;

namespace FinpalPro.Cdk
{
    sealed class Program
    {
        public static void Main(string[] args)
        {
            var app = new App();

            // ── Environment ────────────────────────────────────────────────
            // Account and region are resolved from the active AWS CLI profile.
            // Override by setting CDK_DEFAULT_ACCOUNT / CDK_DEFAULT_REGION.
            var env = new Amazon.CDK.Environment
            {
                Account = System.Environment.GetEnvironmentVariable("CDK_DEFAULT_ACCOUNT")
                          ?? System.Environment.GetEnvironmentVariable("AWS_ACCOUNT_ID"),
                Region  = System.Environment.GetEnvironmentVariable("CDK_DEFAULT_REGION")
                          ?? System.Environment.GetEnvironmentVariable("AWS_DEFAULT_REGION")
                          ?? "ap-south-1",
            };

            var tags = new System.Collections.Generic.Dictionary<string, string>
            {
                ["Project"]     = "FinpalPro",
                ["ManagedBy"]   = "CDK",
                ["Environment"] = System.Environment.GetEnvironmentVariable("APP_ENV") ?? "dev",
            };

            // ── Distribution stack — S3 + CloudFront APK/AAB hosting ───────
            var distStack = new FinpalDistributionStack(app, "FinpalDistribution", new StackProps
            {
                Env         = env,
                Description = "FinPal Pro — S3 + CloudFront APK/AAB distribution",
                Tags        = tags,
            });

            // ── Foundation stack — Cognito, DynamoDB, API Gateway ──────────
            var foundationStack = new FinpalFoundationStack(app, "FinpalFoundation", new StackProps
            {
                Env         = env,
                Description = "FinPal Pro — Cognito, DynamoDB, API Gateway foundation",
                Tags        = tags,
            });

            app.Synth();
        }
    }
}
