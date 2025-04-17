variable "origin_id" {
  type        = string
  description = "The origin ID for the CloudFront distribution"
}

variable "bucket_domain_name" {
  type        = string
  description = "The domain name of the S3 bucket"
}

variable "cdn_price_class" {
  type        = string
  description = "The price class for the CloudFront distribution"
  default     = "PriceClass_200"
}
variable "cdn_tags" {
  type        = map(string)
  description = "Tags to assign to the CloudFront distribution"
  default     = {}
}