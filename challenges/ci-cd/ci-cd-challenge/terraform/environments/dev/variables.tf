variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "image_uri" {
  type        = string
  description = "URI ECR da imagem (preenchida pela pipeline). Bootstrap: imagem publica de exemplo."
  default     = "public.ecr.aws/aws-containers/hello-app-runner:1"
}

variable "service_name" {
  type    = string
  default = "ci-cd-challenge-dev"
}

variable "external_api_url" {
  type        = string
  default     = "https://httpbin.org/get"
  description = "Exemplo de URL externa (variavel nao sensivel)."
}

variable "cpu" {
  type    = string
  default = "1024"
}

variable "memory" {
  type    = string
  default = "2048"
}
