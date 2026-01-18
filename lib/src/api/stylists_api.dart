import 'package:http/http.dart' as http;
import 'dart:convert';
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

  /// Obtener catálogos/servicios asignados a un estilista
  /// GET /api/v1/stylists/:stylistId/catalogs
  /// Autenticación: Bearer Token (Estilista o Admin)
  Future<http.Response> getStylistCatalogs({
    required String stylistId,
    required String token,
  }) async {
    print('📚 StylistsApi.getStylistCatalogs:');
    print('  - Endpoint: GET /api/v1/stylists/$stylistId/catalogs');
    print('  - Stylist ID: $stylistId');
    
    final response = await _client.get(
      '/api/v1/stylists/$stylistId/catalogs',
      headers: {'Authorization': 'Bearer $token'},
    );
    
    print('📥 Response status: ${response.statusCode}');
    
    return response;
  }

  /// Actualizar servicios del estilista
  /// PUT /api/v1/stylists/:stylistId/services
  /// Autenticación: Bearer Token
  /// Roles permitidos: ADMIN, GERENTE
  Future<http.Response> updateStylistServices({
    required String stylistId,
    required List<String> serviceIds,
    required String token,
  }) async {
    print('🔄 StylistsApi.updateStylistServices:');
    print('  - Endpoint: PUT /api/v1/stylists/$stylistId/services');
    print('  - Services: ${serviceIds.length}');
    
    final response = await _client.put(
      '/api/v1/stylists/$stylistId/services',
      body: jsonEncode({'serviceIds': serviceIds}),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    print('📥 Response status: ${response.statusCode}');
    
    return response;
  }
}
