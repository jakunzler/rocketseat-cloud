variable "s3_bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}

variable "s3_tags" {
  type        = map(string)
  description = "Tags to assign to the CloudFront distribution"
  default     = {}
}