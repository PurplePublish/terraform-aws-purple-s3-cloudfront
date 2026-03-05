module "lambdas" {
  source      = "./modules/lambdas"
  bucket_name = var.bucket_name
  bucket_arn  = module.bucket.s3_bucket_arn
}
