import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmailVerificationDialog extends StatelessWidget {
  final String email;
  final bool isAfterRegistration;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    this.isAfterRegistration = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              child: const Icon(Icons.email, color: Colors.black, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              isAfterRegistration
                  ? '¡Registro exitoso!\nVerifica tu correo: $email'
                  : 'Verifica tu correo: $email',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
