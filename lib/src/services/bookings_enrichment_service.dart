import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';

/// Servicio para enriquecer datos de citas con información de estilistas y servicios
/// Implementa la OPCIÓN 2 (Paralela) del documento clienteverinfo.md
class BookingsEnrichmentService {
  final String token;
  final Map<String, dynamic> _stylistCache = {};
  final Map<String, dynamic> _serviceCache = {};

  BookingsEnrichmentService({required this.token});

  /// Obtener información del estilista
  Future<Map<String, dynamic>> getStylistInfo(String stylistId) async {
    try {
      // Verificar cache
      if (_stylistCache.containsKey(stylistId)) {
        print('📦 Estilista en cache: $stylistId');
        return _stylistCache[stylistId]!;
      }

      print('📥 Obteniendo estilista: $stylistId');
      
      // Construir URL directamente
      final baseUrl = ApiClient.instance.baseUrl;
      final url = Uri.parse('$baseUrl/api/v1/stylists/$stylistId/catalogs');
      
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stylist = data['stylist'] ?? {};
        _stylistCache[stylistId] = stylist;
        print('✅ Estilista cargado: ${stylist['nombre']}');
        return stylist;
      } else {
        print('❌ Error obteniendo estilista (${response.statusCode}): ${response.body}');
        return {'nombre': 'Desconocido'};
      }
    } catch (e) {
      print('❌ Error en getStylistInfo: $e');
      return {'nombre': 'Desconocido'};
    }
  }

  /// Obtener información del servicio
  Future<Map<String, dynamic>> getServiceInfo(String serviceId) async {
    try {
      // Verificar cache
      if (_serviceCache.containsKey(serviceId)) {
        print('📦 Servicio en cache: $serviceId');
        return _serviceCache[serviceId]!;
      }

      print('📥 Obteniendo servicio: $serviceId');
      
      // Construir URL directamente
      final baseUrl = ApiClient.instance.baseUrl;
      final url = Uri.parse('$baseUrl/api/v1/services/$serviceId');
      
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final service = jsonDecode(response.body);
        _serviceCache[serviceId] = service;
        print(
            '✅ Servicio cargado: ${service['nombre']} - \$${service['precio']}');
        return service;
      } else {
        print('❌ Error obteniendo servicio (${response.statusCode}): ${response.body}');
        return {'nombre': 'Desconocido', 'precio': 0};
      }
    } catch (e) {
      print('❌ Error en getServiceInfo: $e');
      return {'nombre': 'Desconocido', 'precio': 0};
    }
  }

  /// Enriquecer una lista de citas con información de estilistas y servicios
  /// OPCIÓN 2: Paralela - Recomendada por rendimiento
  Future<List<Map<String, dynamic>>> enrichBookings(
      List<dynamic> bookings) async {
    try {
      print('🔄 Enriqueciendo ${bookings.length} citas...');
      print('🌐 Base URL: ${ApiClient.instance.baseUrl}');
      print('🔐 Token: ${token.substring(0, 20)}...');

      // Extraer IDs únicos
      final stylistIds = <String>{};
      final serviceIds = <String>{};

      for (var booking in bookings) {
        final stylistId = booking['estilistaId'];
        final serviceId = booking['servicioId'];
        if (stylistId != null) {
          stylistIds.add(stylistId);
          print('  └─ Booking: estilista=$stylistId, servicio=$serviceId');
        }
        if (serviceId != null) serviceIds.add(serviceId);
      }

      print('📊 Estilistas únicos: ${stylistIds.length} - ${stylistIds.toList()}');
      print('📊 Servicios únicos: ${serviceIds.length} - ${serviceIds.toList()}');

      // Hacer TODAS las llamadas en paralelo
      final futures = <Future>[];

      for (var id in stylistIds) {
        futures.add(getStylistInfo(id));
      }

      for (var id in serviceIds) {
        futures.add(getServiceInfo(id));
      }

      print('⏳ Esperando ${futures.length} llamadas en paralelo...');
      await Future.wait(futures);

      // Enriquecer las citas
      final enriched = <Map<String, dynamic>>[];
      for (var booking in bookings) {
        enriched.add({
          ...booking,
          'stylist': _stylistCache[booking['estilistaId']] ?? {},
          'service': _serviceCache[booking['servicioId']] ?? {},
        });
      }

      print('✅ Enriquecimiento completado');
      return enriched;
    } catch (e) {
      print('❌ Error en enrichBookings: $e');
      return [];
    }
  }

  /// Enriquecer una cita individual
  Future<Map<String, dynamic>> enrichSingleBooking(
      Map<String, dynamic> booking) async {
    try {
      final stylist = await getStylistInfo(booking['estilistaId']);
      final service = await getServiceInfo(booking['servicioId']);

      return {
        ...booking,
        'stylist': stylist,
        'service': service,
      };
    } catch (e) {
      print('❌ Error en enrichSingleBooking: $e');
      return booking;
    }
  }

  /// Limpiar cache (útil al logout)
  void clearCache() {
    _stylistCache.clear();
    _serviceCache.clear();
    print('🧹 Cache limpiado');
  }

  /// Obtener tamaño del cache (para debugging)
  String getCacheStats() {
    return 'Estilistas: ${_stylistCache.length}, Servicios: ${_serviceCache.length}';
  }
}
