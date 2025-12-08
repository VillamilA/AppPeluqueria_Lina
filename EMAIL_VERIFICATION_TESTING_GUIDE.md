# Email Verification System - Testing Guide

## Quick Start Testing

### Test 1: Login with Unverified Email (Exception Handling)
**Steps:**
1. Use existing user with unverified email
2. Go to login_page
3. Enter email and password
4. Tap "Ingresar"

**Expected Result:**
- ❌ If backend throws "Confirme primero el correo..." exception
- ✅ Code catches it
- ✅ UnverifiedEmailDialog shows (NOT generic error)
- ✅ Email pre-filled in dialog
- ✅ "Reenviar correo de verificación" button available
- ✅ "Cerrar" button to dismiss

**What's New:**
Previously the error showed as generic SnackBar error. Now it detects the email verification exception and shows the proper dialog.

---

### Test 2: Login with Unverified Email (Flag Response)
**Setup:**
- Register new user to get unverified email
- Close app, reopen
- Try to login immediately

**Steps:**
1. Go to login_page
2. Enter newly registered email/password
3. Tap "Ingresar"

**Expected Result:**
- ✅ If backend returns emailVerified=false flag
- ✅ Code detects it
- ✅ UnverifiedEmailDialog shows
- ✅ Email pre-filled
- ✅ 90-second cooldown active

---

### Test 3: Reenviar Correo Cooldown (Login Dialog)
**Starting State:**
- UnverifiedEmailDialog visible
- "Reenviar correo" button enabled

**Steps:**
1. Click "Reenviar correo de verificación"
2. Watch timer countdown

**Expected Result:**
- ✅ Button immediately disabled
- ✅ Shows "⏱️ Reintenta en: 90 seg"
- ✅ Countdown updates every second
- ✅ After 90 seconds: button re-enables
- ✅ Green SnackBar: "Email reenviado exitosamente"

---

### Test 4: Create Stylist from Admin Panel
**Setup:**
- Login as admin/gerente
- Navigate to "Gestión de Estilistas" or stylists_crud_page

**Steps:**
1. Click FAB (create button)
2. Fill StylistFormPage form:
   - Nombre: "Ana García"
   - Email: "ana@example.com"
   - Password: "password123"
   - Select at least one catalog
   - Fill work schedule
3. Click "Guardar"

**Expected Result:**
- ✅ "Estilista creada exitosamente" SnackBar
- ✅ Stylist appears in list
- ✅ Verification email sent automatically (check backend logs)
- **Test continuation:**
  - Logout
  - Try to login as ana@example.com
  - Should see UnverifiedEmailDialog

---

### Test 5: Create Manager from Admin Panel
**Setup:**
- Login as admin
- Navigate to "Gestión de Gerentes" or managers_crud_page

**Steps:**
1. Click FAB (create button)
2. Fill ManagerFormPage form:
   - Nombre: "Carlos López"
   - Email: "carlos@example.com"
   - Password: "password123"
3. Click "Guardar"

**Expected Result:**
- ✅ "Gerente creado exitosamente" SnackBar
- ✅ Manager appears in list
- ✅ Verification email sent automatically

---

### Test 6: Create Client from Admin Panel
**Setup:**
- Login as admin/gerente
- Navigate to "Gestión de Clientes" or clients_crud_page

**Steps:**
1. Click FAB (create button)
2. Fill ClientFormPage form:
   - Nombre: "María Rodríguez"
   - Email: "maria@example.com"
   - Password: "password123"
3. Click "Guardar"

**Expected Result:**
- ✅ "Cliente creado exitosamente" SnackBar
- ✅ Client appears in list
- ✅ Verification email sent automatically

---

### Test 7: Public Client Registration (Existing)
**Setup:**
- Open app without login
- Navigate to register_page

**Steps:**
1. Select "Cliente" as role
2. Fill registration form
3. Click "Registrarse"

**Expected Result:**
- ✅ "¡Acceso exitoso!" dialog shows (success)
- ✅ VerifyEmailDialog appears with:
  - 📧 Mail icon in gold container
  - User's email displayed
  - "Reenviar correo de verificación" button
  - "Ya verificué mi correo" button
- ✅ Can click "Reenviar" to trigger email (90s cooldown)
- ✅ Can click "Ya verificué" to close dialog

---

### Test 8: Public Stylist Registration (Existing)
**Setup:**
- Open app without login
- Navigate to register_page

**Steps:**
1. Select "Estilista" as role
2. Fill registration form
3. Click "Registrarse"

**Expected Result:**
- ✅ Same as Test 7 (public registration)
- ✅ VerifyEmailDialog shows with same 90s cooldown logic

---

## Debugging Commands

### Check if Email Sent (Backend Logs)
```bash
# After creating a user or clicking "Reenviar correo"
# Look for logs containing:
# ✅ Email enviado a user@example.com
# ✅ POST /api/v1/auth/resend-verification
```

### Check Exception Handling (Flutter Logs)
```dart
// When catching email verification exception:
// Look for:
print('⚠️ Email not verified - showing dialog')
// NOT:
print('Generic error caught')
```

### Token Extraction Debug
```dart
// In register_form.dart:
print('🔐 Token extracted: $token')
// Should show token value, not empty string
```

### Verification Service Debug
```dart
// In verification_service.dart:
print('✅ Email enviado a: $email')
// or
print('⏱️ Cooldown active: 429 status')
```

---

## Common Issues & Solutions

### Issue: UnverifiedEmailDialog doesn't show on login
**Possible Causes:**
1. Backend is not throwing exception OR returning emailVerified flag
2. Email not actually unverified in database
3. Code not reaching catch block

**Solution:**
- Check backend logs
- Verify user's emailVerified status in database
- Add debug prints in login_form.dart catch block

### Issue: Email send fails but user created
**Expected Behavior:**
- ✅ This is correct! Email failures are non-blocking
- User is created successfully
- User can retry sending email from login verification dialog
- Check backend email service logs for why send failed

**Solution:**
- Ensure email service credentials are valid
- Check network connectivity
- Review email service logs

### Issue: Cooldown timer keeps resetting
**Possible Cause:**
- Timer being restarted instead of checking existing state
- Multiple click handlers firing

**Solution:**
- Check `_startCooldown()` is called only once
- Verify button disabled state during countdown
- Ensure `_cooldownTimer?.cancel()` is called in dispose

### Issue: Reenviar button stays disabled forever
**Possible Cause:**
- Timer not reaching 0
- Dispose not called properly
- State not updating after timer completes

**Solution:**
- Verify `_cooldownSeconds--` logic
- Check dispose() cancels timer
- Ensure setState is called in Timer callback

---

## Integration Testing Checklist

### Before Deployment, Verify:

**Login Scenarios:**
- [ ] Login with verified email → dashboard loads
- [ ] Login with unverified email (exception) → verification dialog
- [ ] Login with unverified email (flag) → verification dialog
- [ ] Email remains populated in verification dialog
- [ ] Can close dialog and try again

**Reenviar Cooldown:**
- [ ] First click: button disables, timer shows 90s
- [ ] Timer counts down each second
- [ ] Timer reaches 0: button re-enables
- [ ] Can click again: new 90s cooldown
- [ ] Green SnackBar on success
- [ ] Red SnackBar on error (429)

**Admin User Creation:**
- [ ] Create stylist → email logged
- [ ] Create manager → email logged
- [ ] Create client → email logged
- [ ] User can login and see verification dialog
- [ ] User can verify from their email

**Public Registration:**
- [ ] Client registration → dialog shows
- [ ] Stylist registration → dialog shows
- [ ] Email pre-filled correctly
- [ ] Same cooldown logic works

**Error Scenarios:**
- [ ] Network error during email send → graceful (non-blocking)
- [ ] 429 Cooldown error → "Reintenta en: 90 seg"
- [ ] Invalid email → proper error message
- [ ] Backend exception → caught and handled (not crash)

---

## Performance Considerations

✅ **Timers Properly Cleaned Up**
- `_cooldownTimer?.cancel()` in dispose()
- Prevents memory leaks

✅ **Token Storage Efficient**
- Single call to TokenStorage.getAccessToken()
- No repeated token retrievals

✅ **API Calls Minimal**
- One email send per resubmit
- No duplicate calls on rapid clicks

✅ **UI Updates Minimal**
- setState() only when timer updates or button state changes
- No unnecessary rebuilds

---

## Success Metrics

### For Each Test:
- ✅ Code compiles without errors
- ✅ No runtime exceptions
- ✅ UI renders correctly
- ✅ User feedback is clear (SnackBars, dialogs)
- ✅ Email actually sent (backend logs confirm)
- ✅ Cooldown timer works smoothly
- ✅ Can recover and retry after errors

### Overall System:
- ✅ All 4 user types get verification emails
- ✅ Login handles both backend response types
- ✅ Dialogs are user-friendly and intuitive
- ✅ Errors are non-blocking and logged
- ✅ 90-second cooldown enforced properly
- ✅ Documentation is complete and accurate

---

## Test Results Template

```
Date: _______________
Tester: _______________
Build Version: _______________

TEST 1: Login Exception Handling
Result: □ PASS □ FAIL
Notes: ___________________________________________

TEST 2: Login Flag Response
Result: □ PASS □ FAIL
Notes: ___________________________________________

TEST 3: Reenviar Cooldown
Result: □ PASS □ FAIL
Notes: ___________________________________________

TEST 4: Admin Create Stylist
Result: □ PASS □ FAIL
Notes: ___________________________________________

TEST 5: Admin Create Manager
Result: □ PASS □ FAIL
Notes: ___________________________________________

TEST 6: Admin Create Client
Result: □ PASS □ FAIL
Notes: ___________________________________________

TEST 7: Public Client Registration
Result: □ PASS □ FAIL
Notes: ___________________________________________

TEST 8: Public Stylist Registration
Result: □ PASS □ FAIL
Notes: ___________________________________________

Overall Status: □ READY FOR DEPLOYMENT □ NEEDS FIXES
```

---

## Support

For issues or questions:
1. Check ARCHITECTURE_EMAIL_VERIFICATION.md for system overview
2. Check CHANGES_EMAIL_VERIFICATION_FIX.md for recent changes
3. Review code comments in login_form.dart (catch block)
4. Check backend email service logs
5. Verify EmailVerification API endpoints are accessible
