import 'package:http/http.dart' as http;
import 'api_client.dart';

class PaymentsApi {
  final ApiClient apiClient;

  PaymentsApi(this.apiClient);

  /// Obtener historial de pagos/comprobantes de transferencia (ADMIN/GERENTE)
  /// Puede filtrar por clientId opcionalmente
  Future<http.Response> getTransferProofs({
    required String token,
    String? clientId,
  }) async {
    try {
      final queryParams = clientId != null && clientId.isNotEmpty ? '?clientId=$clientId' : '';
      final url = '/api/v1/payments/transfer-proofs$queryParams';
      
      print('🔄 [GET TRANSFER PROOFS] URL: $url');
      print('🔄 [GET TRANSFER PROOFS] Token: ${token.substring(0, 20)}...');
      print('🔄 [GET TRANSFER PROOFS] clientId: "$clientId" (null? ${clientId == null}, empty? ${clientId?.isEmpty})');
      
      final response = await apiClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('✅ [GET TRANSFER PROOFS] Status: ${response.statusCode}');
      
      return response;
    } catch (e) {
      print('❌ Error en getTransferProofs: $e');
      return http.Response('Error: $e', 500);
    }
  }

  /// Confirmar pago de transferencia (ADMIN/GERENTE)
  Future<http.Response> confirmTransferPayment({
    required String bookingId,
    required String token,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/v1/payments/booking/$bookingId/confirm-transfer',
        body: '{}',  // ← Enviar JSON vacío en lugar de null
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      print('Error en confirmTransferPayment: $e');
      return http.Response('Error: $e', 500);
    }
  }

  /// Obtener mis reservas con información de pago
  Future<http.Response> getMyBookings(String token, {int page = 1, int limit = 20}) async {
    try {
      final response = await apiClient.get(
        '/api/v1/bookings/me?page=$page&limit=$limit',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      print('Error en getMyBookings: $e');
      return http.Response('Error: $e', 500);
    }
  }
}
