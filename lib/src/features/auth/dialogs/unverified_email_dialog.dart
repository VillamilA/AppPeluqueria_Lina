import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/verification_service.dart';
import 'message_dialog.dart';

class UnverifiedEmailDialog extends StatefulWidget {
  final String email;
  final String token;

  const UnverifiedEmailDialog({super.key, 
    required this.email,
    required this.token,
  });

  @override
  State<UnverifiedEmailDialog> createState() => _UnverifiedEmailDialogState();
}

class _UnverifiedEmailDialogState extends State<UnverifiedEmailDialog> {
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  bool _isResending = false;

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 90;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _cooldownTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0) return;

    setState(() => _isResending = true);

    try {
      // Si tiene token (usuario logueado), usar resendVerificationEmail
      // Si NO tiene token, usar sendVerificationEmail (endpoint público)
      if (widget.token.isNotEmpty) {
        // Usuario intentó login pero email no verificado - tiene token temporal
        await VerificationService.instance.resendVerificationEmail(
          widget.email,
          tokenParam: widget.token,
        );
      } else {
        // Usuario no logueado - usar endpoint público
        await VerificationService.instance.sendVerificationEmail(widget.email);
      }

      if (mounted) {
        await showMessageDialog(
          context,
          message: 'Correo de verificación reenviado exitosamente',
          type: MessageType.success,
          duration: Duration(seconds: 3),
        );
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
        
        await showMessageDialog(
          context,
          message: errorMsg,
          type: MessageType.error,
          duration: Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.charcoal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.orange,
                size: 40,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Correo no verificado',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Recuerda activar tu correo para acceder completamente a tu cuenta.',
              style: TextStyle(color: AppColors.gray, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              widget.email,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Revisa el correo que te enviamos.',
                          style: TextStyle(color: AppColors.gray, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Revisa también la carpeta de spam.',
                          style: TextStyle(color: AppColors.gray, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            if (_cooldownSeconds > 0)
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Reintenta en: $_cooldownSeconds seg',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cooldownSeconds > 0 ? Colors.grey : AppColors.gold,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _cooldownSeconds > 0 || _isResending ? null : _resendVerificationEmail,
              child: _isResending
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      'Reenviar correo de verificación',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
