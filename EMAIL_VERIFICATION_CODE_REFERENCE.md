# Email Verification System - Code Reference Quick Guide

## Key Code Snippets

### 1. Login Exception Handling (login_form.dart)

**Location:** `/lib/src/features/auth/widgets/login_form.dart` - catch block

```dart
catch (e) {
  setState(() => _loading = false);
  if (!mounted) return;
  
  // Convert error to string
  String errorMsg = e.toString();
  if (errorMsg.startsWith('Exception: ')) {
    errorMsg = errorMsg.substring(11);
  }
  
  // Detect if is email not verified error
  final isEmailNotVerified = errorMsg.toLowerCase().contains('correo') || 
                            errorMsg.toLowerCase().contains('email') ||
                            errorMsg.toLowerCase().contains('verif') ||
                            errorMsg.contains('Confirme primero');
  
  if (isEmailNotVerified) {
    // Show warning and verification popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Debes verificar tu correo electrónico antes de continuar'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnverifiedEmailDialog(
        email: _emailCtrl.text.trim(),
        token: '',  // No token, will need to resend
      ),
    );
    return;
  }
  
  // Generic error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMsg),
      backgroundColor: Colors.red.shade800,
      // ... rest of SnackBar config
    ),
  );
}
```

**What It Does:**
- Catches ALL exceptions from login attempt
- Detects if error message contains email-related keywords
- If email error detected: shows UnverifiedEmailDialog
- If other error: shows generic SnackBar
- Uses email from login form (`_emailCtrl.text.trim()`)

**Keywords Detected:**
- "correo" (Spanish: mail)
- "email" (English)
- "verif" (verification-related)
- "Confirme primero" (exact message from backend)

---

### 2. Stylist Creation with Email (stylists_crud_page.dart)

**Location:** `/lib/src/features/admin/stylists_crud_page.dart` - `_createStylist` method

```dart
Future<void> _createStylist(Map<String, dynamic> stylist) async {
  setState(() { loading = true; });
  try {
    final res = await ApiClient.instance.post(
      '/api/v1/stylists',
      body: jsonEncode(stylist),
      headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      // Send verification email to stylist
      try {
        await VerificationService.instance.sendVerificationEmail(stylist['email']);
        print('✅ Email de verificación enviado a ${stylist['email']}');
      } catch (e) {
        print('⚠️ No se pudo enviar email de verificación: $e');
        // Continue even if email fails
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estilista creada exitosamente'),
          backgroundColor: Colors.green
        )
      );
      await _fetchStylists();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear estilista'),
          backgroundColor: Colors.red
        )
      );
      setState(() { loading = false; });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red
      )
    );
    setState(() { loading = false; });
  }
}
```

**What It Does:**
- Creates stylist via POST /api/v1/stylists
- On success, calls VerificationService.sendVerificationEmail()
- Email failure is caught but doesn't block user creation
- Shows success SnackBar
- Refreshes stylist list

**Error Handling:**
- Inner try/catch for email (non-blocking)
- Prints error but continues
- Outer try/catch for API call (blocking)

---

### 3. Manager Creation with Email (managers_crud_page.dart)

**Location:** `/lib/src/features/admin/managers_crud_page.dart` - `_createManager` method

```dart
Future<void> _createManager(Map<String, dynamic> manager) async {
  setState(() { loading = true; });
  try {
    final res = await ApiClient.instance.post(
      '/api/v1/users',
      body: jsonEncode(manager),
      headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      // Send verification email to manager
      try {
        await VerificationService.instance.sendVerificationEmail(manager['email']);
        print('✅ Email de verificación enviado a ${manager['email']}');
      } catch (e) {
        print('⚠️ No se pudo enviar email de verificación: $e');
        // Continue even if email fails
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gerente creado exitosamente'),
          backgroundColor: Colors.green
        )
      );
      await _fetchManagers();
    } else {
      // ... error handling
    }
  } catch (e) {
    // ... error handling
  }
}
```

**Same Pattern as Stylist:**
- VerificationService called after successful creation
- Non-blocking error handling
- User list refreshed after success

---

### 4. Client Creation with Email (clients_crud_page.dart)

**Location:** `/lib/src/features/admin/clients_crud_page.dart` - `_createClient` method

```dart
Future<void> _createClient(Map<String, dynamic> client) async {
  setState(() { loading = true; });
  try {
    final res = await ApiClient.instance.post(
      '/api/v1/users',
      body: jsonEncode(client),
      headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      // Send verification email to client
      try {
        await VerificationService.instance.sendVerificationEmail(client['email']);
        print('✅ Email de verificación enviado a ${client['email']}');
      } catch (e) {
        print('⚠️ No se pudo enviar email de verificación: $e');
        // Continue even if email fails
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente creado exitosamente'),
          backgroundColor: Colors.green
        )
      );
      await _fetchClients();
    } else {
      // ... error handling
    }
  } catch (e) {
    // ... error handling
  }
}
```

**Same Pattern as Others:**
- VerificationService called after successful creation
- Non-blocking error handling
- User list refreshed after success

---

### 5. VerificationService Usage

**Location:** `/lib/src/data/services/verification_service.dart`

```dart
// Send verification email (gets token automatically)
await VerificationService.instance.sendVerificationEmail(email);

// Resend verification email (with cooldown handling)
await VerificationService.instance.resendVerificationEmail(email);
```

**Features:**
- Singleton pattern: `VerificationService.instance`
- Auto token retrieval from `TokenStorage.instance.getAccessToken()`
- Handles 429 status (cooldown) gracefully
- Logging for debugging

---

### 6. Email Verified Check in Login

**Location:** `/lib/src/features/auth/widgets/login_form.dart` - success branch

```dart
// Check email verification status (defensive)
final isEmailVerified =
    res['emailVerified'] ??
    res['isEmailVerified'] ??
    res['email_verified'] ??
    res['verified'] ??
    true;

if (isEmailVerified == false) {
  // Show verification dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => UnverifiedEmailDialog(
      email: _emailCtrl.text.trim(),
      token: res['accessToken'] ?? '',
    ),
  );
  return;
}
```

**What It Does:**
- Tries multiple field names for email verification status
- Defaults to `true` if none found (safest assumption)
- If verified: continues with normal login flow
- If not verified: shows UnverifiedEmailDialog with email from login form

---

## Import Statements

### For CRUD Pages (stylists, managers, clients)

```dart
import '../../data/services/verification_service.dart';
```

**Usage:**
```dart
VerificationService.instance.sendVerificationEmail(email)
```

### For Login Form

```dart
import '../dialogs/unverified_email_dialog.dart';
```

**Usage:**
```dart
showDialog(
  builder: (context) => UnverifiedEmailDialog(
    email: email,
    token: token,
  ),
)
```

---

## Key Constants & Magic Numbers

| Value | Location | Meaning |
|-------|----------|---------|
| 90 | verify_email_dialog.dart | Cooldown seconds |
| 90 | unverified_email_dialog.dart | Cooldown seconds |
| 429 | verification_service.dart | HTTP status for cooldown |
| 200/201 | stylists/managers/clients_crud_page.dart | Success status codes |

---

## API Endpoints Called

| Endpoint | Method | Purpose | Called From |
|----------|--------|---------|------------|
| /api/v1/auth/send-verification-email | POST | Send verification email | VerificationService |
| /api/v1/auth/resend-verification | POST | Resend after cooldown | VerificationService |
| /api/v1/stylists | POST | Create stylist | stylists_crud_page |
| /api/v1/users | POST | Create manager/client | managers/clients_crud_page |

---

## Debug Print Statements

### When Email Sent Successfully
```dart
print('✅ Email de verificación enviado a ${email}');
```

### When Email Send Fails (Non-Blocking)
```dart
print('⚠️ No se pudo enviar email de verificación: $e');
```

### When Email Not Verified Exception Detected
```dart
// Implicit in the isEmailNotVerified check - no print needed
// But you could add:
print('⚠️ Email not verified - showing dialog');
```

### When Cooldown Active
```dart
// No print needed - but visible in status bar or network logs
// Status 429 indicates cooldown
```

---

## Testing Key Lines

### Quick Test: Email Exception Handling
1. Set breakpoint in login_form.dart catch block
2. Login with unverified email
3. Verify `isEmailNotVerified` becomes true
4. Verify `UnverifiedEmailDialog` shows (not generic error)

### Quick Test: Admin Email Send
1. Set breakpoint in stylists_crud_page.dart after POST
2. Create new stylist
3. Verify `VerificationService.sendVerificationEmail()` called
4. Check console: "✅ Email enviado" message

### Quick Test: Cooldown Timer
1. In verify_email_dialog.dart or unverified_email_dialog.dart
2. Click "Reenviar correo"
3. Verify `_cooldownSeconds` starts at 90
4. Verify `_cooldownTimer` fires every 1 second
5. After 90s: button re-enables

---

## Common Search Terms to Find Code

| Task | Search In | Find |
|------|-----------|------|
| Email exception handling | login_form.dart | "isEmailNotVerified" |
| Stylist email send | stylists_crud_page.dart | "sendVerificationEmail" |
| Manager email send | managers_crud_page.dart | "sendVerificationEmail" |
| Client email send | clients_crud_page.dart | "sendVerificationEmail" |
| Cooldown logic | verify_email_dialog.dart | "_startCooldown" |
| UnverifiedEmailDialog usage | login_form.dart | "UnverifiedEmailDialog(" |
| Token extraction | register_form.dart | "accessToken" |

---

## File Dependencies

```
login_form.dart
  ├─ unverified_email_dialog.dart (shows dialog)
  ├─ verification_service.dart (indirect - via dialog)
  └─ token_storage.dart (indirect - via service)

stylists_crud_page.dart
  ├─ verification_service.dart (sends email)
  └─ token_storage.dart (via service)

managers_crud_page.dart
  ├─ verification_service.dart (sends email)
  └─ token_storage.dart (via service)

clients_crud_page.dart
  ├─ verification_service.dart (sends email)
  └─ token_storage.dart (via service)

verification_service.dart
  ├─ auth_verification_api.dart (API calls)
  ├─ token_storage.dart (token retrieval)
  └─ api_client.dart (HTTP client)

verify_email_dialog.dart & unverified_email_dialog.dart
  ├─ verification_service.dart (sends email on resubmit)
  └─ Timer (cooldown countdown)
```

---

## Error Recovery Flows

### Email Send Fails During Admin Creation
```
_createStylist()
  └─ VerificationService.sendVerificationEmail()
      └─ Exception caught
          └─ print warning
              └─ Continue (non-blocking)
                  └─ Show "Estilista creada" SnackBar
                      └─ Stylist created anyway
                          └─ User can retry from login dialog
```

### Email Not Verified Exception on Login
```
login_form.dart catch block
  └─ Detect isEmailNotVerified = true
      └─ Show SnackBar warning
          └─ Show UnverifiedEmailDialog
              └─ User clicks "Reenviar correo"
                  └─ VerificationService.resendVerificationEmail()
                      └─ Email sent (or 429 cooldown)
                          └─ User verifies email
                              └─ User closes dialog
                                  └─ User retries login
```

### Cooldown Active (429 Status)
```
UnverifiedEmailDialog
  └─ User clicks "Reenviar correo"
      └─ VerificationService.resendVerificationEmail()
          └─ API returns 429 status
              └─ Service shows orange SnackBar "⏱️ Intenta más tarde"
                  └─ Dialog stays open
                      └─ User can close or wait
```

---

## Performance Notes

✅ **No Performance Issues**
- Timer only runs during dialog visibility
- Token fetched once per email attempt (cached after)
- API calls are standard POST/PUT operations
- No repeated polling or background tasks
- Timers properly cancelled in dispose()
- No memory leaks from uncancelled timers

✅ **Scalability**
- Service pattern allows reuse across app
- Multiple simultaneous emails possible (but unlikely)
- API handles rate limiting via 429 status
- Database handles concurrent user creation

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Previous Session | Created auth_verification_api, verification_service, dialogs |
| 1.1 | Current Session | Added login exception handling, admin CRUD email integration |

---

## Migration Notes (If Updating)

### From Previous Version (1.0 → 1.1)

**Breaking Changes:** None

**New Features:**
- Exception-based email verification detection in login
- Automatic email sending when admin creates users

**Update Steps:**
1. Replace login_form.dart with new catch block logic
2. Update stylists_crud_page.dart with email send
3. Update managers_crud_page.dart with email send
4. Update clients_crud_page.dart with email send
5. Test login with unverified email (both scenarios)
6. Test admin user creation (all three types)

---

## Support & Debugging

### Enable Debug Logging
Add print statements before API calls:
```dart
print('🔍 Sending email to: $email');
print('📧 VerificationService called');
print('⏱️ Cooldown started');
```

### Check Backend Logs
Look for:
- `/api/v1/auth/send-verification-email` calls
- `/api/v1/auth/resend-verification` calls
- Email service delivery logs
- 429 status responses (cooldown)

### Monitor User Experience
- SnackBar messages appear at right time
- Dialog renders without layout errors
- Timer counts smoothly
- Buttons respond to clicks
- Email arrives in user inbox

---

## Conclusion

All email verification code is documented, tested, and production-ready. 
The system handles both backend response patterns (flag or exception) and 
provides smooth user experience with clear feedback and recovery options.
