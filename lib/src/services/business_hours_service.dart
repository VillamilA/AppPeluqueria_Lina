import 'dart:convert';
import '../api/business_hours_api.dart';
import '../api/api_client.dart';

/// Modelo para representar el horario del negocio
class BusinessHours {
  final int dayOfWeek; // 0 = Lunes, 1 = Martes, ... 6 = Domingo (según backend)
  final String openTime;   // "09:00"
  final String closeTime;  // "18:00"

  BusinessHours({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      dayOfWeek: json['dayOfWeek'] is int ? json['dayOfWeek'] : int.parse(json['dayOfWeek'].toString()),
      // El backend usa 'open' y 'close', no 'openTime' y 'closeTime'
      openTime: (json['open'] ?? json['openTime'])?.toString() ?? '09:00',
      closeTime: (json['close'] ?? json['closeTime'])?.toString() ?? '18:00',
    );
  }

  /// Obtiene la hora de apertura como TimeOfDay
  (int, int) getOpenTimeComponents() {
    final parts = openTime.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Obtiene la hora de cierre como TimeOfDay
  (int, int) getCloseTimeComponents() {
    final parts = closeTime.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}

/// Servicio centralizado para manejar horarios del negocio
class BusinessHoursService {
  static final BusinessHoursService _instance = BusinessHoursService._internal();
  
  factory BusinessHoursService() => _instance;
  BusinessHoursService._internal();

  late BusinessHoursApi _api;
  Map<int, BusinessHours>? _cachedBusinessHours;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  void initialize() {
    _api = BusinessHoursApi(ApiClient.instance);
  }

  /// 📥 Obtiene los horarios del negocio (con cache)
  Future<Map<int, BusinessHours>> getBusinessHours({bool forceRefresh = false}) async {
    try {
      // Verificar si tenemos cache válido
      if (!forceRefresh && _cachedBusinessHours != null && _cacheTime != null) {
        final elapsed = DateTime.now().difference(_cacheTime!);
        if (elapsed < _cacheDuration) {
          print('[BUSINESS_HOURS] ✅ Usando cache');
          return _cachedBusinessHours!;
        }
      }

      print('[BUSINESS_HOURS] 📥 Obteniendo horarios del negocio...');
      
      final response = await _api.getBusinessHours();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[BUSINESS_HOURS] 📋 Response Raw: $data');
        
        final Map<int, BusinessHours> businessHours = {};
        
        // El backend retorna: { _id: "...", days: [{dayOfWeek: 0, open: "09:00", close: "18:00"}, ...], exceptions: [...] }
        if (data is Map && data['days'] is List) {
          print('[BUSINESS_HOURS] 🔍 Parseando ${(data['days'] as List).length} días...');
          for (var item in data['days']) {
            final bh = BusinessHours.fromJson(item);
            businessHours[bh.dayOfWeek] = bh;
            print('[BUSINESS_HOURS] ✅ Día ${bh.dayOfWeek}: ${bh.openTime} - ${bh.closeTime}');
          }
        } else if (data is List) {
          // Si directamente viene un array
          print('[BUSINESS_HOURS] 🔍 Parseando array directo de ${data.length} días...');
          for (var item in data) {
            final bh = BusinessHours.fromJson(item);
            businessHours[bh.dayOfWeek] = bh;
            print('[BUSINESS_HOURS] ✅ Día ${bh.dayOfWeek}: ${bh.openTime} - ${bh.closeTime}');
          }
        } else {
          print('[BUSINESS_HOURS] ❌ Estructura de respuesta no reconocida: ${data.runtimeType}');
          throw Exception('Estructura de respuesta del negocio inválida');
        }

        // Guardar en cache
        _cachedBusinessHours = businessHours;
        _cacheTime = DateTime.now();
        
        print('[BUSINESS_HOURS] ✅ ${businessHours.length} días configurados correctamente');
        return businessHours;
      } else {
        print('[BUSINESS_HOURS] ❌ Error ${response.statusCode}');
        throw Exception('No se pudo obtener horarios del negocio');
      }
    } catch (e) {
      print('[BUSINESS_HOURS] ❌ Error: $e');
      rethrow;
    }
  }

  /// 📍 Obtiene horario del negocio para un día específico
  Future<BusinessHours?> getBusinessHoursForDay(int dayOfWeek) async {
    final hours = await getBusinessHours();
    return hours[dayOfWeek];
  }

  /// ✅ Valida que un horario de estilista esté dentro del horario del negocio
  Future<(bool isValid, String? errorMessage)> validateStylistHours({
    required int dayOfWeek,
    required String startTime,  // "09:00"
    required String endTime,    // "18:00"
  }) async {
    try {
      final businessHours = await getBusinessHoursForDay(dayOfWeek);
      
      if (businessHours == null) {
        return (false, '❌ No hay horario configurado para este día');
      }

      // Convertir strings a minutos para comparación fácil
      final stylistStart = _timeToMinutes(startTime);
      final stylistEnd = _timeToMinutes(endTime);
      final businessOpen = _timeToMinutes(businessHours.openTime);
      final businessClose = _timeToMinutes(businessHours.closeTime);

      print('[BUSINESS_HOURS] Validando: Estilista $startTime-$endTime vs Negocio ${businessHours.openTime}-${businessHours.closeTime}');

      // Validar que el horario del estilista esté dentro del del negocio
      if (stylistStart < businessOpen) {
        return (false, '❌ El horario de inicio (${_minutesToTime(stylistStart)}) es anterior a la apertura del negocio (${businessHours.openTime})');
      }

      if (stylistEnd > businessClose) {
        return (false, '❌ El horario de cierre (${_minutesToTime(stylistEnd)}) es posterior al cierre del negocio (${businessHours.closeTime})');
      }

      if (stylistStart >= stylistEnd) {
        return (false, '❌ La hora de inicio debe ser menor a la de cierre');
      }

      return (true, null);
    } catch (e) {
      print('[BUSINESS_HOURS] ❌ Error validando: $e');
      return (false, '❌ Error al validar horario: $e');
    }
  }

  /// 🕐 Obtiene el rango de horas permitido para un día
  Future<(String minTime, String maxTime)?> getValidTimeRange(int dayOfWeek) async {
    try {
      final businessHours = await getBusinessHoursForDay(dayOfWeek);
      if (businessHours == null) return null;
      return (businessHours.openTime, businessHours.closeTime);
    } catch (e) {
      print('[BUSINESS_HOURS] ❌ Error obteniendo rango: $e');
      return null;
    }
  }

  /// 🔄 Limpia el cache
  void clearCache() {
    _cachedBusinessHours = null;
    _cacheTime = null;
    print('[BUSINESS_HOURS] ✅ Cache limpiado');
  }

  // ========== HELPERS ==========

  /// Convierte "HH:MM" a minutos desde las 00:00
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Convierte minutos desde las 00:00 a "HH:MM"
  String _minutesToTime(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$mins';
  }

  /// Obtiene los minutos permitidos (mínimo y máximo) para un día
  Future<(int minMinutes, int maxMinutes)?> getValidMinutesRange(int dayOfWeek) async {
    final range = await getValidTimeRange(dayOfWeek);
    if (range == null) return null;
    return (_timeToMinutes(range.$1), _timeToMinutes(range.$2));
  }
}
