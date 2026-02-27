# Guía de Pruebas de Concurrencia

## 📋 Descripción

Scripts de prueba para validar el comportamiento del sistema bajo condiciones de concurrencia extrema.

## 🧪 Scripts Disponibles

### 1. `concurrent_booking_test.py`

Script principal que simula múltiples usuarios intentando reservar la misma habitación simultáneamente.

**Uso:**

```bash
python concurrent_booking_test.py \
    --url http://localhost:5002/api \
    --users 50 \
    --room-id 1 \
    --check-in 2026-03-15 \
    --check-out 2026-03-17 \
    --output results.json
```

**Parámetros:**

- `--url`: URL del servicio de booking (default: http://localhost:5002/api)
- `--users`: Número de usuarios concurrentes (default: 50)
- `--room-id`: ID de la habitación a reservar (default: 1)
- `--check-in`: Fecha de check-in YYYY-MM-DD (default: mañana)
- `--check-out`: Fecha de check-out YYYY-MM-DD (default: pasado mañana)
- `--output`: Archivo de salida JSON (default: test_results.json)

**Salida:**

- Reporte en consola con métricas detalladas
- Archivo JSON con resultados completos
- Validación automática de criterios de éxito

### 2. `validation/validate_results.py`

Script de validación que verifica la consistencia de datos en las bases de datos después de la prueba.

**Uso:**

```bash
python validation/validate_results.py \
    --room-id 1 \
    --check-in 2026-03-15 \
    --booking-host localhost \
    --booking-port 5433 \
    --inventory-host localhost \
    --inventory-port 5432
```

**Parámetros:**

- `--room-id`: ID de la habitación (requerido)
- `--check-in`: Fecha de check-in (requerido)
- `--booking-host`: Host de booking DB (default: localhost)
- `--booking-port`: Puerto de booking DB (default: 5433)
- `--booking-db`: Nombre de booking DB (default: booking_db)
- `--booking-user`: Usuario de booking DB (default: booking_user)
- `--booking-password`: Password de booking DB (default: booking_pass)
- `--inventory-host`: Host de inventory DB (default: localhost)
- `--inventory-port`: Puerto de inventory DB (default: 5432)
- `--inventory-db`: Nombre de inventory DB (default: inventory_db)
- `--inventory-user`: Usuario de inventory DB (default: inventory_user)
- `--inventory-password`: Password de inventory DB (default: inventory_pass)

**Validaciones:**

1. Solo 1 reserva confirmada
2. Múltiples intentos de reserva registrados
3. Inventario consistente con reservas
4. Sin reservas duplicadas por usuario

### 3. `run_full_test.sh` / `run_full_test.bat`

Scripts que ejecutan el flujo completo de pruebas:
1. Prueba de concurrencia
2. Validación de base de datos
3. Reporte de resultados

**Uso (Windows):**

```bash
run_full_test.bat
```

**Uso (Linux/Mac):**

```bash
chmod +x run_full_test.sh
./run_full_test.sh
```

**Variables de Entorno:**

```bash
export BOOKING_URL=http://localhost:5002/api
export NUM_USERS=50
export ROOM_ID=1
export CHECK_IN=2026-03-15
export CHECK_OUT=2026-03-17
```

## 📊 Interpretación de Resultados

### Métricas Clave

1. **Total Requests**: Debe ser igual al número de usuarios
2. **Successful Bookings**: Debe ser exactamente 1
3. **Failed Bookings**: Debe ser (usuarios - 1)
4. **95th Percentile Response Time**: Debe ser < 1.5s

### Códigos de Estado Esperados

- `201 Created`: 1 request (reserva exitosa)
- `409 Conflict`: 49 requests (sin disponibilidad)
- `503 Service Unavailable`: 0 requests (idealmente, indica problema con locks)

### Ejemplo de Salida Exitosa

```
================================================================================
TEST RESULTS ANALYSIS
================================================================================

Total Requests: 50
Successful Bookings (201): 1
Failed Bookings: 49

Status Code Distribution:
  201: 1 requests
  409: 49 requests

================================================================================
PERFORMANCE METRICS
================================================================================

Response Time Statistics:
  Min: 0.123s
  Max: 1.456s
  Average: 0.567s
  95th Percentile: 1.234s

================================================================================
VALIDATION CRITERIA
================================================================================

✓ Only 1 successful booking: PASS
✓ 95th percentile < 1.5s: PASS
✓ Correct number of failures: PASS

================================================================================
OVERALL RESULT: ✓ PASS
================================================================================
```

## 🔧 Troubleshooting

### Error: Connection Refused

```bash
# Verificar que los servicios estén corriendo
curl http://localhost:5002/api/health
curl http://localhost:5001/api/health

# Si usan Docker Compose
docker-compose ps
```

### Error: Múltiples Reservas Exitosas

Indica problema con el mecanismo de bloqueo:

```bash
# Verificar Redis
docker-compose exec redis redis-cli ping

# Ver locks activos
docker-compose exec redis redis-cli KEYS "lock:*"

# Revisar logs del servicio de booking
docker-compose logs booking-service
```

### Error: Tiempos de Respuesta Altos

```bash
# Verificar carga del sistema
docker stats

# Revisar logs para identificar cuellos de botella
docker-compose logs -f booking-service
docker-compose logs -f inventory-service
```

### Error: Database Connection Failed

```bash
# Verificar bases de datos
docker-compose exec booking-db pg_isready -U booking_user
docker-compose exec inventory-db pg_isready -U inventory_user

# Verificar credenciales en el script
python validation/validate_results.py --help
```

## 📈 Escenarios de Prueba Recomendados

### Escenario 1: Carga Baja (10 usuarios)

```bash
python concurrent_booking_test.py --users 10 --room-id 1
```

**Objetivo**: Validar funcionamiento básico

### Escenario 2: Carga Media (50 usuarios)

```bash
python concurrent_booking_test.py --users 50 --room-id 1
```

**Objetivo**: Validar historia de usuario (caso base)

### Escenario 3: Carga Alta (100 usuarios)

```bash
python concurrent_booking_test.py --users 100 --room-id 1
```

**Objetivo**: Stress test del sistema

### Escenario 4: Habitación con Mayor Capacidad

```bash
python concurrent_booking_test.py --users 50 --room-id 2
```

**Objetivo**: Validar con room que tiene `total_quantity=2`

### Escenario 5: Múltiples Fechas

```bash
# Fecha 1
python concurrent_booking_test.py --check-in 2026-03-15 --check-out 2026-03-17

# Fecha 2
python concurrent_booking_test.py --check-in 2026-03-20 --check-out 2026-03-22
```

**Objetivo**: Validar que locks son independientes por fecha

## 📝 Notas Importantes

1. **Limpieza entre pruebas**: Considerar limpiar la base de datos entre pruebas para resultados consistentes
2. **Datos de prueba**: Asegurar que la habitación tenga disponibilidad antes de cada prueba
3. **Concurrencia real**: Los threads de Python simulan concurrencia, pero están limitados por el GIL
4. **Network latency**: En entornos de red real, los tiempos pueden variar

## 🎯 Criterios de Aceptación

Para que el experimento sea exitoso:

- [x] Solo 1 reserva confirmada
- [x] 95% de requests < 1.5s
- [x] Sin errores de timeout
- [x] Inventario consistente
- [x] Sin reservas duplicadas
- [x] Locks liberados correctamente

## 📦 Dependencias

```bash
pip install -r requirements.txt
```

Incluye:
- `requests`: Para hacer HTTP requests
- `psycopg2-binary`: Para conectar a PostgreSQL
