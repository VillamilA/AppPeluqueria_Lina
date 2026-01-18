import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Diálogo elegante y profesional para mostrar mensajes al usuario
/// Incluye animaciones suaves y diseño responsive
class AuthMessageDialog extends StatelessWidget {
  final String title;
  final String message;
  final MessageType type;
  final VoidCallback? onConfirm;
  final String? confirmText;

  const AuthMessageDialog({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onConfirm,
    this.confirmText,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? size.width * 0.9 : 360,
        ),
        decoration: BoxDecoration(
          color: AppColors.charcoal, // Negro elegante de la empresa
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Espacio superior
            SizedBox(height: isSmallScreen ? 32 : 36),
            
            // Icono simple y clásico
            Container(
              width: isSmallScreen ? 60 : 70,
              height: isSmallScreen ? 60 : 70,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                color: Colors.white,
                size: isSmallScreen ? 32 : 38,
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 18 : 22),
            
            // Título clásico
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.gold, // Dorado para el título
                  fontSize: isSmallScreen ? 19 : 21,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 12 : 14),
            
            // Mensaje
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 28),
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.gray, // Gris para el mensaje
                  fontSize: isSmallScreen ? 14 : 15,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 28 : 32),
            
            // Solo mostrar botón si hay confirmText
            if (confirmText != null && confirmText!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: isSmallScreen ? 24 : 28,
                  right: isSmallScreen ? 24 : 28,
                  bottom: isSmallScreen ? 24 : 28,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 44 : 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold, // Botón dorado
                      foregroundColor: Colors.black, // Texto negro
                      elevation: 4,
                      shadowColor: AppColors.gold.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmText ?? 'Entendido',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: isSmallScreen ? 24 : 28),
          ],
        ),
      ),
    );
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case MessageType.success:
        return const Color(0xFF4CAF50); // Verde suave para éxito
      case MessageType.error:
        return const Color(0xFFD32F2F); // Rojo clásico
      case MessageType.warning:
        return const Color(0xFFF57C00); // Naranja cálido
      case MessageType.info:
        return const Color(0xFF1976D2); // Azul clásico
    }
  }

  IconData _getIcon() {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.cancel;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.info:
        return Icons.info;
    }
  }

  /// Método estático para mostrar el diálogo fácilmente
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required MessageType type,
    VoidCallback? onConfirm,
    String? confirmText,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AuthMessageDialog(
        title: title,
        message: message,
        type: type,
        onConfirm: onConfirm,
        confirmText: confirmText,
      ),
    );
  }

  /// Método para mostrar diálogo que se cierra automáticamente después de unos segundos
  static Future<void> showAuto(
    BuildContext context, {
    required String title,
    required String message,
    required MessageType type,
    VoidCallback? onClose,
    int seconds = 2,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AuthMessageDialog(
        title: title,
        message: message,
        type: type,
        confirmText: '',
      ),
    );
    
    await Future.delayed(Duration(seconds: seconds));
    
    if (context.mounted) {
      Navigator.of(context).pop();
      onClose?.call();
    }
  }
}

enum MessageType {
  success,
  error,
  warning,
  info,
}
