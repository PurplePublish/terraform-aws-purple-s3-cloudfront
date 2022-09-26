module "acm" {
  source  = "registry.terraform.io/terraform-aws-modules/acm/aws"
  version = ">= 4.1.0"
  providers = {
    aws = aws.us-east-1
  }

  create_certificate   = var.cloudfront_domain != "" && var.manage_certificate
  domain_name          = var.cloudfront_domain
  zone_id              = var.acm_zone_id
  validate_certificate = true
  wait_for_validation  = true

  tags = {
    Name = try(var.acm_certificate_name, "Certificate ${var.cloudfront_domain}")
  }
}
