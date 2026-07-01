# AGENTS.md

## Propósito del proyecto

Este repositorio contiene una infraestructura creada con Terraform para Google Cloud Platform.
El objetivo es desplegar una arquitectura con una única IP pública que distribuya tráfico HTTP entre dos servicios independientes:

1. Servicio Principal.
2. Servicio de Contingencia.

La distribución del tráfico se controla únicamente modificando variables en `terraform.tfvars`.

## Contexto del reto

El proyecto simula una arquitectura de alta flexibilidad para una plataforma web.
La empresa necesita cambiar el comportamiento del tráfico sin modificar manualmente la consola de GCP ni reescribir la infraestructura.

La solución debe permitir estos tres escenarios:

* Producción activa: 100% al servicio principal y 0% al servicio de contingencia.
* Mantenimiento total: 0% al servicio principal y 100% al servicio de contingencia.
* Balance 50/50: distribución equilibrada entre ambos servicios.

## Archivos principales

### `providers.tf`

Configura Terraform y el proveedor de Google Cloud.

Define el uso del provider:

```hcl
hashicorp/google
```

También usa las variables:

```hcl
project_id
region
zone
```

### `variables.tf`

Define las variables necesarias para parametrizar el proyecto:

```hcl
project_id
region
zone
peso_principal
peso_contingencia
```

### `terraform.tfvars`

Archivo donde se cambian los valores concretos del proyecto.

Ejemplo:

```hcl
project_id = "proyecto-terraform-gcp"
region     = "us-east1"
zone       = "us-east1-b"

peso_principal    = 100
peso_contingencia = 0
```

Este archivo permite activar cada escenario sin modificar el código principal.

### `main.tf`

Contiene la infraestructura principal:

* VPC.
* Subred.
* Reglas de firewall.
* Máquina virtual del servicio principal.
* Máquina virtual del servicio de contingencia.
* Grupos de instancias.
* Health check HTTP.
* Backend services.
* URL map con pesos.
* Proxy HTTP.
* IP pública global.
* Forwarding rule.

### `outputs.tf`

Muestra información útil después del despliegue:

```hcl
ip_publica_balanceador
url_servicio
escenario_actual
```

### `startup-principal.sh`

Script de inicio de la máquina virtual principal.

Crea una página HTML con el mensaje:

```text
Bienvenido al Servicio Principal - Versión Producción
```

También crea y activa un servicio web en el puerto 80.

### `startup-contingencia.sh`

Script de inicio de la máquina virtual de contingencia.

Crea una página HTML con el mensaje:

```text
Error 503 - Sitio en Mantenimiento Programado
```

También crea y activa un servicio web en el puerto 80.

## Arquitectura general

El flujo esperado es:

```text
Usuario en Internet
        |
        v
IP pública única del Load Balancer
        |
        v
URL Map con pesos de tráfico
        |
        +----------------------------+
        |                            |
        v                            v
Backend Servicio Principal     Backend Servicio Contingencia
        |                            |
        v                            v
VM principal                  VM contingencia
```

## Reglas importantes del proyecto

El servicio principal y el servicio de contingencia deben estar en máquinas virtuales independientes.

No se debe configurar nada manualmente por SSH después del despliegue.

Todo debe crearse con:

```bash
terraform apply
```

Todo debe eliminarse con:

```bash
terraform destroy
```

## Cómo cambiar escenarios

### Escenario 1: Producción activa

Editar `terraform.tfvars`:

```hcl
peso_principal    = 100
peso_contingencia = 0
```

Resultado esperado:

```text
Bienvenido al Servicio Principal - Versión Producción
```

### Escenario 2: Mantenimiento total

Editar `terraform.tfvars`:

```hcl
peso_principal    = 0
peso_contingencia = 100
```

Resultado esperado:

```text
Error 503 - Sitio en Mantenimiento Programado
```

### Escenario 3: Balance 50/50

Editar `terraform.tfvars`:

```hcl
peso_principal    = 50
peso_contingencia = 50
```

Resultado esperado:

El balanceador distribuye las solicitudes entre ambos servicios.
La alternancia puede no ocurrir en cada recarga exacta del navegador, pero al realizar múltiples solicitudes se deben observar respuestas de ambos servicios.

## Comandos recomendados

Inicializar Terraform:

```bash
terraform init
```

Formatear archivos:

```bash
terraform fmt
```

Validar configuración:

```bash
terraform validate
```

Ver plan:

```bash
terraform plan
```

Aplicar cambios:

```bash
terraform apply
```

Destruir recursos:

```bash
terraform destroy
```

## Consideraciones para un LLM

Al analizar este proyecto, se debe revisar primero `terraform.tfvars`, porque allí se define el escenario activo.

Luego se debe revisar `main.tf`, especialmente estos recursos:

```hcl
google_compute_url_map.url_map
google_compute_backend_service.backend_principal
google_compute_backend_service.backend_contingencia
google_compute_instance.servicio_principal
google_compute_instance.servicio_contingencia
```

El control de tráfico se realiza mediante:

```hcl
weighted_backend_services
```

Los pesos usados son:

```hcl
var.peso_principal
var.peso_contingencia
```

Por lo tanto, el comportamiento del tráfico depende directamente de esas variables.

## Limpieza del proyecto

Al terminar las pruebas se debe ejecutar:

```bash
terraform destroy
```

Esto elimina la infraestructura creada en GCP y evita consumo innecesario de créditos.

## Archivos que no deben subirse

No se deben subir:

```text
.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
```

Estos archivos deben estar excluidos mediante `.gitignore`.
