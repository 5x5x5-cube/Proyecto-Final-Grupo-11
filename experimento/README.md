# Experimento de Validación de Reservas Concurrentes

## Descripción

Este experimento valida la historia de usuario **PFG1-11**: "Como viajero cuando confirme una reserva desde el carrito de compra, dado que hay disponibilidad de la habitación seleccionada, quiero que la reserva se cree correctamente sin conflictos con otros usuarios, esto debe suceder en menos de 1.5 segundos."

## Objetivos del Experimento

1. **Consistencia**: Validar que solo 1 reserva se crea cuando múltiples usuarios intentan reservar la misma habitación simultáneamente
2. **Performance**: Confirmar que el tiempo de respuesta es < 1.5 segundos (percentil 95)
3. **Concurrencia**: Verificar que el mecanismo de bloqueo distribuido con Redis previene race conditions
4. **Integridad**: Asegurar que el inventario se actualiza correctamente sin inconsistencias

## Arquitectura

```
┌─────────────────┐
│   50 Usuarios   │
│   Concurrentes  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│    Booking Service (Flask)      │
│  - Bloqueo distribuido (Redis)  │
│  - PostgreSQL (booking_db)      │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│   Inventory Service (Flask)     │
│  - PostgreSQL (inventory_db)    │
└─────────────────────────────────┘

Redis: Distributed Locking
  - Key: lock:room:{room_id}:{date}
  - TTL: 10 segundos
  - Retry: 3 intentos con backoff exponencial
```

## Estructura del Proyecto

```
experimento/
├── inventory/              # Microservicio de Inventario
│   ├── app/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── models.py      # Room, Availability
│   │   └── routes.py      # API endpoints
│   ├── Dockerfile
│   ├── requirements.txt
│   └── init_db.py
│
├── booking/               # Microservicio de Reservas
│   ├── app/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── models.py      # Booking
│   │   ├── redis_lock.py  # Distributed locking
│   │   └── routes.py      # API endpoints
│   ├── Dockerfile
│   ├── requirements.txt
│   └── init_db.py
│
├── k8s/                   # Kubernetes Manifests
│   ├── namespace.yaml
│   ├── postgres/
│   ├── redis/
│   ├── inventory/
│   └── booking/
│
├── tests/                 # Scripts de Prueba
│   ├── concurrent_booking_test.py
│   ├── validation/
│   │   └── validate_results.py
│   ├── requirements.txt
│   ├── run_full_test.sh
│   └── run_full_test.bat
│
├── docker-compose.yml
└── README.md
```

## Despliegue

### Docker Compose (Desarrollo Local)

#### 1. Construir e iniciar servicios

```bash
cd experimento
docker-compose up -d --build
```
#### 2. Inicializar datos de prueba

```bash
# Inicializar inventario
docker-compose exec inventory-service python init_db.py

# Inicializar booking
docker-compose exec booking-service python init_db.py
```

#### 3. Verificar servicios

```bash
# Health check - Inventory
curl http://localhost:5001/api/health

# Health check - Booking
curl http://localhost:5002/api/health

# Listar habitaciones
curl http://localhost:5001/api/rooms
```

### Kubernetes 

#### 1. Construir imágenes Docker

```bash
cd experimento

# Inventory service
docker build -t inventory-service:latest ./inventory

# Booking service
docker build -t booking-service:latest ./booking
```

#### 2. Desplegar en Kubernetes

```bash
# Crear namespace
kubectl apply -f k8s/namespace.yaml

# Desplegar bases de datos
kubectl apply -f k8s/postgres/

# Desplegar Redis
kubectl apply -f k8s/redis/

# Esperar a que las bases de datos estén listas
kubectl wait --for=condition=ready pod -l app=inventory-db -n booking-experiment --timeout=120s
kubectl wait --for=condition=ready pod -l app=booking-db -n booking-experiment --timeout=120s

# Desplegar servicios
kubectl apply -f k8s/inventory/
kubectl apply -f k8s/booking/

# Verificar despliegue
kubectl get pods -n booking-experiment
```

#### 3. Inicializar datos

```bash
# Obtener nombre del pod de inventory
INVENTORY_POD=$(kubectl get pods -n booking-experiment -l app=inventory-service -o jsonpath='{.items[0].metadata.name}')

# Inicializar datos
kubectl exec -n booking-experiment $INVENTORY_POD -- python init_db.py

# Obtener nombre del pod de booking
BOOKING_POD=$(kubectl get pods -n booking-experiment -l app=booking-service -o jsonpath='{.items[0].metadata.name}')

# Inicializar datos
kubectl exec -n booking-experiment $BOOKING_POD -- python init_db.py
```

#### 4. Acceder a los servicios

```bash
# Port forward para acceso local
kubectl port-forward -n booking-experiment service/booking-service 5002:5002
kubectl port-forward -n booking-experiment service/inventory-service 5001:5001
```

## Ejecutar Pruebas de Concurrencia

### Instalación de dependencias de prueba

```bash
cd tests
pip install -r requirements.txt
```


### Ejecutar prueba completa

```bash
cd tests
chmod +x run_full_test.sh
./run_full_test.sh
```

### Parámetros de configuración

```bash
# Variables de entorno
export BOOKING_URL=http://localhost:5002/api
export NUM_USERS=50
export ROOM_ID=1
export CHECK_IN=2026-03-15
export CHECK_OUT=2026-03-17

# Ejecutar con configuración personalizada
python concurrent_booking_test.py \
    --url $BOOKING_URL \
    --users $NUM_USERS \
    --room-id $ROOM_ID \
    --check-in $CHECK_IN \
    --check-out $CHECK_OUT \
    --output results.json
```


## API Endpoints

### Inventory Service (Puerto 5001)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/rooms` | Listar habitaciones |
| GET | `/api/rooms/{id}` | Obtener habitación |
| GET | `/api/rooms/{id}/availability?date=YYYY-MM-DD` | Verificar disponibilidad |
| POST | `/api/rooms/{id}/reserve` | Reservar (decrementar) |
| POST | `/api/rooms/{id}/release` | Liberar (incrementar) |

### Booking Service (Puerto 5002)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| POST | `/api/bookings/confirm` | Confirmar reserva |
| GET | `/api/bookings/{id}` | Obtener reserva |
| GET | `/api/bookings/user/{user_id}` | Reservas por usuario |
| GET | `/api/bookings` | Todas las reservas |

