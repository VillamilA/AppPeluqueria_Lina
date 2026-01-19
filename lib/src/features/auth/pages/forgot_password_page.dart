import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/auth_service.dart';
import '../widgets/auth_message_dialog.dart';
import 'reset_password_page.dart';

/// Página para solicitar código de recuperación de contraseña
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _canResend = true;
  int _countdown = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  /// Inicia temporizador de 90 segundos para rate limiting
  void _startCountdown() {
    setState(() {
      _canResend = false;
      _countdown = 90;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _canResend = true;
        }
      });

      return _countdown > 0;
    });
  }

  /// Solicita código de recuperación
  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canResend) return;

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();

    // Mostrar loading "Enviando código..."
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enviando código...',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      await AuthService.forgotPassword(email);

      if (!mounted) return;

      // Cerrar loading
      Navigator.of(context).pop();

      // Iniciar countdown
      _startCountdown();

      // ✅ NAVEGAR DIRECTAMENTE AL FORMULARIO DE CAMBIO CON EL CÓDIGO
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(email: email),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Cerrar loading
      Navigator.of(context).pop();

      String message = 'Error al enviar el código';
      
      if (e.toString().contains('Usuario no encontrado')) {
        message = 'No existe una cuenta con ese correo electrónico';
      } else if (e.toString().contains('90 segundos')) {
        message = 'Debes esperar 90 segundos antes de solicitar otro código';
        _startCountdown();
        
        // Mostrar alerta que se cierra automáticamente en 3 segundos
        // pero el botón estará deshabilitado por 90 segundos
        AuthMessageDialog.showAuto(
          context,
          type: MessageType.warning,
          title: 'Espera un momento',
          message: message + '\nEl botón se habilitará en $_countdown segundos',
          seconds: 3,
        );
        return;
      } else if (e.toString().contains('connection')) {
        message = 'Error de conexión. Verifica tu internet.';
      }

      AuthMessageDialog.show(
        context,
        type: MessageType.error,
        title: 'Error',
        message: message,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: AppColors.charcoal,
        foregroundColor: AppColors.gold,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icono de candado
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 50,
                        color: AppColors.gold,
                      ),
                    ),

                    // Título
                    Text(
                      '¿Olvidaste tu contraseña?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Descripción
                    Text(
                      'Ingresa tu correo electrónico y te enviaremos un código de 6 dígitos para recuperar tu cuenta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Campo Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_loading,
                      validator: Validators.email,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        hintText: 'tu@correo.com',
                        hintStyle: TextStyle(color: AppColors.gray.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.gold),
                        filled: true,
                        fillColor: Colors.black26,
                        labelStyle: const TextStyle(color: AppColors.gray),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gray),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gold, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Indicador de expiración
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'El código expira en 15 minutos',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.gray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Enviar Código
                    ElevatedButton(
                      onPressed: _loading || !_canResend ? null : _requestCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 4,
                        shadowColor: AppColors.gold.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppColors.gray,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _canResend 
                                  ? 'Enviar Código' 
                                  : 'Espera $_countdown segundos',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Botón Volver al Login
                    TextButton(
                      onPressed: _loading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Volver al inicio de sesión',
                        style: TextStyle(
                          color: AppColors.gray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Info adicional
                    if (!_canResend) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Revisa tu bandeja de spam si no ves el correo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
