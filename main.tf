# ============================================================
# RED VPC Y SUBRED
# ============================================================

resource "google_compute_network" "vpc" {
  name                    = "vpc-proyecto-terraform"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet-proyecto-terraform"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# ============================================================
# FIREWALL HTTP Y HEALTH CHECKS
# ============================================================

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-proyecto-terraform"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-terraform"]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-health-checks-proyecto-terraform"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = ["web-terraform"]
}

# ============================================================
# INSTANCIA DEL SERVICIO PRINCIPAL
# ============================================================

resource "google_compute_instance" "servicio_principal" {
  name         = "vm-servicio-principal"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["web-terraform"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # IP externa temporal para pruebas directas.
      # Los usuarios finales usarán la IP pública del balanceador.
    }
  }

  metadata_startup_script = file("${path.module}/startup-principal.sh")
}

# ============================================================
# INSTANCIA DEL SERVICIO DE CONTINGENCIA
# ============================================================

resource "google_compute_instance" "servicio_contingencia" {
  name         = "vm-servicio-contingencia"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["web-terraform"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # IP externa temporal para pruebas directas.
      # Los usuarios finales usarán la IP pública del balanceador.
    }
  }

  metadata_startup_script = file("${path.module}/startup-contingencia.sh")
}

# ============================================================
# GRUPOS DE INSTANCIAS NO ADMINISTRADOS
# ============================================================

resource "google_compute_instance_group" "grupo_principal" {
  name = "grupo-servicio-principal"
  zone = var.zone

  instances = [
    google_compute_instance.servicio_principal.self_link
  ]

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_instance_group" "grupo_contingencia" {
  name = "grupo-servicio-contingencia"
  zone = var.zone

  instances = [
    google_compute_instance.servicio_contingencia.self_link
  ]

  named_port {
    name = "http"
    port = 80
  }
}

# ============================================================
# HEALTH CHECK
# ============================================================

resource "google_compute_health_check" "http_health_check" {
  name = "http-health-check-proyecto"

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# ============================================================
# BACKEND SERVICES
# ============================================================

resource "google_compute_backend_service" "backend_principal" {
  name                  = "backend-servicio-principal"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 10

  health_checks = [
    google_compute_health_check.http_health_check.id
  ]

  backend {
    group = google_compute_instance_group.grupo_principal.id
  }
}

resource "google_compute_backend_service" "backend_contingencia" {
  name                  = "backend-servicio-contingencia"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 10

  health_checks = [
    google_compute_health_check.http_health_check.id
  ]

  backend {
    group = google_compute_instance_group.grupo_contingencia.id
  }
}

# ============================================================
# URL MAP CON PESOS DE TRAFICO
# ============================================================

resource "google_compute_url_map" "url_map" {
  name = "url-map-proyecto-terraform"

  default_service = google_compute_backend_service.backend_principal.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "matcher-principal"
  }

  path_matcher {
    name            = "matcher-principal"
    default_service = google_compute_backend_service.backend_principal.id

    route_rules {
      priority = 1

      match_rules {
        prefix_match = "/"
      }

      route_action {
        weighted_backend_services {
          backend_service = google_compute_backend_service.backend_principal.id
          weight          = var.peso_principal
        }

        weighted_backend_services {
          backend_service = google_compute_backend_service.backend_contingencia.id
          weight          = var.peso_contingencia
        }
      }
    }
  }
}

# ============================================================
# PROXY HTTP
# ============================================================

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-proxy-proyecto-terraform"
  url_map = google_compute_url_map.url_map.id
}

# ============================================================
# IP PUBLICA UNICA DEL BALANCEADOR
# ============================================================

resource "google_compute_global_address" "lb_ip" {
  name = "ip-publica-proyecto-terraform"
}

# ============================================================
# REGLA DE REENVIO GLOBAL
# ============================================================

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "http-forwarding-rule-proyecto"
  ip_address            = google_compute_global_address.lb_ip.id
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}