// ==========================================================================================================================
// S3
// ==========================================================================================================================

output "s3_bucket_id" {
  value = module.bucket.s3_bucket_id
}

output "s3_bucket_bucket_domain_name" {
  value = module.bucket.s3_bucket_bucket_domain_name
}

output "s3_bucket_bucket_regional_domain_name" {
  value = module.bucket.s3_bucket_bucket_regional_domain_name
}

output "s3_bucket_region" {
  value = module.bucket.s3_bucket_region
}

output "s3_bucket_arn" {
  value = module.bucket.s3_bucket_arn
}
output "s3_bucket_hosted_zone_id" {
  value = module.bucket.s3_bucket_hosted_zone_id
}

output "s3_user_name" {
  value = aws_iam_user.default.name
}

output "s3_access_key" {
  value = aws_iam_access_key.default.id
}

output "s3_secret_key" {
  value     = aws_iam_access_key.default.secret
  sensitive = true
}

// ==========================================================================================================================
// Cloudfront
// ==========================================================================================================================

output "cloudfront_distribution_id" {
  value = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  value = module.cloudfront.cloudfront_distribution_hosted_zone_id
}
