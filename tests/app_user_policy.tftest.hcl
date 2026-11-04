# The app user policy grants what the Purple apps use and no more. Polly is limited to the two calls
# the text-to-speech path makes, since polly:* would also allow the account-wide lexicon changes,
# and a client may abort its own multipart uploads.

mock_provider "aws" {
  # The IAM resources validate their policy JSON, which a mocked string is not
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }

  # Applying attaches the policy by ARN, which the provider validates
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/s3-purple-files-test"
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

run "app_user_policy_grants_only_the_calls_the_apps_make" {
  command = apply

  assert {
    condition = toset(flatten([
      for s in jsondecode(aws_iam_policy.bucket.policy).Statement : s.Action if length([for a in s.Action : a if startswith(a, "polly:")]) > 0
    ])) == toset(["polly:StartSpeechSynthesisTask", "polly:GetSpeechSynthesisTask"])
    error_message = "The Polly statement must hold exactly StartSpeechSynthesisTask and GetSpeechSynthesisTask"
  }

  assert {
    condition     = length([for s in jsondecode(aws_iam_policy.bucket.policy).Statement : s if contains(s.Action, "s3:AbortMultipartUpload") && endswith(s.Resource, "/*")]) == 1
    error_message = "s3:AbortMultipartUpload must be granted on the objects of the bucket"
  }

  assert {
    condition     = length([for s in jsondecode(aws_iam_policy.bucket.policy).Statement : s if contains(s.Action, "polly:*") || contains(s.Action, "s3:*")]) == 0
    error_message = "The policy must not use wildcard actions"
  }
}
