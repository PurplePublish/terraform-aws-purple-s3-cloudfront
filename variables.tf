// ==========================================================================================================================
// S3
// ==========================================================================================================================

variable "bucket_name" {
  type = string
}

variable "bucket_prefix" {
  type    = string
  default = ""
}

variable "bucket_iam_user_name" {
  type    = string
  default = null
}

variable "bucket_additional_cloudfront_arns" {
  type    = list(string)
  default = []
}

variable "bucket_automatic_cleanup_enabled" {
  type = bool
  default = true
}

variable "bucket_automatic_cleanup_days" {
  description = "How many days should deleted objects be kept"
  type = number
  default = 400
}

variable "bucket_automatic_cleanup_multipart_upload_days" {
  description = "How many days should aborted multipart uploads be kept"
  type = number
  default = 7
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

variable "cloudfront_public_web" {
  type    = bool
  default = false
}

variable "cloudfront_logging_config" {
  description = "The logging configuration that controls how logs are written to your distribution (maximum one)."
  type        = any
  default     = {}
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
