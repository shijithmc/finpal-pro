using System;
using System.IO;
using System.Text.Json;

namespace FinpalPro.Cdk
{
    // Prevent a normal deploy from exposing USER_AUTH while old users still have
    // the shared development password. No AWS calls are made during synthesis.
    internal static class AuthMigrationGuard
    {
        public static string Validate(string account, string region)
        {
            var stage = Environment.GetEnvironmentVariable("AUTH_STAGE");
            if (stage != "locked" && stage != "otp")
                throw new InvalidOperationException(
                    "Set AUTH_STAGE=locked for the SMS migration maintenance stage, " +
                    "or AUTH_STAGE=otp with a verified migration receipt. See scripts/SMS_AUTH.md.");

            if (stage == "locked") return stage;

            var receiptPath = Environment.GetEnvironmentVariable("AUTH_MIGRATION_RECEIPT");
            var expectedPool = Environment.GetEnvironmentVariable("AUTH_USER_POOL_ID");
            if (string.IsNullOrWhiteSpace(receiptPath) || string.IsNullOrWhiteSpace(expectedPool))
                throw new InvalidOperationException(
                    "OTP activation requires AUTH_MIGRATION_RECEIPT and AUTH_USER_POOL_ID. " +
                    "Run scripts/migrate-sms-auth.mjs after deploying AUTH_STAGE=locked.");

            using var document = JsonDocument.Parse(File.ReadAllText(receiptPath));
            var receipt = document.RootElement;
            var valid = receipt.GetProperty("schemaVersion").GetInt32() == 1
                && receipt.GetProperty("authStage").GetString() == "locked"
                && receipt.GetProperty("migrationComplete").GetBoolean()
                && receipt.GetProperty("stackName").GetString() == "FinpalFoundation"
                && receipt.GetProperty("account").GetString() == account
                && receipt.GetProperty("region").GetString() == region
                && receipt.GetProperty("poolId").GetString() == expectedPool
                && receipt.GetProperty("migratedUsers").GetInt32() >= 0;
            var completedAt = receipt.GetProperty("completedAt").GetDateTimeOffset();
            var age = DateTimeOffset.UtcNow - completedAt;
            if (!valid || age < TimeSpan.Zero)
                throw new InvalidOperationException(
                    "SMS migration receipt is invalid or belongs to another target. " +
                    "Use the completed migration receipt for this account, region and pool.");

            return stage;
        }
    }
}
