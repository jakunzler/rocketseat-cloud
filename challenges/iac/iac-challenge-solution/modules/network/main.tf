resource "google_compute_network" "this" {
  name                    = "vpc-app-${var.environment}"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "app" {
  name          = "sn-app-${var.environment}"
  project       = var.project_id
  network       = google_compute_network.this.id
  region        = var.region
  ip_cidr_range = var.subnetwork_cidr

  private_ip_google_access = true

  log_config {
    flow_sampling = 0.1
  }
}

resource "google_compute_router" "this" {
  name    = "rtr-nat-${var.environment}"
  project = var.project_id
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  name    = "nat-${var.environment}"
  project = var.project_id
  region  = var.region
  router  = google_compute_router.this.name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
