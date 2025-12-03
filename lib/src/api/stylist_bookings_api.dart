import 'package:http/http.dart' as http;
import 'api_client.dart';

class StylistBookingsApi {
  final ApiClient _client;
  StylistBookingsApi(this._client);

  /// Obtener mis reservas como estilista autenticado
  Future<http.Response> getMyBookings(String token) async =>
      await _client.get(
        '/api/v1/bookings/mystyle',
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Confirmar una reserva
  Future<http.Response> confirmBooking(String bookingId, String token) async =>
      await _client.post(
        '/api/v1/bookings/$bookingId/confirm',
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Marcar reserva como completada
  Future<http.Response> completeBooking(String bookingId, String token) async =>
      await _client.post(
        '/api/v1/bookings/$bookingId/complete',
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Cancelar una reserva
  Future<http.Response> cancelBooking(String bookingId, String token) async =>
      await _client.post(
        '/api/v1/bookings/$bookingId/cancel',
        headers: {'Authorization': 'Bearer $token'},
      );
}
