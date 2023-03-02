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
  name = var.bucket_name
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
  name        = var.bucket_name
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
    enable_accept_encoding_brotli = false
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_response_headers_policy" "s3" {
  name = var.bucket_name
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

resource "aws_cloudfront_public_key" "purple" {
  name_prefix = "${var.bucket_name}-"
  comment     = "Public key of Purple DS"
  encoded_key = file("${path.module}/cloudfront/purple-public.pem")
  lifecycle {
    create_before_destroy = true
  }
}

resource "tls_private_key" "lambda" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_cloudfront_public_key" "lambda" {
  name_prefix = "${var.bucket_name}-lambda-"
  comment     = "Public key of Purple DS (Lambda)"
  encoded_key = tls_private_key.lambda.public_key_pem
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_key_group" "default" {
  name    = var.bucket_name
  comment = "Public keys for ${var.bucket_name}"
  items   = [aws_cloudfront_public_key.purple.id, aws_cloudfront_public_key.lambda.id]
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = var.bucket_name
  description                       = "Origin access control policy for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = ">= 3.0.0"

  # Metadata
  comment = coalesce(var.cloudfront_comment, var.cloudfront_domain != "" ? "Cloudfront for ${var.cloudfront_domain}" : "Cloudfront for ${var.bucket_name}")

  # Basic settings
  http_version    = "http2"
  is_ipv6_enabled = true
  price_class     = var.cloudfront_price_class
  aliases         = var.cloudfront_domain != "" ? [var.cloudfront_domain] : null

  # Origins
  origin = {
    "S3-${var.bucket_name}" = {
      domain_name              = module.bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.default.id
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

    trusted_signers    = null
    trusted_key_groups = [aws_cloudfront_key_group.default.id]
  })
  ordered_cache_behavior = [
    merge(local.behavior_defaults, {
      path_pattern     = "public/*"
      target_origin_id = "S3-${var.bucket_name}"
    }),
    merge(local.behavior_defaults, {
      path_pattern     = "tts/*"
      target_origin_id = "S3-${var.bucket_name}"
    }),
    merge(local.behavior_defaults, { # require signing for HTML files
      path_pattern     = "*.pkar/web/*"
      target_origin_id = "S3-${var.bucket_name}"

      trusted_signers    = null
      trusted_key_groups = [aws_cloudfront_key_group.default.id]

      lambda_function_association = {
        "origin-request" = {
          lambda_arn   = module.tachyon.lambda_function_qualified_arn
          include_body = false
        }
        "viewer-response" = {
          lambda_arn   = module.web_signed_cookies.lambda_function_qualified_arn
          include_body = false
        }
      }
    }),
    merge(local.behavior_defaults, {
      path_pattern     = "*/thumbnails/*"
      target_origin_id = "S3-${var.bucket_name}"
    })
  ]

  viewer_certificate = var.cloudfront_domain != "" ? {
    acm_certificate_arn      = var.manage_certificate ? module.acm.acm_certificate_arn : var.acm_certificate_arn
    minimum_protocol_version = var.cloudfront_minimum_protocol_version
    ssl_support_method       = "sni-only"
    } : {
    cloudfront_default_certificate = true
  }
}
