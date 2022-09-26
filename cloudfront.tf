locals {
  behavior_defaults = {
    viewer_protocol_policy     = "allow-all"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    use_forwarded_values       = false
    cache_policy_id            = aws_cloudfront_cache_policy.s3.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.s3.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.s3.id

    lambda_function_association = {
      "origin-request" = {
        lambda_arn   = module.tachyon.lambda_function_qualified_arn
        include_body = false
      }
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "s3" {
  name = "Purple-${var.bucket_name}"
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_cache_policy" "s3" {
  name        = "Purple-${var.bucket_name}"
  min_ttl     = 1
  max_ttl     = 31536000
  default_ttl = 86400
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "s3" {
  name = "Purple-${var.bucket_name}"
  cors_config {
    access_control_allow_credentials = false
    origin_override                  = true
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["POST", "GET", "HEAD", "PATCH", "DELETE", "OPTIONS", "PUT"]
    }
    access_control_allow_origins {
      items = var.cloudfront_cors_allow_origins != null ? var.cloudfront_cors_allow_origins : ["*"]
    }
  }
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = ">= 3.0.0"

  # Metadata
  comment = try(var.cloudfront_comment, var.cloudfront_domain != "" ? "Cloudfront for ${var.cloudfront_domain}" : null)

  # Basic settings
  http_version    = "http2and3"
  is_ipv6_enabled = true
  price_class     = var.cloudfront_price_class
  aliases         = var.cloudfront_domain != "" ? [var.cloudfront_domain] : null

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

  viewer_certificate = var.cloudfront_domain != "" ? {
    acm_certificate_arn      = var.manage_certificate ? module.acm.acm_certificate_arn : var.acm_certificate_arn
    minimum_protocol_version = var.cloudfront_minimum_protocol_version
    ssl_support_method       = "sni-only"
    } : {
    cloudfront_default_certificate = true
    minimum_protocol_version       = var.cloudfront_minimum_protocol_version
  }
}
