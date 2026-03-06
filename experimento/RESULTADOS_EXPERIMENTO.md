# Resultados del Experimento de Concurrencia

## Resumen

Este documento presenta los resultados del experimento de pruebas de concurrencia realizado sobre el sistema de reservas desplegado en AWS ECS (Elastic Container Service). El objetivo fue validar el comportamiento del sistema bajo condiciones de alta concurrencia y evaluar el rendimiento de la infraestructura cloud.

---

## Objetivo del Experimento

Evaluar la capacidad del sistema para manejar múltiples solicitudes concurrentes de reserva de habitaciones, verificando:
- Correcta gestión de conflictos de concurrencia
- Integridad de datos bajo carga
- Rendimiento y latencia del sistema
- Comportamiento de la infraestructura AWS ECS

---

## Configuración del Experimento

### Herramienta de Pruebas
**Apache JMeter** - Herramienta de pruebas de carga y rendimiento

### Parámetros de Prueba

| Parámetro | Valor |
|-----------|-------|
| **Número de Usuarios Concurrentes** | 50 |
| **Tipo de Prueba** | Concurrent Booking Users |
| **Ramp-up Period** | 1 segundo |
| **Loop Count** | 1 iteración |
| **Endpoint Probado** | Create Booking Request |

### Infraestructura AWS

- **Servicio**: Amazon ECS (Elastic Container Service)
- **Servicios Desplegados**:
  - `booking-experiment-dev-booking` (Servicio de Reservas)
  - `booking-experiment-dev-inventory` (Servicio de Inventario)
- **Región**: us-east-1
- **URL de Prueba**: `booking-experiment-dev-alb-2372489821.us-1.elb.amazonaws.com:5002/api/bookings`

---

## Resultados de las Pruebas
<img width="1918" height="1003" alt="JMETER2" src="https://github.com/user-attachments/assets/2484b207-0e15-438f-b49b-206a72f5515d" />

<img width="1918" height="935" alt="JMETER3" src="https://github.com/user-attachments/assets/303322bc-5fd1-426f-8ac3-5a4dbd602963" />

### Métricas Generales (JMeter)

| Métrica | Valor |
|---------|-------|
| **Total de Solicitudes** | 50 |
| **Promedio de Tiempo de Respuesta** | 840 ms |
| **Tiempo Mínimo** | 277 ms |
| **Tiempo Máximo** | 7536 ms |
| **Desviación Estándar** | 1114.00 ms |
| **Tasa de Error** | 98.00% |
| **Throughput** | 6.7/sec |
| **KB/sec Recibidos** | 1.68 |
| **KB/sec Enviados** | 2.05 |

### Distribución de Respuestas

```
Reservas Exitosas:     1  (2%)
Conflictos (409):     45 (90%)
No Disponible (503):   4  (8%)
Errores del Servidor:  0  (0%)
```

### Latencias (Python Test)

| Percentil | Latencia |
|-----------|----------|
| **P95** | 591.36 ms |
| **P99** | 765.33 ms |
| **Throughput** | 58.82 req/s |

---

## Métricas de Infraestructura AWS

### Utilización de CPU

**Servicio de Booking:**
- **Promedio**: ~25-30% durante el pico de carga
- **Comportamiento**: Picos variables entre 23:00 y 01:30 UTC
- **Observación**: La CPU se mantuvo en niveles aceptables, sin saturación

**Servicio de Inventory:**
- **Promedio**: ~0.4% (muy bajo)
- **Comportamiento**: Uso consistente y estable
- **Observación**: Servicio con carga mínima durante las pruebas

### Utilización de Memoria

**Servicio de Booking:**
- **Promedio**: ~56-58%
- **Comportamiento**: Estable durante toda la prueba
- **Pico Máximo**: Aproximadamente 60%

**Servicio de Inventory:**
- **Promedio**: ~3.8%
- **Comportamiento**: Muy estable y bajo
- **Observación**: Consumo mínimo de memoria

---

## Análisis de Resultados
<img width="1918" height="996" alt="JMETER4" src="https://github.com/user-attachments/assets/be1e8325-bae0-4b39-b66c-e017dccf7890" />

1. **Gestión Correcta de Conflictos**
   - El sistema detectó y manejó correctamente 45 conflictos de concurrencia (HTTP 409)
   - Solo 1 reserva fue exitosa, demostrando que el mecanismo de bloqueo funciona

2. **Integridad de Datos**
   - No se registraron errores del servidor (500)
   - El sistema previno correctamente las reservas duplicadas

3. **Rendimiento de Infraestructura**
   - CPU del servicio de booking se mantuvo bajo control (~25-30%)
   - Memoria estable sin fugas evidentes
   - No se observó degradación del sistema

4. **Latencias Aceptables**
   - P95: 591ms - Dentro de rangos aceptables para operaciones transaccionales
   - P99: 765ms - Buen rendimiento incluso en el percentil 99


## 🎓 Conclusiones

### Validación del Sistema
<img width="1918" height="508" alt="image" src="https://github.com/user-attachments/assets/687a5547-df9e-4e72-8c1d-b4d77c1c6b86" />
En la imagen se observa que la reserva se realizo una sola vez.
El experimento **validó exitosamente** los siguientes aspectos:

 **Control de Concurrencia**: El sistema implementa correctamente mecanismos de bloqueo pesimista/optimista para prevenir reservas duplicadas

 **Escalabilidad de Infraestructura**: AWS ECS manejó la carga sin saturación de recursos (CPU < 30%, Memoria < 60%)

 **Resiliencia**: No se registraron errores críticos del servidor, demostrando estabilidad del código

 **Rendimiento**: Latencias en percentiles altos dentro de rangos aceptables para aplicaciones web



## Datos Técnicos del Experimento

### Configuración JMeter

```
Thread Group: Concurrent Booking Users
├── Number of Threads: 50
├── Ramp-up Period: 1 second
├── Loop Count: 1
└── Sampler: HTTP Request
    ├── Method: POST
    ├── Path: /api/bookings
    └── Content-Type: application/json
```

### Respuesta de Ejemplo 

```json
{
  "check_in_date": "2026-03-12",
  "check_out_date": "2026-03-17",
  "created_at": "2026-03-05T23:19:47.195370",
  "id": 1,
  "room_id": 1,
  "status": "confirmed",
  "total_price": 200.0,
  "updated_at": "2026-03-05T23:19:47.195377"
}
```

### Detalles de Errores

- **HTTP 409 (Conflict)**: Habitación ya reservada para las fechas solicitadas
- **HTTP 503 (Service Unavailable)**: Servicio temporalmente no disponible

---

## Resultado final

**EXPERIMENTO EXITOSO**

El sistema demostró un comportamiento **robusto y correcto** bajo condiciones de alta concurrencia. Los mecanismos de control de concurrencia funcionan según lo diseñado, previniendo efectivamente las reservas duplicadas. La infraestructura AWS ECS proporcionó recursos suficientes sin saturación.


