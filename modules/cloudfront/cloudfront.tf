locals {
  behavior_defaults = {
    viewer_protocol_policy     = var.cloudfront_viewer_protocol_policy
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    use_forwarded_values       = false
    cache_policy_id            = var.cloudfront_cache_policy_id
    origin_request_policy_id   = var.cloudfront_origin_request_policy_id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.s3.id

    lambda_function_association = {
      "origin-request" = {
        lambda_arn   = var.cloudfront_tachyon_qualified_arn
        include_body = false
      }
    }
  }
}

locals {
  public_behaviors = [
    merge(local.behavior_defaults, {
      path_pattern     = "${var.bucket_prefix}public/*"
      target_origin_id = "S3-${var.bucket_name}"
    }),
    merge(local.behavior_defaults, {
      path_pattern     = "${var.bucket_prefix}tts/*"
      target_origin_id = "S3-${var.bucket_name}"
    }),
  ]

  web_behaviors = [
    merge(local.behavior_defaults, {
      path_pattern     = "*.pkar/web/*"
      target_origin_id = "S3-${var.bucket_name}"

      trusted_signers    = null
      trusted_key_groups = var.cloudfront_public_web ? null : [var.cloudfront_key_group_id]
    }),
    merge(local.behavior_defaults, {
      path_pattern     = "*/web/*.pkar/*"
      target_origin_id = "S3-${var.bucket_name}"

      trusted_signers    = null
      trusted_key_groups = var.cloudfront_public_web ? null : [var.cloudfront_key_group_id]
    }),
    merge(local.behavior_defaults, {
      path_pattern     = "*/thumbnails/*"
      target_origin_id = "S3-${var.bucket_name}"
    }),
    merge(local.behavior_defaults, {
      path_pattern     = "thumbnails/*"
      target_origin_id = "S3-${var.bucket_name}"
    }),
  ]

  # Patterns that already have a behaviour are skipped: CloudFront rejects a distribution with two
  # behaviours of the same path pattern.
  fixed_path_patterns = [for behavior in concat(local.public_behaviors, local.web_behaviors) : behavior.path_pattern]
  additional_public_behaviors = [
    for pattern in distinct(var.cloudfront_public_path_patterns) : merge(local.behavior_defaults, {
      path_pattern     = pattern
      target_origin_id = "S3-${var.bucket_name}"
    }) if !contains(local.fixed_path_patterns, pattern)
  ]

  # Behaviours without trusted_key_groups serve their path without a signed URL; the
  # cloudfront_unsigned_path_patterns output is derived from that, so it cannot drift from them.
  # The additional public paths come before the web package paths: the first matching behaviour
  # wins, and a public object must not require a signature because its key also matches one of them.
  ordered_cache_behaviors = concat(local.public_behaviors, local.additional_public_behaviors, local.web_behaviors)
}

resource "aws_cloudfront_response_headers_policy" "s3" {
  name = "${var.bucket_name}${var.cloudfront_postfix}"
  cors_config {
    access_control_allow_credentials = false
    origin_override                  = true
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["ALL"]
    }
    access_control_allow_origins {
      items = var.cloudfront_cors_allow_origins != null ? var.cloudfront_cors_allow_origins : ["*"]
    }
  }
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "${var.bucket_name}${var.cloudfront_postfix}"
  description                       = "Origin access control policy for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.4.0"

  # Metadata
  comment = coalesce(var.cloudfront_comment, var.cloudfront_domain != "" ? "Cloudfront for ${var.cloudfront_domain}" : "Cloudfront for ${var.bucket_name}")

  # Basic settings
  http_version          = "http2"
  is_ipv6_enabled       = true
  price_class           = var.cloudfront_price_class
  aliases               = var.cloudfront_domain != "" ? [var.cloudfront_domain] : null
  wait_for_deployment   = var.cloudfront_wait_for_deployment
  origin_access_control = null

  # Origins
  origin = {
    "S3-${var.bucket_name}" = {
      domain_name              = var.bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.default.id
      custom_header = {
        "X-AWS-S3-REGION" = var.bucket_region
        "X-AWS-S3-BUCKET" = var.bucket_name
      }
    }
  }

  default_cache_behavior = merge(local.behavior_defaults, {
    target_origin_id = "S3-${var.bucket_name}"

    trusted_signers    = null
    trusted_key_groups = [var.cloudfront_key_group_id]
  })
  ordered_cache_behavior = local.ordered_cache_behaviors

  viewer_certificate = var.cloudfront_domain != "" ? {
    acm_certificate_arn      = var.manage_certificate ? module.acm.acm_certificate_arn : var.acm_certificate_arn
    minimum_protocol_version = var.cloudfront_minimum_protocol_version
    ssl_support_method       = "sni-only"
    } : {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }

  logging_config = var.cloudfront_logging_config
}
