// ==========================================================================================================================
// S3
// ==========================================================================================================================

variable "bucket_name" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "bucket_regional_domain_name" {
  type = string
}

variable "bucket_region" {
  type = string
}

// ==========================================================================================================================
// Cloudfront
// ==========================================================================================================================

variable "cloudfront_comment" {
  type    = string
  default = null
}

variable "cloudfront_price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "cloudfront_domain" {
  type    = string
  default = ""
}

variable "cloudfront_minimum_protocol_version" {
  type    = string
  default = "TLSv1.2_2021"
}

variable "cloudfront_cors_allow_origins" {
  type    = list(string)
  default = null
}

variable "cloudfront_public_tts" {
  type    = bool
  default = false
}

variable "cloudfront_postfix" {
  type    = string
  default = ""
}

variable "cloudfront_tachyon_qualified_arn" {
  type = string
}

variable "cloudfront_key_group_id" {
  type = string
}

variable "cloudfront_cookies_qualified_arn" {
  type    = string
  default = null
}

variable "cloudfront_cache_policy_id" {
  type = string
}

variable "cloudfront_origin_request_policy_id" {
  type = string
}

variable "cloudfront_wait_for_deployment" {
  type    = bool
  default = false
}

// ==========================================================================================================================
// ACM
// ==========================================================================================================================

variable "manage_certificate" {
  type    = bool
  default = true
}

variable "acm_certificate_name" {
  type    = string
  default = null
}

variable "acm_certificate_arn" {
  type    = string
  default = null
}

variable "acm_zone_id" {
  type    = string
  default = null
}
