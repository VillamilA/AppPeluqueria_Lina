import 'package:http/http.dart' as http;
import 'api_client.dart';

class BookingsApi {
  final ApiClient _client;
  BookingsApi(this._client);

  /// Obtener slots disponibles para un servicio en una fecha
  /// GET /api/v1/bookings/availability?date=YYYY-MM-DD&serviceId=ID
  /// Retorna un array directo de slots: [{ slotId, stylistId, stylistName, start, end }, ...]
  /// NO REQUIERE autenticación (público)
  Future<http.Response> getSlots({
    required String serviceId,
    required String date,
  }) async {
    String path = '/api/v1/bookings/availability?date=$date&serviceId=$serviceId';
    print('📍 BookingsApi.getSlots: $path');
    return await _client.get(path);
  }

  Future<http.Response> createBooking(Map<String, dynamic> data, {required String token}) async =>
      await _client.post('/api/v1/bookings', body: data, headers: {'Authorization': 'Bearer $token'});

  Future<http.Response> getClientBookings(String token) async =>
      await _client.get('/api/v1/bookings/me', headers: {'Authorization': 'Bearer $token'});

  Future<http.Response> getStylistBookings(String status) async =>
      await _client.get('/api/v1/bookings/mystyle?status=$status');

  Future<http.Response> getBookingsByStylistId(String stylistId, String status) async =>
      await _client.get('/api/v1/bookings/stylist/$stylistId?status=$status');

  Future<http.Response> getAllBookings(String status) async =>
      await _client.get('/api/v1/bookings/all?status=$status');

  Future<http.Response> getBookingDetails(String bookingId) async =>
      await _client.get('/api/v1/bookings/$bookingId');

  Future<http.Response> confirmBooking(String bookingId) async =>
      await _client.post('/api/v1/bookings/$bookingId/confirm');

  Future<http.Response> completeBooking(String bookingId) async =>
      await _client.post('/api/v1/bookings/$bookingId/complete');

  Future<http.Response> cancelBooking(String bookingId, {Map<String, dynamic>? data, String? token}) async =>
      await _client.post('/api/v1/bookings/$bookingId/cancel', body: data, headers: token != null ? {'Authorization': 'Bearer $token'} : null);

  Future<http.Response> rescheduleBooking(String bookingId, {required Map<String, dynamic> data, required String token}) async =>
      await _client.put('/api/v1/bookings/$bookingId/reschedule', body: data, headers: {'Authorization': 'Bearer $token'});
}
