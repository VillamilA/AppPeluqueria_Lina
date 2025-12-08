import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../api/stylist_bookings_api.dart';
import '../../api/ratings_api.dart';
import '../../api/api_client.dart';
import 'dart:convert';

class StylistHomeTab extends StatefulWidget {
  final String token;
  final String stylistName;
  final String stylistLastName;
  final VoidCallback? onViewAllBookings;

  const StylistHomeTab({
    super.key,
    required this.token,
    required this.stylistName,
    required this.stylistLastName,
    this.onViewAllBookings,
  });

  @override
  State<StylistHomeTab> createState() => _StylistHomeTabState();
}

class _StylistHomeTabState extends State<StylistHomeTab> {
  late StylistBookingsApi _bookingsApi;
  late RatingsApi _ratingsApi;
  List<dynamic> _todayBookings = [];
  List<dynamic> _weekBookings = [];
  List<dynamic> _ratings = [];

  @override
  void initState() {
    super.initState();
    _bookingsApi = StylistBookingsApi(ApiClient.instance);
    _ratingsApi = RatingsApi(ApiClient.instance);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadBookings(),
        _loadRatings(),
      ]);
    } catch (e) {
      print('[STYLIST_HOME] Error loading data: $e');
    }
  }

  Future<void> _loadBookings() async {
    try {
      print('🔵 [STYLIST_HOME] Iniciando carga de citas...');
      final response = await _bookingsApi.getMyBookings(widget.token);
      print('📥 [STYLIST_HOME] Response status: ${response.statusCode}');
      print('📥 [STYLIST_HOME] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [STYLIST_HOME] Data type: ${data.runtimeType}');
        
        final allBookings = List.from(data['data'] ?? []);
        print('✅ [STYLIST_HOME] Total citas: ${allBookings.length}');

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekEnd = today.add(Duration(days: 7));

        final todayList = allBookings.where((b) {
          try {
            final inicioStr = b['inicio']?.toString();
            if (inicioStr == null) return false;
            final bookingDate = DateTime.parse(inicioStr);
            return DateTime(bookingDate.year, bookingDate.month, bookingDate.day) == today;
          } catch (e) {
            return false;
          }
        }).toList();

        final weekList = allBookings.where((b) {
          try {
            final inicioStr = b['inicio']?.toString();
            if (inicioStr == null) return false;
            final bookingDate = DateTime.parse(inicioStr);
            final normalizedDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
            return normalizedDate.isAfter(today) && normalizedDate.isBefore(weekEnd);
          } catch (e) {
            return false;
          }
        }).toList();

        print('✅ [STYLIST_HOME] Citas hoy: ${todayList.length}');
        print('✅ [STYLIST_HOME] Citas semana: ${weekList.length}');

        // Ordenar por hora
        todayList.sort((a, b) {
          try {
            final aInicio = a['inicio'] != null ? DateTime.parse(a['inicio']) : null;
            final bInicio = b['inicio'] != null ? DateTime.parse(b['inicio']) : null;
            if (aInicio == null || bInicio == null) return 0;
            return aInicio.compareTo(bInicio);
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          _todayBookings = todayList;
          _weekBookings = weekList;
        });
      } else {
        print('❌ [STYLIST_HOME] Error: ${response.statusCode}');
      }
    } catch (e, st) {
      print('❌ [STYLIST_HOME] Error loading bookings: $e');
      print('   Stack: $st');
    }
  }

  Future<void> _loadRatings() async {
    try {
      final response = await _ratingsApi.getReceivedRatings(widget.token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ratings = data['data'] ?? [];
        });
      }
    } catch (e) {
      print('[STYLIST_HOME] Error loading ratings: $e');
    }
  }

  double get _averageRating {
    if (_ratings.isEmpty) return 0;
    final sum = _ratings.fold<double>(0, (acc, r) => acc + (r['estrellas'] ?? 0).toDouble());
    return sum / _ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BIENVENIDA
            _buildWelcomeSection(),
            SizedBox(height: 24),

            // BOTÓN VER MIS CITAS
            _buildViewAllBookingsCard(),
            SizedBox(height: 24),

            // CITAS DEL DÍA
            _buildTodayBookingsSection(),
            SizedBox(height: 24),

            // AGENDA SEMANAL
            _buildWeeklyScheduleSection(),
            SizedBox(height: 24),

            // CALIFICACIONES
            _buildRatingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.charcoal, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenida, ${widget.stylistName}',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hoy es ${DateFormat('EEEE, d MMMM', 'es_ES').format(DateTime.now())}',
            style: TextStyle(color: AppColors.gray, fontSize: 14),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Citas Hoy', _todayBookings.length.toString(), Icons.calendar_today),
              _buildStatCard('Citas Semana', _weekBookings.length.toString(), Icons.event_note),
              _buildStatCard(
                'Calificación',
                _averageRating.toStringAsFixed(1),
                Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.gray, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildViewAllBookingsCard() {
    return GestureDetector(
      onTap: widget.onViewAllBookings,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gold.withOpacity(0.1), AppColors.gold.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Ver Mis Citas',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ver todas mis citas y gestionar su estado',
                  style: TextStyle(
                    color: AppColors.gray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.gold, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📅 Citas de Hoy',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_todayBookings.length} citas',
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_todayBookings.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No hay citas programadas para hoy',
                style: TextStyle(color: AppColors.gray),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _todayBookings.length,
            separatorBuilder: (_, __) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final booking = _todayBookings[index];
              return _buildBookingCard(booking);
            },
          ),
      ],
    );
  }

  Widget _buildWeeklyScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📆 Agenda de la Semana',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        if (_weekBookings.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No hay citas programadas para esta semana',
                style: TextStyle(color: AppColors.gray),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _weekBookings.length,
            separatorBuilder: (_, __) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final booking = _weekBookings[index];
              return _buildBookingCard(booking);
            },
          ),
      ],
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    // Obtener datos del cliente
    final clienteNombre = booking['clienteNombre'] ?? 'Cliente';
    final clienteApellido = booking['clienteApellido'] ?? '';
    final servicioNombre = booking['servicioNombre'] ?? 'Servicio';
    
    DateTime? fecha;
    String startTime = '--:--';
    String endTime = '--:--';
    
    try {
      if (booking['inicio'] != null) {
        fecha = DateTime.parse(booking['inicio']);
        startTime = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
      }
      if (booking['fin'] != null) {
        final finTime = DateTime.parse(booking['fin']);
        endTime = '${finTime.hour.toString().padLeft(2, '0')}:${finTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Si no se puede parsear la fecha, usar valores por defecto
    }
    
    final estado = booking['estado'] ?? booking['status'] ?? 'SCHEDULED';

    Color statusColor = Colors.orange;
    String statusLabel = 'Pendiente';
    if (estado == 'CONFIRMED') {
      statusColor = Colors.blue;
      statusLabel = 'Confirmada';
    } else if (estado == 'COMPLETED') {
      statusColor = Colors.green;
      statusLabel = 'Completada';
    } else if (estado == 'CANCELLED') {
      statusColor = Colors.red;
      statusLabel = 'Cancelada';
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$clienteNombre $clienteApellido',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      servicioNombre,
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: AppColors.gray, size: 14),
              SizedBox(width: 6),
              Text(
                '$startTime - $endTime',
                style: TextStyle(color: AppColors.gray, fontSize: 11),
              ),
              SizedBox(width: 16),
              Icon(Icons.calendar_today, color: AppColors.gray, size: 14),
              SizedBox(width: 6),
              Text(
                fecha != null ? DateFormat('d MMM', 'es_ES').format(fecha) : 'Sin fecha',
                style: TextStyle(color: AppColors.gray, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '⭐ Calificaciones Recibidas',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_ratings.length} calificaciones',
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_ratings.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No tienes calificaciones aún',
                style: TextStyle(color: AppColors.gray),
              ),
            ),
          )
        else
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                Icons.star,
                                color: i < _averageRating.floor()
                                    ? Colors.amber
                                    : Colors.grey,
                                size: 16,
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promedio',
                          style: TextStyle(color: AppColors.gray, fontSize: 12),
                        ),
                        Text(
                          'de ${_ratings.length} clientes',
                          style: TextStyle(color: AppColors.gold, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _ratings.take(5).length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final rating = _ratings[index];
                  final clienteNombre = rating['clientId']?['nombre'] ?? 'Cliente';
                  final estrellas = rating['estrellas'] ?? 0;

                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              clienteNombre,
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                ...List.generate(5, (i) {
                                  return Icon(
                                    Icons.star,
                                    color: i < estrellas ? Colors.amber : Colors.grey,
                                    size: 12,
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                        if (rating['comentario'] != null &&
                            rating['comentario'].isNotEmpty)
                          SizedBox(height: 4),
                        if (rating['comentario'] != null &&
                            rating['comentario'].isNotEmpty)
                          Text(
                            rating['comentario'],
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}
