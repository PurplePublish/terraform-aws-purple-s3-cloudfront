module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = ">= 3.4.0"
  providers = {
    aws = aws.bucket-region
  }

  bucket        = var.bucket_name
  attach_policy = true
  policy        = <<JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipalReadOnly",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "${module.cloudfront.cloudfront_distribution_arn}"
                }
            }
        }
    ]
}
JSON
  cors_rule = [{
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 0
  }]

  versioning = {
    enabled = true
  }
}
