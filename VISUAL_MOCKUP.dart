// VISUAL MOCKUP - SCHEDULE MANAGEMENT PAGE
// ============================================================

/*

┌────────────────────────────────────────────────────────────┐
│                  📱 PANTALLA: GESTIONAR HORARIOS            │
│                                                              │
│ ◀  Gestionar Horarios                              [≡]      │
└────────────────────────────────────────────────────────────┘

╔════════════════════════════════════════════════════════════╗
║ 📅 TURNO SEMANAL                                           ║
║ Define el horario base para cada día de la semana         ║
╠════════════════════════════════════════════════════════════╣
║                                                              ║
║ [⊙] DOMINGO       09:00  a  18:00  ✓                       ║
║ ├─ Color: Gris si deshabilitado                           ║
║ └─ Al tocar picker: Abre time picker                      ║
║                                                              ║
║ [⊙] LUNES         09:00  a  18:00  ✓                       ║
║ [⊙] MARTES        09:00  a  18:00  ✓                       ║
║ [⊙] MIÉRCOLES     09:00  a  18:00  ✓                       ║
║ [⊙] JUEVES        09:00  a  18:00  ✓                       ║
║ [⊙] VIERNES       09:00  a  18:00  ✓                       ║
║ [⊙] SÁBADO        09:00  a  18:00  ✓                       ║
║                                                              ║
║ Tokens:                                                     ║
║ ⊙  = Toggle switch (SwiftUI-like)                          ║
║ 09:00 = Time picker button                                 ║
║ a   = Texto separador                                      ║
║ ✓  = Botón guardar (gradient oro)                          ║
║                                                              ║
╚════════════════════════════════════════════════════════════╝

╔════════════════════════════════════════════════════════════╗
║ 📋 GENERAR DISPONIBILIDAD REAL                             ║
║ Crea espacios disponibles para que clientes reserven      ║
╠════════════════════════════════════════════════════════════╣
║                                                              ║
║ Fecha a generar:                                           ║
║ ┌──────────────────────────────┐                           ║
║ │ 📅  12/01/2026               │  ← GestureDetector         ║
║ └──────────────────────────────┘                           ║
║                                                              ║
║ Servicio:                                                  ║
║ ┌──────────────────────────────┐                           ║
║ │ ✂️  Peinado Niña (30 min) ▼   │  ← Dropdown (placeholder)║
║ └──────────────────────────────┘                           ║
║                                                              ║
║ ┌──────────────────────────────┐                           ║
║ │ + Generar Espacios Disponibles│                           ║
║ │   (Fondo gradient oro)         │ ← Material InkWell       ║
║ └──────────────────────────────┘                           ║
║                                                              ║
╚════════════════════════════════════════════════════════════╝

╔════════════════════════════════════════════════════════════╗
║ Espacios generados para 2026-01-12                         ║
╠════════════════════════════════════════════════════════════╣
║                                                              ║
║ ┌──────────────────────────────┐                           ║
║ │ 🕐  09:00 - 10:00  [Disponib]│                           ║
║ └──────────────────────────────┘                           ║
║                                                              ║
║ ┌──────────────────────────────┐                           ║
║ │ 🕐  10:00 - 11:00  [Disponib]│                           ║
║ └──────────────────────────────┘                           ║
║                                                              ║
║ ┌──────────────────────────────┐                           ║
║ │ 🕐  11:00 - 12:00  [Disponib]│                           ║
║ └──────────────────────────────┘                           ║
║                                                              ║
║ ┌──────────────────────────────┐                           ║
║ │ 🕐  14:00 - 15:00  [Disponib]│                           ║
║ └──────────────────────────────┘                           ║
║                                                              ║
║ ┌──────────────────────────────┐                           ║
║ │ 🕐  15:00 - 16:00  [Disponib]│                           ║
║ └──────────────────────────────┘                           ║
║                                                              ║
║ (Generados automáticamente cada 30 min según servicio)     ║
║                                                              ║
╚════════════════════════════════════════════════════════════╝

                             [Desplazable hacia arriba]

┌────────────────────────────────────────────────────────────┐
│ 🏠 Inicio | 📅 Citas | 🕐 Horarios | ✂️ Servicios | 👤     │
└────────────────────────────────────────────────────────────┘
  (Gradient dorado con iconos negros)

═══════════════════════════════════════════════════════════════

COLORES UTILIZADOS:

  Fondo principal:      AppColors.charcoal (Negro muy oscuro)
  Accent:              AppColors.gold (Dorado)
  Textos principales:  Colors.white
  Textos secundarios:  AppColors.gray
  Texto disabled:      Colors.grey.shade700
  Bordes:              AppColors.gold.withOpacity(0.2-0.35)
  Fondo cards:         Colors.grey.shade900 o Colors.black.withOpacity()
  Gradient buttons:    LinearGradient(AppColors.gold → AppColors.gold.withOpacity(0.8))
  Shadow:              AppColors.gold.withOpacity(0.1-0.3)

═══════════════════════════════════════════════════════════════

INTERACCIONES:

1. Toggle Día:
   [⊙] → Tap → Cambio en _dayEnabled[dayIndex]
   Si OFF: Textos grises, inputs deshabilitados
   Si ON: Textos blancos, inputs activos

2. Time Picker:
   Tap en "09:00" → showTimePicker() → Selector de horas
   Resultado guardado en _dayStartTime[dayIndex]
   
3. Guardar Día:
   Tap ✓ → _saveSchedule(dayIndex)
   → PUT /api/v1/schedules/stylist
   → SnackBar "Horario guardado: Lunes"

4. Date Picker:
   Tap fecha → showDatePicker()
   Min: Hoy, Max: +90 días
   Guardado en _selectedDate

5. Service Dropdown:
   Tap servicio → Muestra lista (TODO: implementar)
   Guardado en _selectedServiceId

6. Generar Slots:
   Tap botón → _generateSlots()
   → POST /api/v1/slots/day
   → Respuesta con slots generados
   → ListView con los slots

═══════════════════════════════════════════════════════════════

ANIMACIONES Y TRANSICIONES:

✓ Transform.scale(0.8) en toggles para verlos más pequeños
✓ InkWell en botones para efecto ripple
✓ Container con border para inputs
✓ GestureDetector para seleccionables
✓ LinearGradient en buttons
✓ BoxShadow para profundidad
✓ BorderRadius para suavidad

═══════════════════════════════════════════════════════════════

RESPONSIVE:

- Small Phone (< 360px):
  * Padding reducido
  * Fonts más pequeñas
  * Espaciados ajustados

- Phone (360-600px):
  * Padding normal
  * Fonts medianas
  * Layout full width

- Tablet (600-900px):
  * Padding mayor
  * Fonts más grandes
  * Elementos separados

- Desktop (> 900px):
  * Padding máximo
  * Layout en columnas
  * Sidebar posible

═══════════════════════════════════════════════════════════════

KEYBOARD BEHAVIOR:

- Time picker: No abre teclado (custom UI)
- Date picker: Usa calendar picker (no teclado)
- ScrollView: BouncingScrollPhysics para iOS feel
- FocusNode: Automático (no necesita manual)

═══════════════════════════════════════════════════════════════

ACCESSIBILITY:

✓ Sufficiently contrasted text
✓ Touch targets > 48x48 dp
✓ Labels for all inputs
✓ Icons + text combinations
✓ Error messages clear
✓ Focus states visible

═══════════════════════════════════════════════════════════════

EMPTY STATES:

✓ Si no hay servicios: "Selecciona servicio"
✓ Si no hay fecha: "Selecciona fecha"
✓ Si no hay slots: No mostrar sección
✓ Mensajes amigables en gris

═══════════════════════════════════════════════════════════════

LOADING STATES (TODO - Optional):

⏳ Mientras guarda schedule:
   - Botón ✓ deshabilitado
   - CircularProgressIndicator small

⏳ Mientras genera slots:
   - Botón grande "Generando..."
   - CircularProgressIndicator full

═══════════════════════════════════════════════════════════════

ERROR MESSAGES (SnackBar):

❌ "Error: El horario no está configurado para Lunes"
❌ "Error al guardar horario"
❌ "Error al generar slots"
❌ "Selecciona servicio y fecha"

✅ "Horario guardado: Lunes"
✅ "15 espacios generados"

═══════════════════════════════════════════════════════════════

*/
