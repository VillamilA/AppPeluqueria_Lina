class DateRange {
  final DateTime from;
  final DateTime to;
  final String label;

  DateRange({required this.from, required this.to, required this.label});

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      from: DateTime.parse(json['from']),
      to: DateTime.parse(json['to']),
      label: json['label'],
    );
  }
}

class Totals {
  final double totalRevenue;
  final int totalPaidBookings;

  Totals({required this.totalRevenue, required this.totalPaidBookings});

  factory Totals.fromJson(Map<String, dynamic> json) {
    return Totals(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalPaidBookings: json['totalPaidBookings'] ?? 0,
    );
  }
}

class RevenueByDay {
  final String day;
  final double total;
  final int count;

  RevenueByDay({required this.day, required this.total, required this.count});

  factory RevenueByDay.fromJson(Map<String, dynamic> json) {
    return RevenueByDay(
      day: json['day'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class RevenueByStylist {
  final String id;
  final String stylistName;
  final double totalRevenue;
  final int bookingsCount;

  RevenueByStylist({
    required this.id,
    required this.stylistName,
    required this.totalRevenue,
    required this.bookingsCount,
  });

  factory RevenueByStylist.fromJson(Map<String, dynamic> json) {
    return RevenueByStylist(
      id: json['_id'] ?? '',
      stylistName: json['stylistName'] ?? 'Sin nombre',
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      bookingsCount: json['bookingsCount'] ?? 0,
    );
  }
}

class TopService {
  final String id;
  final String serviceName;
  final double totalRevenue;
  final int bookingsCount;

  TopService({
    required this.id,
    required this.serviceName,
    required this.totalRevenue,
    required this.bookingsCount,
  });

  factory TopService.fromJson(Map<String, dynamic> json) {
    return TopService(
      id: json['_id'] ?? '',
      serviceName: json['serviceName'] ?? 'Sin nombre',
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      bookingsCount: json['bookingsCount'] ?? 0,
    );
  }
}

class BookingByStatus {
  final String status;
  final int count;

  BookingByStatus({required this.status, required this.count});

  factory BookingByStatus.fromJson(Map<String, dynamic> json) {
    return BookingByStatus(
      status: json['_id'] ?? 'UNKNOWN',
      count: json['count'] ?? 0,
    );
  }
}

class RatingByStylist {
  final String id;
  final String stylistName;
  final double avgRating;
  final int ratingsCount;

  RatingByStylist({
    required this.id,
    required this.stylistName,
    required this.avgRating,
    required this.ratingsCount,
  });

  factory RatingByStylist.fromJson(Map<String, dynamic> json) {
    return RatingByStylist(
      id: json['_id'] ?? '',
      stylistName: json['stylistName'] ?? 'Sin nombre',
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      ratingsCount: json['ratingsCount'] ?? 0,
    );
  }
}

class SummaryReport {
  final DateRange range;
  final Totals totals;
  final List<RevenueByDay> revenueByDay;
  final List<RevenueByStylist> revenueByStylist;
  final List<TopService> topServices;
  final List<BookingByStatus> bookingsByStatus;
  final List<RatingByStylist> ratingsByStylist;

  SummaryReport({
    required this.range,
    required this.totals,
    required this.revenueByDay,
    required this.revenueByStylist,
    required this.topServices,
    required this.bookingsByStatus,
    required this.ratingsByStylist,
  });

  factory SummaryReport.fromJson(Map<String, dynamic> json) {
    return SummaryReport(
      range: DateRange.fromJson(json['range'] ?? {}),
      totals: Totals.fromJson(json['totals'] ?? {}),
      revenueByDay: (json['revenueByDay'] as List<dynamic>?)
              ?.map((e) => RevenueByDay.fromJson(e))
              .toList() ??
          [],
      revenueByStylist: (json['revenueByStylist'] as List<dynamic>?)
              ?.map((e) => RevenueByStylist.fromJson(e))
              .toList() ??
          [],
      topServices: (json['topServices'] as List<dynamic>?)
              ?.map((e) => TopService.fromJson(e))
              .toList() ??
          [],
      bookingsByStatus: (json['bookingsByStatus'] as List<dynamic>?)
              ?.map((e) => BookingByStatus.fromJson(e))
              .toList() ??
          [],
      ratingsByStylist: (json['ratingsByStylist'] as List<dynamic>?)
              ?.map((e) => RatingByStylist.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class StylistInfo {
  final String id;
  final String name;
  final String? email;
  final bool isActive;

  StylistInfo({
    required this.id,
    required this.name,
    this.email,
    required this.isActive,
  });

  factory StylistInfo.fromJson(Map<String, dynamic> json) {
    return StylistInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Sin nombre',
      email: json['email'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class Earnings {
  final double totalRevenue;
  final int paidBookings;
  final double avgTicket;

  Earnings({
    required this.totalRevenue,
    required this.paidBookings,
    required this.avgTicket,
  });

  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      paidBookings: json['paidBookings'] ?? 0,
      avgTicket: (json['avgTicket'] ?? 0).toDouble(),
    );
  }
}

class RatingDistribution {
  final int stars;
  final int count;

  RatingDistribution({required this.stars, required this.count});

  factory RatingDistribution.fromJson(Map<String, dynamic> json) {
    return RatingDistribution(
      stars: json['stars'] ?? 0,
      count: json['count'] ?? 0,
    );
  }
}

class LatestComment {
  final int estrellas;
  final String commentText;
  final DateTime createdAt;
  final String clientName;

  LatestComment({
    required this.estrellas,
    required this.commentText,
    required this.createdAt,
    required this.clientName,
  });

  factory LatestComment.fromJson(Map<String, dynamic> json) {
    return LatestComment(
      estrellas: json['estrellas'] ?? 0,
      commentText: json['commentText'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      clientName: json['clientName'] ?? 'Anónimo',
    );
  }
}

class Ratings {
  final double avgRating;
  final int ratingsCount;
  final List<RatingDistribution> distribution;
  final List<LatestComment> latestComments;

  Ratings({
    required this.avgRating,
    required this.ratingsCount,
    required this.distribution,
    required this.latestComments,
  });

  factory Ratings.fromJson(Map<String, dynamic> json) {
    return Ratings(
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      ratingsCount: json['ratingsCount'] ?? 0,
      distribution: (json['distribution'] as List<dynamic>?)
              ?.map((e) => RatingDistribution.fromJson(e))
              .toList() ??
          [],
      latestComments: (json['latestComments'] as List<dynamic>?)
              ?.map((e) => LatestComment.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AppointmentNote {
  final DateTime date;
  final String estado;
  final String servicio;
  final String cliente;
  final String notas;

  AppointmentNote({
    required this.date,
    required this.estado,
    required this.servicio,
    required this.cliente,
    required this.notas,
  });

  factory AppointmentNote.fromJson(Map<String, dynamic> json) {
    return AppointmentNote(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      estado: json['estado'] ?? 'UNKNOWN',
      servicio: json['servicio'] ?? 'Sin servicio',
      cliente: json['cliente'] ?? 'Sin cliente',
      notas: json['notas'] ?? '',
    );
  }
}

class ExtraStats {
  final int totalBookings;
  final int uniqueClients;
  final double cancelRatePct;
  final double completionRatePct;
  final String? peakHour;
  final String? peakWeekday;

  ExtraStats({
    required this.totalBookings,
    required this.uniqueClients,
    required this.cancelRatePct,
    required this.completionRatePct,
    this.peakHour,
    this.peakWeekday,
  });

  factory ExtraStats.fromJson(Map<String, dynamic> json) {
    return ExtraStats(
      totalBookings: json['totalBookings'] ?? 0,
      uniqueClients: json['uniqueClients'] ?? 0,
      cancelRatePct: (json['cancelRatePct'] ?? 0).toDouble(),
      completionRatePct: (json['completionRatePct'] ?? 0).toDouble(),
      peakHour: json['peakHour'],
      peakWeekday: json['peakWeekday'],
    );
  }
}

class StylistDetail {
  final StylistInfo stylist;
  final Earnings earnings;
  final Ratings ratings;
  final List<AppointmentNote> appointmentsNotes;
  final List<TopService> topServices;
  final List<BookingByStatus> bookingsByStatus;
  final ExtraStats extra;

  StylistDetail({
    required this.stylist,
    required this.earnings,
    required this.ratings,
    required this.appointmentsNotes,
    required this.topServices,
    required this.bookingsByStatus,
    required this.extra,
  });

  factory StylistDetail.fromJson(Map<String, dynamic> json) {
    return StylistDetail(
      stylist: StylistInfo.fromJson(json['stylist'] ?? {}),
      earnings: Earnings.fromJson(json['earnings'] ?? {}),
      ratings: Ratings.fromJson(json['ratings'] ?? {}),
      appointmentsNotes: (json['appointmentsNotes'] as List<dynamic>?)
              ?.map((e) => AppointmentNote.fromJson(e))
              .toList() ??
          [],
      topServices: (json['topServices'] as List<dynamic>?)
              ?.map((e) => TopService.fromJson(e))
              .toList() ??
          [],
      bookingsByStatus: (json['bookingsByStatus'] as List<dynamic>?)
              ?.map((e) => BookingByStatus.fromJson(e))
              .toList() ??
          [],
      extra: ExtraStats.fromJson(json['extra'] ?? {}),
    );
  }
}

class StylistReport {
  final DateRange range;
  final int count;
  final List<StylistDetail> reports;

  StylistReport({required this.range, required this.count, required this.reports});

  factory StylistReport.fromJson(Map<String, dynamic> json) {
    return StylistReport(
      range: DateRange.fromJson(json['range'] ?? {}),
      count: json['count'] ?? 0,
      reports: (json['reports'] as List<dynamic>?)
              ?.map((e) => StylistDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}
