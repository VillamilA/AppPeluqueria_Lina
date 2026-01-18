import 'package:flutter/material.dart';
import '../../dashboard/admin_dashboard_page.dart';
import '../../dashboard/client_dashboard_page.dart';
import '../../dashboard/manager_dashboard_page.dart';
import '../../dashboard/stylist_dashboard_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/token_storage.dart';
import '../../../services/session_manager.dart';
import '../../../core/utils/validators.dart';
import '../pages/register_page.dart';
import '../pages/forgot_password_page.dart';
import '../dialogs/unverified_email_dialog.dart';
import '../../common/dialogs/app_dialogs.dart';
import 'package:peluqueria_lina_app/src/widgets/custom_input_field.dart';
import 'auth_message_dialog.dart';

// LoginForm es el formulario donde el usuario ingresa sus datos para iniciar sesión
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Controladores para los campos de texto
  final _formKey = GlobalKey<FormState>(); // Llave para validar el formulario
  final _emailCtrl = TextEditingController(); // Controlador para el email
  final _passCtrl = TextEditingController(); // Controlador para la contraseña
  bool _obscure = true; // Para mostrar/ocultar la contraseña
  bool _loading = false; // Para mostrar el indicador de carga

  @override
  void dispose() {
    // Liberar recursos de los controladores
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono decorativo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [AppColors.gold, Colors.transparent],
                          radius: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: AppColors.gold,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Formulario centrado y con ancho máximo
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Form(
                        key: _formKey, // Asocia la llave para validación
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mensaje de bienvenida
                            const Text(
                              'Bienvenido, inicia sesión para continuar',
                              style: TextStyle(color: AppColors.gray, fontSize: 13),
                            ),
                            const SizedBox(height: 14), // Espacio vertical
                            // Campo de correo electrónico
                            CustomInputField(
                              controller: _emailCtrl,
                    label: 'Correo',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email, // Usa función de validación
                  ),
                  const SizedBox(height: 10),
                  // Campo de contraseña con opción de mostrar/ocultar
                  CustomInputField(
                    controller: _passCtrl,
                    label: 'Contraseña',
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.gray,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Enlace "¿Olvidaste tu contraseña?" - Dorado y visible
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_reset,
                        size: 18,
                        color: AppColors.gold,
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.gold,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Botón para iniciar sesión
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold, // Fondo dorado
                      foregroundColor: Colors.black,   // Letras negras
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading
                        ? null
                        : () async {
                            // Validar el formulario
                            if (!(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            
                            // Mostrar diálogo de carga
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => PopScope(
                                canPop: false,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.charcoal,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: AppColors.gold),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Iniciando sesión...',
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                            
                            setState(() => _loading = true);
                            
                            try {
                              // Llamar al servicio de login
                              final res = await AuthService.instance.login(
                                email: _emailCtrl.text.trim(),
                                password: _passCtrl.text,
                              );
                              print('Respuesta login: $res');
                              
                              // El JSON de login tiene los datos directamente, no en res.user
                              final isEmailVerified =
                                  res['emailVerified'] ??
                                  res['isEmailVerified'] ??
                                  res['email_verified'] ??
                                  res['verified'] ??
                                  true;
                              
                              if (isEmailVerified == false) {
                                setState(() => _loading = false);
                                if (!mounted) return;
                                Navigator.of(context).pop(); // Cerrar loading
                                
                                // Esperar un momento para que se cierre el loading
                                await Future.delayed(const Duration(milliseconds: 300));
                                if (!mounted) return;
                                
                                // Mostrar diálogo de advertencia
                                await AuthMessageDialog.show(
                                  context,
                                  title: 'Email No Verificado',
                                  message: 'Debes verificar tu correo electrónico antes de continuar. Revisa tu bandeja de entrada.',
                                  type: MessageType.warning,
                                );
                                
                                if (!mounted) return;
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
                              
                              // Guardar los tokens de acceso
                              await TokenStorage.instance.saveTokens(
                                accessToken: res['accessToken'],
                                refreshToken: res['refreshToken'] ?? '',
                              );
                              
                              // Iniciar el monitoreo de sesión (20 minutos de inactividad)
                              SessionManager().startSession();
                              
                              if (!mounted) return;
                              
                              // Cerrar diálogo de carga
                              Navigator.of(context).pop();
                              
                              // Mostrar éxito brevemente y redirigir automáticamente
                              await AuthMessageDialog.showAuto(
                                context,
                                title: '¡Bienvenido!',
                                message: 'Has iniciado sesión correctamente',
                                type: MessageType.success,
                                seconds: 2,
                                onClose: () => _redirectToDashboard(res),
                              );
                            } catch (e) {
                              setState(() => _loading = false);
                              if (!mounted) return;
                              Navigator.of(context).pop(); // Cerrar loading
                              
                              // Convertir error a string
                              String errorMsg = e.toString();
                              if (errorMsg.startsWith('Exception: ')) {
                                errorMsg = errorMsg.substring(11);
                              }
                              
                              print('[LOGIN_ERROR] $errorMsg');
                              
                              // Detectar si es error de email no verificado
                              final isEmailNotVerified = errorMsg.toLowerCase().contains('correo') || 
                                                        errorMsg.toLowerCase().contains('email') ||
                                                        errorMsg.toLowerCase().contains('verif') ||
                                                        errorMsg.contains('Confirme primero');
                              
                              if (isEmailNotVerified) {
                                // Mostrar diálogo de email no verificado
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => UnverifiedEmailDialog(
                                    email: _emailCtrl.text.trim(),
                                    token: '',  // Sin token, se pedirá reenviar
                                  ),
                                );
                                return;
                              }
                              
                              // Detectar si es error de credenciales inválidas
                              final isInvalidCredentials = errorMsg.toLowerCase().contains('credenciales') ||
                                                          errorMsg.toLowerCase().contains('usuario') ||
                                                          errorMsg.toLowerCase().contains('contraseña') ||
                                                          errorMsg.toLowerCase().contains('password') ||
                                                          errorMsg.toLowerCase().contains('incorrectos') ||
                                                          errorMsg.toLowerCase().contains('invalid');
                              
                              // Mostrar error con diálogo elegante
                              await AuthMessageDialog.show(
                                context,
                                title: isInvalidCredentials ? 'Credenciales Incorrectas' : 'Error de Inicio de Sesión',
                                message: isInvalidCredentials 
                                    ? 'El correo o la contraseña que ingresaste no son correctos. Por favor verifica tus datos e intenta nuevamente.'
                                    : errorMsg,
                                type: MessageType.error,
                                confirmText: 'Reintentar',
                              );
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 16),
                 /* // Botón para crear cuenta
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(color: AppColors.gold, fontSize: 16),
                    ),
                  ),*/
                  const SizedBox(height: 8),
                  // Botón de texto para registro alternativo
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text('¿No tienes cuenta? Regístrate aquí'),
                  ),
                ],
              ),
            ),
          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _redirectToDashboard(Map<String, dynamic> res) {
    // Redirigir según el rol (normalizado)
    final userData = res['user'] ?? res;
    final token = res['accessToken'] ?? '';
    print('🔐 Token del login: $token');
    print('🔐 userData recibido: $userData');
    
    // Agregar token a userData para que se pase a los dashboards
    userData['accessToken'] = token;
    userData['token'] = token;
    
    final role = (userData['role'] ?? '').toString().toUpperCase().trim();
    print('✅ Rol normalizado: "$role"');
    print('🔑 Token en userData ahora: ${userData['accessToken'] ?? userData['token'] ?? "NO ENCONTRADO"}');
    
    Widget dashboard;
    if (role == 'CLIENTE') {
      print('➡️ Redirigiendo a ClientDashboardPage');
      dashboard = ClientDashboardPage(user: userData);
    } else if (role == 'ESTILISTA') {
      print('➡️ Redirigiendo a StylistDashboardPage');
      dashboard = StylistDashboardPage(user: userData);
    } else if (role == 'GERENTE') {
      print('➡️ Redirigiendo a ManagerDashboardPage');
      dashboard = ManagerDashboardPage(user: userData);
    } else if (role == 'ADMIN') {
      print('➡️ Redirigiendo a AdminDashboardPage');
      dashboard = AdminDashboardPage(user: userData);
    } else {
      print('❌ ERROR: Rol desconocido: "$role". Redirigiendo al login.');
      AppDialogHelper.showError(
        context,
        title: 'Error',
        message: 'Rol no reconocido. Por favor contacta soporte.',
      );
      return;
    }
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false,
    );
  }
}