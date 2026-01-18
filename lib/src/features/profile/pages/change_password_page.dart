import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/change_password_section.dart';

class ChangePasswordPage extends StatelessWidget {
  final String token;

  const ChangePasswordPage({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Cambiar Contraseña',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ChangePasswordSection(token: token),
      ),
    );
  }
}
