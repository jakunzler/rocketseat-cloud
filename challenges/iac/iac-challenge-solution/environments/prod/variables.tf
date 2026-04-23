variable "project_id" {
  type = string
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
  default = "prod"
}

variable "subnetwork_cidr" {
  type    = string
  default = "10.2.0.0/20"
}

variable "proxy_subnetwork_cidr" {
  type    = string
  default = "10.2.16.0/24"
}

variable "machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "min_replicas" {
  type    = number
  default = 2
}

variable "max_replicas" {
  type    = number
  default = 6
}

variable "boot_disk_size_gb" {
  type    = number
  default = 30
}

variable "app_environment" {
  type = map(string)
  default = {
    LOG_LEVEL   = "warn"
    APP_PROFILE = "production"
  }
}

variable "app_secret_id" {
  type    = string
  default = null
}

variable "ssh_ingress_cidr" {
  type        = string
  default     = "10.255.255.0/32"
  description = "Ajuste para o CIDR de bastion/escritório ou use IAP (35.235.240.0/20) antes do apply em produção."
}

variable "common_labels" {
  type    = map(string)
  default = { project = "iac-challenge" }
}
