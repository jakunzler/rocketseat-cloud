output "http_url" {
  value       = module.app.http_url
  description = "URL pública (HTTP) do balanceador. Considere HTTPS com certificado gerenciado em produção."
}

output "load_balancer_ip" {
  value = module.app.load_balancer_ip
}

output "network_name" {
  value = module.network.network_name
}

output "app_secret_id" {
  value       = module.app.secret_id
  sensitive   = true
  description = "Identificador do segredo"
}
