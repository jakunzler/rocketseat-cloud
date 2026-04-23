output "network_id" {
  value = google_compute_network.this.id
}

output "network_name" {
  value = google_compute_network.this.name
}

output "subnetwork_id" {
  value = google_compute_subnetwork.app.id
}

output "subnetwork_name" {
  value = google_compute_subnetwork.app.name
}

output "subnetwork_self_link" {
  value = google_compute_subnetwork.app.self_link
}

output "network_self_link" {
  value = google_compute_network.this.self_link
}
