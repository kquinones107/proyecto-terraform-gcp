# Proyecto Terraform - Servicios en la Nube 2026-01

Este proyecto implementa una arquitectura en Google Cloud Platform usando Terraform.  
La infraestructura permite distribuir tráfico HTTP entre un servicio principal de producción y un servicio de contingencia o mantenimiento, usando una única IP pública de entrada.

## Arquitectura

La solución crea los siguientes recursos:

- Una red VPC personalizada.
- Una subred regional.
- Dos máquinas virtuales independientes:
  - Servicio principal.
  - Servicio de contingencia.
- Dos grupos de instancias no administrados.
- Dos backend services.
- Un health check HTTP.
- Un URL Map con distribución ponderada de tráfico.
- Un HTTP Load Balancer externo administrado.
- Una única IP pública global.

## Servicios

### Servicio Principal

Mensaje mostrado en el navegador:

```text
Bienvenido al Servicio Principal - Versión Producción
Servicio de Contingencia

Mensaje mostrado en el navegador:

Error 503 - Sitio en Mantenimiento Programado
Variables principales

El comportamiento del tráfico se controla desde el archivo terraform.tfvars.

Ejemplo base:

project_id = "proyecto-terraform-gcp"
region     = "us-east1"
zone       = "us-east1-b"

peso_principal    = 100
peso_contingencia = 0
Escenarios de evaluación
Escenario 1: Producción activa
peso_principal    = 100
peso_contingencia = 0

Resultado esperado:

Bienvenido al Servicio Principal - Versión Producción
Escenario 2: Mantenimiento total
peso_principal    = 0
peso_contingencia = 100

Resultado esperado:

Error 503 - Sitio en Mantenimiento Programado
Escenario 3: Balance 50/50
peso_principal    = 50
peso_contingencia = 50

Resultado esperado:

El balanceador distribuye las solicitudes entre ambos servicios.
La alternancia no necesariamente ocurre en cada recarga del navegador, pero al realizar múltiples solicitudes se evidencian respuestas de ambos servicios.

Comandos de uso

Inicializar Terraform:

terraform init

Formatear archivos:

terraform fmt

Validar configuración:

terraform validate

Ver plan de ejecución:

terraform plan

Aplicar infraestructura:

terraform apply

Destruir infraestructura:

terraform destroy
Salidas esperadas

Al finalizar terraform apply, Terraform muestra:

ip_publica_balanceador
url_servicio
escenario_actual

La URL pública es la única dirección que deben usar los usuarios para acceder al servicio.

Nota importante

No se debe subir al repositorio la carpeta .terraform/ ni archivos de estado como terraform.tfstate.

El proyecto debe ser desplegado desde cero usando únicamente el código del repositorio y el comando:

terraform apply

Al finalizar las pruebas, se debe ejecutar:

terraform destroy

para evitar consumo innecesario de créditos en GCP.
