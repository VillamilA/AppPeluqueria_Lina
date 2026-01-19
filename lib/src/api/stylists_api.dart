import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

/// Stylists API - Gestión de estilistas, catálogos y servicios
/// Documentación: estilista.md
class StylistsApi {
  final ApiClient _client;
  StylistsApi(this._client);

  /// ENDPOINT 1: GET /api/v1/stylists
  /// Listar todos los estilistas activos
  /// Autenticación: NO requerida (Público)
  /// Response: Array de objetos estilista con servicios y catálogos populate
  Future<http.Response> listStylists({String? token}) async {
    print('📋 StylistsApi.listStylists:');
    print('  - Endpoint: GET /api/v1/stylists');
    print('  - Autenticación: ${token != null ? 'Sí (Bearer)' : 'No'}');
    
    final response = await _client.get(
      '/api/v1/stylists',
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
    
    print('📥 Response status: ${response.statusCode}');
    return response;
  }

  /// POST /api/v1/stylists
  /// Crear nuevo estilista
  /// Autenticación: Bearer Token
  /// Roles permitidos: ADMIN, GERENTE
  /// Body: { nombre, apellido, cedula, email, password, telefono?, genero?, catalogs[] }
  Future<http.Response> createStylist(Map<String, dynamic> data) async =>
      await _client.post('/api/v1/stylists', body: data);

  /// PUT /api/v1/stylists/:id
  /// Actualizar estilista (genérico)
  Future<http.Response> updateStylist(String stylistId, Map<String, dynamic> data) async =>
      await _client.put('/api/v1/stylists/$stylistId', body: data);

  /// DELETE /api/v1/stylists/:id
  Future<http.Response> deleteStylist(String stylistId) async =>
      await _client.delete('/api/v1/stylists/$stylistId');

  /// GET /api/v1/stylists/:id
  /// Obtener un estilista específico
  Future<http.Response> getStylist(String stylistId) async =>
      await _client.get('/api/v1/stylists/$stylistId');

  /// ENDPOINT 2: GET /api/v1/stylists/:id/catalogs
  /// Ver catálogos asignados a un estilista con sus servicios
  /// Autenticación: NO requerida (Público)
  /// Response: { stylist: {id, nombre, apellido}, catalogs: [{_id, nombre, descripcion, activo, services: [...]}] }
  Future<http.Response> getStylistCatalogs({
    required String stylistId,
  }) async {
    print('📚 StylistsApi.getStylistCatalogs:');
    print('  - Endpoint: GET /api/v1/stylists/$stylistId/catalogs');
    print('  - Stylist ID: $stylistId');
    print('  - Autenticación: No requerida');
    
    final response = await _client.get('/api/v1/stylists/$stylistId/catalogs');
    
    print('📥 Response status: ${response.statusCode}');
    return response;
  }

  /// ENDPOINT 3: GET /api/v1/stylists/:id/catalogs/:catalogId/services
  /// Ver servicios de un catálogo específico de un estilista
  /// Autenticación: NO requerida (Público)
  /// Response: { stylist: {id, nombre, apellido}, catalog: {id, nombre, descripcion, services: [...]} }
  Future<http.Response> getStylistCatalogServices({
    required String stylistId,
    required String catalogId,
  }) async {
    print('🛍️ StylistsApi.getStylistCatalogServices:');
    print('  - Endpoint: GET /api/v1/stylists/$stylistId/catalogs/$catalogId/services');
    print('  - Stylist ID: $stylistId');
    print('  - Catalog ID: $catalogId');
    print('  - Autenticación: No requerida');
    
    final response = await _client.get(
      '/api/v1/stylists/$stylistId/catalogs/$catalogId/services',
    );
    
    print('📥 Response status: ${response.statusCode}');
    return response;
  }

  /// ENDPOINT 5: PUT /api/v1/stylists/:id/services
  /// Actualizar catálogos asignados a un estilista (recalcula servicesOffered automáticamente)
  /// Autenticación: Bearer Token
  /// Roles permitidos: ADMIN, GERENTE, ESTILISTA (ESTILISTA solo su propio ID)
  /// Body: { catalogs: ['id1', 'id2', ...] }
  /// Response: Estilista actualizado con catalogs y servicesOffered recalculados
  Future<http.Response> updateStylistCatalogs({
    required String stylistId,
    required List<String> catalogIds,
    required String token,
  }) async {
    print('🔄 StylistsApi.updateStylistCatalogs:');
    print('  - Endpoint: PUT /api/v1/stylists/$stylistId/services');
    print('  - Catalogs: ${catalogIds.length}');
    print('  - Autenticación: Bearer Token');
    
    final body = jsonEncode({'catalogs': catalogIds});
    final response = await _client.put(
      '/api/v1/stylists/$stylistId/services',
      body: body,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    print('📥 Response status: ${response.statusCode}');
    return response;
  }

  /// Método legacy - mantener compatibilidad
  /// (Usa updateStylistCatalogs en su lugar)
  @Deprecated('Use updateStylistCatalogs instead')
  Future<http.Response> updateStylistServices({
    required String stylistId,
    required List<String> serviceIds,
    required String token,
  }) async {
    print('⚠️ StylistsApi.updateStylistServices (DEPRECATED)');
    return updateStylistCatalogs(
      stylistId: stylistId,
      catalogIds: serviceIds,
      token: token,
    );
  }
}
