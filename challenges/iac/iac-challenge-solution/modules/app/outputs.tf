output "load_balancer_ip" {
  value       = google_compute_forwarding_rule.http.ip_address
  description = "IP externo (HTTP) do balanceador regional."
}

output "http_url" {
  value       = "http://${google_compute_forwarding_rule.http.ip_address}/"
  description = "URL HTTP do balanceador (sem TLS; em produção use HTTPS + certificado gerenciado)."
}

output "secret_id" {
  value       = local.secret_id
  description = "Identificador do segredo (defina o payload fora do Terraform)."
  sensitive   = true
}

output "instance_group" {
  value = google_compute_region_instance_group_manager.app.instance_group
}

output "app_network_tag" {
  value = local.app_tag
}
