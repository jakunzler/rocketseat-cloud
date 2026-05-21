variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "image_uri" {
  type        = string
  description = "URI ECR da imagem (mesma tag validada em dev)."
  default     = "public.ecr.aws/aws-containers/hello-app-runner:1"
}

variable "service_name" {
  type    = string
  default = "ci-cd-challenge-prod"
}

variable "external_api_url" {
  type    = string
  default = "https://httpbin.org/get"
}

variable "cpu" {
  type    = string
  default = "2048"
}

variable "memory" {
  type    = string
  default = "4096"
}
