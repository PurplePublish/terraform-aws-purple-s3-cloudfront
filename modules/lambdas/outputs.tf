output "tachyon_qualified_arn" {
  value = module.tachyon.lambda_function_qualified_arn
}
output "cookies_qualified_arn" {
  value = module.web_signed_cookies.lambda_function_qualified_arn
}
output "cloudfront_public_key_id" {
  value = aws_cloudfront_public_key.lambda.id
}
