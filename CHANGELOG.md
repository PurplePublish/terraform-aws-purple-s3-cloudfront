# Changelog

All notable changes to `terraform-aws-purple-s3-cloudfront` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Entries are derived from the Git tags of this repository.

> Note: releases up to `v0.0.39` were tagged with a `v` prefix; from `0.0.40`
> onward the prefix was dropped.

## [0.1.10] - 2026-08-21
### Changed
- Keep the attribution query parameters `appId` and `platform` out of the CloudFront cache key and out of the
  origin request policy. They exist only to attribute traffic in access-log analysis: neither changes the object
  returned - the request path is the S3 key - and CloudFront records the query string verbatim in the access log
  whether or not it is part of the cache key. Keying on them split the cache across values that all resolve to
  the same object, which cost hit rate on exactly the small, frequently requested objects where it matters most.
  The exclusion is unconditional and no longer tied to `cloudfront_exclude_tracking_params`, which now covers
  only third-party click-tracking parameters. As a result `query_string_behavior` is always `allExcept`, where
  it was `all` for callers that left that variable at its default. Parameters that do change the response -
  `response-content-disposition` and the Tachyon image parameters `w`/`h`/`webp`/`quality`/`crop` - stay in the
  cache key. **Applying this updates the cache and origin request policies in place - their ids do not change,
  so attached distributions are not replaced - and triggers a CloudFront distribution deployment; cached objects
  are re-keyed, so expect a brief dip in hit rate before it settles above the previous level.**

## [0.1.9] - 2026-08-10
### Changed
- Raise the default Tachyon memory from 512 MB to 2048 MB, and expose it as `tachyon_memory_size`.
  512 MB is not enough for larger source images: decoding an original into a bitmap needs far more memory than
  the encoded file size suggests, and on exceeding its allocation Lambda kills the function rather than letting
  it return an error. Because Tachyon runs as an origin-request Lambda@Edge, CloudFront has by then accepted
  the viewer connection and has nothing to send, so callers see a connected but silent socket until the 30s
  timeout expires rather than a failure they can act on.
  Lambda CPU scales with memory, so this also cuts resize duration; for CPU-bound work the billed GB-ms should
  stay roughly flat. **Applying this republishes the Lambda@Edge version and triggers a CloudFront
  distribution deployment, which takes a few minutes to propagate.**

## [0.1.8] - 2026-08-06
### Changed
- Grant the CloudFront service principal `s3:ListBucket` on the bucket, so a request for an
  object that does not exist returns `404` instead of `403`. Previously a missing object and a
  rejected signature were indistinguishable to both viewers and log analysis.

## [0.1.7] - 2026-03-05
### Fixed
- Correct default value for `cloudfront_logging_config`.
- Correct default values for `viewer_certificate`.

## [0.1.6] - 2026-03-05
### Fixed
- Use the correct region for `cookies_private_key`.

## [0.1.5] - 2026-03-05
### Changed
- Reverted "Re-add configuration_aliases for migrations" (0.1.1) and "Re-add providers for migrations" (0.1.2).

## [0.1.4] - 2026-03-05
### Changed
- Disable `origin_access_control`.

## [0.1.3] - 2026-03-05
### Fixed
- Fix origin custom headers.

## [0.1.2] - 2026-03-05
### Added
- Re-add providers to support migrations.

## [0.1.1] - 2026-03-05
### Added
- Re-add `configuration_aliases` to support migrations.

## [0.1.0] - 2026-03-05
### Changed
- Switch to the `region` parameter for the AWS provider (aligns with newer AWS provider configuration).

## [0.0.61] - 2026-02-23
### Added
- New `cloudfront_distribution_arn` output.

## [0.0.60] - 2025-10-02
### Changed
- Make CloudFront tracking-parameter exclusion optional.

## [0.0.59] - 2025-10-02
### Added
- Add CloudFront cache and origin request policy.

## [0.0.58] - 2025-08-22
### Changed
- Update Lambda runtime to Node.js 22.x (#1).

## [0.0.57] - 2025-04-23
### Changed
- Update modules and providers.

## [0.0.56] - 2025-03-12
### Added
- Add thumbnails path from root.

## [0.0.55] - 2025-02-20
### Added
- New `s3_access_policy_arn` output.

## [0.0.54] - 2025-02-20
### Fixed
- Fix newlines problem.

## [0.0.53] - 2025-02-20
### Fixed
- Attempt to fix newlines problem.

## [0.0.52] - 2025-02-18
### Fixed
- Fix `bucket_prefix` variable.

## [0.0.51] - 2025-02-18
### Added
- New `bucket_prefix` variable.

## [0.0.50] - 2025-01-31
### Added
- Add cleanup of deletion markers to the lifecycle policy.

## [0.0.49] - 2025-01-31
### Added
- Add automatic cleanup lifecycle policy.

## [0.0.48] - 2025-01-06
### Changed
- Upgrade Tachyon.

## [0.0.47] - 2025-01-06
### Changed
- Upgrade Tachyon.

## [0.0.46] - 2024-11-04
### Changed
- Upgrade Tachyon.

## [0.0.45] - 2024-10-17
### Added
- Add support for `logging_config`.

## [0.0.44] - 2024-09-23
### Added
- Add support for new web paths.

## [0.0.43] - 2024-07-02
### Changed
- Pin module versions and update parameters.

## [0.0.42] - 2024-02-23
### Added
- Enable `INTELLIGENT_TIERING` lifecycle rule.

## [0.0.41] - 2023-12-14
### Changed
- Update bucket object ownership configuration.

## [0.0.40] - 2023-08-04
### Changed
- Adjust CORS policy.

## [v0.0.39] - 2023-04-27
### Fixed
- Fix defaults for the bucket.

## [v0.0.38] - 2023-03-20
### Added
- Add variable for public web access.

## [v0.0.37] - 2023-03-20
### Changed
- Extract CloudFront and Lambdas into separate sub-modules.
- Reverted "Allow public access to web resources" (0.0.36).

## [v0.0.36] - 2023-03-18
### Changed
- Allow public access to web resources.

## [v0.0.35] - 2023-03-17
### Changed
- Set CloudFront cookie `SameSite` to `None`.

## [v0.0.34] - 2023-03-17
### Fixed
- Fix CORS configuration for CloudFront.

## [v0.0.33] - 2023-03-02
### Added
- Add public TTS path.

## [v0.0.31] - [v0.0.32] - 2023-02-21
### Changed
- Switch to a prepackaged Lambda source.

## [v0.0.26] - [v0.0.30] - 2023-02-20
### Added
- Add Lambda for adding signed cookies (v0.0.26), with subsequent Lambda configuration updates.

## [v0.0.25] - 2023-02-18
### Changed
- Revert "Add additional behaviours for web access" (v0.0.23 / v0.0.24).

## [v0.0.23] - [v0.0.24] - 2023-02-16
### Added
- Add additional behaviours for web access.

## [v0.0.22] - 2022-10-27
### Changed
- Disable HTTP/3 (QUIC) due to issues with Apple iOS clients.
- Add IntelliJ IDEA configuration folder to `.gitignore`.

## [v0.0.21] - 2022-10-13
### Added
- Add permissions to use Polly.

## [v0.0.20] - 2022-10-13
### Changed
- Adjust default comment for CloudFront.

## [v0.0.19] - 2022-10-13
### Fixed
- Fix IAM user default naming.

## [v0.0.18] - 2022-10-13
### Changed
- Disable Brotli compression.

## [v0.0.17] - 2022-09-28
### Removed
- Remove empty `security_headers_config` block.

## [v0.0.16] - 2022-09-27
### Changed
- Enable compression in the CloudFront configuration.

## [v0.0.15] - 2022-09-27
### Changed
- Change CloudFront policy names.

## [v0.0.14] - 2022-09-27
### Changed
- Switch to Origin Access Control policy for the S3 origin.

## [v0.0.13] - 2022-09-27
### Changed
- Switch to the regional domain name for the S3 bucket origin.

## [v0.0.12] - 2022-09-27
### Changed
- Create the new signing key before destroying the old one.

## [v0.0.11] - 2022-09-27
### Changed
- Adjust the names of the public key and key group.

## [v0.0.9] - [v0.0.10] - 2022-09-27
### Changed
- Switch to using a public key in a key group for CloudFront signing.

## [v0.0.8] - 2022-09-26
### Added
- Add configurable CORS response policy.

## [v0.0.7] - 2022-09-26
### Changed
- Update minimum requirement for the AWS provider.

## [v0.0.6] - 2022-09-26
### Changed
- Change source of the ACM module.

## [v0.0.5] - 2022-09-26
### Fixed
- Fix optional CloudFront domain.

## [v0.0.4] - 2022-09-23
### Changed
- Publish new versions of the Lambda.

## [v0.0.3] - 2022-09-23
### Fixed
- Fix Tachyon permissions for the bucket and Cloudflare caching policy.

## [v0.0.2] - 2022-09-23
### Changed
- Update README.

## [v0.0.1] - 2022-09-23
### Added
- Initial version.
