import 'package:flutter/material.dart';
import 'dart:convert';
import '../src/api/api_client.dart';

class RatingsService {
  static final RatingsService _instance = RatingsService._internal();

  final Map<String, dynamic> _bookingCache = {};
  final Map<String, dynamic> _userCache = {};
  final Map<String, dynamic> _serviceCache = {};
  final Map<String, dynamic> _stylistCache = {};

  String? _token;

  RatingsService._internal();

  factory RatingsService() => _instance;

  // Establecer token
  void setToken(String token) {
    _token = token;
  }

  // ============================================
  // MÉTODO PRINCIPAL: OBTENER RATINGS ENRIQUECIDOS
  // ============================================
  Future<Map<String, dynamic>> getEstilistaRatingsEnriquecidos({
    required String stylistId,
    int page = 1,
    int limit = 20,
    int? minStars,
    int? maxStars,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      // Construir URL con parámetros
      String url = '/api/v1/ratings/stylist/$stylistId?page=$page&limit=$limit';

      if (minStars != null) url += '&minStars=$minStars';
      if (maxStars != null) url += '&maxStars=$maxStars';
      if (dateFrom != null) {
        final dateStr = dateFrom.toIso8601String().split('T')[0];
        url += '&dateFrom=$dateStr';
      }
      if (dateTo != null) {
        final dateStr = dateTo.toIso8601String().split('T')[0];
        url += '&dateTo=$dateStr';
      }

      debugPrint('🔗 Fetching: $url');

      final response = await ApiClient.instance.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Enriquecer cada calificación
        final enrichedRatings = <Map<String, dynamic>>[];

        for (final ratingDyn in data['data'] ?? []) {
          try {
            final rating = ratingDyn is Map<String, dynamic>
                ? ratingDyn
                : Map<String, dynamic>.from(ratingDyn as Map);
            final enriched = await _enrichRating(rating);
            enrichedRatings.add(enriched);
          } catch (e) {
            debugPrint('⚠️ Error enriqueciendo rating: $e');
            enrichedRatings.add(ratingDyn);
          }
        }

        return {
          'data': enrichedRatings,
          'meta': data['meta'] ?? {'page': page, 'limit': limit, 'total': 0},
          'success': true,
        };
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado - Token inválido o expirado');
      } else if (response.statusCode == 403) {
        throw Exception('No autorizado - Solo GERENTE/ADMIN puede ver esto');
      } else if (response.statusCode == 404) {
        throw Exception('Estilista no encontrado');
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en getEstilistaRatingsEnriquecidos: $e');
      return {
        'success': false,
        'error': e.toString(),
        'data': [],
        'meta': {'page': page, 'limit': limit, 'total': 0},
      };
    }
  }

  // ============================================
  // ENRIQUECER UNA CALIFICACIÓN
  // ============================================
  Future<Map<String, dynamic>> _enrichRating(Map<String, dynamic> rating) async {
    try {
      final bookingId = rating['bookingId'] as String?;
      final estilistaId = rating['estilistaId'] as String?;
      final clienteId = rating['clienteId'] as String?;

      // Obtener datos en paralelo
      final futures = <Future>[];
      if (bookingId != null) futures.add(_getOrFetchBooking(bookingId));
      if (estilistaId != null) futures.add(_getOrFetchUser(estilistaId));
      if (clienteId != null) futures.add(_getOrFetchUser(clienteId));

      final results = await Future.wait(futures);

      Map<String, dynamic>? booking;
      Map<String, dynamic>? estilista;
      Map<String, dynamic>? cliente;
      Map<String, dynamic>? servicio;

      int idx = 0;
      if (bookingId != null) {
        booking = results[idx] as Map<String, dynamic>?;
        idx++;
      }
      if (estilistaId != null) {
        estilista = results[idx] as Map<String, dynamic>?;
        idx++;
      }
      if (clienteId != null) {
        cliente = results[idx] as Map<String, dynamic>?;
      }

      // Obtener servicio desde booking
      if (booking != null && booking['servicioId'] != null) {
        servicio = await _getOrFetchService(booking['servicioId'] as String);
      }

      return {
        ...rating,
        'bookingData': booking,
        'stylistData': estilista,
        'clientData': cliente,
        'serviceData': servicio,
      };
    } catch (e) {
      debugPrint('Error enriqueciendo: $e');
      return rating;
    }
  }

  // ============================================
  // OBTENER O CACHEAR: BOOKING
  // ============================================
  Future<Map<String, dynamic>?> _getOrFetchBooking(String bookingId) async {
    if (_bookingCache.containsKey(bookingId)) {
      debugPrint('📦 Booking desde cache: $bookingId');
      return _bookingCache[bookingId];
    }

    try {
      final response = await ApiClient.instance.get(
        '/api/v1/bookings/$bookingId',
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final booking = jsonDecode(response.body);
        final bookingData = booking is Map ? (booking['data'] ?? booking) : booking;
        _bookingCache[bookingId] = bookingData;
        debugPrint('✅ Booking obtenido: $bookingId');
        return bookingData;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching booking $bookingId: $e');
    }
    return null;
  }

  // ============================================
  // OBTENER O CACHEAR: USUARIO (Estilista/Cliente)
  // ============================================
  Future<Map<String, dynamic>?> _getOrFetchUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      debugPrint('👤 User desde cache: $userId');
      return _userCache[userId];
    }

    try {
      final response = await ApiClient.instance.get(
        '/api/v1/users/$userId',
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        final userData = user is Map ? (user['data'] ?? user) : user;
        _userCache[userId] = userData;
        debugPrint('✅ User obtenido: $userId');
        return userData;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching user $userId: $e');
    }
    return null;
  }

  // ============================================
  // OBTENER O CACHEAR: SERVICIO
  // ============================================
  Future<Map<String, dynamic>?> _getOrFetchService(String serviceId) async {
    if (_serviceCache.containsKey(serviceId)) {
      debugPrint('🔧 Service desde cache: $serviceId');
      return _serviceCache[serviceId];
    }

    try {
      final response = await ApiClient.instance.get(
        '/api/v1/services/$serviceId',
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final service = jsonDecode(response.body);
        final serviceData = service is Map ? (service['data'] ?? service) : service;
        _serviceCache[serviceId] = serviceData;
        debugPrint('✅ Service obtenido: $serviceId');
        return serviceData;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching service $serviceId: $e');
    }
    return null;
  }

  // ============================================
  // ACTUALIZAR CALIFICACIÓN (GERENTE)
  // ============================================
  Future<bool> updateRating({
    required String ratingId,
    int? estrellas,
    String? comentario,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (estrellas != null) body['estrellas'] = estrellas;
      if (comentario != null) body['comentario'] = comentario;

      final response = await ApiClient.instance.put(
        '/api/v1/ratings/$ratingId',
        headers: {'Authorization': 'Bearer $_token'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('✅ Rating actualizado: $ratingId');
        return true;
      } else {
        debugPrint('❌ Error actualizando rating: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error en updateRating: $e');
      return false;
    }
  }

  // ============================================
  // ELIMINAR CALIFICACIÓN (GERENTE)
  // ============================================
  Future<bool> deleteRating(String ratingId) async {
    try {
      final response = await ApiClient.instance.delete(
        '/api/v1/ratings/$ratingId',
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('✅ Rating eliminado: $ratingId');
        return true;
      } else {
        debugPrint('❌ Error eliminando rating: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error en deleteRating: $e');
      return false;
    }
  }

  // ============================================
  // LIMPIAR CACHE
  // ============================================
  void clearCache() {
    _bookingCache.clear();
    _userCache.clear();
    _serviceCache.clear();
    _stylistCache.clear();
    debugPrint('🗑️ Cache limpiado');
  }
}
