module "lambdas" {
  source      = "./modules/lambdas"
  providers = {
    aws.us-east-1 = aws
  }
  bucket_name = var.bucket_name
  bucket_arn  = module.bucket.s3_bucket_arn
}
