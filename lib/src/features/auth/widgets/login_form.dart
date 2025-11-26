import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/token_storage.dart';
import '../../../core/utils/validators.dart';
import '../pages/register_page.dart';
import 'email_verification_dialog.dart';
import 'package:peluqueria_lina_app/src/widgets/custom_input_field.dart';
import '../pages/dashboard_page.dart';

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
    return Center(
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
          const SizedBox(height: 24),
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
                  const SizedBox(height: 16), // Espacio vertical
                  // Campo de correo electrónico
                  CustomInputField(
                    controller: _emailCtrl,
                    label: 'Correo',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email, // Usa función de validación
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 18),
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
                            setState(() => _loading = true); // Mostrar carga
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
                                // Mostrar advertencia y popup de verificación
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
                                  builder: (context) => EmailVerificationDialog(
                                    email: _emailCtrl.text.trim(),
                                    isAfterRegistration: false,
                                  ),
                                );
                                return;
                              }
                              // Guardar los tokens de acceso
                              await TokenStorage.instance.saveTokens(
                                accessToken: res['accessToken'],
                                refreshToken: res['refreshToken'] ?? '',
                              );
                              if (!mounted) return;
                              // Mostrar check de éxito
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: AppColors.charcoal,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: const BoxDecoration(
                                            color: AppColors.gold,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, color: Colors.black, size: 32),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('¡Acceso exitoso!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                              await Future.delayed(const Duration(milliseconds: 1500));
                              if (!mounted) return;
                              // Redirigir según el rol
                              final role = res['role'] ?? '';
                              Widget dashboard;
                              if (role == 'cliente') {
                                dashboard = ClientDashboardPage(user: res);
                              } else if (role == 'estilista') {
                                dashboard = StylistDashboardPage(user: res);
                              } else if (role == 'gerente') {
                                dashboard = ManagerDashboardPage(user: res);
                              } else if (role == 'admin') {
                                dashboard = AdminDashboardPage(user: res);
                              } else {
                                dashboard = DashboardPage(user: res); // fallback
                              }
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => dashboard),
                                (route) => false,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              // Mostrar error en SnackBar
                              String errorMsg = e.toString();
                              if (errorMsg.startsWith('Exception: ')) {
                                errorMsg = errorMsg.substring(11);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: Colors.red.shade800,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
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
    );
  }
}
