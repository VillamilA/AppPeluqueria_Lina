import '../../api/api_client.dart';
import '../../api/auth_verification_api.dart';
import './token_storage.dart';

class VerificationService {
  static final VerificationService _instance = VerificationService._internal();

  factory VerificationService() {
    return _instance;
  }

  VerificationService._internal();

  static VerificationService get instance => _instance;

  AuthVerificationApi? _authVerificationApi;

  /// Obtener la instancia de AuthVerificationApi (lazy initialization)
  AuthVerificationApi _getApi() {
    _authVerificationApi ??= AuthVerificationApi(ApiClient.instance);
    return _authVerificationApi!;
  }

  /// Enviar correo de verificación (SIN autenticación)
  Future<bool> sendVerificationEmail(String email) async {
    try {
      final res = await _getApi().sendVerificationEmail(
        email: email,
        token: null, // No requiere token
      );

      print('📧 Response status: ${res.statusCode}');
      print('📧 Response body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        print('✅ Correo de verificación enviado a $email');
        return true;
      } else if (res.statusCode == 500) {
        print('❌ Error del servidor al enviar correo');
        throw Exception('El servidor no pudo enviar el correo. Por favor, intenta más tarde.');
      } else if (res.statusCode == 400) {
        print('❌ Email inválido o ya verificado');
        throw Exception('El email no es válido o ya está verificado.');
      } else {
        print('❌ Error al enviar correo: ${res.statusCode}');
        throw Exception('Error al enviar correo: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Exception en sendVerificationEmail: $e');
      rethrow;
    }
  }

  /// Reenviar correo de verificación (con cooldown 90s)
  /// 
  /// Si [tokenParam] es provided, lo usa.
  /// Si no, lo obtiene de TokenStorage.
  Future<bool> resendVerificationEmail(String email, {String? tokenParam}) async {
    try {
      // Usar token proporcionado o obtenerlo del almacenamiento
      String? token = tokenParam;
      if (token == null || token.isEmpty) {
        token = await TokenStorage.instance.getAccessToken();
      }
      
      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final res = await _getApi().resendVerificationEmail(
        email: email,
        token: token,
      );

      print('📧 Response status: ${res.statusCode}');
      print('📧 Response body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        print('✅ Correo de verificación reenviado a $email');
        return true;
      } else if (res.statusCode == 429) {
        // Too Many Requests - cooldown activo
        print('⏱️ Cooldown activo - esperar 90 segundos');
        throw Exception('Espera 90 segundos antes de intentar nuevamente');
      } else if (res.statusCode == 500) {
        print('❌ Error del servidor al reenviar correo');
        throw Exception('El servidor no pudo reenviar el correo. Por favor, intenta más tarde.');
      } else if (res.statusCode == 400) {
        print('❌ Email inválido o ya verificado');
        throw Exception('El email no es válido o ya está verificado.');
      } else {
        print('❌ Error al reenviar correo: ${res.statusCode}');
        throw Exception('Error al reenviar correo: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Exception en resendVerificationEmail: $e');
      rethrow;
    }
  }
}
