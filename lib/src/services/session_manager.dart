import 'dart:async';
import 'package:flutter/material.dart';
import '../data/services/token_storage.dart';

/// Gestor de sesión que maneja la inactividad y cierre automático
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  BuildContext? _context;
  bool _sessionExpiredDialogShown = false;
  
  // Timer de inactividad
  Timer? _inactivityTimer;
  static const Duration _inactivityTimeout = Duration(minutes: 15);
  bool _isSessionActive = false;

  /// Registra el contexto actual para mostrar diálogos
  void registerContext(BuildContext context) {
    _context = context;
  }

  /// Limpia el contexto cuando ya no es necesario
  void clearContext() {
    _context = null;
    _sessionExpiredDialogShown = false;
  }

  /// Inicia el monitoreo de inactividad después del login
  void startSession() {
    _isSessionActive = true;
    _sessionExpiredDialogShown = false;
    resetInactivityTimer();
    print('[SESSION_MANAGER] Sesión iniciada - Timer de 15 minutos activado');
  }

  /// Detiene el monitoreo de inactividad
  void stopSession() {
    _isSessionActive = false;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    print('[SESSION_MANAGER] Sesión detenida');
  }

  /// Resetea el timer de inactividad (se llama en cada interacción)
  void resetInactivityTimer() {
    if (!_isSessionActive) return;

    _inactivityTimer?.cancel();
    
    _inactivityTimer = Timer(_inactivityTimeout, () {
      print('[SESSION_MANAGER] 20 minutos de inactividad detectados');
      _showSessionExpiredDialog();
    });
  }

  /// Registra actividad del usuario (llamar desde interceptores de API)
  void recordActivity() {
    if (_isSessionActive && !_sessionExpiredDialogShown) {
      resetInactivityTimer();
    }
  }

  /// Maneja errores de respuesta HTTP
  /// Retorna true si manejó el error, false si debe propagarse
  Future<bool> handleHttpError(dynamic error, {int? statusCode, String? message}) async {
    // Verificar si es un error 401 por inactividad
    if (statusCode == 401 && message != null) {
      final isInactivityExpiration = message.toLowerCase().contains('inactividad') ||
          message.toLowerCase().contains('expirada') ||
          message.toLowerCase().contains('sesión expirada');

      if (isInactivityExpiration) {
        await _showSessionExpiredDialog();
        return true; // Error manejado
      }
    }

    return false; // No manejado, propagar
  }

  /// Muestra diálogo de sesión expirada por inactividad
  Future<void> _showSessionExpiredDialog() async {
    if (_context == null || _sessionExpiredDialogShown) return;
    
    _sessionExpiredDialogShown = true;

    if (_context!.mounted) {
      await showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time_filled,
                  color: Color(0xFFFF6B6B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sesión Expirada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu sesión se cerró por inactividad después de 20 minutos sin actividad.',
                style: TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFFFFD93D),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Por seguridad, debes volver a iniciar sesión.',
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop(); // Cerrar diálogo
                  await _performLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE4A853),
                  foregroundColor: const Color(0xFF181818),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Volver a Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  /// Realiza el logout: limpia tokens y redirige al login
  Future<void> _performLogout() async {
    try {
      // Detener sesión y timer
      stopSession();
      
      // Limpiar tokens almacenados
      await TokenStorage.instance.clearTokens();
      
      // Redirigir al login
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      print('[SESSION_MANAGER] Error durante logout: $e');
    } finally {
      _sessionExpiredDialogShown = false;
    }
  }

  /// Verifica manualmente si la sesión está activa (llamada desde APIs)
  Future<void> checkSession({int? statusCode, String? errorMessage}) async {
    if (statusCode == 401) {
      await handleHttpError(
        Exception('Session expired'),
        statusCode: statusCode,
        message: errorMessage,
      );
    }
  }
}
