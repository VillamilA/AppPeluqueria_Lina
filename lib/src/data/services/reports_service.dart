import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../../api/reports_api.dart';
import '../models/report_models.dart';

class ReportsService {
  final ReportsApi _api;

  ReportsService(this._api);

  /// Obtiene el resumen general del local
  Future<SummaryReport> getSummary(String token, String from, String to) async {
    final response = await _api.getSummaryReport(
      token: token,
      fromDate: from,
      toDate: to,
    );

    if (response.statusCode == 200) {
      return SummaryReport.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener resumen: ${response.statusCode} - ${response.body}');
    }
  }

  /// Obtiene ingresos por día
  Future<Map<String, dynamic>> getRevenue(String token, String from, String to) async {
    final response = await _api.getRevenueReport(
      token: token,
      fromDate: from,
      toDate: to,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener ingresos: ${response.statusCode} - ${response.body}');
    }
  }

  /// Obtiene ingresos por estilista
  Future<Map<String, dynamic>> getStylistsRevenue(String token, String from, String to) async {
    final response = await _api.getStylistsRevenueReport(
      token: token,
      fromDate: from,
      toDate: to,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener ingresos por estilista: ${response.statusCode} - ${response.body}');
    }
  }

  /// Obtiene reporte detallado de estilistas
  Future<StylistReport> getStylistsReport(
    String token,
    String from,
    String to, {
    String? stylistId,
  }) async {
    final response = await _api.getStylistsDetailedReport(
      token: token,
      fromDate: from,
      toDate: to,
      stylistId: stylistId,
    );

    if (response.statusCode == 200) {
      return StylistReport.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener reporte de estilistas: ${response.statusCode} - ${response.body}');
    }
  }

  /// Obtiene mi reporte personal (ESTILISTA)
  Future<StylistReport> getMyReport(String token, String from, String to) async {
    final response = await _api.getMyReport(
      token: token,
      fromDate: from,
      toDate: to,
    );

    if (response.statusCode == 200) {
      return StylistReport.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener mi reporte: ${response.statusCode} - ${response.body}');
    }
  }

  /// Descarga y guarda el PDF del reporte general
  Future<String> downloadGeneralPdf(String token, String from, String to) async {
    final response = await _api.downloadGeneralReportPdf(
      token: token,
      fromDate: from,
      toDate: to,
    );

    if (response.statusCode == 200) {
      return await _savePdfFile(response.bodyBytes, 'reporte_general');
    } else {
      throw Exception('Error al descargar PDF general: ${response.statusCode} - ${response.body}');
    }
  }

  /// Descarga y guarda el PDF del reporte de estilistas
  Future<String> downloadStylistsPdf(
    String token,
    String from,
    String to, {
    String? stylistId,
  }) async {
    final response = await _api.downloadStylistsReportPdf(
      token: token,
      fromDate: from,
      toDate: to,
      stylistId: stylistId,
    );

    if (response.statusCode == 200) {
      return await _savePdfFile(response.bodyBytes, 'reporte_estilistas');
    } else {
      throw Exception('Error al descargar PDF de estilistas: ${response.statusCode} - ${response.body}');
    }
  }

  /// Descarga y guarda el PDF del reporte personal
  Future<String> downloadMyPdf(String token, String from, String to) async {
    final response = await _api.downloadMyReportPdf(
      token: token,
      fromDate: from,
      toDate: to,
    );

    if (response.statusCode == 200) {
      return await _savePdfFile(response.bodyBytes, 'mi_reporte');
    } else {
      throw Exception('Error al descargar mi PDF: ${response.statusCode} - ${response.body}');
    }
  }

  /// Guarda el archivo PDF en el almacenamiento del dispositivo
  Future<String> _savePdfFile(List<int> bytes, String prefix) async {
    try {
      // Obtener el directorio de documentos del usuario
      final Directory directory = await getDownloadsDirectory() ?? 
                                   await getApplicationDocumentsDirectory();

      // Crear nombre de archivo con timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = '${prefix}_$timestamp.pdf';
      final String filePath = '${directory.path}/$filename';

      // Escribir el archivo
      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      print('[REPORTS_SERVICE] PDF guardado en: $filePath');
      return filePath;
    } catch (e) {
      print('[REPORTS_SERVICE] Error al guardar PDF: $e');
      throw Exception('Error al guardar el archivo PDF: $e');
    }
  }

  /// Abre el archivo PDF guardado en Android
  Future<void> openPdfFile(String filePath) async {
    try {
      const platform = MethodChannel('com.peluquerialina.app/pdf');
      await platform.invokeMethod('openPdf', {'filePath': filePath});
      print('[REPORTS_SERVICE] PDF abierto correctamente: $filePath');
    } catch (e) {
      print('[REPORTS_SERVICE] Error al abrir PDF: $e');
      throw Exception('Error al abrir el archivo PDF: $e');
    }
  }
}
