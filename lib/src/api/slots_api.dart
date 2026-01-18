import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

class SlotsApi {
  final ApiClient _client;
  SlotsApi(this._client);

  /// Crear horario de servicio (POST /api/v1/slots/day)
  /// URL SIEMPRE IGUAL - El stylistId y serviceId van en el BODY
  /// El servidor valida que el token coincida con el stylistId del body
  /// 
  /// Structure esperada:
  /// {
  ///   "stylistId": "507f1f77bcf86cd799439011",
  ///   "serviceId": "507f1f77bcf86cd799439013",
  ///   "dayOfWeek": "LUNES",
  ///   "dayStart": "08:00",
  ///   "dayEnd": "12:00"
  /// }
  Future<http.Response> createSlots(
    Map<String, dynamic> data, {
    required String token,
  }) async {
    print('🟦 SlotsApi.createSlots:');
    print('  - Endpoint: POST /api/v1/slots/day');
    print('  - Stylist ID (body): ${data['stylistId']}');
    print('  - Service ID (body): ${data['serviceId']}');
    print('  - Day of Week: ${data['dayOfWeek']}');
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

  /// Obtener horarios de un estilista (y opcionalmente filtrados por servicio)
  Future<http.Response> getSlots({
    required String stylistId,
    String? serviceId,
    String? dayOfWeek,
    String? token,
  }) async {
    String path = '/api/v1/slots?stylistId=$stylistId';
    if (serviceId != null) {
      path += '&serviceId=$serviceId';
    }
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

  /// Actualizar/Crear horario de trabajo (PUT /api/v1/schedules/stylist)
  /// URL SIEMPRE IGUAL - El stylistId va en el BODY
  /// El servidor valida que el token coincida con el stylistId del body
  /// 
  /// Roles permitidos: ESTILISTA (su propio), ADMIN, GERENTE
  /// 
  /// Structure esperada:
  /// {
  ///   "stylistId": "507f1f77bcf86cd799439011",
  ///   "dayOfWeek": 1,
  ///   "slots": [
  ///     {"start": "09:00", "end": "13:00"},
  ///     {"start": "14:00", "end": "18:00"}
  ///   ],
  ///   "exceptions": [
  ///     {
  ///       "date": "2026-01-20",
  ///       "closed": false,
  ///       "blocks": [{"start": "12:00", "end": "13:30"}]
  ///     }
  ///   ]
  /// }
  Future<http.Response> updateStylistSchedule({
    required Map<String, dynamic> scheduleData,
    required String token,
  }) async {
    print('📅 SlotsApi.updateStylistSchedule:');
    print('  - Endpoint: PUT /api/v1/schedules/stylist');
    print('  - Stylist ID (body): ${scheduleData['stylistId']}');
    print('  - Day of Week: ${scheduleData['dayOfWeek']}');
    print('  - Slots: ${scheduleData['slots']}');
    
    final response = await _client.put(
      '/api/v1/schedules/stylist',
      body: jsonEncode(scheduleData),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );
    
    print('📥 Response status: ${response.statusCode}');
    print('  - Body: ${response.body}');
    
    return response;
  }

  /// Crear horario de servicio (POST /api/v1/slots/day)
  /// URL SIEMPRE IGUAL - El stylistId y serviceId van en el BODY
  /// El servidor valida que el token coincida con el stylistId del body
  /// 
  /// Structure esperada:
  /// {
  ///   "stylistId": "507f1f77bcf86cd799439011",
  ///   "serviceId": "507f1f77bcf86cd799439013",
  ///   "dayOfWeek": "LUNES",
  ///   "dayStart": "08:00",
  ///   "dayEnd": "12:00"
  /// }

  /// Obtener horario del estilista
  /// GET /api/v1/schedules/stylist/:id
  Future<http.Response> getStylistSchedule({
    required String token,
    required String stylistId,
  }) async {
    final endpoint = '/api/v1/schedules/stylist/$stylistId';
    
    print('📅 SlotsApi.getStylistSchedule:');
    print('  - Endpoint: GET $endpoint');
    print('  - Stylist ID: $stylistId');
    
    final response = await _client.get(
      endpoint,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    print('📥 Schedule response: ${response.statusCode}');
    print('📋 Body: ${response.body}');
    
    return response;
  }
}
