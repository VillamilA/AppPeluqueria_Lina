import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'dart:convert';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<http.Response> login(String email, String password) async {
    return await _client.post('/api/v1/auth/login', body: '{"email": "$email", "password": "$password"}');
  }

  Future<http.Response> register(Map<String, dynamic> data) async {
    return await _client.post('/api/v1/auth/register', body: data);
  }

  Future<http.Response> sendVerification(String email) async {
    return await _client.post('/api/v1/auth/send-verification', body: '{"email": "$email"}');
  }

  Future<http.Response> verifyEmail(String code) async {
    return await _client.post('/api/v1/auth/verify-email', body: '{"code": "$code"}');
  }

  /// Solicita código de recuperación de contraseña
  Future<http.Response> forgotPassword(String email) async {
    return await _client.post(
      '/api/v1/auth/forgot-password',
      body: json.encode({'email': email}),
    );
  }

  /// Restablece la contraseña con código de recuperación
  Future<http.Response> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return await _client.post(
      '/api/v1/auth/reset-password',
      body: json.encode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );
  }
}
