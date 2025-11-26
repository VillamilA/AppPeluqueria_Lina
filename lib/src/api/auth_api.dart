import 'package:http/http.dart' as http;
import 'api_client.dart';

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
}
