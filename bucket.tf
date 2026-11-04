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

  # Without s3:ListBucket, S3 answers a GetObject for a key that does not exist with
  # AccessDenied rather than NoSuchKey, and CloudFront surfaces that to the viewer as 403.
  # A missing object is then indistinguishable from a rejected signature, which makes both
  # undiagnosable: the same status covers "this content is gone" and "this URL is not valid".
  #
  # Granting it does not let anyone enumerate the bucket. CloudFront never issues ListBucket
  # on a viewer's behalf and exposes no listing operation, and the grant stays restricted to
  # the CloudFront service principal for these distributions only. The single effect is that
  # an absent key now returns 404 instead of 403.
  statement {
    sid    = "AllowCloudFrontServicePrincipalDistinguishMissingObjects"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = concat([module.default_cloudfront.cloudfront_distribution_arn], var.bucket_additional_cloudfront_arns)
    }
  }
}

# Bucket content is served only through CloudFront. A public-read object ACL would bypass that: S3
# evaluates ACLs separately from the bucket policy, so such an object is readable straight from
# the S3 endpoint, without a signed URL. ignore_public_acls makes S3 disregard every public ACL, on
# existing objects too. block_public_policy refuses a bucket policy that grants public access, and
# restrict_public_buckets limits a public policy attached outside Terraform to this account. ACL
# grants to specific AWS accounts are not public and still apply until ACLs are disabled.
#
# block_public_acls stays false, and ACLs stay enabled (BucketOwnerPreferred), while uploaders
# still send public-read: with either one S3 rejects those uploads instead of ignoring their ACL.
module "bucket" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  version                  = "5.10.0"
  region                   = var.bucket_region
  bucket                   = var.bucket_name
  attach_policy            = true
  policy                   = data.aws_iam_policy_document.bucket.json
  block_public_acls        = false
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
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
    # Non-current versions are only read to undo an overwrite or deletion. They keep the class they
    # had while current - Intelligent-Tiering, or Standard if overwritten before the day-0 transition
    # ran - and Glacier Instant Retrieval undercuts both. The per-object transition fee only pays off
    # above a size threshold, see bucket_noncurrent_version_transition_min_size. Separate from
    # automatic-cleanup so it still applies when cleanup is disabled.
    {
      id      = "noncurrent-versions"
      enabled = true

      filter = {
        object_size_greater_than = var.bucket_noncurrent_version_transition_min_size
      }

      noncurrent_version_transition = [
        {
          days          = 0
          storage_class = "GLACIER_IR"
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
