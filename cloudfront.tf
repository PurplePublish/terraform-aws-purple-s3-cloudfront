locals {
  behavior_defaults = {
    viewer_protocol_policy   = "allow-all"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    use_forwarded_values     = false
    cache_policy_id          = data.aws_cloudfront_cache_policy.s3.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors.id

    lambda_function_association = {
      "origin-request" = {
        lambda_arn   = module.tachyon.lambda_function_qualified_arn
        include_body = false
      }
    }
  }
}

data "aws_cloudfront_origin_request_policy" "cors" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_cache_policy" "s3" {
  name = "Managed-CachingOptimized"
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = ">= 3.0.0"

  # Metadata
  comment = try(var.cloudfront_comment, var.cloudfront_domain != null ? "Cloudfront for ${var.cloudfront_domain}" : null)

  # Basic settings
  http_version    = "http2and3"
  is_ipv6_enabled = true
  price_class     = var.cloudfront_price_class
  aliases         = [var.cloudfront_domain]

  create_origin_access_identity = true
  origin_access_identities = {
    (var.bucket_name) = "Origin Access Identity for Bucket ${var.bucket_name}"
  }

  # Origins
  origin = {
    "S3-${var.bucket_name}" = {
      domain_name = module.bucket.s3_bucket_bucket_domain_name
      s3_origin_config = {
        origin_access_identity = var.bucket_name
      }
      custom_header = {
        region = {
          name  = "X-AWS-S3-REGION"
          value = module.bucket.s3_bucket_region
        }
        bucket = {
          name  = "X-AWS-S3-BUCKET"
          value = var.bucket_name
        }
      }
    }
  }

  default_cache_behavior = merge(local.behavior_defaults, {
    target_origin_id = "S3-${var.bucket_name}"

    trusted_signers = [for account_id in concat(["self"], var.cloudfront_trusted_signers) : account_id if account_id != data.aws_caller_identity.current.account_id]
  })
  ordered_cache_behavior = [
    merge(local.behavior_defaults, {
      path_pattern     = "*/thumbnails/*"
      target_origin_id = "S3-${var.bucket_name}"
    }),
    merge(local.behavior_defaults, {
      path_pattern     = "public/*"
      target_origin_id = "S3-${var.bucket_name}"
    })
  ]

  viewer_certificate = var.cloudfront_domain != null ? {
    acm_certificate_arn      = var.manage_certificate ? module.acm.acm_certificate_arn : var.acm_certificate_arn
    minimum_protocol_version = var.cloudfront_minimum_protocol_version
    ssl_support_method       = "sni-only"
    } : {
    cloudfront_default_certificate = true
    minimum_protocol_version       = var.cloudfront_minimum_protocol_version
  }
}
