# Guía de Despliegue en AWS - Windows

Instrucciones paso a paso para desplegar en AWS desde Windows usando PowerShell.

## 📋 Prerequisitos

### 1. Instalar Herramientas

**AWS CLI:**
```powershell
# Descargar e instalar desde:
# https://awscli.amazonaws.com/AWSCLIV2.msi

# Verificar instalación
aws --version
```

**Terraform:**
```powershell
# Descargar desde:
# https://www.terraform.io/downloads

# O usar Chocolatey:
choco install terraform

# Verificar
terraform --version
```

**Docker Desktop:**
```powershell
# Descargar desde:
# https://www.docker.com/products/docker-desktop

# Verificar
docker --version
```

### 2. Configurar AWS CLI

```powershell
# Configurar credenciales
aws configure

# Ingresa:
# AWS Access Key ID: [tu access key]
# AWS Secret Access Key: [tu secret key]
# Default region name: us-east-1
# Default output format: json

# Verificar
aws sts get-caller-identity
```

## 🚀 Despliegue Paso a Paso

### **Opción A: Usando Scripts Automáticos**

```powershell
# 1. Ir a la carpeta terraform
cd c:\Users\ronal\Documents\proyectoandes\Proyecto-Final-Grupo-11\experimento\terraform

# 2. Configurar variables
copy terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
# Edita db_password y otros valores

# 3. Ejecutar despliegue completo
cd scripts
.\deploy.bat
```

### **Opción B: Paso a Paso Manual (Recomendado para aprender)**

#### **Paso 1: Configurar Variables**

```powershell
cd c:\Users\ronal\Documents\proyectoandes\Proyecto-Final-Grupo-11\experimento\terraform

# Copiar archivo de ejemplo
copy terraform.tfvars.example terraform.tfvars

# Editar con tus valores
notepad terraform.tfvars
```

**Valores importantes a cambiar en `terraform.tfvars`:**
```hcl
aws_region   = "us-east-1"
db_password  = "TuPasswordSeguro123!"  # CAMBIAR ESTO
desired_count = 1  # Usar 1 para ahorrar costos
```

#### **Paso 2: Inicializar Terraform**

```powershell
# Inicializar (descarga providers)
terraform init

# Validar configuración
terraform validate
```

#### **Paso 3: Crear Infraestructura Base**

```powershell
# Ver qué se va a crear
terraform plan

# Crear solo ECR primero (repositorios Docker)
terraform apply -target=module.ecr

# Confirmar con: yes
```

#### **Paso 4: Build y Push de Imágenes Docker**

```powershell
# Obtener información de ECR
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$AWS_REGION = "us-east-1"
$INVENTORY_REPO = terraform output -raw ecr_inventory_repository_url
$BOOKING_REPO = terraform output -raw ecr_booking_repository_url

# Login a ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Build Inventory
cd ..\inventory
docker build -t inventory-service:latest .
docker tag inventory-service:latest "$INVENTORY_REPO:latest"
docker push "$INVENTORY_REPO:latest"

# Build Booking
cd ..\booking
docker build -t booking-service:latest .
docker tag booking-service:latest "$BOOKING_REPO:latest"
docker push "$BOOKING_REPO:latest"

# Volver a terraform
cd ..\terraform
```

#### **Paso 5: Crear Toda la Infraestructura**

```powershell
# Crear todo
terraform apply

# Revisar el plan y confirmar con: yes
# Esto tomará ~10-15 minutos
```

#### **Paso 6: Esperar a que los Servicios Estén Listos**

```powershell
# Obtener nombres
$CLUSTER = terraform output -raw ecs_cluster_name
$INV_SERVICE = terraform output -raw inventory_service_name
$BOOK_SERVICE = terraform output -raw booking_service_name

# Ver estado de servicios
aws ecs describe-services --cluster $CLUSTER --services $INV_SERVICE,$BOOK_SERVICE --query "services[*].[serviceName,runningCount,desiredCount]" --output table

# Esperar hasta que runningCount = desiredCount
# Puede tomar 3-5 minutos
```

#### **Paso 7: Inicializar Bases de Datos**

```powershell
# Obtener task ARN de inventory
$INV_TASK = aws ecs list-tasks --cluster $CLUSTER --service-name $INV_SERVICE --desired-status RUNNING --query "taskArns[0]" --output text

# Inicializar DB de inventory
aws ecs execute-command --cluster $CLUSTER --task $INV_TASK --container inventory --interactive --command "python init_db.py"

# Obtener task ARN de booking
$BOOK_TASK = aws ecs list-tasks --cluster $CLUSTER --service-name $BOOK_SERVICE --desired-status RUNNING --query "taskArns[0]" --output text

# Inicializar DB de booking
aws ecs execute-command --cluster $CLUSTER --task $BOOK_TASK --container booking --interactive --command "python init_db.py"
```

#### **Paso 8: Verificar Despliegue**

```powershell
# Obtener URL del ALB
$ALB_URL = terraform output -raw alb_url

# Probar servicios
curl "http://$ALB_URL:5001/api/health"
curl "http://$ALB_URL:5002/api/health"

# Deberías ver: {"service":"inventory","status":"healthy"}
```

#### **Paso 9: Ejecutar Pruebas**

```powershell
# Ir a carpeta de tests
cd ..\tests

# Ejecutar prueba de concurrencia
python concurrent_booking_test.py --url "http://$ALB_URL:5002/api" --users 50 --room-id 1 --check-in 2026-03-15 --check-out 2026-03-17

# Validar base de datos
python validation\validate_results.py --room-id 1 --check-in 2026-03-15
```

## 🔧 Comandos Útiles

### Ver Outputs de Terraform

```powershell
cd c:\Users\ronal\Documents\proyectoandes\Proyecto-Final-Grupo-11\experimento\terraform

# Ver todos los outputs
terraform output

# Ver URL del ALB
terraform output alb_url

# Ver endpoint de RDS
terraform output rds_endpoint
```

### Ver Logs de ECS

```powershell
# Logs de Inventory
aws logs tail /ecs/booking-experiment-dev/inventory --follow

# Logs de Booking
aws logs tail /ecs/booking-experiment-dev/booking --follow
```

### Actualizar Imágenes Docker

```powershell
# Rebuild y push
cd scripts
.\build-and-push.bat

# Forzar nuevo despliegue
$CLUSTER = terraform output -raw ecs_cluster_name
aws ecs update-service --cluster $CLUSTER --service booking-experiment-dev-inventory --force-new-deployment
aws ecs update-service --cluster $CLUSTER --service booking-experiment-dev-booking --force-new-deployment
```

### Escalar Servicios

```powershell
$CLUSTER = terraform output -raw ecs_cluster_name

# Escalar a 0 (apagar)
aws ecs update-service --cluster $CLUSTER --service booking-experiment-dev-inventory --desired-count 0
aws ecs update-service --cluster $CLUSTER --service booking-experiment-dev-booking --desired-count 0

# Escalar a 2 (encender)
aws ecs update-service --cluster $CLUSTER --service booking-experiment-dev-inventory --desired-count 2
aws ecs update-service --cluster $CLUSTER --service booking-experiment-dev-booking --desired-count 2
```

## 🗑️ Destruir Infraestructura

### Opción A: Script Automático

```powershell
cd scripts
.\destroy.bat
```

### Opción B: Manual

```powershell
cd c:\Users\ronal\Documents\proyectoandes\Proyecto-Final-Grupo-11\experimento\terraform

# Destruir todo
terraform destroy

# Confirmar con: yes
# Esto tomará ~10 minutos
```

## 🔍 Troubleshooting

### Error: "Docker daemon not running"

```powershell
# Iniciar Docker Desktop
# Esperar a que esté completamente iniciado
docker ps
```

### Error: "No space left on device"

```powershell
# Limpiar Docker
docker system prune -a
```

### Error: "Task failed to start"

```powershell
# Ver logs
$CLUSTER = terraform output -raw ecs_cluster_name
aws logs tail /ecs/booking-experiment-dev/booking --follow

# Verificar imágenes en ECR
aws ecr describe-images --repository-name booking-experiment-dev-inventory
aws ecr describe-images --repository-name booking-experiment-dev-booking
```

### Error: "Cannot connect to RDS"

```powershell
# Verificar security groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=booking-experiment-dev-db-sg"

# Verificar que RDS esté disponible
aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]"
```

### Error: "Health check failed"

```powershell
# Ver estado de tasks
$CLUSTER = terraform output -raw ecs_cluster_name
aws ecs describe-tasks --cluster $CLUSTER --tasks $(aws ecs list-tasks --cluster $CLUSTER --query "taskArns[0]" --output text)

# Ver target groups
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw inventory_target_group_arn)
```

## 💰 Monitorear Costos

```powershell
# Ver costos estimados (requiere Cost Explorer habilitado)
aws ce get-cost-and-usage --time-period Start=2026-03-01,End=2026-03-31 --granularity MONTHLY --metrics BlendedCost

# O revisar en AWS Console:
# https://console.aws.amazon.com/billing/
```

## 📊 Monitoreo

### CloudWatch Dashboard

```powershell
# Abrir CloudWatch en navegador
start "https://console.aws.amazon.com/cloudwatch/"
```

### Ver Métricas de ECS

```powershell
$CLUSTER = terraform output -raw ecs_cluster_name

# CPU Utilization
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=booking-experiment-dev-booking Name=ClusterName,Value=$CLUSTER --start-time 2026-03-04T00:00:00Z --end-time 2026-03-04T23:59:59Z --period 3600 --statistics Average

# Memory Utilization
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization --dimensions Name=ServiceName,Value=booking-experiment-dev-booking Name=ClusterName,Value=$CLUSTER --start-time 2026-03-04T00:00:00Z --end-time 2026-03-04T23:59:59Z --period 3600 --statistics Average
```

## 🎯 Resumen de Comandos Rápidos

```powershell
# Despliegue completo
cd c:\Users\ronal\Documents\proyectoandes\Proyecto-Final-Grupo-11\experimento\terraform\scripts
.\deploy.bat

# Ver URL
cd ..
terraform output alb_url

# Ver logs
aws logs tail /ecs/booking-experiment-dev/booking --follow

# Destruir todo
cd scripts
.\destroy.bat
```

## 📚 Recursos

- [AWS CLI Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [PowerShell AWS Tools](https://aws.amazon.com/powershell/)
