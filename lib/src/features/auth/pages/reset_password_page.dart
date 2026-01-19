import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/auth_service.dart';
import '../widgets/auth_message_dialog.dart';
import 'dart:async';

/// Página para restablecer contraseña con código de recuperación
class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _isResendingCode = false;
  String? _codeError; // Para mostrar error del código
  bool _showResendButton = false; // Mostrar botón de reenviar cuando código es incorrecto
  int _resendCooldownSeconds = 0; // Cooldown de 90 segundos para reenviar
  Timer? _resendCooldownTimer; // Timer para el cooldown

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  /// Verifica fortaleza de la contraseña
  Map<String, bool> _checkPasswordStrength(String password) {
    return {
      'length': password.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'number': RegExp(r'\d').hasMatch(password),
      'special': RegExp(r'[^a-zA-Z0-9\s]').hasMatch(password), // ✅ CARÁCTER ESPECIAL (cualquier símbolo)
    };
  }

  /// Reenvía el código de recuperación
  Future<void> _resendCode() async {
    // Validar cooldown
    if (_resendCooldownSeconds > 0) {
      await AuthMessageDialog.showAuto(
        context,
        type: MessageType.warning,
        title: 'Espera un momento',
        message: 'Por favor espera $_resendCooldownSeconds segundos antes de reenviar otro código',
        seconds: 3,
      );
      return;
    }

    setState(() => _isResendingCode = true);

    try {
      await AuthService.forgotPassword(widget.email);

      if (mounted) {
        await AuthMessageDialog.showAuto(
          context,
          type: MessageType.success,
          title: 'Código Reenviado',
          message: 'Se ha enviado un nuevo código a tu correo: ${widget.email}',
          seconds: 3,
        );
        
        setState(() {
          _codeError = null;
          _showResendButton = false;
          _codeCtrl.clear();
        });
        
        // Iniciar cooldown de 90 segundos
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        await AuthMessageDialog.showAuto(
          context,
          type: MessageType.error,
          title: 'Error al Reenviar',
          message: errorMsg.replaceFirst('Exception: ', ''),
          seconds: 3,
        );
      }
    } finally {
      setState(() => _isResendingCode = false);
    }
  }

  /// Inicia el cooldown de 90 segundos para reenviar código
  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    setState(() {
      _resendCooldownSeconds = 90;
    });

    _resendCooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldownSeconds--;
      });
      if (_resendCooldownSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  /// Restablece la contraseña
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ VALIDAR EL CÓDIGO (no puede estar vacío)
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = 'Ingresa el código de recuperación');
      return;
    }

    final newPassword = _passwordCtrl.text;

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
                    'Verificando código y actualizando contraseña...',
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
      // ✅ LLAMAR AL API CON EL CÓDIGO INGRESADO
      await AuthService.resetPassword(
        widget.email,
        code,
        newPassword,
      );

      if (!mounted) return;

      // Cerrar loading
      Navigator.of(context).pop();

      // Mostrar éxito con auto-cierre
      await AuthMessageDialog.showAuto(
        context,
        type: MessageType.success,
        title: '¡Contraseña Actualizada!',
        message: 'Tu contraseña ha sido restablecida exitosamente.',
        seconds: 3,
      );

      // Navegar al login y limpiar stack
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Cerrar loading
      Navigator.of(context).pop();

      String errorMsg = e.toString();

      // ✅ DIFERENCIAR ERRORES DE CÓDIGO
      if (errorMsg.contains('expirado')) {
        setState(() {
          _codeError = '❌ Código expirado. Solicita uno nuevo.';
          _showResendButton = true; // Mostrar botón de reenviar
        });
        // Mostrar alerta prominente
        await AuthMessageDialog.showAuto(
          context,
          type: MessageType.error,
          title: 'Código Expirado',
          message: 'El código de recuperación ha expirado. Solicita uno nuevo en "¿Olvidaste tu contraseña?"',
          seconds: 4,
        );
      } else if (errorMsg.contains('incorrecto')) {
        setState(() {
          _codeError = '❌ Código incorrecto. Verifica y intenta de nuevo.';
          _showResendButton = true; // Mostrar botón de reenviar
        });
        // Mostrar alerta prominente para código incorrecto
        await AuthMessageDialog.showAuto(
          context,
          type: MessageType.error,
          title: 'Código Incorrecto',
          message: 'El código de recuperación ingresado es incorrecto.\n\nVerifica el código en tu correo y copia exactamente lo que ves.',
          seconds: 4,
        );
      } else if (errorMsg.contains('contraseña')) {
        // Error de validación de contraseña
        await AuthMessageDialog.showAuto(
          context,
          type: MessageType.error,
          title: 'Contraseña Inválida',
          message: 'La contraseña no cumple los requisitos. Verifica los criterios.',
          seconds: 4,
        );
      } else {
        await AuthMessageDialog.showAuto(
          context,
          type: MessageType.error,
          title: 'Error',
          message: errorMsg.replaceFirst('Exception: ', ''),
          seconds: 3,
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordChecks = _passwordCtrl.text.isEmpty
        ? null
        : _checkPasswordStrength(_passwordCtrl.text);

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: const Text('Restablecer Contraseña'),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icono de llave
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
                        Icons.vpn_key_rounded,
                        size: 50,
                        color: AppColors.gold,
                      ),
                    ),

                    // Título
                    Text(
                      'Crear Nueva Contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✅ CAMPO CÓDIGO DE RECUPERACIÓN
                    TextFormField(
                      controller: _codeCtrl,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Código de Recuperación',
                        hintText: 'Ingresa el código enviado a tu email',
                        hintStyle: TextStyle(color: AppColors.gray.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.vpn_key, color: AppColors.gold),
                        filled: true,
                        fillColor: Colors.black26,
                        labelStyle: const TextStyle(color: AppColors.gray),
                        errorText: _codeError,
                        errorStyle: const TextStyle(color: Colors.red),
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
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      onChanged: (value) {
                        // Limpiar error cuando el usuario empieza a escribir
                        if (_codeError != null) {
                          setState(() => _codeError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    // Advertencia recordando donde se envió el código
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            size: 16,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recuerda: el código se envió a tu correo (${widget.email})',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.gold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón de reenviar código cuando hay error
                    if (_showResendButton)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isResendingCode || _resendCooldownSeconds > 0 ? null : _resendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _resendCooldownSeconds > 0 
                                  ? AppColors.gold.withOpacity(0.1)
                                  : AppColors.gold.withOpacity(0.2),
                              foregroundColor: AppColors.gold,
                              side: BorderSide(
                                color: _resendCooldownSeconds > 0 
                                    ? AppColors.gold.withOpacity(0.3)
                                    : AppColors.gold,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: _isResendingCode
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.gold,
                                    ),
                                  )
                                : Icon(
                                    _resendCooldownSeconds > 0 
                                        ? Icons.schedule 
                                        : Icons.mail_outline,
                                    size: 18,
                                  ),
                            label: Text(
                              _isResendingCode 
                                  ? 'Reenviando...'
                                  : _resendCooldownSeconds > 0
                                  ? 'Espera $_resendCooldownSeconds segundos'
                                  : 'Reenviar Código',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Campo Nueva Contraseña
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      enabled: !_loading,
                      validator: Validators.password,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        hintText: 'Mínimo 8 caracteres',
                        hintStyle: TextStyle(color: AppColors.gray.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.gold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.gold,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
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
                    const SizedBox(height: 16),

                    // Indicador de fortaleza
                    if (passwordChecks != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.gray.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Requisitos de la contraseña:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPasswordCheck('Mínimo 8 caracteres', passwordChecks['length']!),
                            _buildPasswordCheck('Una letra mayúscula', passwordChecks['uppercase']!),
                            _buildPasswordCheck('Una letra minúscula', passwordChecks['lowercase']!),
                            _buildPasswordCheck('Un número', passwordChecks['number']!),
                            _buildPasswordCheck('Un carácter especial', passwordChecks['special']!), // ✅ VALIDADOR ESPECIAL
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Campo Confirmar Contraseña
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirm,
                      enabled: !_loading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma tu contraseña';
                        }
                        if (value != _passwordCtrl.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        hintText: 'Repite la contraseña',
                        hintStyle: TextStyle(color: AppColors.gray.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.gold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.gold,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                        ),
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

                    // Botón Restablecer
                    ElevatedButton(
                      onPressed: _loading ? null : _resetPassword,
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
                          : const Text(
                              'Restablecer Contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCheck(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isValid ? Colors.green : Colors.red.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? AppColors.gold : AppColors.gray,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
