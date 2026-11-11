# Additional distributions are allowed to read the bucket through its policy. S3 treats a policy
# whose AWS:SourceArn holds a wildcard or a policy variable as public, and the bucket's public access
# block refuses it once bucket_block_public_access is on, so only exact distribution ARNs are accepted
# whatever the switch says.

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
}

run "wildcard_cloudfront_arn_is_rejected" {
  command = plan

  variables {
    bucket_additional_cloudfront_arns = ["arn:aws:cloudfront::123456789012:distribution/*"]
  }

  expect_failures = [var.bucket_additional_cloudfront_arns]
}

run "single_character_wildcard_cloudfront_arn_is_rejected" {
  command = plan

  variables {
    bucket_additional_cloudfront_arns = ["arn:aws:cloudfront::123456789012:distribution/E2ABCDEF?"]
  }

  expect_failures = [var.bucket_additional_cloudfront_arns]
}

run "policy_variable_cloudfront_arn_is_rejected" {
  command = plan

  variables {
    bucket_additional_cloudfront_arns = ["arn:aws:cloudfront::123456789012:distribution/$${aws:username}"]
  }

  expect_failures = [var.bucket_additional_cloudfront_arns]
}

run "exact_cloudfront_arn_is_accepted" {
  command = plan

  variables {
    bucket_additional_cloudfront_arns = ["arn:aws:cloudfront::123456789012:distribution/E2ABCDEF123456"]
  }
}

run "distribution_id_instead_of_arn_is_rejected" {
  command = plan

  variables {
    bucket_additional_cloudfront_arns = ["E2ABCDEF123456"]
  }

  expect_failures = [var.bucket_additional_cloudfront_arns]
}

run "null_cloudfront_arns_fall_back_to_none" {
  command = plan

  variables {
    bucket_additional_cloudfront_arns = null
  }
}
