using Amazon.CDK;
using Amazon.CDK.AWS.CloudFront;
using Amazon.CDK.AWS.CloudFront.Origins;
using Amazon.CDK.AWS.S3;
using Amazon.CDK.AWS.SSM;
using Constructs;

namespace FinpalPro.Cdk
{
    /// <summary>
    /// S3 bucket + CloudFront distribution for FinPal Pro APK/AAB release hosting.
    /// Provides a stable CloudFront URL for direct APK download links.
    /// </summary>
    public class FinpalDistributionStack : Stack
    {
        /// <summary>CloudFront distribution domain name (e.g. d1234.cloudfront.net).</summary>
        public CfnOutput DistributionDomain { get; }

        /// <summary>S3 bucket name for manual artifact upload or CI upload.</summary>
        public CfnOutput ArtifactBucketName { get; }

        public FinpalDistributionStack(Construct scope, string id, IStackProps props = null)
            : base(scope, id, props)
        {
            // ── S3 Bucket ──────────────────────────────────────────────────────
            // Private bucket — all access via CloudFront OAC only.
            var bucket = new Bucket(this, "ArtifactBucket", new BucketProps
            {
                BucketName        = $"finpal-pro-artifacts-{Account}",
                Versioned         = true,
                BlockPublicAccess = BlockPublicAccess.BLOCK_ALL,
                Encryption        = BucketEncryption.S3_MANAGED,
                EnforceSSL        = true,

                // Retain bucket on stack delete to prevent accidental APK loss.
                RemovalPolicy     = RemovalPolicy.RETAIN,

                // CORS: allow direct presigned URL downloads from app/browser.
                Cors = new[]
                {
                    new CorsRule
                    {
                        AllowedMethods = new[] { HttpMethods.GET, HttpMethods.HEAD },
                        AllowedOrigins = new[] { "*" },
                        AllowedHeaders = new[] { "*" },
                        MaxAge         = 3600,
                    },
                },
            });

            // ── CloudFront OAC ─────────────────────────────────────────────────
            var oac = new CfnOriginAccessControl(this, "BucketOAC", new CfnOriginAccessControlProps
            {
                OriginAccessControlConfig = new CfnOriginAccessControl.OriginAccessControlConfigProperty
                {
                    Name                          = $"finpal-pro-oac-{Account}",
                    OriginAccessControlOriginType = "s3",
                    SigningBehavior                = "always",
                    SigningProtocol                = "sigv4",
                    Description                   = "OAC for FinPal Pro artifact bucket",
                },
            });

            // ── CloudFront Distribution ────────────────────────────────────────
            var s3Origin = S3BucketOrigin.WithOriginAccessControl(bucket);

            var distribution = new Distribution(this, "ArtifactCDN", new DistributionProps
            {
                Comment           = "FinPal Pro — APK/AAB release distribution",
                DefaultBehavior   = new BehaviorOptions
                {
                    Origin                = s3Origin,
                    ViewerProtocolPolicy  = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                    CachePolicy           = CachePolicy.CACHING_OPTIMIZED,
                    AllowedMethods        = AllowedMethods.ALLOW_GET_HEAD,
                    Compress              = true,
                },
                // Cache APK files for 7 days; they are versioned by name.
                AdditionalBehaviors = new System.Collections.Generic.Dictionary<string, IBehaviorOptions>
                {
                    ["*.apk"] = new BehaviorOptions
                    {
                        Origin               = s3Origin,
                        ViewerProtocolPolicy = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                        CachePolicy          = new CachePolicy(this, "ApkCachePolicy", new CachePolicyProps
                        {
                            CachePolicyName      = "FinpalApkCachePolicy",
                            DefaultTtl           = Duration.Days(7),
                            MaxTtl               = Duration.Days(30),
                            MinTtl               = Duration.Seconds(0),
                            EnableAcceptEncodingGzip = true,
                        }),
                    },
                    ["*.aab"] = new BehaviorOptions
                    {
                        Origin               = s3Origin,
                        ViewerProtocolPolicy = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                        CachePolicy          = CachePolicy.CACHING_OPTIMIZED,
                    },
                },
                // Enable access logging for download analytics.
                EnableLogging     = true,
                HttpVersion       = HttpVersion.HTTP2_AND_3,
                PriceClass        = PriceClass.PRICE_CLASS_ALL, // Serve from nearest edge globally.
            });

            // ── SSM Parameters (consumed by CI/CD and backend) ─────────────────
            new StringParameter(this, "BucketNameParam", new StringParameterProps
            {
                ParameterName  = "/finpal-pro/distribution/bucket-name",
                StringValue    = bucket.BucketName,
                Description    = "FinPal Pro artifact S3 bucket name",
                Tier           = ParameterTier.STANDARD,
            });

            new StringParameter(this, "DistributionDomainParam", new StringParameterProps
            {
                ParameterName  = "/finpal-pro/distribution/domain",
                StringValue    = distribution.DistributionDomainName,
                Description    = "FinPal Pro CloudFront distribution domain",
                Tier           = ParameterTier.STANDARD,
            });

            new StringParameter(this, "DistributionIdParam", new StringParameterProps
            {
                ParameterName  = "/finpal-pro/distribution/id",
                StringValue    = distribution.DistributionId,
                Description    = "FinPal Pro CloudFront distribution ID",
                Tier           = ParameterTier.STANDARD,
            });

            // ── Outputs ────────────────────────────────────────────────────────
            DistributionDomain = new CfnOutput(this, "DistributionDomainOutput", new CfnOutputProps
            {
                Value       = $"https://{distribution.DistributionDomainName}",
                Description = "CloudFront URL for APK/AAB downloads",
                ExportName  = "FinpalDistributionDomain",
            });

            ArtifactBucketName = new CfnOutput(this, "ArtifactBucketOutput", new CfnOutputProps
            {
                Value       = bucket.BucketName,
                Description = "S3 bucket for APK/AAB artifacts",
                ExportName  = "FinpalArtifactBucket",
            });
        }
    }
}
