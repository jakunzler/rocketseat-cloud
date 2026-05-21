output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.app.name
}

output "service_arn" {
  value = aws_apprunner_service.app.arn
}

output "service_id" {
  value = aws_apprunner_service.app.id
}

output "service_url" {
  value = "https://${aws_apprunner_service.app.service_url}"
}

output "apprunner_access_role_arn" {
  value = aws_iam_role.apprunner_access.arn
}
