data "aws_iam_policy_document" "bucket" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = concat([module.default_cloudfront.cloudfront_distribution_arn], var.bucket_additional_cloudfront_arns)
    }
  }
}

module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.7.0"
  providers = {
    aws = aws.bucket-region
  }

  bucket                   = var.bucket_name
  attach_policy            = true
  policy                   = data.aws_iam_policy_document.bucket.json
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  cors_rule = [{
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 0
  }]
  lifecycle_rule = [
    {
      id      = "intelligent-tiering"
      enabled = true

      transition = [
        {
          days          = 0
          storage_class = "INTELLIGENT_TIERING"
        }
      ]
    },
    {
      id                                     = "automatic-cleanup"
      enabled                                = var.bucket_automatic_cleanup_enabled
      abort_incomplete_multipart_upload_days = var.bucket_automatic_cleanup_multipart_upload_days
      expiration = {
        expired_object_delete_marker = true
      }
      noncurrent_version_expiration = {
        days = var.bucket_automatic_cleanup_days
      }
    }
  ]

  versioning = {
    enabled = true
  }
}
