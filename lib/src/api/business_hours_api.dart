import 'package:http/http.dart' as http;
import 'api_client.dart';

class BusinessHoursApi {
  final ApiClient _apiClient;

  BusinessHoursApi(this._apiClient);

  /// GET /api/v1/schedules/business - Obtener horarios del negocio
  Future<http.Response> getBusinessHours() async {
    try {
      final response = await _apiClient.get('/api/v1/schedules/business');
      return response;
    } catch (e) {
      print('❌ Error getting business hours: $e');
      rethrow;
    }
  }

  /// PUT /api/v1/schedules/business - Crear/actualizar horarios del negocio
  Future<http.Response> upsertBusinessHours(
    Map<String, dynamic> payload,
    {required String token}
  ) async {
    try {
      // ← NO codificar a JSON aquí, dejar que ApiClient lo haga
      final response = await _apiClient.put(
        '/api/v1/schedules/business',
        body: payload,  // ← Pasar Map directo, no jsonEncode
        headers: {'Authorization': 'Bearer $token'},
      );
      return response;
    } catch (e) {
      print('❌ Error upserting business hours: $e');
      rethrow;
    }
  }

  /// DELETE /api/v1/schedules/business - Eliminar horarios del negocio
  Future<http.Response> deleteBusinessHours({required String token}) async {
    try {
      final response = await _apiClient.delete(
        '/api/v1/schedules/business',
        headers: {'Authorization': 'Bearer $token'},
      );
      return response;
    } catch (e) {
      print('❌ Error deleting business hours: $e');
      rethrow;
    }
  }
}
