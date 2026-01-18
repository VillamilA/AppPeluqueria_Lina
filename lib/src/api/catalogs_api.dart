import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

class CatalogsApi {
  final ApiClient _client;

  CatalogsApi(this._client);

  /// Obtener todos los catálogos
  Future<http.Response> getCatalogs({required String token}) async =>
      await _client.get(
        '/api/v1/catalog',
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Obtener un catálogo específico
  Future<http.Response> getCatalogById({
    required String catalogId,
    required String token,
  }) async =>
      await _client.get(
        '/api/v1/catalog/$catalogId',
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Obtener servicios de un catálogo
  Future<http.Response> getCatalogServices({
    required String catalogId,
    required String token,
  }) async =>
      await _client.get(
        '/api/v1/catalog/$catalogId/services',
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Crear un nuevo catálogo
  Future<http.Response> createCatalog({
    required String nombre,
    required String descripcion,
    String? imageUrl,
    bool activo = true,
    List<String> services = const [],
    required String token,
  }) async {
    final body = {
      'nombre': nombre,
      'descripcion': descripcion,
      'imageUrl': imageUrl ?? '',
      'activo': activo,
      'services': services,
    };

    return await _client.post(
      '/api/v1/catalog',
      body: jsonEncode(body),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  /// Actualizar un catálogo
  Future<http.Response> updateCatalog({
    required String catalogId,
    required String nombre,
    required String descripcion,
    String? imageUrl,
    bool? activo,
    List<String>? services,
    required String token,
  }) async {
    final body = {
      'nombre': nombre,
      'descripcion': descripcion,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (activo != null) 'activo': activo,
      if (services != null) 'services': services,
    };

    return await _client.put(
      '/api/v1/catalog/$catalogId',
      body: jsonEncode(body),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  /// Eliminar un catálogo
  Future<http.Response> deleteCatalog({
    required String catalogId,
    required String token,
  }) async =>
      await _client.delete(
        '/api/v1/catalog/$catalogId',
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Activar un catálogo (PATCH /api/v1/catalog/:id/activate)
  Future<http.Response> activateCatalog({
    required String catalogId,
    required String token,
  }) async =>
      await _client.patch(
        '/api/v1/catalog/$catalogId/activate',
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Desactivar un catálogo (PATCH /api/v1/catalog/:id/deactivate)
  Future<http.Response> deactivateCatalog({
    required String catalogId,
    required String token,
  }) async =>
      await _client.patch(
        '/api/v1/catalog/$catalogId/deactivate',
        headers: {'Authorization': 'Bearer $token'},
      );
}
