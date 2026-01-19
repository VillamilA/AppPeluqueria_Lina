import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

class AuthVerificationApi {
  final ApiClient _client;

  AuthVerificationApi(this._client);

  /// Enviar correo de verificación después del registro (sin autenticación)
  Future<http.Response> sendVerificationEmail({
    required String email,
    required String? token,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    
    // Si el token no es null, agregarlo al header
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return await _client.post(
      '/api/v1/auth/send-verification-email',
      body: jsonEncode({'email': email}),
      headers: headers,
    );
  }

  /// Reenviar correo de verificación (con token y cooldown 90 segundos)
  Future<http.Response> resendVerificationEmail({
    required String email,
    required String token,
  }) async =>
      await _client.post(
        '/api/v1/auth/resend-verification',
        body: jsonEncode({'email': email}),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
}
