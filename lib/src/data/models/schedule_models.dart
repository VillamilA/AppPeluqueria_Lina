// ============================================================
// MODELOS PARA GESTIÓN DE HORARIOS Y SLOTS
// Sincronizado con TypeScript Backend
// ============================================================

/// Índice de día de la semana (0-6 o 1-7 según contexto)
/// Usado en PUT /schedules/stylist
typedef DayOfWeekIndex = int;

/// Nombre del día de la semana en español
/// Usado en POST /slots/day
enum WeekdayName {
  lunes('LUNES', 1),
  martes('MARTES', 2),
  miercoles('MIERCOLES', 3),
  jueves('JUEVES', 4),
  viernes('VIERNES', 5),
  sabado('SABADO', 6),
  domingo('DOMINGO', 0);

  final String value;
  final int weekIndex;

  const WeekdayName(this.value, this.weekIndex);

  /// Convierte número (0-6) a WeekdayName
  static WeekdayName fromIndex(int index) {
    return WeekdayName.values.firstWhere((e) => e.weekIndex == index);
  }

  /// Obtiene nombre localizado
  String getLocalizedName() {
    const names = {
      'LUNES': 'Lunes',
      'MARTES': 'Martes',
      'MIERCOLES': 'Miércoles',
      'JUEVES': 'Jueves',
      'VIERNES': 'Viernes',
      'SABADO': 'Sábado',
      'DOMINGO': 'Domingo',
    };
    return names[value] ?? value;
  }
}

/// Bloque horario (inicio - fin)
class TimeBlock {
  final String start; // "09:00"
  final String end; // "18:00"

  TimeBlock({
    required this.start,
    required this.end,
  });

  factory TimeBlock.fromJson(Map<String, dynamic> json) {
    return TimeBlock(
      start: json['start'] ?? '09:00',
      end: json['end'] ?? '18:00',
    );
  }

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
  };

  @override
  String toString() => '$start - $end';
}

/// Excepción en horario (feriado, cierre, etc.)
class ScheduleException {
  final String date; // "2026-01-20"
  final bool closed; // true = cerrado este día
  final List<TimeBlock>? blocks; // Bloques ocupados si no está cerrado

  ScheduleException({
    required this.date,
    this.closed = false,
    this.blocks,
  });

  factory ScheduleException.fromJson(Map<String, dynamic> json) {
    return ScheduleException(
      date: json['date'] ?? '',
      closed: json['closed'] ?? false,
      blocks: (json['blocks'] as List?)
          ?.map((b) => TimeBlock.fromJson(b))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'closed': closed,
    if (blocks != null) 'blocks': blocks!.map((b) => b.toJson()).toList(),
  };
}

/// Horario de trabajo del estilista (se guarda una sola vez por día)
class StylistSchedule {
  final String? id;
  final String stylistId;
  final int dayOfWeek; // 0-6 (lunes-domingo) para PUT
  final List<TimeBlock> slots; // Bloques de trabajo disponibles
  final List<ScheduleException>? exceptions;

  StylistSchedule({
    this.id,
    required this.stylistId,
    required this.dayOfWeek,
    required this.slots,
    this.exceptions,
  });

  factory StylistSchedule.fromJson(Map<String, dynamic> json) {
    return StylistSchedule(
      id: json['_id'] ?? json['id'],
      stylistId: json['stylistId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      slots: (json['slots'] as List?)
          ?.map((s) => TimeBlock.fromJson(s))
          .toList() ?? [TimeBlock(start: '09:00', end: '18:00')],
      exceptions: (json['exceptions'] as List?)
          ?.map((e) => ScheduleException.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'stylistId': stylistId,
    'dayOfWeek': dayOfWeek,
    'slots': slots.map((s) => s.toJson()).toList(),
    if (exceptions != null) 'exceptions': exceptions!.map((e) => e.toJson()).toList(),
  };

  @override
  String toString() => 'Schedule(day=$dayOfWeek, slots=${slots.length})';
}

/// Slot de disponibilidad (generado por fecha + servicio)
class AvailabilitySlot {
  final String slotId;
  final String stylistId;
  final String stylistName; // Para mostrar al cliente
  final String start; // "09:00"
  final String end; // "09:30"
  final String dayOfWeek; // "LUNES"

  AvailabilitySlot({
    required this.slotId,
    required this.stylistId,
    required this.stylistName,
    required this.start,
    required this.end,
    required this.dayOfWeek,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      slotId: json['slotId'] ?? json['_id'] ?? '',
      stylistId: json['stylistId'] ?? '',
      stylistName: json['stylistName'] ?? '',
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'slotId': slotId,
    'stylistId': stylistId,
    'stylistName': stylistName,
    'start': start,
    'end': end,
    'dayOfWeek': dayOfWeek,
  };

  @override
  String toString() => 'Slot($start-$end, $dayOfWeek)';
}

/// Solicitud para generar slots
class GenerateSlotsRequest {
  final String stylistId;
  final String serviceId;
  final String dayOfWeek; // "LUNES" - UPPERCASE
  final String dayStart; // "09:00"
  final String dayEnd; // "18:00"

  GenerateSlotsRequest({
    required this.stylistId,
    required this.serviceId,
    required this.dayOfWeek,
    required this.dayStart,
    required this.dayEnd,
  });

  Map<String, dynamic> toJson() => {
    'stylistId': stylistId,
    'serviceId': serviceId,
    'dayOfWeek': dayOfWeek,
    'dayStart': dayStart,
    'dayEnd': dayEnd,
  };

  @override
  String toString() => 'GenerateSlots($dayOfWeek, $dayStart-$dayEnd)';
}
