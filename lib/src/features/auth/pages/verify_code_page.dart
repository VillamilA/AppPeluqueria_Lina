import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth_message_dialog.dart';
import 'reset_password_page.dart';

/// Página para verificar el código de 6 dígitos
class VerifyCodePage extends StatefulWidget {
  final String email;

  const VerifyCodePage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String _codeError = '';

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  /// Valida que el código tenga 6 dígitos
  void _validateCode(String value) {
    setState(() {
      if (value.isEmpty) {
        _codeError = '';
      } else if (value.length < 6) {
        _codeError = 'El código debe tener 6 dígitos';
      } else if (!RegExp(r'^\d+$').hasMatch(value)) {
        _codeError = 'Solo se permiten números';
      } else {
        _codeError = '';
      }
    });
  }

  /// Verifica el código ingresado
  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();

    if (code.length != 6) {
      setState(() => _codeError = 'El código debe tener 6 dígitos');
      return;
    }

    setState(() => _loading = true);

    // Mostrar loading
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
                    'Verificando código...',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
      // Verificar código con el backend (usando una petición HEAD o similar)
      // Por ahora solo validamos que el código tenga el formato correcto
      await Future.delayed(const Duration(seconds: 1)); // Simular petición

      if (!mounted) return;

      // Cerrar loading
      Navigator.of(context).pop();

      // Navegar a página de nueva contraseña
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(
            email: widget.email,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Cerrar loading
      Navigator.of(context).pop();

      String message = 'Error al verificar el código';

      if (e.toString().contains('Código expirado')) {
        message = 'El código ha expirado. Solicita uno nuevo.';
      } else if (e.toString().contains('Código incorrecto')) {
        message = 'El código ingresado es incorrecto';
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
        title: const Text('Verificar Código'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icono de correo
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
                      Icons.mail_lock_rounded,
                      size: 50,
                      color: AppColors.gold,
                    ),
                  ),

                  // Título
                  Text(
                    'Ingresa el Código',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
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
                          Icons.email,
                          size: 20,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Código enviado a: ${widget.email}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.gray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo Código
                  TextField(
                    controller: _codeCtrl,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Código de 6 dígitos',
                      hintText: '• • • • • •',
                      hintStyle: TextStyle(
                        color: AppColors.gray.withOpacity(0.5),
                        letterSpacing: 12,
                      ),
                      errorText: _codeError.isEmpty ? null : _codeError,
                      filled: true,
                      fillColor: Colors.black26,
                      labelStyle: const TextStyle(color: AppColors.gray),
                      counterText: '',
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: _validateCode,
                    onSubmitted: (_) => _verifyCode(),
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 16),

                  // Info expiración
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
                  const SizedBox(height: 32),

                  // Botón Verificar
                  ElevatedButton(
                    onPressed: _loading || _codeError.isNotEmpty ? null : _verifyCode,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Verificar Código',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Botón Solicitar Nuevo Código
                  TextButton.icon(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    icon: Icon(Icons.refresh_rounded, color: AppColors.gold),
                    label: Text(
                      'Solicitar nuevo código',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
