output "cdn_id" {
  value       = data.aws_cloudfront_distribution.cloudfront.id
  sensitive   = false
  description = "This is the CloudFront distribution ID"
}

output "cdn_domain_name" {
  value       = data.aws_cloudfront_distribution.cloudfront.domain_name
  sensitive   = false
  description = "This is the CloudFront distribution domain name"
}
