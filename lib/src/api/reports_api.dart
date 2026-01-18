import 'package:http/http.dart' as http;
import 'api_client.dart';

class ReportsApi {
  final ApiClient _client;

  ReportsApi(this._client);

  /// Obtiene el resumen general de reportes con rango de fechas
  /// GET /api/v1/reports/summary?from=YYYY-MM-DD&to=YYYY-MM-DD
  /// Roles requeridos: ADMIN, GERENTE
  Future<http.Response> getSummaryReport({
    required String token,
    required String fromDate,  // Formato: YYYY-MM-DD
    required String toDate,    // Formato: YYYY-MM-DD
  }) async {
    try {
      final url = '/api/v1/reports/summary?from=$fromDate&to=$toDate';
      
      print('[REPORTS_API] getSummaryReport:');
      print('  URL: $url');
      print('  From: $fromDate, To: $toDate');
      
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      print('[REPORTS_API] getSummaryReport - Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[REPORTS_API] Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      print('[REPORTS_API] getSummaryReport Error: $e');
      return http.Response('{"error": "Error en la solicitud: $e"}', 500);
    }
  }

  /// Obtiene el reporte detallado de ingresos por día
  /// GET /api/v1/reports/revenue?from=YYYY-MM-DD&to=YYYY-MM-DD
  /// Roles requeridos: ADMIN, GERENTE
  Future<http.Response> getRevenueReport({
    required String token,
    required String fromDate,  // Formato: YYYY-MM-DD
    required String toDate,    // Formato: YYYY-MM-DD
  }) async {
    try {
      final url = '/api/v1/reports/revenue?from=$fromDate&to=$toDate';
      
      print('[REPORTS_API] getRevenueReport:');
      print('  URL: $url');
      print('  From: $fromDate, To: $toDate');
      
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      print('[REPORTS_API] getRevenueReport - Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[REPORTS_API] Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      print('[REPORTS_API] getRevenueReport Error: $e');
      return http.Response('{"error": "Error en la solicitud: $e"}', 500);
    }
  }

  /// Obtiene los ingresos agrupados por estilista
  /// GET /api/v1/reports/stylists-revenue?from=YYYY-MM-DD&to=YYYY-MM-DD
  /// Roles requeridos: ADMIN, GERENTE
  Future<http.Response> getStylistsRevenueReport({
    required String token,
    required String fromDate,  // Formato: YYYY-MM-DD
    required String toDate,    // Formato: YYYY-MM-DD
  }) async {
    try {
      final url = '/api/v1/reports/stylists-revenue?from=$fromDate&to=$toDate';
      
      print('[REPORTS_API] getStylistsRevenueReport:');
      print('  URL: $url');
      print('  From: $fromDate, To: $toDate');
      
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      print('[REPORTS_API] getStylistsRevenueReport - Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[REPORTS_API] Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      print('[REPORTS_API] getStylistsRevenueReport Error: $e');
      return http.Response('{"error": "Error en la solicitud: $e"}', 500);
    }
  }

  /// Obtiene reporte detallado por estilistas (1 o varios)
  /// GET /api/v1/reports/stylists?from=YYYY-MM-DD&to=YYYY-MM-DD&stylistId=<opcional>
  /// Roles requeridos: ADMIN, GERENTE, ESTILISTA
  Future<http.Response> getStylistsDetailedReport({
    required String token,
    required String fromDate,   // Formato: YYYY-MM-DD
    required String toDate,     // Formato: YYYY-MM-DD
    String? stylistId,          // Opcional: MongoDB ID del estilista
  }) async {
    try {
      String url = '/api/v1/reports/stylists?from=$fromDate&to=$toDate';
      if (stylistId != null && stylistId.isNotEmpty) {
        url += '&stylistId=$stylistId';
      }
      
      print('[REPORTS_API] getStylistsDetailedReport:');
      print('  URL: $url');
      print('  From: $fromDate, To: $toDate');
      if (stylistId != null) {
        print('  StylistId: $stylistId');
      }
      
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      print('[REPORTS_API] getStylistsDetailedReport - Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[REPORTS_API] Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      print('[REPORTS_API] getStylistsDetailedReport Error: $e');
      return http.Response('{"error": "Error en la solicitud: $e"}', 500);
    }
  }

  /// Obtiene mi reporte personal (Solo para ESTILISTA)
  /// GET /api/v1/reports/my?from=YYYY-MM-DD&to=YYYY-MM-DD
  /// Roles requeridos: ESTILISTA
  /// Nota: El estilista automáticamente ve su propio reporte
  Future<http.Response> getMyReport({
    required String token,
    required String fromDate,  // Formato: YYYY-MM-DD
    required String toDate,    // Formato: YYYY-MM-DD
  }) async {
    try {
      final url = '/api/v1/reports/my?from=$fromDate&to=$toDate';
      
      print('[REPORTS_API] getMyReport:');
      print('  URL: $url');
      print('  From: $fromDate, To: $toDate');
      
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      print('[REPORTS_API] getMyReport - Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[REPORTS_API] Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      print('[REPORTS_API] getMyReport Error: $e');
      return http.Response('{"error": "Error en la solicitud: $e"}', 500);
    }
  }

  /// Descarga PDF del reporte general del local
  /// GET /api/v1/reports/pdf?from=YYYY-MM-DD&to=YYYY-MM-DD
  /// Roles requeridos: ADMIN, GERENTE
  /// Retorna: application/pdf con Content-Disposition: attachment
  Future<http.Response> downloadGeneralReportPdf({
    required String token,
    required String fromDate,  // Formato: YYYY-MM-DD
    required String toDate,    // Formato: YYYY-MM-DD
  }) async {
    try {
      final url = '/api/v1/reports/pdf?from=$fromDate&to=$toDate';
      
      print('[REPORTS_API] downloadGeneralReportPdf:');
      print('  URL: $url');
      print('  From: $fromDate, To: $toDate');
      
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 60));

      print('[REPORTS_API] downloadGeneralReportPdf - Status: ${response.statusCode}');
      print('[REPORTS_API] Content-Type: ${response.headers['content-type']}');
      
      if (response.statusCode != 200) {
        print('[REPORTS_API] Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      print('[REPORTS_API] downloadGeneralReportPdf Error: $e');
      return http.Response('{"error": "Error en la solicitud: $e"}', 500);
    }
  }

  /// Descarga PDF del reporte detallado de estilistas
  /// GET /api/v1/reports/stylists/pdf?from=YYYY-MM-DD&to=YYYY-MM-DD&stylistId=<opcional>
  /// Roles requeridos: ADMIN, GERENTE, ESTILISTA
  /// Retorna: application/pdf con Content-Disposition: attachment
  Future<http.Response> downloadStylistsReportPdf({
    required String token,
    required String fromDate,   // Formato: YYYY-MM-DD
    required String toDate,     // Formato: YYYY-MM-DD
    String? stylistId,          // Opcional: MongoDB ID del estilista
  }) async {
    try {
      String url = '/api/v1/reports/stylists/pdf?from=$fromDate&to=$toDate';
      if (stylistId != null && stylistId.isNotEmpty) {
        url += '&stylistId=$stylistId';
      }
      
      print('[REPORTS_API] downloadStylistsReportPdf:');
      print('  URL: $url');
      print('  From: $fromDate, To: $toDate');
      if (stylistId != null) {
        print('  StylistId: $stylistId');
      }
      
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 60));

      print('[REPORTS_API] downloadStylistsReportPdf - Status: ${response.statusCode}');
      print('[REPORTS_API] Content-Type: ${response.headers['content-type']}');
      
      if (response.statusCode != 200) {
        print('[REPORTS_API] Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      print('[REPORTS_API] downloadStylistsReportPdf Error: $e');
      return http.Response('{"error": "Error en la solicitud: $e"}', 500);
    }
  }

  /// Descarga PDF del reporte personal (Solo para ESTILISTA)
  /// GET /api/v1/reports/my/pdf?from=YYYY-MM-DD&to=YYYY-MM-DD
  /// Roles requeridos: ESTILISTA
  /// Retorna: application/pdf con Content-Disposition: attachment
  Future<http.Response> downloadMyReportPdf({
    required String token,
    required String fromDate,  // Formato: YYYY-MM-DD
    required String toDate,    // Formato: YYYY-MM-DD
  }) async {
    try {
      final url = '/api/v1/reports/my/pdf?from=$fromDate&to=$toDate';
      
      print('[REPORTS_API] downloadMyReportPdf:');
      print('  URL: $url');
      print('  From: $fromDate, To: $toDate');
      
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 60));

      print('[REPORTS_API] downloadMyReportPdf - Status: ${response.statusCode}');
      print('[REPORTS_API] Content-Type: ${response.headers['content-type']}');
      
      if (response.statusCode != 200) {
        print('[REPORTS_API] Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      print('[REPORTS_API] downloadMyReportPdf Error: $e');
      return http.Response('{"error": "Error en la solicitud: $e"}', 500);
    }
  }
}