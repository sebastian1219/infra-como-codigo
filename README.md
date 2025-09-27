# 🧀 AUY1103 - EA1: Despliegue de Aplicación de Quesos con Terraform en AWS

Este proyecto corresponde a la evaluación **EA1** del curso **Infraestructura como Código**.  
El objetivo es desplegar una arquitectura web simple, escalable y segura en **Amazon Web Services (AWS)** utilizando **Terraform**.

---

## 📌 Objetivo
Automatizar el despliegue de una aplicación web de "The Cheese Factory", que muestra diferentes tipos de quesos en contenedores Docker distribuidos en múltiples instancias EC2 detrás de un **Application Load Balancer (ALB)**.

---

## 🏗️ Arquitectura

- **Región**: `us-east-1`
- **VPC + Subredes públicas**: 1 VPC con 3 subnets en distintas AZs.
- **Internet Gateway + Route Table**: Para acceso a internet.
- **Instancias EC2 (t2.micro)**: 3 instancias distribuidas en distintas AZs.
  - Instancia 1 → `errm/cheese:wensleydale`
  - Instancia 2 → `errm/cheese:cheddar`
  - Instancia 3 → `errm/cheese:stilton`
- **Balanceador de Carga (ALB)**:
  - Listener en puerto 80.
  - Target Group con health checks.
  - Distribuye tráfico entre las 3 instancias.
- **Security Groups**:
  - ALB SG → Permite HTTP (80) desde internet.
  - EC2 SG → Permite HTTP solo desde el ALB y SSH solo desde la IP del desarrollador.
- **Terraform**:
  - Uso de **variables** (`variables.tf`).
  - **terraform.tfvars.example** como ejemplo de configuración.
  - **Expresiones condicionales** (`IsPrimary = true/false`).
  - Uso de **funciones nativas** (`element()`, `cidrsubnet()`).

---

## 📂 Estructura del Proyecto

cheese-terraform/
│── main.tf
│── variables.tf
│── outputs.tf
│── terraform.tfvars.example
│── .gitignore
│── README.md


---

## ⚙️ Requisitos Previos

- Cuenta de AWS con credenciales configuradas (`aws configure`).
- Terraform instalado (>= v1.5 recomendado).
- PowerShell o bash para ejecutar los comandos.

---

## 🚀 Despliegue paso a paso

### 1️⃣ Clonar el repositorio
```powershell
git clone <URL_DE_TU_REPOSITORIO>
cd cheese-terraform

✅ Recomendaciones para complementar tu README
🔧 2️⃣ Inicializar Terraform
Agrega este paso después de clonar el repositorio:

bash
terraform init
📋 3️⃣ Revisar el plan
bash
terraform plan -var-file="terraform.tfvars"
🚀 4️⃣ Aplicar el despliegue
bash
terraform apply -var-file="terraform.tfvars" -auto-approve
📤 5️⃣ Verificar los outputs
bash
terraform output
🧨 Destrucción de la infraestructura
Agrega una sección para eliminar los recursos:

bash
terraform destroy -var-file="terraform.tfvars" -auto-approve
📦 Outputs esperados
Incluye una sección que muestre lo que Terraform devuelve:

alb_dns_name: URL pública del Load Balancer

instance_ids: IDs de las instancias EC2 desplegadas

🧪 Pruebas
Puedes agregar una sección opcional para verificar que cada contenedor responde:

bash
curl http://<alb_dns_name>
🛡️ Seguridad y buenas prácticas
No subir terraform.tfvars si contiene datos sensibles.

Usar terraform.tfvars.example como plantilla pública.

Agregar .terraform, .tfstate, y .tfvars al .gitignore.





