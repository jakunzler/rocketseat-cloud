variable "project_name" {
  type        = string
  description = "Prefixo de nomenclatura (ex.: ci-cd-challenge)."
  default     = "ci-cd-challenge"
}

variable "environment" {
  type        = string
  description = "Ambiente lógico: dev ou prod."
}

variable "service_name" {
  type        = string
  description = "Nome do serviço App Runner (único por região/conta)."
}

variable "image_uri" {
  type        = string
  description = "URI completa da imagem ECR (tag aplicada pela pipeline)."
}

variable "port" {
  type    = number
  default = 3000
}

variable "cpu" {
  type    = string
  default = "1024"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "runtime_environment_variables" {
  type        = map(string)
  description = "Variáveis de ambiente não sensíveis no runtime."
  default     = {}
}

variable "runtime_environment_secrets" {
  type        = map(string)
  description = "Mapa nome => ARN (Secrets Manager ou SSM). Opcional."
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
