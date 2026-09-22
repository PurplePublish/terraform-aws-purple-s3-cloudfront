# Purple Cloudfront Terraform module

This module sets up a S3 bucket and Cloudfront distribution suitable for content distribution with [Purple](https://purplepublish.com).

It optionally supports a custom domain setup for Cloudfront, e.g. cdn.example.com, and configures a suitable certificate using AWS ACM.

## Bucket configuration

* Private
* Access allowed for Cloudfront distribution

## Cloudfront configuration

* Default access using signed URLs
* HTTP viewer requests are redirected to HTTPS (configurable via `cloudfront_viewer_protocol_policy`)
* Following paths are publicly accessible:
    * \*/thumbnails/\*
    * /public/\*

## Migration from manual setup

Add module to Terraform configuration, adjust values to match current names and then execute `terraform plan`.
For each new resource perform `terraform import`. After all existing resources are imported, check `terraform plan`
again for any changes. If everything looks correct, apply changes with `terraform apply`.

If the distribution already serves signed URLs, set `cloudfront_additional_public_key_ids` to the IDs of the
public keys it trusts today before applying. This module always creates its own public key, and CloudFront
verifies a signed URL by looking up the `Key-Pair-Id` it carries among the keys in the key groups attached to
the behavior - so the new key does not stand in for the old one, even when the key material is identical.
Listing the existing IDs keeps URLs signed with them valid across the apply. Whoever issues those URLs can then
be moved to the key this module creates - its ID is the `cloudfront_public_key_id` output - as a separate step,
after which the IDs can be dropped from the list again.

## Required IAM permissions

[`deploy-policy-cdn.json`](deploy-policy-cdn.json) and [`deploy-policy-iam.json`](deploy-policy-iam.json) are
identity policies covering everything this module creates, reads, updates and destroys. Attach both to the principal
that runs `terraform plan` and `terraform apply`. The IAM grants are kept in their own file so they can be reviewed
and bounded separately; see below.

Replace every `BUCKET_NAME` with the value of `bucket_name` before using them. The Lambda functions, their roles and
log groups, the IAM user, its policy and the Parameter Store keys are all named after the bucket, so the policies are
scoped to those exact names. An unedited copy fails closed: `BUCKET_NAME` matches no real resource, and `plan` is
denied rather than granted too much. If `bucket_iam_user_name` is set, use that value in the two `user/` ARNs and the
bucket name everywhere else. Each file stays under the 6,144-character limit for managed policies with any valid
bucket name. Listing several buckets in one copy can exceed it, so use one pair of copies per bucket.

Keep the names exact. A prefix such as `role/purple-web-*` also matches unrelated roles that happen to share it, and
`role/purple-web-BUCKET_NAME*` matches the roles of every bucket whose name starts with this one. Either would let
the principal rewrite those roles' trust and inline policies.

Some grants are easy to get wrong:

* `lambda:EnableReplication` and `lambda:DisableReplication` on the function version are needed by whoever creates
  or updates the *distribution*, because associating a Lambda@Edge function replicates it. Without them the function
  and the distribution both plan cleanly and `CreateDistribution` / `UpdateDistribution` then fails.
* The Lambda functions, log groups, Parameter Store keys and the ACM certificate are always in `us-east-1`, whatever
  `bucket_region` is. A principal fenced with an `aws:RequestedRegion` condition needs `us-east-1` in addition to the
  bucket's region.
* No KMS grant is needed, although every refresh decrypts the `SecureString` signed-cookie key. The key is under the
  AWS-managed `aws/ssm` key, whose key policy already allows its use through Parameter Store to every principal in the
  account.

Some statements stay on `*` or on a wildcard ID. CloudFront distributions, policies, keys and key groups get IDs
generated at creation, so they cannot be named in advance. `acm:RequestCertificate` creates a certificate that has no
ARN yet, and `logs:DescribeLogGroups` and `ssm:DescribeParameters` are account-wide list calls. The Route 53 grant
covers every hosted zone; with a custom domain it can be narrowed to `acm_zone_id`, and without one the ACM and
Route 53 statements can be removed.

`iam:CreateUser`, `iam:CreateAccessKey` and `iam:CreatePolicy` in `deploy-policy-iam.json` remain powerful even when
scoped to the bucket's names: the principal chooses the content of the policy it creates, so it can mint credentials
with any permissions it can write. Attaching is limited to the module's own `s3-` policy, which rules out attaching an
existing managed policy such as `AdministratorAccess`, but not writing an equivalent one. Where that matters,
additionally require a permissions boundary on the created user.

Not covered: `cloudfront_logging_config` with an S3 log bucket additionally needs `s3:GetBucketAcl` and
`s3:PutBucketAcl` on that log bucket. The access key secret and the signed-cookie private key are stored in the
Terraform state in plain text, so the state backend's encryption and access control are part of this module's
security.
