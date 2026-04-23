variable "project_id" {
  type        = string
  description = "ID do projeto GCP (ex.: meu-projeto-123)."
}

variable "region" {
  type        = string
  description = "Região (ex.: southamerica-east1)."
}

variable "environment" {
  type = string
}

variable "subnetwork_cidr" {
  type        = string
  description = "CIDR da sub-rede privada (região) onde rodam as VMs."
}
