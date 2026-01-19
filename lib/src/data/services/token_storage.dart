import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();
  final _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _sessionTimestampKey = 'sessionTimestamp';

  /// Guarda tokens y timestamp de sesión
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _sessionTimestampKey, value: timestamp);
    print('[TOKEN_STORAGE] ✅ Tokens guardados. Sesión iniciada: $timestamp');
  }

  Future<String?> getAccessToken() async => await _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() async => await _storage.read(key: _refreshTokenKey);
  
  /// Obtiene el timestamp de la sesión (en milisegundos)
  Future<int?> getSessionTimestamp() async {
    final timestamp = await _storage.read(key: _sessionTimestampKey);
    return timestamp != null ? int.tryParse(timestamp) : null;
  }

  /// Verifica si la sesión es válida (no ha pasado más de 15 minutos)
  Future<bool> isSessionValid() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        print('[TOKEN_STORAGE] ❌ No hay token guardado');
        return false;
      }

      final timestamp = await getSessionTimestamp();
      if (timestamp == null) {
        print('[TOKEN_STORAGE] ❌ No hay timestamp de sesión');
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final durationMinutes = (now - timestamp) / (1000 * 60);
      
      final isValid = durationMinutes < 15;
      print('[TOKEN_STORAGE] Sesión válida: $isValid (${durationMinutes.toStringAsFixed(1)} min)');
      
      return isValid;
    } catch (e) {
      print('[TOKEN_STORAGE] ❌ Error verificando sesión: $e');
      return false;
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _sessionTimestampKey);
    print('[TOKEN_STORAGE] ✅ Tokens limpiados');
  }
}
