using Amazon.CDK;
using Amazon.CDK.AWS.CloudFront;
using Amazon.CDK.AWS.CloudFront.Origins;
using Amazon.CDK.AWS.S3;
using Amazon.CDK.AWS.SSM;
using Constructs;

namespace FinpalPro.Cdk
{
    /// <summary>
    /// S3 bucket + CloudFront distribution for FinPal Pro Flutter Web hosting.
    /// Serves the Flutter Web SPA (build/web/) via CloudFront OAC v2.
    ///
    /// Cache strategy:
    ///   index.html           — no-cache (always fresh, Flutter router entry point)
    ///   *.js / *.wasm        — 1 year  (content-hashed filenames by Flutter build)
    ///   flutter_service_worker.js — no-cache
    ///   assets/**            — 1 year  (content-hashed)
    ///   *.html (other)       — no-cache
    /// </summary>
    public class FinpalDistributionStack : Stack
    {
        /// <summary>CloudFront distribution domain name (e.g. d1234.cloudfront.net).</summary>
        public CfnOutput DistributionDomain { get; }

        /// <summary>S3 bucket name for web asset upload.</summary>
        public CfnOutput WebBucketName { get; }

        /// <summary>CloudFront distribution ID (needed for cache invalidation after deploy).</summary>
        public CfnOutput DistributionId { get; }

        public FinpalDistributionStack(Construct scope, string id, IStackProps props = null)
            : base(scope, id, props)
        {
            // ── S3 Bucket (web assets) ─────────────────────────────────────────
            // Private — all access via CloudFront OAC. No static website hosting
            // needed because CloudFront handles the SPA routing via error responses.
            var bucket = new Bucket(this, "WebBucket", new BucketProps
            {
                BucketName        = $"finpal-pro-web-{Account}",
                BlockPublicAccess = BlockPublicAccess.BLOCK_ALL,
                Encryption        = BucketEncryption.S3_MANAGED,
                EnforceSSL        = true,
                RemovalPolicy     = RemovalPolicy.RETAIN,
                // Versioning: helpful for rollback; minor cost on frequent deploys.
                Versioned         = true,
            });

            // ── CloudFront OAC ─────────────────────────────────────────────────
            var s3Origin = S3BucketOrigin.WithOriginAccessControl(bucket);

            // ── Cache policies ─────────────────────────────────────────────────

            // No-cache: HTML entry points + service worker — must always be fresh.
            // Note: EnableAcceptEncodingGzip/Brotli are invalid when MaxTtl = 0.
            // CloudFront still compresses via the Compress = true behavior flag.
            var noCachePolicy = new CachePolicy(this, "NoCachePolicy", new CachePolicyProps
            {
                CachePolicyName = "FinpalNoCache",
                DefaultTtl      = Duration.Seconds(0),
                MaxTtl          = Duration.Seconds(1),  // CloudFront requires MaxTtl >= 1s
                MinTtl          = Duration.Seconds(0),
            });

            // Long-cache: content-hashed JS/WASM/assets — immutable once deployed.
            var immutableCachePolicy = new CachePolicy(this, "ImmutableCachePolicy", new CachePolicyProps
            {
                CachePolicyName          = "FinpalImmutable",
                DefaultTtl               = Duration.Days(365),
                MaxTtl                   = Duration.Days(365),
                MinTtl                   = Duration.Days(365),
                EnableAcceptEncodingGzip = true,
                EnableAcceptEncodingBrotli = true,
            });

            // ── CloudFront Distribution ────────────────────────────────────────
            var distribution = new Distribution(this, "WebCDN", new DistributionProps
            {
                Comment              = "FinPal Pro — Flutter Web SPA",
                // Serve index.html when accessing the root — Flutter SPA entry point.
                DefaultRootObject    = "index.html",
                DefaultBehavior      = new BehaviorOptions
                {
                    Origin               = s3Origin,
                    ViewerProtocolPolicy = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                    // HTML files: no-cache so Flutter router and app updates are immediate.
                    CachePolicy          = noCachePolicy,
                    AllowedMethods       = AllowedMethods.ALLOW_GET_HEAD,
                    Compress             = true,
                },
                // ── Per-path cache behaviors ───────────────────────────────────
                AdditionalBehaviors = new System.Collections.Generic.Dictionary<string, IBehaviorOptions>
                {
                    // Content-hashed JS + WASM — safe to cache for 1 year.
                    ["*.js"] = new BehaviorOptions
                    {
                        Origin               = s3Origin,
                        ViewerProtocolPolicy = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                        CachePolicy          = immutableCachePolicy,
                        Compress             = true,
                    },
                    ["*.wasm"] = new BehaviorOptions
                    {
                        Origin               = s3Origin,
                        ViewerProtocolPolicy = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                        CachePolicy          = immutableCachePolicy,
                        Compress             = false, // wasm already compressed
                    },
                    // Flutter assets (fonts, images, canvaskit) — content-hashed.
                    ["assets/*"] = new BehaviorOptions
                    {
                        Origin               = s3Origin,
                        ViewerProtocolPolicy = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                        CachePolicy          = immutableCachePolicy,
                        Compress             = true,
                    },
                    // Service worker: must never be cached (versioning handled by Flutter).
                    ["flutter_service_worker.js"] = new BehaviorOptions
                    {
                        Origin               = s3Origin,
                        ViewerProtocolPolicy = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                        CachePolicy          = noCachePolicy,
                        Compress             = true,
                    },
                },
                // ── SPA routing — 403/404 from S3 → serve index.html ──────────
                // Flutter's Router handles the path client-side. Without this,
                // deep-linking (e.g. /dashboard) returns S3 NoSuchKey (403/404).
                ErrorResponses = new[]
                {
                    new ErrorResponse
                    {
                        HttpStatus          = 403,
                        ResponseHttpStatus  = 200,
                        ResponsePagePath    = "/index.html",
                        Ttl                 = Duration.Seconds(0),
                    },
                    new ErrorResponse
                    {
                        HttpStatus          = 404,
                        ResponseHttpStatus  = 200,
                        ResponsePagePath    = "/index.html",
                        Ttl                 = Duration.Seconds(0),
                    },
                },
                EnableLogging = true,
                HttpVersion   = HttpVersion.HTTP2_AND_3,
                PriceClass    = PriceClass.PRICE_CLASS_ALL,
            });

            // ── SSM Parameters ─────────────────────────────────────────────────
            new StringParameter(this, "BucketNameParam", new StringParameterProps
            {
                ParameterName = "/finpal-pro/distribution/bucket-name",
                StringValue   = bucket.BucketName,
                Description   = "FinPal Pro web S3 bucket name",
                Tier          = ParameterTier.STANDARD,
            });

            new StringParameter(this, "DistributionDomainParam", new StringParameterProps
            {
                ParameterName = "/finpal-pro/distribution/domain",
                StringValue   = distribution.DistributionDomainName,
                Description   = "FinPal Pro CloudFront distribution domain",
                Tier          = ParameterTier.STANDARD,
            });

            new StringParameter(this, "DistributionIdParam", new StringParameterProps
            {
                ParameterName = "/finpal-pro/distribution/id",
                StringValue   = distribution.DistributionId,
                Description   = "FinPal Pro CloudFront distribution ID",
                Tier          = ParameterTier.STANDARD,
            });

            // ── Outputs ────────────────────────────────────────────────────────
            DistributionDomain = new CfnOutput(this, "DistributionDomainOutput", new CfnOutputProps
            {
                Value       = $"https://{distribution.DistributionDomainName}",
                Description = "CloudFront URL — Flutter Web app",
                ExportName  = "FinpalDistributionDomain",
            });

            WebBucketName = new CfnOutput(this, "WebBucketOutput", new CfnOutputProps
            {
                Value       = bucket.BucketName,
                Description = "S3 bucket for Flutter Web assets",
                ExportName  = "FinpalWebBucket",
            });

            DistributionId = new CfnOutput(this, "DistributionIdOutput", new CfnOutputProps
            {
                Value       = distribution.DistributionId,
                Description = "CloudFront distribution ID (for cache invalidation)",
                ExportName  = "FinpalDistributionId",
            });
        }
    }
}
