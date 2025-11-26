import 'package:http/http.dart' as http;
import 'api_client.dart';

class StylistsApi {
  final ApiClient _client;
  StylistsApi(this._client);

  Future<http.Response> listStylists({String? token}) async =>
      await _client.get('/api/v1/stylists', headers: token != null ? {'Authorization': 'Bearer $token'} : null);

  Future<http.Response> createStylist(Map<String, dynamic> data) async =>
      await _client.post('/api/v1/stylists', body: data);

  Future<http.Response> updateStylist(String stylistId, Map<String, dynamic> data) async =>
      await _client.put('/api/v1/stylists/$stylistId', body: data);

  Future<http.Response> deleteStylist(String stylistId) async =>
      await _client.delete('/api/v1/stylists/$stylistId');

  Future<http.Response> getStylist(String stylistId) async =>
      await _client.get('/api/v1/stylists/$stylistId');
}
