moved {
  from = tls_private_key.lambda
  to   = module.lambdas.tls_private_key.lambda
}

moved {
  from = aws_ssm_parameter.cookies_private_key
  to   = module.lambdas.aws_ssm_parameter.cookies_private_key
}

moved {
  from = aws_cloudfront_public_key.lambda
  to   = module.lambdas.aws_cloudfront_public_key.lambda
}

moved {
  from = aws_ssm_parameter.cookies_keypair_id
  to   = module.lambdas.aws_ssm_parameter.cookies_keypair_id
}

moved {
  from = module.web_signed_cookies
  to   = module.lambdas.module.web_signed_cookies
}
