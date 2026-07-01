variable "project_id" {
  description = "ID del proyecto de Google Cloud Platform donde se desplegará la infraestructura."
  type        = string
}

variable "region" {
  description = "Región de GCP donde se crearán los recursos."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona de GCP donde se crearán las máquinas virtuales."
  type        = string
  default     = "us-central1-a"
}

variable "peso_principal" {
  description = "Peso de tráfico enviado al servicio principal."
  type        = number
  default     = 100
}

variable "peso_contingencia" {
  description = "Peso de tráfico enviado al servicio de contingencia."
  type        = number
  default     = 0
}