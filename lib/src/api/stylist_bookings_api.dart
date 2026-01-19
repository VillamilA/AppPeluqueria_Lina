import 'package:http/http.dart' as http;
import 'dart:convert';
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

  /// Confirmar una reserva (PATCH /api/v1/bookings/{bookingId}/confirm)
  /// Solo ESTILISTA puede confirmar
  /// Sin body requerido
  Future<http.Response> confirmBooking(String bookingId, String token) async =>
      await _client.patch(
        '/api/v1/bookings/$bookingId/confirm',
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Marcar reserva como completada (PATCH /api/v1/bookings/{bookingId}/complete)
  /// Body: { clienteAsistio: boolean, precio?: number }
  /// Genera estados COMPLETED o NO_SHOW
  Future<http.Response> completeBooking(
    String bookingId,
    String token, {
    required bool clienteAsistio,
    double? precio,
  }) async =>
      await _client.patch(
        '/api/v1/bookings/$bookingId/complete',
        body: {
          'clienteAsistio': clienteAsistio,
          if (precio != null) 'precio': precio,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

  /// Cancelar una reserva con motivo (POST /api/v1/bookings/{bookingId}/cancel)
  /// Body: { motivo: string }
  /// Nota: Cliente tiene regla de 12 horas (congelación de cuenta si cancela tarde)
  Future<http.Response> cancelBooking(String bookingId, String token, {String? motivo}) async =>
      await _client.post(
        '/api/v1/bookings/$bookingId/cancel',
        headers: {'Authorization': 'Bearer $token'},
        body: motivo != null ? jsonEncode({'motivo': motivo}) : null,
      );
}
