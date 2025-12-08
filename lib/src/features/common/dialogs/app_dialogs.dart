import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Diálogo de éxito
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onAccept;
  final String buttonText;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onAccept,
    this.buttonText = 'Aceptar',
  });

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade700,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 48),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: AppColors.gray, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 45),
              ),
              onPressed: () {
                Navigator.pop(context);
                onAccept?.call();
              },
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de error
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? subtitle;
  final VoidCallback? onAccept;
  final String buttonText;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.onAccept,
    this.buttonText = 'Aceptar',
  });

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade900,
              ),
              child: Icon(Icons.close, color: Colors.red, size: 48),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: AppColors.gray, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 45),
              ),
              onPressed: () {
                Navigator.pop(context);
                onAccept?.call();
              },
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de advertencia con dos opciones
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? subtitle;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

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
            Icon(
              Icons.warning_outlined,
              color: isDestructive ? Colors.red : Colors.orange,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: AppColors.gray, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDestructive ? Colors.red : Colors.orange)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isDestructive ? Colors.red : Colors.orange)
                        .withOpacity(0.3),
                  ),
                ),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    color: isDestructive ? Colors.red.shade300 : Colors.orange.shade300,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: Size(120, 45),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onCancel?.call();
                  },
                  child: Text(cancelText),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDestructive ? Colors.red.shade700 : AppColors.gold,
                    foregroundColor: isDestructive ? Colors.white : Colors.black,
                    minimumSize: Size(120, 45),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm?.call();
                  },
                  child: Text(confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de carga (loading)
class LoadingDialog extends StatelessWidget {
  final String? message;

  const LoadingDialog({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            if (message != null) ...[
              SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Diálogo de información
class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onAccept;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Aceptar',
    this.onAccept,
  });

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.2),
              ),
              child: Icon(Icons.info_outline, color: AppColors.gold, size: 48),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: AppColors.gray, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 45),
              ),
              onPressed: () {
                Navigator.pop(context);
                onAccept?.call();
              },
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

/// Utilidad para mostrar diálogos fácilmente
class AppDialogHelper {
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onAccept,
    String buttonText = 'Aceptar',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessDialog(
        title: title,
        message: message,
        onAccept: onAccept,
        buttonText: buttonText,
      ),
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    String? subtitle,
    VoidCallback? onAccept,
    String buttonText = 'Aceptar',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ErrorDialog(
        title: title,
        message: message,
        subtitle: subtitle,
        onAccept: onAccept,
        buttonText: buttonText,
      ),
    );
  }

  static void showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String? subtitle,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        subtitle: subtitle,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
      ),
    );
  }

  static void showLoading(
    BuildContext context, {
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingDialog(message: message),
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Aceptar',
    VoidCallback? onAccept,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => InfoDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onAccept: onAccept,
      ),
    );
  }

  /// Cierra el diálogo de carga actual
  static void dismissLoading(BuildContext context) {
    Navigator.pop(context);
  }
}
