import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

class ServicesApi {
  final ApiClient _client;
  ServicesApi(this._client);

  /// Obtener todos los servicios
  Future<http.Response> listServices({String? token}) async =>
      await _client.get(
        '/api/v1/services',
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

  /// Obtener un servicio específico
  Future<http.Response> getService(String serviceId, {String? token}) async =>
      await _client.get(
        '/api/v1/services/$serviceId',
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

  /// Crear un nuevo servicio (requiere ADMIN o GERENTE)
  Future<http.Response> createService({
    required Map<String, dynamic> data,
    required String token,
  }) async =>
      await _client.post(
        '/api/v1/services',
        body: jsonEncode(data),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

  /// Actualizar un servicio (requiere ADMIN o GERENTE)
  Future<http.Response> updateService({
    required String serviceId,
    required Map<String, dynamic> data,
    required String token,
  }) async =>
      await _client.put(
        '/api/v1/services/$serviceId',
        body: jsonEncode(data),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

  /// Eliminar un servicio (requiere ADMIN o GERENTE)
  Future<http.Response> deleteService({
    required String serviceId,
    required String token,
  }) async =>
      await _client.delete(
        '/api/v1/services/$serviceId',
        headers: {'Authorization': 'Bearer $token'},
      );
}
