# AWS ECS Fargate Deployment - Terraform

Despliegue automatizado del experimento de reservas concurrentes en AWS usando ECS Fargate.

## 📋 Prerequisitos

### 1. Herramientas Requeridas

```bash
# AWS CLI
aws --version  # >= 2.0

# Terraform
terraform --version  # >= 1.0

# Docker
docker --version  # >= 20.0
```

### 2. Configurar AWS CLI

```bash
# Configurar credenciales de cuenta académica
aws configure

# Verificar acceso
aws sts get-caller-identity
```

### 3. Permisos IAM Necesarios

Tu usuario IAM necesita permisos para:
- VPC, Subnets, Security Groups
- RDS (PostgreSQL)
- ElastiCache (Redis)
- ECR (Elastic Container Registry)
- ECS (Elastic Container Service)
- Application Load Balancer
- IAM Roles
- CloudWatch Logs

## 🚀 Despliegue Rápido

### Paso 1: Configurar Variables

```bash
# Copiar archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
nano terraform.tfvars
```

**Valores importantes a cambiar:**
```hcl
aws_region   = "us-east-1"  # Tu región preferida
db_password  = "TuPasswordSeguro123!"  # CAMBIAR ESTO
desired_count = 1  # Usar 1 para ahorrar costos
```

### Paso 2: Desplegar Infraestructura

```bash
cd scripts
chmod +x *.sh
./deploy.sh
```

Este script ejecutará automáticamente:
1. `terraform init` - Inicializar Terraform
2. `terraform plan` - Planear cambios
3. `terraform apply` - Crear infraestructura
4. Build y push de imágenes Docker a ECR
5. Inicialización de bases de datos

**Tiempo estimado:** 15-20 minutos

### Paso 3: Verificar Despliegue

```bash
# Obtener URL del ALB
terraform output alb_url

# Probar servicios
curl http://<ALB_URL>:5001/api/health  # Inventory
curl http://<ALB_URL>:5002/api/health  # Booking
```

## 📊 Arquitectura Desplegada

```
Internet
    │
    ▼
┌─────────────────────────────────────────┐
│  Application Load Balancer (ALB)        │
│  - Port 5001 → Inventory Service        │
│  - Port 5002 → Booking Service          │
└──────────────┬──────────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼────────┐    ┌──────▼─────┐
│ ECS Fargate│    │ ECS Fargate│
│ Inventory  │    │  Booking   │
│ (2 tasks)  │    │ (2 tasks)  │
└────┬───────┘    └─────┬──────┘
     │                  │
     │    ┌─────────────┴──────┐
     │    │                    │
     ▼    ▼                    ▼
┌──────────────┐      ┌────────────┐
│ RDS PostgreSQL│      │ElastiCache │
│ - inventory_db│      │   Redis    │
│ - booking_db  │      │            │
└───────────────┘      └────────────┘
```

## 💰 Estimación de Costos

### Configuración Mínima (desired_count=1)
- **ECS Fargate**: ~$20/mes (2 tasks)
- **RDS t3.micro**: Free Tier (12 meses)
- **ElastiCache t3.micro**: Free Tier (12 meses)
- **ALB**: Free Tier (12 meses)
- **NAT Gateway**: ~$35/mes
- **Total**: ~$55/mes

### Configuración Recomendada (desired_count=2)
- **ECS Fargate**: ~$40/mes (4 tasks)
- **Total**: ~$75/mes

### Optimización de Costos

Para reducir costos en cuenta académica:

1. **Usar 1 réplica:**
```hcl
desired_count = 1
```

2. **Deshabilitar NAT Gateway** (containers no tendrán internet):
```hcl
enable_nat_gateway = false
```

3. **Apagar cuando no uses:**
```bash
# Escalar a 0 tasks
aws ecs update-service --cluster <cluster-name> --service <service-name> --desired-count 0

# Volver a escalar
aws ecs update-service --cluster <cluster-name> --service <service-name> --desired-count 2
```

## 🔧 Comandos Útiles

### Ver Outputs

```bash
terraform output
terraform output -raw alb_url
terraform output -raw rds_endpoint
```

### Ver Logs de ECS

```bash
# Listar tasks
aws ecs list-tasks --cluster <cluster-name>

# Ver logs
aws logs tail /ecs/<project>-<env>/inventory --follow
aws logs tail /ecs/<project>-<env>/booking --follow
```

### Actualizar Imágenes Docker

```bash
# Rebuild y push
cd scripts
./build-and-push.sh

# Forzar nuevo despliegue
aws ecs update-service --cluster <cluster-name> --service <service-name> --force-new-deployment
```

### Conectarse a Base de Datos

```bash
# Obtener endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

# Conectar desde bastion o VPN
psql -h $RDS_ENDPOINT -U dbadmin -d inventory_db
```

### Ejecutar Comando en Container

```bash
# Habilitar ECS Exec (ya está habilitado en el código)
aws ecs execute-command \
    --cluster <cluster-name> \
    --task <task-arn> \
    --container inventory \
    --interactive \
    --command "/bin/sh"
```

## 🧪 Ejecutar Pruebas

```bash
# Obtener URL del ALB
ALB_URL=$(terraform output -raw alb_url)

# Ejecutar pruebas de concurrencia
cd ../tests
python concurrent_booking_test.py \
    --url http://$ALB_URL:5002/api \
    --users 50 \
    --room-id 1 \
    --check-in 2026-03-15 \
    --check-out 2026-03-17
```

## 🗑️ Destruir Infraestructura

```bash
cd scripts
./destroy.sh
```

**ADVERTENCIA:** Esto eliminará todos los recursos y datos. No se puede deshacer.

## 📁 Estructura de Archivos

```
terraform/
├── main.tf                 # Configuración principal
├── variables.tf            # Variables de entrada
├── outputs.tf              # Outputs
├── terraform.tfvars        # Valores de variables (gitignored)
├── terraform.tfvars.example
│
├── modules/
│   ├── networking/         # VPC, subnets, security groups
│   ├── ecr/                # Container registry
│   ├── rds/                # PostgreSQL databases
│   ├── elasticache/        # Redis cluster
│   ├── alb/                # Application Load Balancer
│   └── ecs/                # ECS Fargate cluster y services
│
└── scripts/
    ├── deploy.sh           # Despliegue completo
    ├── build-and-push.sh   # Build y push de imágenes
    ├── init-databases.sh   # Inicializar datos
    └── destroy.sh          # Destruir todo
```

## 🔍 Troubleshooting

### Error: "No space left on device"

Docker está sin espacio. Limpiar:
```bash
docker system prune -a
```

### Error: "Task failed to start"

Ver logs de ECS:
```bash
aws logs tail /ecs/<project>-<env>/booking --follow
```

### Error: "Health check failed"

Verificar security groups y que los containers estén escuchando en los puertos correctos.

### Error: "Cannot connect to RDS"

Verificar que:
1. Security group permite conexiones desde ECS
2. RDS está en subnets privadas correctas
3. Credenciales son correctas

## 📚 Recursos Adicionales

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Free Tier](https://aws.amazon.com/free/)

## 🆘 Soporte

Si encuentras problemas:
1. Revisa los logs de CloudWatch
2. Verifica los security groups
3. Confirma que las imágenes están en ECR
4. Revisa el estado de los servicios ECS
