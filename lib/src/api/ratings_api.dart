import 'package:http/http.dart' as http;
import 'api_client.dart';

class RatingsApi {
  final ApiClient _client;
  RatingsApi(this._client);

  Future<http.Response> createRating({
    required String bookingId,
    required int estrellas,
    required String comentario,
    required String token,
  }) async {
    final data = {
      "bookingId": bookingId,
      "estrellas": estrellas,
      "comentario": comentario,
    };
    return await _client.post(
      '/api/v1/ratings',
      body: data,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> getRatingByBookingId(String bookingId, {String? token}) async {
    return await _client.get(
      '/api/v1/ratings/booking/$bookingId',
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
  }

  Future<http.Response> getReceivedRatings(String token) async {
    return await _client.get(
      '/api/v1/ratings/received',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> getMyRatings(String token) async {
    return await _client.get(
      '/api/v1/ratings/my',
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
