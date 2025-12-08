import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

class AuthVerificationApi {
  final ApiClient _client;

  AuthVerificationApi(this._client);

  /// Enviar correo de verificación después del registro
  Future<http.Response> sendVerificationEmail({
    required String email,
    required String token,
  }) async =>
      await _client.post(
        '/api/v1/auth/send-verification-email',
        body: jsonEncode({'email': email}),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

  /// Reenviar correo de verificación (cooldown 90 segundos)
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
