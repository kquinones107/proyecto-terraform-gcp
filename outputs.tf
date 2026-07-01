output "ip_publica_balanceador" {
  description = "IP publica unica del balanceador HTTP."
  value       = google_compute_global_address.lb_ip.address
}

output "url_servicio" {
  description = "URL publica para probar el servicio desde el navegador."
  value       = "http://${google_compute_global_address.lb_ip.address}"
}

output "escenario_actual" {
  description = "Pesos actuales de trafico configurados."
  value = {
    servicio_principal    = var.peso_principal
    servicio_contingencia = var.peso_contingencia
  }
}