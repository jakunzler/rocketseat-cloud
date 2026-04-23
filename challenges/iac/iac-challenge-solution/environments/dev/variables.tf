variable "project_id" {
  type        = string
  description = "ID do projeto no GCP. Defina no terraform.tfvars ou com TF_VAR_project_id."
}

variable "region" {
  type    = string
  default = "southamerica-east1"
}

variable "zone" {
  type    = string
  default = "southamerica-east1-a"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "subnetwork_cidr" {
  type    = string
  default = "10.0.0.0/20"
}

variable "proxy_subnetwork_cidr" {
  type        = string
  default     = "10.0.16.0/24"
  description = "CIDR só para o load balancer (REGIONAL_MANAGED_PROXY); não sobrepor à sub-rede de VMs."
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "min_replicas" {
  type    = number
  default = 1
}

variable "max_replicas" {
  type    = number
  default = 2
}

variable "boot_disk_size_gb" {
  type    = number
  default = 20
}

variable "app_environment" {
  type = map(string)
  default = {
    LOG_LEVEL   = "debug"
    APP_PROFILE = "development"
  }
  description = "Pares chave/valor não sensíveis (startup script + metadata)."
}

variable "app_secret_id" {
  type        = string
  default     = null
  description = "Nome curto de um segredo existente; se nulo, o módulo cria um."
}

variable "ssh_ingress_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Origem do SSH. Restrinja em produção; IAP usa 35.235.240.0/20."
}

variable "common_labels" {
  type    = map(string)
  default = { project = "iac-challenge" }
}
