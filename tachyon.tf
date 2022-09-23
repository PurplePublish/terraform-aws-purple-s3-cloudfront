module "tachyon" {
  source  = "terraform-aws-modules/lambda/aws"
  version = ">= 4.0.2"
  providers = {
    aws = aws.us-east-1
  }

  function_name                     = "tachyon-${var.bucket_name}"
  description                       = "Lambda@Edge Tachyon for ${var.bucket_name}"
  handler                           = "lambda-handler.handler"
  runtime                           = "nodejs12.x"
  timeout                           = 30
  memory_size                       = 256
  lambda_at_edge                    = true
  create_package                    = false
  local_existing_package            = "${path.module}/tachyon/tachyon-r32.zip"
  cloudwatch_logs_retention_in_days = 30
}
