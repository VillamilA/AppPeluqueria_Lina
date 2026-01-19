import 'package:http/http.dart' as http;
import 'api_client.dart';

/// API para gestión de pagos y transferencias
/// 
/// Implementa el flujo completo de pagos descrito en pagoyfactura.md:
/// 1. Cliente solicita pago (requestTransferPayment)
/// 2. Cliente sube comprobante (uploadTransferProof)
/// 3. Admin ve comprobantes pendientes (getTransferProofs)
/// 4. Admin confirma pago (confirmTransferPayment)
class PaymentsApi {
  final ApiClient apiClient;

  PaymentsApi(this.apiClient);

  /// **GET /api/v1/payments/transfer-proofs**
  /// 
  /// Obtiene lista de comprobantes pendientes de confirmación
  /// 
  /// **Parámetros:**
  /// - token: JWT del admin/gerente
  /// - clientId: (opcional) Filtrar por cliente específico
  /// 
  /// **Campos retornados (20 campos):**
  /// - _id, bookingId, amount, currency, method, status
  /// - transactionRef, transferProofUrl, transferProofUploadedAt
  /// - clientId, clientName, clientEmail, clientPhone
  /// - stylistName, serviceName, servicePrice
  /// - bookingDate, createdAt, updatedAt, invoiceNumber
  /// 
  /// **Validaciones:**
  /// - Solo ADMIN/GERENTE pueden ver
  /// - Muestra solo pagos con status = PENDING
  /// - Cada pago tiene toda la info necesaria para validar
  /// 
  /// **Response:**
  /// ```json
  /// {
  ///   "data": [
  ///     {
  ///       "amount": 30.00,
  ///       "clientName": "Carlos López",
  ///       "transactionRef": "RES-20260118-001",
  ///       "transferProofUrl": "https://...",
  ///       ...
  ///     }
  ///   ]
  /// }
  /// ```
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

  /// **POST /api/v1/payments/booking/{bookingId}/confirm-transfer**
  /// 
  /// Confirma pago de transferencia con transacción atómica
  /// 
  /// **Requisitos previos:**
  /// - Booking debe existir
  /// - Payment debe existir con status = PENDING
  /// - transferProofUrl debe estar presente (cliente subió imagen)
  /// - Booking.estado = PENDING_STYLIST_CONFIRMATION o COMPLETED
  /// 
  /// **Transacción atómica:**
  /// 1. Valida que pago sea PENDING
  /// 2. Actualiza Payment.status = PAID
  /// 3. Actualiza Booking.paymentStatus = PAID
  /// 4. Genera invoiceNumber (FCT-YYYYMMDD-XXXXX)
  /// 5. Registra paidAt = DateTime.now()
  /// 6. Genera PDF de factura
  /// 7. Envía email al cliente
  /// 
  /// **Si algo falla:**
  /// - Transacción se revierte (rollback)
  /// - Nada se guarda, estado queda PENDING
  /// - Se retorna error específico
  /// 
  /// **Response exitoso (200):**
  /// ```json
  /// {
  ///   "message": "Transferencia confirmada, pago registrado y cita confirmada",
  ///   "bookingId": "507f...",
  ///   "paymentId": "507f...",
  ///   "invoiceNumber": "FCT-20260118-001",
  ///   "transferProofUrl": "https://..."
  /// }
  /// ```
  /// 
  /// **Errores posibles:**
  /// - 409: Pago ya confirmado | Sin comprobante para confirmar
  /// - 404: Booking/Payment no existe
  /// - 403: No eres admin/gerente
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

  /// **GET /api/v1/bookings/me**
  /// 
  /// Obtiene mis reservas con información de pago
  /// 
  /// **Parámetros:**
  /// - page: Número de página (default: 1)
  /// - limit: Elementos por página (default: 20)
  /// 
  /// **Retorna:**
  /// - Listado de bookings del cliente actual
  /// - Incluye: precio, paymentStatus, paymentMethod, invoiceNumber, paidAt
  /// 
  /// **Campos en respuesta:**
  /// - estado: PENDING_STYLIST_CONFIRMATION, COMPLETED, CONFIRMED, CANCELLED, NO_SHOW
  /// - paymentStatus: UNPAID, PAID
  /// - paymentMethod: TRANSFER_PICHINCHA (cuando está pagado)
  /// - precio: Actualizado por estilista si agregó extras
  /// - invoiceNumber: Generado cuando admin confirma pago (FCT-...)
  /// - paidAt: Fecha cuando admin confirmó
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
