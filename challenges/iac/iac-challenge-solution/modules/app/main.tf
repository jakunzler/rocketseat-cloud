data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

locals {
  app_tag   = replace("${var.name_prefix}-${var.environment}", ".", "-")
  secret_id = var.app_secret_id != null ? var.app_secret_id : google_secret_manager_secret.app[0].secret_id
}

# Segredo: container criado no Secret Manager; valor real fora do Terraform.
resource "google_secret_manager_secret" "app" {
  count     = var.app_secret_id == null ? 1 : 0
  secret_id = "${var.name_prefix}-credentials-${var.environment}"
  project   = var.project_id
  labels    = merge(var.labels, { environment = var.environment })

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "placeholder" {
  count  = var.app_secret_id == null ? 1 : 0
  secret = google_secret_manager_secret.app[0].id
  # Valor inofensivo: substitua no Console/gcloud. ignore_changes evita overwrite em re-applies.
  secret_data = jsonencode({ note = "Defina o valor fora do Terraform (gcloud, Console ou pipeline)." })

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_service_account" "app" {
  # account_id: 6–30 [a-z0-9-], único por projeto; sem truncar a meio de palavra
  account_id   = "sa-w-${var.environment}"
  display_name = "SA app ${var.name_prefix} ${var.environment}"
  project      = var.project_id
}

resource "google_secret_manager_secret_iam_member" "app_accessor" {
  project   = var.project_id
  secret_id = local.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app.email}"
}

# No mesmo módulo que a forwarding rule: garante criação antes do L7 e dependência explícita.
# (No outro módulo, a API podia tratar a regra antes de a sub-rede “ativa” existir no fluxo de apply.)
resource "google_compute_subnetwork" "proxy_only" {
  name          = "sn-proxy-lb-${var.environment}"
  project       = var.project_id
  region        = var.region
  network       = var.network_id
  ip_cidr_range = var.proxy_subnetwork_cidr
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Health checks (ranges oficiais do balanceador e probes).
resource "google_compute_firewall" "lb_and_health" {
  name    = "fw-${var.name_prefix}-hc-${var.environment}"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]

  target_tags = [local.app_tag]
  direction   = "INGRESS"
  priority    = 1000
  description = "HTTP do balanceador (probes) e fontes conhecidas do GCP L7"
}

resource "google_compute_firewall" "ssh" {
  name    = "fw-${var.name_prefix}-ssh-${var.environment}"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_ingress_cidr]
  target_tags   = [local.app_tag]
  priority      = 1000
  description   = "SSH. Prefira acesso via IAP e restringir este CIDR em produção."
}

resource "google_compute_instance_template" "app" {
  name_prefix  = "tpl-${var.name_prefix}-${var.environment}-"
  machine_type = var.machine_type
  project      = var.project_id

  labels = merge(var.labels, { environment = var.environment })

  disk {
    source_image = data.google_compute_image.debian.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = var.boot_disk_size_gb
    disk_type    = "pd-balanced"
  }

  network_interface {
    subnetwork         = var.subnetwork_self_link
    subnetwork_project = var.project_id
  }

  service_account {
    email  = google_service_account.app.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = [local.app_tag]

  metadata = merge(
    {
      app_env_json  = jsonencode(var.app_environment)
      secret_id_ref = var.app_secret_id != null ? var.app_secret_id : "${var.name_prefix}-credentials-${var.environment}"
    },
    { enable-osconfig = "TRUE" }
  )

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euo pipefail
    export SECRET_ID="${local.secret_id}"
    ${join("\n    ", [for k, v in var.app_environment : "export ${k}=\"${replace(v, "\"", "\\\"")}\""])}
    export ENVIRONMENT="${var.environment}"
    apt-get update -y
    apt-get install -y nginx
    systemctl enable --now nginx
    echo "<h1>${var.name_prefix} / ${var.environment}</h1><p>OK (GCP + nginx)</p>" > /var/www/html/index.html
  EOT

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "app" {
  name    = "rgm-${var.name_prefix}-${var.environment}"
  region  = var.region
  project = var.project_id

  base_instance_name = "vm-${var.name_prefix}-${var.environment}"
  version {
    name              = "primary"
    instance_template = google_compute_instance_template.app.id
  }

  target_size = var.min_replicas

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_region_health_check.app.id
    initial_delay_sec = 300
  }

  update_policy {
    type                  = "PROACTIVE"
    replacement_method    = "SUBSTITUTE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 3
    max_unavailable_fixed = 0
  }
}

# Escalonamento: recurso separado (regional MIG não usa o bloco autoscaling do template zonal)
resource "google_compute_region_autoscaler" "app" {
  name    = "ras-${var.name_prefix}-${var.environment}"
  region  = var.region
  project = var.project_id
  target  = google_compute_region_instance_group_manager.app.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 60

    cpu_utilization {
      target = 0.65
    }
  }
}

resource "google_compute_region_health_check" "app" {
  name    = "hc-${var.name_prefix}-${var.environment}"
  region  = var.region
  project = var.project_id

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_region_backend_service" "app" {
  name    = "bes-${var.name_prefix}-${var.environment}"
  region  = var.region
  project = var.project_id

  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  port_name             = "http"

  health_checks = [google_compute_region_health_check.app.id]

  backend {
    group           = google_compute_region_instance_group_manager.app.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
    max_utilization = 0.8
  }
}

resource "google_compute_region_url_map" "app" {
  name    = "um-${var.name_prefix}-${var.environment}"
  region  = var.region
  project = var.project_id

  default_service = google_compute_region_backend_service.app.id
}

resource "google_compute_region_target_http_proxy" "app" {
  name    = "pxy-${var.name_prefix}-${var.environment}"
  region  = var.region
  project = var.project_id

  url_map = google_compute_region_url_map.app.id
}

resource "google_compute_forwarding_rule" "http" {
  name    = "fr-${var.name_prefix}-${var.environment}"
  region  = var.region
  project = var.project_id

  # Regra EXTERNAL: sem network/subnetwork. A sub-rede proxy (acima) tem de existir e estar ACTIVE.
  depends_on = [google_compute_subnetwork.proxy_only]

  target                = google_compute_region_target_http_proxy.app.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
}
