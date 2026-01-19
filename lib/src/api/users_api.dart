import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

class UsersApi {
  final ApiClient _client;
  UsersApi(this._client);

  Future<http.Response> listUsers() async =>
      await _client.get('/api/v1/users');

  /// Obtener todos los usuarios con paginación y filtros
  /// GET /api/v1/users?page=1&limit=50&role=CLIENTE&isActive=true
  Future<http.Response> listAllUsers({
    required String token,
    int page = 1,
    int limit = 50,
    String? role,
    bool? isActive,
  }) async {
    String url = '/api/v1/users?page=$page&limit=$limit';
    if (role != null && role.isNotEmpty && role != 'ALL') {
      url += '&role=$role';
    }
    if (isActive != null) {
      url += '&isActive=$isActive';
    }
    
    print('📋 UsersApi.listAllUsers: GET $url');
    
    return await _client.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> getUser(String userId, {String? token}) async =>
      await _client.get('/api/v1/users/$userId', headers: token != null ? {'Authorization': 'Bearer $token'} : null);

  /// Actualizar usuario/estilista completo (PUT /api/v1/users/:userId/profile)
  /// Este es el endpoint CORRECTO para que ADMIN/GERENTE edite a otros usuarios
  /// Admin y Gerente pueden modificar sin problemas
  Future<http.Response> updateUserComplete(
    String userId,
    Map<String, dynamic> data, {
    required String token,
  }) async {
    print('✏️ UsersApi.updateUserComplete:');
    print('  - Endpoint: PUT /api/v1/users/$userId/profile');
    print('  - Data keys: ${data.keys.join(", ")}');
    
    return await _client.put(
      '/api/v1/users/$userId/profile',
      body: jsonEncode(data),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<http.Response> updateUser(String userId, Map<String, dynamic> data) async =>
      await _client.put('/api/v1/users/$userId/profile', body: data);

  Future<http.Response> getUsersByRole(String role, {String? token}) async =>
      await _client.get(
        '/api/v1/users?role=$role',
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

  Future<http.Response> updateUserStatus(
    String userId,
    bool isActive, {
    required String token,
  }) async =>
      await _client.patch(
        '/api/v1/users/$userId/status',
        body: {'isActive': isActive},
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Activar usuario/estilista (PATCH /api/v1/users/:stylistId/activate)
  Future<http.Response> activateUser(String userId, {required String token}) async {
    print('✅ UsersApi.activateUser: $userId');
    return await _client.patch(
      '/api/v1/users/$userId/activate',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// Desactivar usuario/estilista (PATCH /api/v1/users/:stylistId/deactivate)
  Future<http.Response> deactivateUser(String userId, {required String token}) async {
    print('❌ UsersApi.deactivateUser: $userId');
    return await _client.patch(
      '/api/v1/users/$userId/deactivate',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> updateMyProfile(Map<String, dynamic> data, String token) async {
    return await _client.put(
      '/api/v1/users/me',
      body: data,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> changePassword(Map<String, dynamic> data, String token) async {
    return await _client.post(
      '/api/v1/users/change-password',
      body: data,
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
