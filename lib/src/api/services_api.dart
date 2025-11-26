import 'package:http/http.dart' as http;
import 'api_client.dart';

class ServicesApi {
  final ApiClient _client;
  ServicesApi(this._client);

  Future<http.Response> listServices({String? token}) async =>
      await _client.get('/api/v1/services', headers: token != null ? {'Authorization': 'Bearer $token'} : null);

  Future<http.Response> createService(Map<String, dynamic> data) async =>
      await _client.post('/api/v1/services', body: data);

  Future<http.Response> updateService(String serviceId, Map<String, dynamic> data) async =>
      await _client.put('/api/v1/services/$serviceId', body: data);

  Future<http.Response> deleteService(String serviceId) async =>
      await _client.delete('/api/v1/services/$serviceId');

  Future<http.Response> getService(String serviceId) async =>
      await _client.get('/api/v1/services/$serviceId');
}
