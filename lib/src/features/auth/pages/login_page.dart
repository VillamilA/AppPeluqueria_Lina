import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/login_form.dart';

// LoginPage es la pantalla principal de inicio de sesión
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
      body: const SafeArea(
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
    );
  }
}
