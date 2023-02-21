resource "aws_ssm_parameter" "cookies_private_key" {
  provider = aws.us-east-1
  name     = "/purple/cloudfront/lambda/purple-web-${var.bucket_name}/privateKey"
  type     = "SecureString"
  value    = tls_private_key.lambda.private_key_pem
}

resource "aws_ssm_parameter" "cookies_keypair_id" {
  provider = aws.us-east-1
  name     = "/purple/cloudfront/lambda/purple-web-${var.bucket_name}/keyPairId"
  type     = "String"
  value    = aws_cloudfront_public_key.lambda.id
}

data "aws_iam_policy_document" "web_signed_cookies" {
  statement {
    sid    = "AllowAccessToParameterStore"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      aws_ssm_parameter.cookies_private_key.arn,
      aws_ssm_parameter.cookies_keypair_id.arn
    ]
  }
}

module "web_signed_cookies" {
  source  = "terraform-aws-modules/lambda/aws"
  version = ">= 4.0.2"
  providers = {
    aws = aws.us-east-1
  }

  function_name                     = "purple-web-${var.bucket_name}"
  description                       = "Lambda@Edge for ${var.bucket_name}"
  handler                           = "index.handler"
  runtime                           = "nodejs18.x"
  timeout                           = 5   # Limit of viewer-* lambdas
  memory_size                       = 128 # Limit of viewer-* lambdas
  lambda_at_edge                    = true
  local_existing_package            = "${path.module}/lambda/cookies/cookies-r1.zip"
  cloudwatch_logs_retention_in_days = 30
  attach_policy_jsons               = true
  number_of_policy_jsons            = 1
  policy_jsons                      = [data.aws_iam_policy_document.web_signed_cookies.json]
}
