import 'package:http/http.dart' as http;
import 'api_client.dart';

class BookingsApi {
    Future<http.Response> getSlots({
        required String stylistId,
        required String serviceId,
        required String dayOfWeek,
        String? token,
    }) async {
        final path = '/api/v1/slots?stylistId=$stylistId&serviceId=$serviceId&dayOfWeek=$dayOfWeek';
        return await _client.get(path, headers: token != null ? {'Authorization': 'Bearer $token'} : null);
    }
  final ApiClient _client;
  BookingsApi(this._client);

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
