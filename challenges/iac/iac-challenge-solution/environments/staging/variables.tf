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
  default = "staging"
}

variable "subnetwork_cidr" {
  type    = string
  default = "10.1.0.0/20"
}

variable "proxy_subnetwork_cidr" {
  type    = string
  default = "10.1.16.0/24"
}

variable "machine_type" {
  type    = string
  default = "e2-small"
}

variable "min_replicas" {
  type    = number
  default = 1
}

variable "max_replicas" {
  type    = number
  default = 4
}

variable "boot_disk_size_gb" {
  type    = number
  default = 20
}

variable "app_environment" {
  type = map(string)
  default = {
    LOG_LEVEL   = "info"
    APP_PROFILE = "staging"
  }
}

variable "app_secret_id" {
  type    = string
  default = null
}

variable "ssh_ingress_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "common_labels" {
  type    = map(string)
  default = { project = "iac-challenge" }
}
