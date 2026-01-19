import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/login_form.dart';

// LoginPage es la pantalla principal de inicio de sesión
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _appVersion = 'v1.00';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
      print('📱 [LOGIN] Versión de app: $_appVersion');
    } catch (e) {
      print('⚠️ [LOGIN] Error obteniendo versión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold es el contenedor base de la pantalla, provee estructura visual
    return Scaffold(
      // AppBar es la barra superior de la pantalla, aquí ponemos el título
      appBar: AppBar(
        title: const Text('Iniciar Sesión'), // Título que aparece arriba
        backgroundColor: AppColors.charcoal, // Color de fondo del AppBar
        foregroundColor: AppColors.gold,     // Color del texto y los íconos
      ),
      // body es el contenido principal de la pantalla
      body: Stack(
        children: [
          SafeArea(
            // SafeArea evita que el contenido se superponga con la barra de estado del teléfono
            child: Center(
              // Center centra el contenido en la pantalla
              child: Padding(
                padding: EdgeInsets.all(16), // Espacio alrededor del contenido
                // LoginForm es el formulario de login modularizado
                child: LoginForm(),
              ),
            ),
          ),
          // Versión en la parte inferior
          Positioned(
            bottom: 16,
            right: 16,
            child: Text(
              _appVersion,
              style: TextStyle(
                color: AppColors.gold.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
