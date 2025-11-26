import 'package:http/http.dart' as http;
import 'api_client.dart';

class UsersApi {
  final ApiClient _client;
  UsersApi(this._client);

  Future<http.Response> listUsers() async =>
      await _client.get('/api/v1/users');

  Future<http.Response> getUser(String userId, {String? token}) async =>
      await _client.get('/api/v1/users/$userId', headers: token != null ? {'Authorization': 'Bearer $token'} : null);

  Future<http.Response> updateUser(String userId, Map<String, dynamic> data) async =>
      await _client.put('/api/v1/users/$userId/update', body: data);
}
