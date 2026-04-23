resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
  ])

  project = var.project_id
  service = each.key

  disable_on_destroy         = false
  disable_dependent_services = false
}

module "network" {
  source = "../../modules/network"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  subnetwork_cidr = var.subnetwork_cidr

  depends_on = [google_project_service.apis]
}

module "app" {
  source = "../../modules/app"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  name_prefix = "web"

  network_name          = module.network.network_name
  network_id            = module.network.network_id
  subnetwork_self_link  = module.network.subnetwork_self_link
  proxy_subnetwork_cidr = var.proxy_subnetwork_cidr

  machine_type      = var.machine_type
  min_replicas      = var.min_replicas
  max_replicas      = var.max_replicas
  boot_disk_size_gb = var.boot_disk_size_gb

  app_environment  = var.app_environment
  app_secret_id    = var.app_secret_id
  ssh_ingress_cidr = var.ssh_ingress_cidr
  labels           = var.common_labels

  depends_on = [google_project_service.apis, module.network]
}
