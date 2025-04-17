output "bucket_domain_name" {
  value       = data.aws_s3_bucket.bucket.bucket_domain_name
  description = ""
  sensitive   = false
}

output "bucket_id" {
  value       = data.aws_s3_bucket.bucket.id
  description = "The ID of the S3 bucket"
  sensitive   = false
}