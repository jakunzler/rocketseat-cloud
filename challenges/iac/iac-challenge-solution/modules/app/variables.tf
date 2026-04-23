variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "network_name" {
  description = "Nome da rede VPC (google_compute_network.name)."
  type        = string
}

# ID/self link da VPC (apenas de rede), para a sub-rede proxy-only.
variable "network_id" {
  type = string
}

variable "subnetwork_self_link" {
  type = string
}

variable "proxy_subnetwork_cidr" {
  type        = string
  description = "CIDR exclusivo, sem sobreposição com a sub-rede das VMs (REGIONAL_MANAGED_PROXY)."
}

variable "machine_type" {
  type = string
}

variable "min_replicas" {
  type = number
}

variable "max_replicas" {
  type = number
}

variable "boot_disk_size_gb" {
  type    = number
  default = 20
}

variable "app_environment" {
  type        = map(string)
  description = "Pares chave/valor não sensíveis (metadata + startup)."
  default     = {}
}

variable "app_secret_id" {
  type        = string
  default     = null
  description = "Se preenchido, usa este Secret (nome curto) em vez de criar um."
}

variable "ssh_ingress_cidr" {
  type        = string
  description = "CIDR permitido em TCP/22. Restrinja em produção; veja README para IAP (35.235.240.0/20)."
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "name_prefix" {
  type    = string
  default = "web"
}
