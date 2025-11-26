import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';
import '../widgets/register_form.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta'),
        backgroundColor: AppColors.charcoal, // Fondo negro
        foregroundColor: AppColors.gold,   ),// Letras doradas
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: RegisterForm(),
        ),
      ),
    );
  }
}
