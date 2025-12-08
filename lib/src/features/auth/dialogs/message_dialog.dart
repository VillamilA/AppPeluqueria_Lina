import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';

class MessageDialog extends StatefulWidget {
  final String message;
  final MessageType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const MessageDialog({super.key, 
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
  });

  @override
  State<MessageDialog> createState() => _MessageDialogState();
}

enum MessageType {
  success, // Verde
  error,   // Rojo
  warning, // Naranja
  info,    // Azul
}

class _MessageDialogState extends State<MessageDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    // Auto-dismiss después del tiempo especificado
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.type) {
      case MessageType.success:
        return Colors.green.shade600;
      case MessageType.error:
        return Colors.red.shade600;
      case MessageType.warning:
        return Colors.orange.shade600;
      case MessageType.info:
        return Colors.blue.shade600;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_outline;
      case MessageType.error:
        return Icons.error_outline;
      case MessageType.warning:
        return Icons.warning_amber;
      case MessageType.info:
        return Icons.info_outline;
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case MessageType.success:
        return 'Éxito';
      case MessageType.error:
        return 'Error';
      case MessageType.warning:
        return 'Advertencia';
      case MessageType.info:
        return 'Información';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getColor().withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getColor().withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getColor().withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(),
                    color: _getColor(),
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),

                // Título
                Text(
                  _getTitle(),
                  style: TextStyle(
                    color: _getColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),

                // Mensaje
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.gray,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: null,
                    minHeight: 3,
                    backgroundColor: _getColor().withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function para mostrar el diálogo
Future<void> showMessageDialog(
  BuildContext context, {
  required String message,
  required MessageType type,
  Duration duration = const Duration(seconds: 4),
  VoidCallback? onDismiss,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black26,
    builder: (context) => MessageDialog(
      message: message,
      type: type,
      duration: duration,
      onDismiss: onDismiss,
    ),
  );
}
