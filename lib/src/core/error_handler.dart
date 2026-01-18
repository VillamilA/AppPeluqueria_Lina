import 'package:flutter/material.dart';
import '../data/services/token_storage.dart';

/// GlobalKey para acceder al Navigator desde cualquier lugar
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Gestor centralizado de errores HTTP para toda la aplicación
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  BuildContext? _context;
  bool _dialogShown = false;

  /// Registra el contexto para mostrar diálogos (alternativo)
  void registerContext(BuildContext context) {
    _context = context;
    print('[ERROR_HANDLER] Contexto registrado: ${_context != null}');
  }

  /// Maneja errores HTTP globalmente
  Future<void> handleHttpError(int statusCode, String? message) async {
    print('[ERROR_HANDLER] Manejando error $statusCode, dialogShown=$_dialogShown');
    
    // Evitar múltiples diálogos simultáneos
    if (_dialogShown) {
      print('[ERROR_HANDLER] Abortando: dialogShown ya es true');
      return;
    }

    _dialogShown = true;
    print('[ERROR_HANDLER] Mostrando diálogo para error $statusCode');

    switch (statusCode) {
      case 401:
        await _show401UnauthorizedDialog();
        break;
      case 403:
        await _show403ForbiddenDialog();
        break;
      case 500:
        print('[ERROR_HANDLER] Mostrando diálogo 500...');
        await _show500ServerErrorDialog();
        break;
      default:
        _dialogShown = false;
        break;
    }
  }

  /// Maneja específicamente errores de token expirado
  Future<void> handleTokenExpired() async {
    print('[ERROR_HANDLER] ✅ handleTokenExpired() llamado');
    
    // Si ya hay un diálogo mostrado, no mostrar otro
    if (_dialogShown) {
      print('[ERROR_HANDLER] ⚠️ Ya hay un diálogo mostrado, abortando');
      return;
    }

    _dialogShown = true;
    print('[ERROR_HANDLER] 🔥 MOSTRANDO DIÁLOGO DE SESIÓN EXPIRADA - Flag activado');
    
    await _showSessionExpiredDialog();
  }

  /// Diálogo específico para sesión expirada - Usando NavigatorKey para garantizar funcionamiento
  Future<void> _showSessionExpiredDialog() async {
    print('[ERROR_HANDLER] 🔥 _showSessionExpiredDialog iniciado');
    
    BuildContext? context = _getValidContext();
    if (context == null) {
      print('[ERROR_HANDLER] ❌ No hay contexto válido disponible');
      _dialogShown = false;
      return;
    }

    print('[ERROR_HANDLER] ✅ Contexto válido, mostrando AlertDialog...');
    
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          print('[ERROR_HANDLER] 🎨 Builder del diálogo ejecutándose');
          return AlertDialog(
            backgroundColor: const Color(0xFF282828),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
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
                  'Tu sesión ha expirado por inactividad o ha caducado.',
                  style: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por tu seguridad, debes iniciar sesión nuevamente.',
                  style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 14,
                    height: 1.4,
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
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFFD93D),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Serás redirigido al inicio de sesión.',
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
                    print('[ERROR_HANDLER] 👆 Usuario hizo click en "Volver al Login"');
                    Navigator.of(dialogContext).pop();
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
                      Icon(Icons.login_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Volver al Login',
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
          );
        },
      );
      print('[ERROR_HANDLER] ✅ Diálogo cerrado correctamente');
    } catch (e) {
      print('[ERROR_HANDLER] ❌ ERROR al mostrar diálogo: $e');
    } finally {
      // Resetear el flag cuando el diálogo se cierre
      _dialogShown = false;
      print('[ERROR_HANDLER] 🔄 Flag _dialogShown reseteado a false');
    }
  }

  /// Obtiene un contexto válido desde NavigatorKey o _context
  BuildContext? _getValidContext() {
    // Primero intenta con NavigatorKey (funciona en cualquier pantalla)
    if (navigatorKey.currentContext != null) {
      print('[ERROR_HANDLER] ✅ Usando contexto de NavigatorKey');
      return navigatorKey.currentContext;
    }
    
    // Alternativo: usa el contexto registrado
    if (_context != null && _context!.mounted) {
      print('[ERROR_HANDLER] ✅ Usando contexto registrado');
      return _context;
    }
    
    print('[ERROR_HANDLER] ❌ No hay contexto disponible');
    return null;
  }

  /// Diálogo para error 401 - Unauthorized
  Future<void> _show401UnauthorizedDialog() async {
    BuildContext? context = _getValidContext();
    if (context == null) {
      _dialogShown = false;
      return;
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFFFF6B6B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Autenticación Requerida',
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
                'Tu sesión ha expirado o las credenciales no son válidas.',
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
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFFD93D),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Por favor, inicia sesión nuevamente.',
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
                  Navigator.of(dialogContext).pop();
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
                      'Ir al Login',
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
    } finally {
      _dialogShown = false;
      print('[ERROR_HANDLER] Flag _dialogShown reseteado a false (401)');
    }
  }

  /// Diálogo para error 403 - Forbidden
  Future<void> _show403ForbiddenDialog() async {
    BuildContext? context = _getValidContext();
    if (context == null) {
      _dialogShown = false;
      return;
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.block,
                  color: Color(0xFFFFD93D),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Acceso Denegado',
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
                'No tienes permisos para acceder a este recurso.',
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
                    color: const Color(0xFFFFD93D).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFFD93D),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Verifica tu rol o solicita acceso al administrador.',
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
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE4A853),
                  foregroundColor: const Color(0xFF181818),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      _dialogShown = false;
      print('[ERROR_HANDLER] Flag _dialogShown reseteado a false (403)');
    }
  }

  /// Diálogo para error 500 - Server Error
  Future<void> _show500ServerErrorDialog() async {
    print('[ERROR_HANDLER] _show500ServerErrorDialog iniciado');
    
    BuildContext? context = _getValidContext();
    if (context == null) {
      print('[ERROR_HANDLER] Contexto no válido en _show500ServerErrorDialog');
      _dialogShown = false;
      return;
    }

    print('[ERROR_HANDLER] Mostrando AlertDialog para error 500...');
    
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '¡Oops! Tu sesión expiró',
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
                'Hubo un problema con el servidor. Por tu seguridad, tu sesión ha sido cerrada.',
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
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFFD93D),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Vuelve a iniciar sesión para continuar.',
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
                  Navigator.of(dialogContext).pop();
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
    } finally {
      _dialogShown = false;
      print('[ERROR_HANDLER] Flag _dialogShown reseteado a false (500)');
    }
  }

  /// Realiza el logout y redirige al login
  Future<void> _performLogout() async {
    print('[ERROR_HANDLER] Iniciando logout...');
    try {
      // Limpiar tokens almacenados
      await TokenStorage.instance.clearTokens();
      print('[ERROR_HANDLER] Tokens limpiados');

      // Redirigir al login usando NavigatorKey (funciona desde cualquier pantalla)
      if (navigatorKey.currentState != null) {
        print('[ERROR_HANDLER] Redirigiendo a /login mediante NavigatorKey...');
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      } else if (_context != null && _context!.mounted) {
        print('[ERROR_HANDLER] Redirigiendo a /login mediante contexto registrado...');
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      } else {
        print('[ERROR_HANDLER] No se puede redirigir: Navigator no disponible');
      }
    } catch (e) {
      print('[ERROR_HANDLER] Error durante logout: $e');
    } finally {
      _dialogShown = false;
      print('[ERROR_HANDLER] Logout completado, _dialogShown reset');
    }
  }

  /// Resetea el estado del diálogo
  void resetDialogState() {
    _dialogShown = false;
  }
}
