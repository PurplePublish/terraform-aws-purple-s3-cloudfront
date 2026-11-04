# The Tachyon Lambda@Edge only reads originals and cached derivatives and writes the derivatives
# under resized/ (see purple-ds-hub-tachyon, src/tachyon.js). Its role gets exactly that, so a bug or
# a compromise in the resizer cannot delete or overwrite customer content or change object ACLs.

mock_provider "aws" {
  # The IAM resources validate their policy JSON, which a mocked string is not
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

variables {
  bucket_name = "purple-files-test"
  bucket_arn  = "arn:aws:s3:::purple-files-test"
}

run "tachyon_policy_is_least_privilege" {
  command = plan

  assert {
    # Compared as JSON: the statement list and the literal below differ in type, not in value
    condition = jsonencode([
      for s in data.aws_iam_policy_document.tachyon_bucket.statement : {
        sid       = s.sid
        effect    = s.effect
        actions   = sort(s.actions)
        resources = sort(s.resources)
      }
      ]) == jsonencode([
      {
        sid       = "AllowListBucket"
        effect    = "Allow"
        actions   = ["s3:ListBucket"]
        resources = ["arn:aws:s3:::purple-files-test"]
      },
      {
        sid       = "AllowReadObjects"
        effect    = "Allow"
        actions   = ["s3:GetObject"]
        resources = ["arn:aws:s3:::purple-files-test/*"]
      },
      {
        sid       = "AllowWriteResizedObjects"
        effect    = "Allow"
        actions   = ["s3:PutObject"]
        resources = ["arn:aws:s3:::purple-files-test/resized/*"]
      },
    ])
    error_message = "The Tachyon policy must grant only ListBucket on the bucket, GetObject on its objects and PutObject under resized/."
  }
}
