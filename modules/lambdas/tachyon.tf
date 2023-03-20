data "aws_iam_policy_document" "tachyon_bucket" {
  statement {
    sid       = "AllowListBucketContents"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.bucket_arn]
  }
  statement {
    sid    = "AllowModificationsToBucket"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["${var.bucket_arn}/*"]
  }
}

module "tachyon" {
  source  = "terraform-aws-modules/lambda/aws"
  version = ">= 4.0.2"
  providers = {
    aws = aws.us-east-1
  }

  function_name                     = "tachyon-${var.bucket_name}"
  description                       = "Lambda@Edge Tachyon for ${var.bucket_name}"
  handler                           = "lambda-handler.handler"
  runtime                           = "nodejs16.x"
  timeout                           = 30
  memory_size                       = 256
  lambda_at_edge                    = true
  publish                           = true
  create_package                    = false
  local_existing_package            = "${path.module}/lambda/tachyon/tachyon-r32.zip"
  cloudwatch_logs_retention_in_days = 30
  attach_policy_jsons               = true
  number_of_policy_jsons            = 1
  policy_jsons                      = [data.aws_iam_policy_document.tachyon_bucket.json]
}
