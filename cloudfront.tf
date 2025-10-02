resource "aws_cloudfront_public_key" "purple" {
  name_prefix = "${var.bucket_name}-"
  comment     = "Public key of Purple DS"
  encoded_key = replace(file("${path.module}/cloudfront/purple-public.pem"), "\r\n", "\n")
  lifecycle {
    create_before_destroy = true
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
      header_behavior = "whitelist"
      headers {
        items = [
          "Origin",
          "Access-Control-Request-Method",
          "Access-Control-Request-Headers",
          "Referer",
        ]
      }
    }
    query_strings_config {
      query_string_behavior = var.cloudfront_exclude_tracking_params ? "allExcept" : "all"
      dynamic "query_strings" {
        for_each = var.cloudfront_exclude_tracking_params ? [1] : []
        content {
          items = [
            "fbclid",
            "gclid",
            "utm_campaign",
            "utm_medium",
            "utm_source",
            "utm_term",
            "msclkid",
            "_ga",
            "mc_cid",
            "dclid"
          ]
        }
      }
    }
    enable_accept_encoding_brotli = false
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_origin_request_policy" "s3" {
  name = var.bucket_name
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Origin",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers",
        "Referer",
      ]
    }
  }
  query_strings_config {
    query_string_behavior = var.cloudfront_exclude_tracking_params ? "allExcept" : "all"
    dynamic "query_strings" {
      for_each = var.cloudfront_exclude_tracking_params ? [1] : []
      content {
        items = [
          "fbclid",
          "gclid",
          "utm_campaign",
          "utm_medium",
          "utm_source",
          "utm_term",
          "msclkid",
          "_ga",
          "mc_cid",
          "dclid"
        ]
      }
    }
  }
}

resource "aws_cloudfront_key_group" "default" {
  name    = var.bucket_name
  comment = "Public keys for ${var.bucket_name}"
  items   = [aws_cloudfront_public_key.purple.id, module.lambdas.cloudfront_public_key_id]
}

module "default_cloudfront" {
  source = "./modules/cloudfront"

  providers = {
    aws.us-east-1 = aws.us-east-1
  }
  bucket_name                         = var.bucket_name
  bucket_prefix                       = var.bucket_prefix
  bucket_regional_domain_name         = module.bucket.s3_bucket_bucket_regional_domain_name
  bucket_region                       = module.bucket.s3_bucket_region
  cloudfront_comment                  = var.cloudfront_comment
  cloudfront_price_class              = var.cloudfront_price_class
  cloudfront_domain                   = var.cloudfront_domain
  cloudfront_minimum_protocol_version = var.cloudfront_minimum_protocol_version
  cloudfront_cors_allow_origins       = var.cloudfront_cors_allow_origins
  cloudfront_tachyon_qualified_arn    = module.lambdas.tachyon_qualified_arn
  cloudfront_public_web               = var.cloudfront_public_web
  cloudfront_cache_policy_id          = aws_cloudfront_cache_policy.s3.id
  cloudfront_origin_request_policy_id = aws_cloudfront_origin_request_policy.s3.id
  cloudfront_key_group_id             = aws_cloudfront_key_group.default.id
  cloudfront_logging_config           = var.cloudfront_logging_config
  manage_certificate                  = var.manage_certificate
  acm_certificate_name                = var.acm_certificate_name
  acm_certificate_arn                 = var.acm_certificate_arn
  acm_zone_id                         = var.acm_zone_id
}

moved {
  from = module.cloudfront
  to   = module.default_cloudfront.module.cloudfront
}

moved {
  from = aws_cloudfront_origin_access_control.default
  to   = module.default_cloudfront.aws_cloudfront_origin_access_control.default
}

moved {
  from = aws_cloudfront_response_headers_policy.s3
  to   = module.default_cloudfront.aws_cloudfront_response_headers_policy.s3
}
