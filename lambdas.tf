module "lambdas" {
  source = "./modules/lambdas"
  providers = {
    aws.us-east-1 = aws.us-east-1
  }

  bucket_name = var.bucket_name
  bucket_arn  = module.bucket.s3_bucket_arn
}
