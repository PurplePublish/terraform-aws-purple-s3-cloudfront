# Purple Cloudfront Terraform module

This module sets up a S3 bucket and Cloudfront distribution suitable for content distribution with [Purple](https://purplepublish.com).

It optionally supports a custom domain setup for Cloudfront, e.g. cdn.example.com, and configures a suitable certificate using AWS ACM.

## Bucket configuration

* Private
* Access allowed for Cloudfront distribution

## Cloudfront configuration

* Default access using signed URLs
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
