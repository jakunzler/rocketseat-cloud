module "s3" {
  source         = "./modules/s3"
  s3_bucket_name = "rocketseat-cloud-module"
  s3_tags = {
    IAC         = true
    Name        = "s3"
    Environment = "production"
  }
}

module "cloudfront" {
  source             = "./modules/cloudfront"
  origin_id          = module.s3.bucket_id
  bucket_domain_name = module.s3.bucket_domain_name
  cdn_price_class    = "PriceClass_200"
  cdn_tags = {
    IAC         = true
    Name        = "cloudfront"
    Environment = "production"
  }
  depends_on = [module.s3]
}

# module "sqs" {
#   source = "terraform-aws-modules/sqs/aws"
#   name   = "example"
#   create_dlq = true
#   tags = {
#     IAC         = true
#   }
# }