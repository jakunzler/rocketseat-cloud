output "bucket_domain_name" {
  value       = data.aws_s3_bucket.s3_bucket.bucket_domain_name
  description = "The domain name of the bucket"
  sensitive   = false
}

output "bucket_region" {
  value       = data.aws_s3_bucket.s3_bucket.region
  description = "The region of the bucket"
  sensitive   = false
}