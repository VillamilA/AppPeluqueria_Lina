import 'package:http/http.dart' as http;
import 'api_client.dart';

class SlotsApi {
  final ApiClient _client;
  SlotsApi(this._client);

  /// Crear horarios para un estilista
  Future<http.Response> createSlots(
    Map<String, dynamic> data, {
    required String token,
  }) async {
    print('🟦 SlotsApi.createSlots:');
    print('  - Endpoint: POST /api/v1/slots/day');
    print('  - Data: $data');
    print('  - Token: ${token.substring(0, 20)}...');
    
    final response = await _client.post(
      '/api/v1/slots/day',
      body: data,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    print('🟦 Response status: ${response.statusCode}');
    print('  - Body: ${response.body}');
    
    return response;
  }

  /// Obtener horarios de un estilista
  Future<http.Response> getSlots({
    required String stylistId,
    String? dayOfWeek,
    String? token,
  }) async {
    String path = '/api/v1/slots?stylistId=$stylistId';
    if (dayOfWeek != null) {
      path += '&dayOfWeek=$dayOfWeek';
    }
    return await _client.get(
      path,
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
  }

  /// Eliminar un horario
  Future<http.Response> deleteSlot(
    String slotId, {
    required String token,
  }) async =>
      await _client.post(
        '/api/v1/slots/$slotId/delete',
        headers: {'Authorization': 'Bearer $token'},
      );
}
