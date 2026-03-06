# Pruebas de Concurrencia con JMeter

## 📋 Requisitos

1. **Descargar JMeter**: https://jmeter.apache.org/download_jmeter.cgi
2. Extraer el archivo ZIP
3. Java 8+ instalado

## 🚀 Ejecutar Pruebas

### Opción 1: Modo GUI (Recomendado para Desarrollo)

```powershell
# Navegar al directorio de JMeter
cd C:\path\to\apache-jmeter-5.x\bin

# Abrir JMeter GUI
.\jmeter.bat

# En JMeter:
# 1. File > Open
# 2. Seleccionar: booking-concurrency-test.jmx
# 3. Click en el botón verde "Start" (▶)
```

### Opción 2: Modo CLI (Recomendado para Producción)

```powershell
# Desde el directorio de tests
cd C:\Users\ronal\Documents\proyectoandes\Proyecto-Final-Grupo-11\experimento\tests

# Ejecutar prueba
C:\path\to\apache-jmeter-5.x\bin\jmeter.bat -n -t booking-concurrency-test.jmx -l results.jtl -e -o report

# Parámetros:
# -n: Modo no-GUI
# -t: Archivo de prueba
# -l: Archivo de resultados
# -e: Generar reporte HTML
# -o: Carpeta de salida del reporte
```

## 🎯 Configuración de la Prueba

El archivo `booking-concurrency-test.jmx` está configurado con:

- **Usuarios concurrentes**: 50
- **Ramp-up time**: 1 segundo (todos los usuarios inician casi simultáneamente)
- **Iteraciones**: 1 por usuario
- **Endpoint**: POST /api/bookings
- **Habitación**: Room ID 1 (Standard, solo 1 disponible)
- **Fechas**: 2026-03-15 a 2026-03-17

### Variables Configurables

Puedes modificar estas variables en el Test Plan:

| Variable | Valor por Defecto | Descripción |
|----------|-------------------|-------------|
| BASE_URL | http://booking-experiment-dev-alb-237248982.us-east-1.elb.amazonaws.com:5002 | URL del servicio de booking |
| ROOM_ID | 1 | ID de la habitación a reservar |
| CHECK_IN | 2026-03-15 | Fecha de check-in |
| CHECK_OUT | 2026-03-17 | Fecha de check-out |

### Modificar Número de Usuarios

En JMeter GUI:
1. Click en "Concurrent Booking Users" (Thread Group)
2. Cambiar "Number of Threads (users)" al valor deseado
3. Ajustar "Ramp-up period" si es necesario

## 📊 Interpretar Resultados

### Summary Report

Muestra estadísticas agregadas:
- **# Samples**: Total de requests (debe ser = número de usuarios)
- **Average**: Tiempo promedio de respuesta
- **Min/Max**: Tiempos mínimo y máximo
- **Error %**: Porcentaje de errores HTTP
- **Throughput**: Requests por segundo

### View Results Tree

Muestra cada request individual con:
- **Response Code**: 200 (éxito), 400 (sin disponibilidad), 500 (error)
- **Response Data**: JSON con resultado de la reserva

### Resultados Esperados

Para Room ID 1 (1 habitación disponible):
- **1 request exitoso**: `{"success": true, "booking_id": X}`
- **49 requests fallidos**: `{"success": false, "error": "No availability"}`

## 🔍 Validación Post-Prueba

Después de ejecutar las pruebas, verifica:

```powershell
# Ver todas las reservas creadas
curl.exe "http://booking-experiment-dev-alb-237248982.us-east-1.elb.amazonaws.com:5002/api/bookings"

# Debería mostrar SOLO 1 reserva para las fechas 2026-03-15 a 2026-03-17
```

## 📈 Pruebas Adicionales

### Prueba con Habitación de Mayor Capacidad

Para probar con Room ID 2 (2 habitaciones disponibles):

1. En JMeter, cambiar variable `ROOM_ID` a `2`
2. Ejecutar prueba
3. Resultado esperado: 2 reservas exitosas, 48 fallidas

### Prueba de Estrés

Para probar con más usuarios:

```powershell
# Modo CLI con 100 usuarios
jmeter.bat -n -t booking-concurrency-test.jmx -l results-100.jtl -JNUM_THREADS=100
```

## 🐛 Troubleshooting

### Error: Connection Refused

- Verificar que los servicios ECS estén running
- Verificar que el ALB esté accesible
- Verificar que la URL en BASE_URL sea correcta

### Error: Timeout

- Aumentar timeout en HTTP Request Sampler
- Verificar logs de ECS para ver si hay errores

### Todos los Requests Fallan

- Verificar que la habitación exista: `curl.exe "http://...:5001/api/rooms"`
- Verificar que las fechas sean futuras
- Verificar formato de fechas (YYYY-MM-DD)

## 📝 Generar Reporte HTML

```powershell
# Después de ejecutar en modo CLI
# El reporte se genera automáticamente en la carpeta 'report'
# Abrir: report/index.html en el navegador
```

El reporte incluye:
- Dashboard con gráficos
- Estadísticas detalladas
- Gráficos de tiempo de respuesta
- Distribución de errores
