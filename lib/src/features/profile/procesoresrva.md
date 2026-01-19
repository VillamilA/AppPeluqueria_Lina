# 🛍️ Servicios, Categorías y Proceso de Reserva de Citas

**Fecha:** 15 de enero de 2026  
**Destinatario:** Equipo Frontend Flutter  
**Enfoque:** Estructura de servicios, categorías y cómo el cliente reserva una cita

---

## 📋 Tabla de Contenidos

1. [Servicios - Estructura y Datos](#servicios---estructura-y-datos)
2. [Categorías - Organización de Servicios](#categorías---organización-de-servicios)
3. [Relación Estilista → Servicios → Categorías](#relación-estilista--servicios--categorías)
4. [Proceso Completo de Reservar una Cita](#proceso-completo-de-reservar-una-cita)
5. [Estados y Validaciones](#estados-y-validaciones)
6. [Manejo de Errores](#manejo-de-errores)

---

## Servicios - Estructura y Datos

### 🔹 ¿Qué es un Servicio?

Un **servicio** es un tipo de trabajo que ofrece el estilista:
- Corte de cabello
- Peinado
- Tintura
- Tratamientos capilares
- Etc.

### 📊 Campos de la Colección `Service`

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `_id` | ObjectId | ✅ | ID único del servicio |
| `nombre` | String | ✅ | Nombre del servicio (ej: "Corte de Cabello") |
| `codigo` | String | ✅ | Código único (ej: "CORTE-01") - ÚNICO en BD |
| `descripcion` | String | ❌ | Descripción larga del servicio |
| `precio` | Number | ✅ | Precio en dólares (ej: 45.50) |
| `duracionMin` | Number | ✅ | Duración en minutos (ej: 60) |
| `activo` | Boolean | ✅ | Si está disponible o no |
| `createdAt` | Date | ✅ | Fecha de creación (automática) |
| `updatedAt` | Date | ✅ | Fecha de actualización (automática) |

### 📌 Endpoint: Listar Todos los Servicios

**Endpoint:**
```
GET /api/v1/services?limit=200&page=1
```

**Autenticación:** ❌ NO Requerida (Público)

**Parámetros Query:**
- `limit` (default: 20, max: 200): Servicios por página
- `page` (default: 1): Número de página

**Respuesta (200 OK):**
```json
{
  "data": [
    {
      "_id": "507f1f77bcf86cd799439014",
      "nombre": "Corte de Cabello Hombre",
      "codigo": "CORTE-HOMBRE-01",
      "descripcion": "Corte profesional para caballero con máquina y tijeras",
      "precio": 45.50,
      "duracionMin": 60,
      "activo": true,
      "createdAt": "2025-01-10T08:00:00.000Z",
      "updatedAt": "2025-01-10T08:00:00.000Z"
    },
    {
      "_id": "507f1f77bcf86cd799439015",
      "nombre": "Peinado Mujer",
      "codigo": "PEINADO-MUJER-01",
      "descripcion": "Peinado elegante para ocasión especial",
      "precio": 55.00,
      "duracionMin": 90,
      "activo": true,
      "createdAt": "2025-01-10T08:00:00.000Z",
      "updatedAt": "2025-01-10T08:00:00.000Z"
    },
    {
      "_id": "507f1f77bcf86cd799439016",
      "nombre": "Tintura",
      "codigo": "TINTURA-01",
      "descripcion": "Tintura profesional con técnica balayage",
      "precio": 75.00,
      "duracionMin": 120,
      "activo": true,
      "createdAt": "2025-01-10T08:00:00.000Z",
      "updatedAt": "2025-01-10T08:00:00.000Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 200,
    "total": 12
  }
}
```

---

## Categorías - Organización de Servicios

### 🔹 ¿Qué es una Categoría?

Una **categoría** es un grupo de servicios relacionados:
- Categoría "Cortes" → incluye varios tipos de cortes
- Categoría "Colorimetría" → incluye tinturas y decoloraciones
- Categoría "Tratamientos" → incluye tratamientos capilares

Cada categoría puede tener **múltiples servicios** y cada **servicio puede estar en varias categorías** (aunque actualmente es 1 a muchos).

### 📊 Campos de la Colección `Category`

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `_id` | ObjectId | ✅ | ID único de la categoría |
| `nombre` | String | ✅ | Nombre de la categoría (ej: "Cortes") - ÚNICO |
| `descripcion` | String | ❌ | Descripción de la categoría |
| `activo` | Boolean | ✅ | Si está disponible o no |
| `services` | ObjectId[] | ✅ | IDs de servicios en esta categoría |
| `createdAt` | Date | ✅ | Fecha de creación (automática) |
| `updatedAt` | Date | ✅ | Fecha de actualización (automática) |

### 📌 Endpoint: Listar Categorías

**Endpoint:**
```
GET /api/v1/catalogs?includeServices=true&limit=20&page=1
```

**Autenticación:** ❌ NO Requerida (Público)

**Parámetros Query:**
- `q` (string, optional): Buscar por nombre (case-insensitive)
- `active` (boolean, optional): Filtrar por activas/inactivas
- `includeServices` (boolean, default: false): Si incluir los servicios de cada categoría
- `limit` (default: 20, max: 200): Categorías por página
- `page` (default: 1): Número de página

**Respuesta (200 OK) - SIN servicios:**
```json
{
  "data": [
    {
      "_id": "507f1f77bcf86cd799439017",
      "nombre": "Cortes",
      "descripcion": "Diferentes tipos de cortes",
      "activo": true,
      "services": ["507f1f77bcf86cd799439014", "507f1f77bcf86cd799439015"]
    },
    {
      "_id": "507f1f77bcf86cd799439018",
      "nombre": "Colorimetría",
      "descripcion": "Servicios de color y tinturas",
      "activo": true,
      "services": ["507f1f77bcf86cd799439016"]
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 5
  }
}
```

**Respuesta (200 OK) - CON servicios (`includeServices=true`):**
```json
{
  "data": [
    {
      "_id": "507f1f77bcf86cd799439017",
      "nombre": "Cortes",
      "descripcion": "Diferentes tipos de cortes",
      "activo": true,
      "services": [
        {
          "_id": "507f1f77bcf86cd799439014",
          "nombre": "Corte de Cabello Hombre",
          "precio": 45.50,
          "duracionMin": 60,
          "activo": true
        },
        {
          "_id": "507f1f77bcf86cd799439015",
          "nombre": "Corte de Cabello Mujer",
          "precio": 50.00,
          "duracionMin": 60,
          "activo": true
        }
      ]
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 5
  }
}
```

### 📌 Endpoint: Obtener una Categoría Específica

**Endpoint:**
```
GET /api/v1/catalogs/{categoryId}?includeServices=true
```

**Autenticación:** ❌ NO Requerida (Público)

**Respuesta (200 OK):**
```json
{
  "_id": "507f1f77bcf86cd799439017",
  "nombre": "Cortes",
  "descripcion": "Diferentes tipos de cortes",
  "activo": true,
  "services": [
    {
      "_id": "507f1f77bcf86cd799439014",
      "nombre": "Corte de Cabello Hombre",
      "precio": 45.50,
      "duracionMin": 60,
      "activo": true
    }
  ]
}
```

---

## Relación Estilista → Servicios → Categorías

### 🔄 Cómo Funciona la Relación

```
┌─────────────────────────────────────────────────────┐
│ ESTILISTA (Juan Pérez)                              │
├─────────────────────────────────────────────────────┤
│ Catálogos Asignados:                                │
│  ├─ Categoría "Cortes"                              │
│  │  └─ Servicios:                                   │
│  │     ├─ Corte Hombre ($45.50, 60 min)            │
│  │     └─ Corte Mujer ($50.00, 60 min)             │
│  │                                                   │
│  ├─ Categoría "Colorimetría"                        │
│  │  └─ Servicios:                                   │
│  │     ├─ Tintura ($75.00, 120 min)                │
│  │     └─ Balayage ($85.00, 120 min)               │
│  │                                                   │
│  └─ Categoría "Tratamientos"                        │
│     └─ Servicios:                                   │
│        └─ Tratamiento Capilar ($65.00, 90 min)     │
│                                                     │
│ Total servicios ofrecidos: 5                        │
└─────────────────────────────────────────────────────┘
```

### 📌 Endpoint: Ver Catálogos de un Estilista

**Endpoint:**
```
GET /api/v1/stylists/{stylistId}/catalogs
```

**Autenticación:** ❌ NO Requerida (Público)

**Respuesta (200 OK):**
```json
{
  "stylist": {
    "id": "507f1f77bcf86cd799439013",
    "nombre": "Juan",
    "apellido": "Pérez"
  },
  "catalogs": [
    {
      "_id": "507f1f77bcf86cd799439017",
      "nombre": "Cortes",
      "descripcion": "Diferentes tipos de cortes",
      "activo": true,
      "services": [
        {
          "_id": "507f1f77bcf86cd799439014",
          "nombre": "Corte de Cabello Hombre",
          "precio": 45.50,
          "duracionMin": 60,
          "activo": true
        }
      ]
    }
  ]
}
```

### 📌 Endpoint: Ver Servicios de un Catálogo del Estilista

**Endpoint:**
```
GET /api/v1/stylists/{stylistId}/catalogs/{catalogId}/services
```

**Autenticación:** ❌ NO Requerida (Público)

**Respuesta (200 OK):**
```json
{
  "stylist": {
    "id": "507f1f77bcf86cd799439013",
    "nombre": "Juan",
    "apellido": "Pérez"
  },
  "catalog": {
    "id": "507f1f77bcf86cd799439017",
    "nombre": "Cortes",
    "descripcion": "Diferentes tipos de cortes",
    "services": [
      {
        "_id": "507f1f77bcf86cd799439014",
        "nombre": "Corte de Cabello Hombre",
        "precio": 45.50,
        "duracionMin": 60,
        "activo": true
      },
      {
        "_id": "507f1f77bcf86cd799439015",
        "nombre": "Corte de Cabello Mujer",
        "precio": 50.00,
        "duracionMin": 60,
        "activo": true
      }
    ]
  }
}
```

---

## Proceso Completo de Reservar una Cita

### 🎯 Resumen del Flujo

```
CLIENTE
  ↓
1️⃣  Abre la app
  ↓
2️⃣  Elige un SERVICIO (de la lista)
  ↓
3️⃣  Elige una FECHA
  ↓
4️⃣  Sistema muestra DISPONIBILIDAD (slots libres)
  ↓
5️⃣  Cliente elige HORA + ESTILISTA
  ↓
6️⃣  Cliente confirma reserva
  ↓
7️⃣  Se crea CITA en PENDING_STYLIST_CONFIRMATION
  ↓
8️⃣  ESTILISTA recibe notificación
  ↓
✅  CLIENTE espera confirmación del estilista
```

---

### 📝 Paso 1: Mostrar Servicios Disponibles

**Acción:** El cliente abre la app y ve lista de servicios

**Endpoint:**
```
GET /api/v1/services?limit=200&page=1
```

**Frontend debe:** 
- Guardar en **caché local** toda la lista de servicios
- Mostrar al cliente: nombre, precio, duración
- Permitir filtrar o buscar

**Ejemplo de pantalla:**
```
┌──────────────────────────────────┐
│ 🛍️  SERVICIOS DISPONIBLES       │
├──────────────────────────────────┤
│                                  │
│ Corte de Cabello Hombre          │
│ Precio: $45.50 | Duración: 60 min│
│ [Ver detalle] [Agendar]          │
│                                  │
│ Peinado Mujer                    │
│ Precio: $55.00 | Duración: 90 min│
│ [Ver detalle] [Agendar]          │
│                                  │
│ Tintura                          │
│ Precio: $75.00 | Duración: 120 min
│ [Ver detalle] [Agendar]          │
│                                  │
└──────────────────────────────────┘
```

---

### 📝 Paso 2: Cliente Elige Servicio y Fecha

**Acción:** Cliente toca "Agendar" en un servicio

**Datos capturados:**
- `servicioId`: ID del servicio elegido
- `fecha`: Fecha que eligió (YYYY-MM-DD)

**Ejemplo:**
- Servicio: "Corte de Cabello Hombre" (`507f1f77bcf86cd799439014`)
- Fecha: "2025-01-20"

---

### 📝 Paso 3: Obtener Disponibilidad (Horarios Libres)

**Acción:** Sistema consulta qué horas están disponibles

**Endpoint:**
```
GET /api/v1/bookings/availability?serviceId=507f1f77bcf86cd799439014&date=2025-01-20
```

**Parámetros Query:**
- `serviceId` (string, required): ID del servicio
- `date` (string, required): Fecha en YYYY-MM-DD
- `stylistId` (string, optional): Si quiere un estilista específico

**Respuesta (200 OK):**
```json
{
  "date": "2025-01-20",
  "serviceId": "507f1f77bcf86cd799439014",
  "slots": [
    {
      "slotId": "507f1f77bcf86cd799439020",
      "stylistId": "507f1f77bcf86cd799439013",
      "stylistName": "Juan Pérez",
      "start": "2025-01-20T09:00:00.000Z",
      "end": "2025-01-20T10:00:00.000Z"
    },
    {
      "slotId": "507f1f77bcf86cd799439021",
      "stylistId": "507f1f77bcf86cd799439013",
      "stylistName": "Juan Pérez",
      "start": "2025-01-20T10:30:00.000Z",
      "end": "2025-01-20T11:30:00.000Z"
    },
    {
      "slotId": "507f1f77bcf86cd799439022",
      "stylistId": "507f1f77bcf86cd799439014",
      "stylistName": "María García",
      "start": "2025-01-20T14:00:00.000Z",
      "end": "2025-01-20T15:00:00.000Z"
    }
  ]
}
```

**¿Qué significa cada campo?**

| Campo | Significado |
|-------|-------------|
| `slotId` | ID del horario (para enviar en la reserva) |
| `stylistId` | ID del estilista que ofrece este horario |
| `stylistName` | Nombre del estilista (para mostrar) |
| `start` | Hora de inicio (ISO 8601 en UTC) |
| `end` | Hora de finalización |

**Validaciones importantes:**
- ✅ Solo muestra horas futuras
- ✅ Solo muestra horas donde el estilista está disponible
- ✅ Solo muestra horas donde NO hay conflicto de citas
- ✅ Agrupa por estilista

---

### 📝 Paso 4: Cliente Elige Hora y Estilista

**Acción:** Cliente ve los slots disponibles y elige uno

**Ejemplo de pantalla:**
```
┌────────────────────────────────────┐
│ ELIGE HORARIO - 20 de enero 2025   │
├────────────────────────────────────┤
│                                    │
│ Juan Pérez                         │
│ ⭐⭐⭐⭐⭐ (4.8 / 5)              │
│ ✅ 09:00 - 10:00 [Agendar]        │
│ ✅ 10:30 - 11:30 [Agendar]        │
│                                    │
│ María García                       │
│ ⭐⭐⭐⭐ (4.5 / 5)               │
│ ✅ 14:00 - 15:00 [Agendar]        │
│                                    │
└────────────────────────────────────┘
```

**Datos capturados:**
- `slotId`: El horario elegido (ej: `507f1f77bcf86cd799439020`)
- `date`: La fecha (ej: `2025-01-20`)
- `notas`: Preferencias opcionales (ej: "No muy corto")

---

### 📝 Paso 5: Cliente Confirma la Reserva

**Acción:** Cliente toca el botón final de "Agendar" o "Confirmar reserva"

**Endpoint:**
```
POST /api/v1/bookings
```

**Autenticación:** ✅ Requerida (rol: CLIENTE, ADMIN, GERENTE)

**Body:**
```json
{
  "slotId": "507f1f77bcf86cd799439020",
  "date": "2025-01-20",
  "notas": "Preferencia: no muy corto"
}
```

O si elige múltiples horas (para servicios largos):
```json
{
  "slotIds": ["507f1f77bcf86cd799439020", "507f1f77bcf86cd799439021"],
  "date": "2025-01-20",
  "notas": "Preferencia: no muy corto"
}
```

**Parámetros:**
- `slotId` O `slotIds` (requerido): ID(s) del/los horario(s)
- `date` (string, requerido): Fecha YYYY-MM-DD
- `notas` (string, opcional): Preferencias del cliente (máximo 200 caracteres)

---

### 📝 Respuesta: Cita Creada

**Respuesta (201 Created):**
```json
{
  "count": 1,
  "bookings": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "clienteId": "507f1f77bcf86cd799439012",
      "estilistaId": "507f1f77bcf86cd799439013",
      "servicioId": "507f1f77bcf86cd799439014",
      "inicio": "2025-01-20T09:00:00.000Z",
      "fin": "2025-01-20T10:00:00.000Z",
      "estado": "PENDING_STYLIST_CONFIRMATION",
      "notas": "Preferencia: no muy corto",
      "precio": 45.50,
      "clienteAsistio": null,
      "paymentStatus": "UNPAID",
      "paymentMethod": null,
      "createdAt": "2025-01-18T14:30:00.000Z",
      "updatedAt": "2025-01-18T14:30:00.000Z"
    }
  ]
}
```

**Estados posibles del campo `estado`:**
- `PENDING_STYLIST_CONFIRMATION`: Esperando que el estilista confirme
- `CONFIRMED`: El estilista confirmó (después de 10 min se auto-cancela si no confirma)
- `COMPLETED`: El cliente asistió y terminó el servicio
- `NO_SHOW`: El cliente no asistió
- `CANCELLED`: Cancelada (por cliente, estilista, admin o auto-cancel)

---

### 📝 Efectos Secundarios Después de la Reserva

1. **Email al Cliente:**
   ```
   Asunto: Reserva registrada (pendiente)
   
   Tu reserva ha sido registrada y está PENDIENTE de confirmación.
   
   Detalles:
   - Servicio: Corte de Cabello Hombre
   - Estilista: Juan Pérez
   - Fecha y hora: 20 de enero 2025 - 09:00
   - Notas: Preferencia: no muy corto
   
   ⏳ El estilista tiene hasta 10 minutos después de la hora
      para confirmar. Si no confirma, se cancelará automáticamente.
   ```

2. **Email al Estilista:**
   ```
   Asunto: Tienes una nueva reserva PENDIENTE de confirmación
   
   Tienes una nueva reserva pendiente.
   
   Cliente: Nombre Cliente
   Servicio: Corte de Cabello Hombre
   Fecha y hora: 20 de enero 2025 - 09:00
   Notas: Preferencia: no muy corto
   
   Por favor confirma en tu app.
   ```

3. **Estado en la App del Cliente:**
   - La cita aparece como "PENDIENTE DE CONFIRMACIÓN" en color naranja
   - Muestra: estilista, servicio, fecha, hora
   - Botón para ver detalles o cancelar si lo desea

4. **Estado en la App del Estilista:**
   - Notificación push: "Tienes una nueva cita pendiente"
   - Cita aparece en sección "PENDIENTES" destacada en rojo
   - Botones: "Confirmar" o "Rechazar"

---

## Estados y Validaciones

### ✅ Validaciones al Reservar

El backend valida automáticamente:

1. **Cliente no congelado**
   - ❌ Error si cliente está congelado (por haber cancelado reciente)
   - Mensaje: "Cuenta temporalmente bloqueada para reservas"

2. **Slots válidos**
   - ✅ Slot debe existir
   - ✅ Slot debe estar activo
   - ✅ Estilista debe estar activo (role = ESTILISTA)
   - ✅ Servicio debe estar activo

3. **Fecha coincide con día del slot**
   - ✅ Ej: Si slot es de LUNES, fecha debe ser un LUNES
   - ❌ Error si no coincide

4. **No hay solapes**
   - ❌ Error si cliente ya tiene cita en ese horario
   - ❌ Error si estilista ya tiene cita en ese horario
   - ❌ Error si los slots se solapan entre sí

5. **Sin conflicto con citas manuales**
   - ❌ Error si hay cita manual (del admin) en ese horario

### 📊 Matriz de Estados

| Estado | Quién puede hacer qué | Duración |
|--------|----------------------|----------|
| `PENDING_STYLIST_CONFIRMATION` | ✅ Estilista: Confirmar o Cancelar | Máx 10 min después de hora inicio |
| | ✅ Cliente: Ver o Cancelar | |
| | ❌ Estilista: Marcar como completada | |
| `CONFIRMED` | ✅ Estilista: Marcar como completada | Hasta la hora fin |
| | ✅ Estilista: Cancelar | |
| | ✅ Cliente: Cancelar (con regla 12h) | |
| | ❌ Cambio de hora | |
| `COMPLETED` | ✅ Cliente: Calificar | |
| | ❌ Cambio de estado | |
| `NO_SHOW` | ❌ Todas las acciones | |
| `CANCELLED` | ❌ Todas las acciones | |

---

## Manejo de Errores

### ❌ Errores Comunes al Reservar

| Error | Motivo | Solución |
|-------|--------|----------|
| `400 - Debes enviar al menos un slot` | No envió `slotId` ni `slotIds` | Seleccionar un horario |
| `400 - Fecha inválida` | Formato de fecha incorrecto | Usar YYYY-MM-DD |
| `400 - Uno o más horarios no existen` | El slot fue eliminado | Recargar disponibilidad |
| `400 - Estilista no disponible` | Estilista está inactivo | Elegir otro estilista |
| `400 - Servicio no disponible` | Servicio está inactivo | Elegir otro servicio |
| `400 - La fecha no coincide con el día configurado` | Ej: slot es LUNES pero fecha es MARTES | Elegir fecha correcta |
| `409 - Ya tienes una reserva en ese horario` | Cliente tiene conflicto | Elegir otra hora |
| `409 - Horario no disponible` | Estilista tiene conflicto | Elegir otra hora |
| `403 - Cuenta temporalmente bloqueada` | Cliente fue congelado por cancelación | Esperar 24h o contactar soporte |
| `401 - No autenticado` | Sin JWT en headers | Iniciar sesión primero |

### 📝 Errores con Detalle

```json
{
  "statusCode": 400,
  "message": "Ya tienes una reserva en uno de los horarios seleccionados",
  "error": "Conflict"
}
```

---

## 🎯 Checklist para Frontend

### Implementación Mínima

- ✅ Endpoint GET `/api/v1/services` - obtener servicios (ejecutar UNA SOLA VEZ)
- ✅ Endpoint GET `/api/v1/bookings/availability` - obtener slots disponibles
- ✅ Endpoint POST `/api/v1/bookings` - crear reserva
- ✅ Mostrar lista de servicios con precio y duración
- ✅ Mostrar calendario/picker de fecha
- ✅ Mostrar disponibilidad (slots) para esa fecha/servicio
- ✅ Permitir seleccionar horario + estilista
- ✅ Mostrar confirmación antes de crear reserva
- ✅ Manejar errores y mostrar mensajes amigables

### Implementación Mejorada

- 🎁 Cachear servicios en localStorage
- 🎁 Filtrar servicios por categoría
- 🎁 Ver estilista (nombre, rating, catálogos)
- 🎁 Ver horarios disponibles por estilista
- 🎁 Guardar preferencias (nota)
- 🎁 Mostrar precio y duración confirmados
- 🎁 Notificar cuando la cita fue confirmada por estilista

---

## 📊 Diagrama Completo del Flujo

```
┌────────────────────────────────────────────────────────────────┐
│ 1️⃣  CLIENTE ABRE LA APP                                        │
│     ↓                                                           │
│     GET /api/v1/services?limit=200                             │
│     ← Recibe: Lista de servicios                               │
│     → Caché en localStorage (ejecutar 1 vez)                   │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ 2️⃣  CLIENTE SELECCIONA SERVICIO + FECHA                        │
│     ↓                                                           │
│     GET /api/v1/bookings/availability                          │
│        ?serviceId=507f...&date=2025-01-20                      │
│     ← Recibe: [slot1, slot2, slot3, ...]                       │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ 3️⃣  CLIENTE ELIGE HORARIO + ESTILISTA                          │
│     ↓                                                           │
│     Muestra opciones:                                          │
│     - Juan Pérez (09:00-10:00)                                 │
│     - Juan Pérez (10:30-11:30)                                 │
│     - María García (14:00-15:00)                               │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ 4️⃣  CLIENTE CONFIRMA RESERVA                                   │
│     ↓                                                           │
│     POST /api/v1/bookings                                      │
│     {                                                          │
│       "slotId": "507f1f77bcf86cd799439020",                   │
│       "date": "2025-01-20",                                    │
│       "notas": "No muy corto"                                  │
│     }                                                          │
│     ← Recibe: Booking en estado PENDING_STYLIST_CONFIRMATION   │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ 5️⃣  CITA CREADA EXITOSAMENTE                                   │
│     ↓                                                           │
│     ✅ Email al cliente: "Reserva registrada (pendiente)"      │
│     ✅ Email al estilista: "Tienes una reserva pendiente"      │
│     ✅ Estado: PENDING_STYLIST_CONFIRMATION                    │
│     ✅ Auto-cancela en 10 min si no confirma                   │
└────────────────────────────────────────────────────────────────┘
                              ↓
        CLIENTE ESPERA CONFIRMACIÓN DEL ESTILISTA
```

---

**Documento generado:** 15 de enero de 2026  
**Versión:** 1.0  
**Estado:** ✅ Guía Completa del Proceso de Reserva
