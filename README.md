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
