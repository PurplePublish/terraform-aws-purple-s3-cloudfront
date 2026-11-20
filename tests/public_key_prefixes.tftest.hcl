# public_key_prefixes lists key prefixes whose objects are public: the module's distribution serves
# them without a signed URL, and every CloudFront distribution of the bucket's account may read them
# through origin access control. Other distributions of the account - for example one that serves a
# website on its own domain - can then deliver these objects too, without their ARNs being known here.
#
# The unsigned path patterns are read from the cloudfront_unsigned_path_patterns output, since the
# behaviours of the child module are not addressable in a test. The bucket policy statements are read
# from the policy document's arguments, which are known at plan time even though its JSON is mocked.

mock_provider "aws" {
  # The IAM resources validate their policy JSON, which a mocked string is not
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
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

run "no_public_key_prefixes_by_default" {
  command = plan

  assert {
    condition = output.cloudfront_unsigned_path_patterns == [
      "public/*",
      "tts/*",
      "*/thumbnails/*",
      "thumbnails/*",
    ]
    error_message = "Without public_key_prefixes the unsigned path patterns must stay as before"
  }

  assert {
    condition     = length([for s in data.aws_iam_policy_document.bucket.statement : s if s.sid == "AllowAccountCloudFrontReadPublicKeys"]) == 0
    error_message = "Without public_key_prefixes no distribution other than the module's own may read the bucket"
  }
}

run "public_key_prefixes_are_served_unsigned" {
  command = plan

  variables {
    public_key_prefixes = ["team-1/public/"]
    # Lists the web package paths among the unsigned ones, so their order can be asserted
    cloudfront_public_web = true
  }

  assert {
    condition     = contains(output.cloudfront_unsigned_path_patterns, "team-1/public/*")
    error_message = "A public key prefix must be served without a signed URL"
  }

  assert {
    # The first matching behaviour wins, so a public object must not fall under a signed one first
    condition     = index(output.cloudfront_unsigned_path_patterns, "team-1/public/*") < index(output.cloudfront_unsigned_path_patterns, "*.pkar/web/*")
    error_message = "A public key prefix must come before the web package paths"
  }
}

run "duplicate_and_built_in_public_key_prefixes_get_one_behaviour" {
  command = plan

  variables {
    public_key_prefixes = ["team-1/public/", "team-1/public/", "public/"]
  }

  assert {
    condition = output.cloudfront_unsigned_path_patterns == [
      "public/*",
      "tts/*",
      "team-1/public/*",
      "*/thumbnails/*",
      "thumbnails/*",
    ]
    error_message = "CloudFront rejects two behaviours with the same path pattern"
  }
}

run "public_key_prefixes_under_a_built_in_public_behaviour_get_no_behaviour_but_the_grant" {
  command = plan

  variables {
    public_key_prefixes = ["public/assets/team-1/", "tts/team-1/"]
  }

  assert {
    # public/* and tts/* come first and already serve them unsigned
    condition = output.cloudfront_unsigned_path_patterns == [
      "public/*",
      "tts/*",
      "*/thumbnails/*",
      "thumbnails/*",
    ]
    error_message = "A prefix a built-in public behaviour serves must not use up another behaviour"
  }

  assert {
    condition = one([for s in data.aws_iam_policy_document.bucket.statement : s if s.sid == "AllowAccountCloudFrontReadPublicKeys"]).resources == toset([
      "arn:aws:s3:::purple-files-test/public/assets/team-1/*",
      "arn:aws:s3:::purple-files-test/resized/public/assets/team-1/*",
      "arn:aws:s3:::purple-files-test/tts/team-1/*",
      "arn:aws:s3:::purple-files-test/resized/tts/team-1/*",
    ])
    error_message = "Prefixes without a behaviour of their own are still granted to the account's distributions"
  }
}

run "public_key_prefix_equal_to_a_built_in_pattern_with_bucket_prefix_gets_one_behaviour" {
  command = plan

  variables {
    bucket_prefix       = "x/"
    public_key_prefixes = ["x/public/", "public/", "x/public/assets/team-1/"]
  }

  assert {
    condition = output.cloudfront_unsigned_path_patterns == [
      "x/public/*",
      "x/tts/*",
      "public/*",
      "*/thumbnails/*",
      "thumbnails/*",
    ]
    error_message = "Only prefixes a built-in pattern serves, bucket_prefix included, are skipped"
  }
}

run "parent_segment_in_public_key_prefix_is_rejected" {
  command = plan

  variables {
    public_key_prefixes = ["team-1/../"]
  }

  expect_failures = [var.public_key_prefixes]
}

run "current_segment_in_public_key_prefix_is_rejected" {
  command = plan

  variables {
    public_key_prefixes = ["team-1/./"]
  }

  expect_failures = [var.public_key_prefixes]
}

run "public_key_prefix_longer_than_a_path_pattern_allows_is_rejected" {
  command = plan

  variables {
    public_key_prefixes = ["${join("", [for i in range(254) : "a"])}/"]
  }

  expect_failures = [var.public_key_prefixes]
}

run "empty_segment_in_public_key_prefix_is_rejected" {
  command = plan

  variables {
    public_key_prefixes = ["team-1//"]
  }

  expect_failures = [var.public_key_prefixes]
}

run "resized_public_key_prefix_is_rejected" {
  command = plan

  variables {
    public_key_prefixes = ["resized/"]
  }

  expect_failures = [var.public_key_prefixes]
}

run "public_key_prefix_with_characters_cloudfront_rejects_is_rejected" {
  command = plan

  variables {
    public_key_prefixes = ["team 1/public/"]
  }

  expect_failures = [var.public_key_prefixes]
}

run "public_key_prefixes_are_readable_by_distributions_of_the_account" {
  command = plan

  variables {
    public_key_prefixes = ["public/assets/team-1/"]
  }

  assert {
    condition = one([for s in data.aws_iam_policy_document.bucket.statement : s if s.sid == "AllowAccountCloudFrontReadPublicKeys"]).resources == toset([
      "arn:aws:s3:::purple-files-test/public/assets/team-1/*",
      "arn:aws:s3:::purple-files-test/resized/public/assets/team-1/*",
    ])
    error_message = "The grant must cover the public objects and their resized copies, and nothing else"
  }

  assert {
    # A listing grant would let a distribution outside the module serve the keys of the whole bucket
    condition = alltrue([
      for s in data.aws_iam_policy_document.bucket.statement : !contains(s.actions, "s3:ListBucket")
      if contains(flatten([for c in s.condition : c.variable]), "AWS:SourceAccount")
    ])
    error_message = "The distributions of the account must not get s3:ListBucket"
  }

  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.bucket.statement : s.actions == toset(["s3:GetObject"])
      if s.sid == "AllowAccountCloudFrontReadPublicKeys"
    ])
    error_message = "Other distributions may only read objects"
  }

  assert {
    condition = alltrue(flatten([
      for s in data.aws_iam_policy_document.bucket.statement : [
        for c in s.condition : c.test == "StringEquals" && c.variable == "AWS:SourceAccount" && c.values == tolist(["123456789012"])
      ] if s.sid == "AllowAccountCloudFrontReadPublicKeys"
    ]))
    error_message = "The grant must be bound to the exact account of the bucket, so S3 does not treat the policy as public"
  }
}

run "wildcard_public_key_prefix_is_rejected" {
  command = plan

  variables {
    public_key_prefixes = ["*/public/"]
  }

  expect_failures = [var.public_key_prefixes]
}

run "public_key_prefix_without_trailing_slash_is_rejected" {
  command = plan

  variables {
    public_key_prefixes = ["team-1/public"]
  }

  expect_failures = [var.public_key_prefixes]
}

run "public_key_prefix_with_leading_slash_is_rejected" {
  command = plan

  variables {
    public_key_prefixes = ["/team-1/public/"]
  }

  expect_failures = [var.public_key_prefixes]
}
