import 'package:http/http.dart' as http;
import 'api_client.dart';

class ClientsApi {
  final ApiClient _client;
  ClientsApi(this._client);

  Future<http.Response> listClients() async =>
      await _client.get('/api/v1/clients');

  Future<http.Response> createClient(Map<String, dynamic> data) async =>
      await _client.post('/api/v1/clients', body: data);

  Future<http.Response> updateClient(String clientId, Map<String, dynamic> data) async =>
      await _client.put('/api/v1/clients/$clientId', body: data);

  Future<http.Response> deleteClient(String clientId) async =>
      await _client.delete('/api/v1/clients/$clientId');

  Future<http.Response> getClient(String clientId) async =>
      await _client.get('/api/v1/clients/$clientId');
}
