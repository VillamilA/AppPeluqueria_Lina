"""
ARQUITECTURA CLEAN - SISTEMA DE VERIFICACIÓN DE EMAIL

DESCRIPCIÓN:
Sistema completo de verificación de correo electrónico después del registro y durante el login.
Implementa cooldown de 90 segundos para reenvíos, contador visual y manejo de errores robusto.
Se envía verificación para TODOS los tipos de usuarios: cliente, estilista, gerente, admin.

CAPAS ARQUITECTÓNICAS:

1. API LAYER (lib/src/api/)
   ├── auth_verification_api.dart
   │   ├── sendVerificationEmail(email, token)
   │   └── resendVerificationEmail(email, token)
   └── Endpoints:
       ├── POST /api/v1/auth/send-verification-email
       └── POST /api/v1/auth/resend-verification (cooldown 90s)

2. DATA LAYER (lib/src/data/services/)
   ├── verification_service.dart (Service Pattern)
   │   ├── sendVerificationEmail(email) - wrapper del API
   │   ├── resendVerificationEmail(email) - wrapper del API
   │   └── Manejo de TokenStorage.instance.getAccessToken()
   └── token_storage.dart - almacenamiento de tokens

3. PRESENTATION LAYER (lib/src/features/auth/)
   ├── dialogs/
   │   ├── verify_email_dialog.dart
   │   │   ├── Mostrado después del REGISTRO
   │   │   ├── Contador de 90 segundos
   │   │   ├── Botón "Reenviar correo de verificación"
   │   │   └── Botón "Ya verificué mi correo"
   │   └── unverified_email_dialog.dart
   │       ├── Mostrado durante LOGIN si email no verificado
   │       ├── Contador de 90 segundos
   │       ├── Botón "Reenviar correo de verificación"
   │       └── Botón "Cerrar"
   ├── widgets/
   │   ├── register_form.dart
   │   │   ├── Registra usuario
   │   │   ├── Obtiene token de respuesta
   │   │   └── Muestra VerifyEmailDialog
   │   └── login_form.dart
   │       ├── Verifica emailVerified en respuesta
   │       ├── Intercepta excepción de email no verificado
   │       ├── Si NO verificado → muestra UnverifiedEmailDialog
   │       └── Si verificado → continúa al dashboard
   └── pages/
       └── register_page.dart - página contenedor

4. ADMIN LAYER (lib/src/features/admin/)
   ├── stylists_crud_page.dart
   │   └── Envía email de verificación tras crear estilista
   ├── managers_crud_page.dart
   │   └── Envía email de verificación tras crear gerente
   └── clients_crud_page.dart
       └── Envía email de verificación tras crear cliente

FLUJO COMPLETO:

─────────────────────────────────────────────────────────────────
DESPUÉS DEL REGISTRO:
─────────────────────────────────────────────────────────────────
1. Usuario completa formulario de registro
2. AuthService.register() se ejecuta
3. Backend responde con token en accessToken
4. Código extrae: String token = res['accessToken']
5. VerifyEmailDialog se muestra con:
   - Email del usuario
   - Ícono de correo
   - Texto explicativo
   - Botón "Reenviar correo de verificación" (habilitado)
   - Botón "Ya verificué mi correo"

CUANDO USUARIO TOCA "Reenviar correo de verificación":
1. VerificationService.resendVerificationEmail(email) se ejecuta
2. POST /api/v1/auth/resend-verification envía email
3. Si éxito: SnackBar verde "Correo reenviado"
4. Inicia cooldown de 90 segundos
5. Botón se deshabilita con contador "Reintenta en: 90 seg"
6. Contador cuenta hacia abajo
7. Cuando llega a 0: botón se habilita nuevamente

CUANDO USUARIO TOCA "Ya verificué mi correo":
1. Dialog se cierra
2. Usuario vuelve a login normalmente

─────────────────────────────────────────────────────────────────
DURANTE EL LOGIN:
─────────────────────────────────────────────────────────────────
1. Usuario ingresa email y contraseña
2. AuthService.login() se ejecuta
3. Backend responde CON DOS POSIBILIDADES:
   
   OPCIÓN A - Respuesta exitosa con emailVerified flag:
   - Backend devuelve emailVerified=true/false en JSON
   - Código verifica: res['emailVerified'] ?? false
   
   OPCIÓN B - Excepción si email no verificado:
   - Backend lanza Exception: "Confirme primero el correo..."
   - Código captura en catch block
   - Detecta si es error de email (contains "correo", "email", "verif")
   
4. Si NO verificado (OPCIÓN A O B):
   a) SnackBar naranja "Debes verificar tu correo..."
   b) UnverifiedEmailDialog se muestra con:
      - Ícono de advertencia
      - Email del usuario (del login intent o error)
      - Consejos (revisar spam, etc.)
      - Botón "Reenviar correo de verificación" (habilitado)
      - Botón "Cerrar"
5. Si emailVerified === true (OPCIÓN A):
   a) Continúa con flujo normal de login
   b) Guarda tokens en TokenStorage
   c) Navega al dashboard según rol

CUANDO USUARIO TOCA "Reenviar correo de verificación":
1. VerificationService.resendVerificationEmail(email) se ejecuta
2. POST /api/v1/auth/resend-verification envía email
3. Same cooldown logic como en registro

─────────────────────────────────────────────────────────────────
DURANTE CREACIÓN DE USUARIOS POR ADMIN:
─────────────────────────────────────────────────────────────────

Los admins/gerentes pueden crear nuevos usuarios desde el panel.
Tres CRUD pages manejan esto:

1. stylists_crud_page.dart → Crear estilista:
   a) Admin llena StylistFormPage
   b) onClick guardar → _createStylist()
   c) POST /api/v1/stylists exitoso
   d) VerificationService.sendVerificationEmail(stylist['email'])
   e) Email de verificación enviado automáticamente
   f) SnackBar verde "Estilista creada exitosamente"

2. managers_crud_page.dart → Crear gerente:
   a) Admin llena ManagerFormPage
   b) onClick guardar → _createManager()
   c) POST /api/v1/users exitoso
   d) VerificationService.sendVerificationEmail(manager['email'])
   e) Email de verificación enviado automáticamente
   f) SnackBar verde "Gerente creado exitosamente"

3. clients_crud_page.dart → Crear cliente:
   a) Admin llena ClientFormPage
   b) onClick guardar → _createClient()
   c) POST /api/v1/users exitoso
   d) VerificationService.sendVerificationEmail(client['email'])
   e) Email de verificación enviado automáticamente
   f) SnackBar verde "Cliente creado exitosamente"

NOTAS IMPORTANTES:
- El email se envía DESPUÉS de que el usuario se cree exitosamente
- Si el envío de email falla, continúa (no bloquea la creación del usuario)
- El usuario puede reenviar el email desde login o desde su dashboard
- Manejo de errores: try/catch con logging sin bloquear la creación

─────────────────────────────────────────────────────────────────
MANEJO DE ERRORES:
─────────────────────────────────────────────────────────────────
- Status 200/201: ✅ Correo enviado - SnackBar verde
- Status 429: ⏱️ Cooldown activo - mostrar contador
- Otras excepciones: ❌ SnackBar rojo con error

─────────────────────────────────────────────────────────────────
DETALLES TÉCNICOS:
─────────────────────────────────────────────────────────────────

TIMER IMPLEMENTATION:
```dart
void _startCooldown() {
  setState(() => _cooldownSeconds = 90);
  _cooldownTimer?.cancel();
  _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
      _cooldownSeconds--;
      if (_cooldownSeconds <= 0) {
        _cooldownTimer?.cancel();
      }
    });
  });
}
```

TOKEN EXTRACTION:
```dart
String token = '';
if (res is Map && res.containsKey('token')) {
  token = res['token'] ?? '';
} else if (res is String) {
  token = res;
}
```

EMAIL VERIFICATION CHECK:
```dart
final isEmailVerified = res['emailVerified'] ?? 
                        res['isEmailVerified'] ?? 
                        res['email_verified'] ?? 
                        res['verified'] ?? 
                        true;
```

─────────────────────────────────────────────────────────────────
COMPONENTES VISUALES:
─────────────────────────────────────────────────────────────────

VerifyEmailDialog (After Registration):
┌─────────────────────────────────────┐
│  📧 (icon in gold container)        │
│  "Verifica tu correo"               │
│  "Te hemos enviado un enlace..."    │
│  user@example.com                   │
│  ┌─ Info box (blue) ─┐              │
│  │ ℹ️ Por favor verifica...          │
│  │ ✓ Revisa spam...                 │
│  └────────────────────┘             │
│  ┌────────────────────────────────┐ │
│  │ ⏱️ Reintenta en: 90 seg        │ │
│  └────────────────────────────────┘ │
│  [Reenviar correo de verificación]  │
│  [Ya verificué mi correo]           │
└─────────────────────────────────────┘

UnverifiedEmailDialog (During Login):
┌─────────────────────────────────────┐
│  ⚠️ (warning icon in orange)        │
│  "Correo no verificado"             │
│  "Recuerda activar tu correo..."    │
│  user@example.com                   │
│  ┌─ Info box (blue) ─┐              │
│  │ ℹ️ Revisa el correo...           │
│  │ ✓ Revisa también spam...         │
│  └────────────────────┘             │
│  ┌────────────────────────────────┐ │
│  │ ⏱️ Reintenta en: 90 seg        │ │
│  └────────────────────────────────┘ │
│  [Reenviar correo de verificación]  │
│  [Cerrar]                           │
└─────────────────────────────────────┘

─────────────────────────────────────────────────────────────────
VENTAJAS DE ESTA ARQUITECTURA:
─────────────────────────────────────────────────────────────────
✅ Clean Architecture - separación de capas clara
✅ Reusable Service - VerificationService puede usarse en cualquier lugar
✅ User-friendly - contador visual, cooldown, manejo de errores
✅ Backend compliance - cooldown 90s respetado
✅ No bordes de papeles - tokens obtenidos correctamente
✅ Defensive programming - múltiples campos para emailVerified
✅ Type-safe - manejo correcto de tipos Map/String
✅ Disposed properly - timers cancelados en dispose()
"""
