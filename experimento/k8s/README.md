# Kubernetes Deployment Guide

## 📋 Descripción

Manifiestos de Kubernetes para desplegar el experimento de reservas concurrentes en un cluster de Kubernetes.

## 🏗️ Arquitectura en Kubernetes

```
booking-experiment (namespace)
├── Redis (Deployment + Service)
├── PostgreSQL Inventory DB (StatefulSet + Service + PVC)
├── PostgreSQL Booking DB (StatefulSet + Service + PVC)
├── Inventory Service (Deployment + Service) - 2 replicas
└── Booking Service (Deployment + Service) - 2 replicas
```

## 📁 Estructura de Manifiestos

```
k8s/
├── namespace.yaml           # Namespace del experimento
├── postgres/
│   ├── secrets.yaml        # Credenciales de bases de datos
│   ├── inventory-db.yaml   # StatefulSet + Service + PVC
│   └── booking-db.yaml     # StatefulSet + Service + PVC
├── redis/
│   ├── deployment.yaml     # Deployment de Redis
│   └── service.yaml        # Service de Redis
├── inventory/
│   ├── deployment.yaml     # Deployment del servicio
│   └── service.yaml        # Service ClusterIP
└── booking/
    ├── deployment.yaml     # Deployment del servicio
    └── service.yaml        # Service LoadBalancer
```

## 🚀 Despliegue Paso a Paso

### Prerequisitos

1. Cluster de Kubernetes funcionando (minikube, kind, GKE, EKS, AKS, etc.)
2. `kubectl` configurado
3. Imágenes Docker construidas

### 1. Construir Imágenes Docker

```bash
cd experimento

# Inventory Service
docker build -t inventory-service:latest ./inventory

# Booking Service
docker build -t booking-service:latest ./booking
```

**Para Minikube:**

```bash
# Usar el daemon de Docker de Minikube
eval $(minikube docker-env)

# Construir imágenes
docker build -t inventory-service:latest ./inventory
docker build -t booking-service:latest ./booking
```

**Para registros remotos (GCR, ECR, Docker Hub):**

```bash
# Tag y push
docker tag inventory-service:latest your-registry/inventory-service:latest
docker push your-registry/inventory-service:latest

docker tag booking-service:latest your-registry/booking-service:latest
docker push your-registry/booking-service:latest

# Actualizar deployments para usar la imagen remota
# Editar k8s/inventory/deployment.yaml y k8s/booking/deployment.yaml
# Cambiar: image: inventory-service:latest
# Por: image: your-registry/inventory-service:latest
# Y cambiar: imagePullPolicy: Never
# Por: imagePullPolicy: Always
```

### 2. Crear Namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

### 3. Desplegar Bases de Datos

```bash
# Aplicar secrets
kubectl apply -f k8s/postgres/secrets.yaml

# Desplegar PostgreSQL databases
kubectl apply -f k8s/postgres/inventory-db.yaml
kubectl apply -f k8s/postgres/booking-db.yaml

# Esperar a que estén listas
kubectl wait --for=condition=ready pod -l app=inventory-db -n booking-experiment --timeout=120s
kubectl wait --for=condition=ready pod -l app=booking-db -n booking-experiment --timeout=120s

# Verificar
kubectl get pods -n booking-experiment
kubectl get pvc -n booking-experiment
```

### 4. Desplegar Redis

```bash
kubectl apply -f k8s/redis/deployment.yaml
kubectl apply -f k8s/redis/service.yaml

# Esperar a que esté listo
kubectl wait --for=condition=ready pod -l app=redis -n booking-experiment --timeout=60s
```

### 5. Desplegar Microservicios

```bash
# Inventory Service
kubectl apply -f k8s/inventory/deployment.yaml
kubectl apply -f k8s/inventory/service.yaml

# Booking Service
kubectl apply -f k8s/booking/deployment.yaml
kubectl apply -f k8s/booking/service.yaml

# Esperar a que estén listos
kubectl wait --for=condition=ready pod -l app=inventory-service -n booking-experiment --timeout=120s
kubectl wait --for=condition=ready pod -l app=booking-service -n booking-experiment --timeout=120s
```

### 6. Verificar Despliegue

```bash
# Ver todos los recursos
kubectl get all -n booking-experiment

# Ver pods
kubectl get pods -n booking-experiment

# Ver servicios
kubectl get svc -n booking-experiment

# Ver logs
kubectl logs -l app=booking-service -n booking-experiment
kubectl logs -l app=inventory-service -n booking-experiment
```

### 7. Inicializar Datos

```bash
# Obtener nombre del pod de inventory
INVENTORY_POD=$(kubectl get pods -n booking-experiment -l app=inventory-service -o jsonpath='{.items[0].metadata.name}')

# Inicializar datos de inventario
kubectl exec -n booking-experiment $INVENTORY_POD -- python init_db.py

# Obtener nombre del pod de booking
BOOKING_POD=$(kubectl get pods -n booking-experiment -l app=booking-service -o jsonpath='{.items[0].metadata.name}')

# Inicializar datos de booking
kubectl exec -n booking-experiment $BOOKING_POD -- python init_db.py
```

### 8. Acceder a los Servicios

**Opción A: Port Forward (Desarrollo)**

```bash
# Booking Service
kubectl port-forward -n booking-experiment service/booking-service 5002:5002

# Inventory Service (en otra terminal)
kubectl port-forward -n booking-experiment service/inventory-service 5001:5001

# Ahora puedes acceder a:
# http://localhost:5002/api/health
# http://localhost:5001/api/health
```

**Opción B: LoadBalancer (Producción)**

```bash
# Obtener IP externa del LoadBalancer
kubectl get svc booking-service -n booking-experiment

# Si estás en Minikube
minikube service booking-service -n booking-experiment --url
```

**Opción C: Ingress (Recomendado para producción)**

Crear un Ingress para exponer los servicios:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: booking-ingress
  namespace: booking-experiment
spec:
  rules:
  - host: booking.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: booking-service
            port:
              number: 5002
```

## 🔍 Monitoreo y Debugging

### Ver Logs

```bash
# Logs de un pod específico
kubectl logs -n booking-experiment <pod-name>

# Logs de todos los pods de un deployment
kubectl logs -n booking-experiment -l app=booking-service --tail=100

# Seguir logs en tiempo real
kubectl logs -n booking-experiment -l app=booking-service -f

# Logs de contenedor específico (si hay múltiples)
kubectl logs -n booking-experiment <pod-name> -c booking
```

### Ejecutar Comandos en Pods

```bash
# Shell interactivo
kubectl exec -it -n booking-experiment <pod-name> -- /bin/sh

# Comando único
kubectl exec -n booking-experiment <pod-name> -- python --version

# Acceder a PostgreSQL
kubectl exec -it -n booking-experiment inventory-db-0 -- psql -U inventory_user -d inventory_db

# Acceder a Redis
kubectl exec -it -n booking-experiment <redis-pod-name> -- redis-cli
```

### Verificar Estado de Recursos

```bash
# Describir pod
kubectl describe pod -n booking-experiment <pod-name>

# Ver eventos
kubectl get events -n booking-experiment --sort-by='.lastTimestamp'

# Ver uso de recursos
kubectl top pods -n booking-experiment
kubectl top nodes
```

### Health Checks

```bash
# Verificar readiness/liveness probes
kubectl describe pod -n booking-experiment <pod-name> | grep -A 10 "Liveness\|Readiness"

# Test manual de health endpoint
kubectl exec -n booking-experiment <booking-pod> -- curl http://localhost:5002/api/health
```

## 📊 Escalado

### Escalar Manualmente

```bash
# Escalar Booking Service
kubectl scale deployment booking-service -n booking-experiment --replicas=3

# Escalar Inventory Service
kubectl scale deployment inventory-service -n booking-experiment --replicas=3

# Verificar
kubectl get pods -n booking-experiment -l app=booking-service
```

### Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: booking-service-hpa
  namespace: booking-experiment
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: booking-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

```bash
kubectl apply -f hpa.yaml
kubectl get hpa -n booking-experiment
```

## 🗄️ Gestión de Datos Persistentes

### Backup de Bases de Datos

```bash
# Backup de Inventory DB
kubectl exec -n booking-experiment inventory-db-0 -- pg_dump -U inventory_user inventory_db > inventory_backup.sql

# Backup de Booking DB
kubectl exec -n booking-experiment booking-db-0 -- pg_dump -U booking_user booking_db > booking_backup.sql
```

### Restore de Bases de Datos

```bash
# Restore de Inventory DB
cat inventory_backup.sql | kubectl exec -i -n booking-experiment inventory-db-0 -- psql -U inventory_user -d inventory_db

# Restore de Booking DB
cat booking_backup.sql | kubectl exec -i -n booking-experiment booking-db-0 -- psql -U booking_user -d booking_db
```

## 🧹 Limpieza

### Eliminar Todo

```bash
# Eliminar namespace completo (elimina todos los recursos)
kubectl delete namespace booking-experiment

# Eliminar PVCs (si no se eliminaron automáticamente)
kubectl delete pvc --all -n booking-experiment
```

### Eliminar Recursos Específicos

```bash
# Eliminar deployments
kubectl delete deployment booking-service inventory-service -n booking-experiment

# Eliminar statefulsets
kubectl delete statefulset inventory-db booking-db -n booking-experiment

# Eliminar servicios
kubectl delete svc --all -n booking-experiment
```

## ⚙️ Configuración Avanzada

### Resource Limits

Los deployments ya incluyen resource limits:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

Ajustar según necesidades de carga.

### Secrets Management

Para producción, considerar usar:
- **Sealed Secrets**
- **External Secrets Operator**
- **HashiCorp Vault**
- **Cloud provider secrets** (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault)

### Network Policies

Implementar network policies para seguridad:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: booking-network-policy
  namespace: booking-experiment
spec:
  podSelector:
    matchLabels:
      app: booking-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 5002
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: inventory-service
    ports:
    - protocol: TCP
      port: 5001
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379
  - to:
    - podSelector:
        matchLabels:
          app: booking-db
    ports:
    - protocol: TCP
      port: 5432
```

## 📝 Notas Importantes

1. **ImagePullPolicy**: Configurado como `Never` para desarrollo local. Cambiar a `Always` para producción con registry remoto.

2. **Persistent Volumes**: Los PVCs requieren un StorageClass configurado en el cluster. Minikube y la mayoría de cloud providers lo tienen por defecto.

3. **LoadBalancer**: El servicio de booking usa tipo `LoadBalancer`. En Minikube, usar `minikube tunnel` para obtener IP externa.

4. **Health Checks**: Configurados con tiempos generosos para desarrollo. Ajustar para producción.

5. **Replicas**: Configuradas 2 réplicas por servicio para alta disponibilidad. Ajustar según carga esperada.

## 🎯 Checklist de Despliegue

- [ ] Cluster de Kubernetes disponible
- [ ] kubectl configurado
- [ ] Imágenes Docker construidas
- [ ] Namespace creado
- [ ] Secrets aplicados
- [ ] Bases de datos desplegadas y listas
- [ ] Redis desplegado y listo
- [ ] Servicios desplegados y listos
- [ ] Datos inicializados
- [ ] Health checks pasando
- [ ] Port forwarding o LoadBalancer configurado
- [ ] Pruebas de conectividad exitosas
