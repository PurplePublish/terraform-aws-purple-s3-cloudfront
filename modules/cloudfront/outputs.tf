// ==========================================================================================================================
// Cloudfront
// ==========================================================================================================================

output "cloudfront_distribution_id" {
  value = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  value = module.cloudfront.cloudfront_distribution_arn
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  value = module.cloudfront.cloudfront_distribution_hosted_zone_id
}

output "cloudfront_unsigned_path_patterns" {
  description = "Path patterns the distribution serves without a signed URL"
  value       = [for behavior in local.ordered_cache_behaviors : behavior.path_pattern if lookup(behavior, "trusted_key_groups", null) == null]
}
