# The bucket's S3 Block Public Access settings are switched together by bucket_block_public_access.
# On (the default) is the lock-down introduced in 0.4.0. Off is what the module did before 0.4.0:
# public object ACLs are honoured, which buckets whose uploaders still send public-read need.
# block_public_acls stays false either way, because with it S3 rejects a public-read upload instead
# of ignoring it.
#
# The flags are read from the s3_bucket_public_access_block output, which is built from the same
# local that module "bucket" is configured with: resources inside a child module are not addressable
# in a test, so the plan of the bucket itself cannot be asserted on.

mock_provider "aws" {
  # The IAM resources validate their policy JSON, which a mocked string is not
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

# The Lambda@Edge function is not part of what is asserted here
override_module {
  target = module.lambdas
  outputs = {
    tachyon_qualified_arn = "arn:aws:lambda:us-east-1:123456789012:function:tachyon:1"
  }
}

variables {
  bucket_name = "purple-files-test"
}

run "public_access_is_blocked_by_default" {
  command = plan

  assert {
    condition = alltrue([
      !output.s3_bucket_public_access_block.block_public_acls,
      output.s3_bucket_public_access_block.block_public_policy,
      output.s3_bucket_public_access_block.ignore_public_acls,
      output.s3_bucket_public_access_block.restrict_public_buckets,
    ])
    error_message = "block_public_policy, ignore_public_acls and restrict_public_buckets must be true and block_public_acls false by default"
  }
}

run "public_access_is_not_blocked_when_switched_off" {
  command = plan

  variables {
    bucket_block_public_access = false
  }

  assert {
    condition = alltrue([
      !output.s3_bucket_public_access_block.block_public_acls,
      !output.s3_bucket_public_access_block.block_public_policy,
      !output.s3_bucket_public_access_block.ignore_public_acls,
      !output.s3_bucket_public_access_block.restrict_public_buckets,
    ])
    error_message = "All four Block Public Access flags must be false when bucket_block_public_access is false"
  }
}
