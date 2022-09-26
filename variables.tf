// ==========================================================================================================================
// S3
// ==========================================================================================================================

variable "bucket_name" {
  type = string
}

variable "bucket_iam_user_name" {
  type    = string
  default = null
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

variable "cloudfront_trusted_signers" {
  type    = list(string)
  default = []
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
