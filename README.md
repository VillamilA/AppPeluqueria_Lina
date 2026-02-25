# Peluquería Lina - Aplicación Móvil

**Desarrollado por:** Angel Vilamil   [![Descargar](https://img.shields.io/badge/Descargar-Itch.io-red?style=for-the-badge)](https://avillamil.itch.io/lina-peluqueria)

**Fecha de Actualización:** Enero 2026

---

## 📱 Descripción General

Aplicación móvil completa de gestión para salón de belleza "Peluquería Lina", desarrollada en Flutter. Permite a clientes realizar reservas de citas, a estilistas gestionar su agenda y horarios, y a gerentes administrar toda la operación del negocio.

---

## ✨ Características Principales

### Para Clientes
- **Búsqueda y Reservas**: Explorar servicios disponibles y reservar citas con estilistas
- **Gestión de Citas**: Ver historial de reservas, cancelar o reagendar citas
- **Selección Flexible**: Elegir estilista específico o cualquiera disponible
- **Notificaciones**: Recordatorios automáticos de citas próximas
- **Categorías de Servicios**: Explorar servicios organizados por categoría (ej: Cortes, Coloración, Tratamientos)

### Para Estilistas
- **Dashboard Personalizado**: Ver citas del día, semana y estadísticas
- **Disponibilidad**: Gestionar horarios laborales y días de descanso
- **Calificaciones**: Monitorear valoraciones de clientes
- **Historial**: Registro completo de citas realizadas

### Para Gerentes
- **Administración Completa**: CRUD de servicios, estilistas, clientes y gerentes
- **✨ Gestión de Servicios y Categorías**: Crear, editar, eliminar servicios y categorías
- **✨ Relación Servicios-Categorías**: Gestionar qué servicios pertenecen a cada categoría
- **Reportes**: Estadísticas de ingresos, ocupación y desempeño
- **Validación de Datos**: Control de calidad en toda la información del sistema
- **Gestión de Acceso**: Control de permisos por rol

---

## 🛠️ Tecnología

- **Framework**: Flutter 3.9.2
- **Lenguaje**: Dart
- **Arquitectura**: Clean Architecture con patrones MVVM
- **Almacenamiento Seguro**: Flutter Secure Storage
- **Mapas**: Flutter Map con Geolocator
- **Gráficos**: FL Chart para reportes
- **Notificaciones**: Flutter Local Notifications
- **Autenticación**: JWT Token-based

---

## 📋 Módulos del Sistema

### Autenticación
- Login con email/contraseña
- Registro de nuevos usuarios
- Recuperación de contraseña con código de verificación
- Sistema de roles (Cliente, Estilista, Gerente)

### Flujo de Reservas
- Selección de servicio
- Búsqueda de disponibilidad por estilista
- Selección de fecha y hora
- Confirmación y pago

### Gestión de Datos
- Servicios: Crear, editar, listar, eliminar
- Estilistas: Perfiles, horarios, disponibilidad
- Clientes: Información de contacto, historial
- Citas: Reservas, cancelaciones, reagendamientos

### Seguridad
- Validación de formularios en tiempo real
- Restricción de caracteres por campo
- Alertas claras para errores
- Protección contra spam de solicitudes

---

## ✅ Estado Actual

### Funcionalidad Completada
- ✅ Sistema de autenticación completo
- ✅ Flujo de reservas de citas
- ✅ Dashboard de estilista con estadísticas
- ✅ Gestión administrativa de servicios
- ✅ Validaciones de formularios
- ✅ Recuperación de contraseña con alertas mejoradas
- ✅ Interfaz responsive sin overflows
- ✅ Sistema de notificaciones

### Últimas Mejoras
- Corrección de carga de slots disponibles (API endpoint)
- Eliminación de overflow en dashboard (28px issue)
- Implementación de validadores reutilizables
- Mejora en alertas de recuperación de contraseña
- Contador de espera en reenvío de código (90 segundos)

---

## 🎨 Diseño y UX

- **Tema**: Charcoal (#181818) + Gold (#FFC93C)
- **Tipografía**: Material Design 3
- **Responsividad**: Compatible con todos los tamaños de pantalla
- **Accesibilidad**: Iconos claramente etiquetados, contraste adecuado
- **Feedback Visual**: Spinners, mensajes de estado, animaciones

---

## 📦 Estructura del Proyecto

```
lib/
├── main.dart
├── core/
│   ├── theme/
│   ├── utils/
│   └── constants/
├── data/
│   ├── services/
│   └── models/
└── src/
    └── features/
        ├── auth/
        ├── home/
        ├── bookings/
        ├── services/
        ├── stylists/
        └── admin/
```

---

## 🚀 Cómo Usar

### Instalación
```bash
flutter pub get
flutter run
```

### Build para Producción
```bash
flutter build apk          # Android
flutter build ios          # iOS
```

---

## 📝 Notas de Desarrollo

- Todas las llamadas API usan endpoints con versión `/v1/`
- Las contraseñas requieren mínimo 6 caracteres con letra y número
- Los códigos de recuperación expiran después de 15 minutos
- El sistema permite máximo una solicitud de código cada 90 segundos
- Los servicios permiten solo letras, espacios y algunos caracteres especiales

---

## 👥 Contacto

**Desarrollador:** Angel Vilamil

Para reportar bugs o sugerencias, contacta con el equipo de desarrollo.

---

**Versión:** 1.0.0  
**Última Actualización:** Enero 18, 2026
