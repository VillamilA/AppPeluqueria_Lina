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
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
      }
    } catch (e) {
      print('❌ [STYLIST_HOME] Error loading bookings: $e');
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isSmallPhone = maxWidth < 360;
        final isPhone = maxWidth < 600;
        final isTablet = maxWidth >= 600 && maxWidth < 900;
        final isDesktop = maxWidth >= 900;
        
        // Espaciados adaptativos
        final horizontalPadding = isSmallPhone ? 12.0 : (isPhone ? 16.0 : (isTablet ? 24.0 : 32.0));
        final verticalPadding = isSmallPhone ? 16.0 : (isPhone ? 20.0 : 24.0);
        final sectionSpacing = isSmallPhone ? 20.0 : (isPhone ? 24.0 : (isTablet ? 28.0 : 32.0));
        
        // Ancho máximo del contenido para centrar
        final contentMaxWidth = isDesktop ? 1200.0 : (isTablet ? 800.0 : double.infinity);
        
        return Container(
          color: AppColors.charcoal,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // BIENVENIDA ELEGANTE
                      _buildWelcomeSection(isSmallPhone, isPhone, isTablet),
                      SizedBox(height: sectionSpacing),

                      // ESTADÍSTICAS EN GRID
                      _buildStatsGrid(isSmallPhone, isPhone, isTablet, maxWidth),
                      SizedBox(height: sectionSpacing),

                      // BOTÓN GESTIONAR CITAS
                      _buildManageBookingsButton(isSmallPhone, isPhone, isTablet),
                      SizedBox(height: sectionSpacing),

                      // CITAS DEL DÍA
                      _buildTodaySection(isSmallPhone, isPhone, isTablet),
                      SizedBox(height: sectionSpacing),

                      // AGENDA SEMANAL
                      _buildWeeklySection(isSmallPhone, isPhone, isTablet),
                      SizedBox(height: sectionSpacing),

                      // CALIFICACIONES
                      _buildRatingsSection(isSmallPhone, isPhone, isTablet),
                      
                      // Espacio final para scroll completo
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== SECCIÓN BIENVENIDA ====================
  Widget _buildWelcomeSection(bool isSmallPhone, bool isPhone, bool isTablet) {
    final iconSize = isSmallPhone ? 24.0 : (isPhone ? 28.0 : 32.0);
    final titleSize = isSmallPhone ? 18.0 : (isPhone ? 22.0 : 26.0);
    final dateSize = isSmallPhone ? 11.0 : (isPhone ? 13.0 : 15.0);
    final padding = isSmallPhone ? 16.0 : (isPhone ? 20.0 : 24.0);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900,
            AppColors.charcoal,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallPhone ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.gold.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.25),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.black,
                  size: iconSize,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenida',
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: isSmallPhone ? 11 : 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      widget.stylistName,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallPhone ? 10 : 12,
              vertical: isSmallPhone ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.gold,
                  size: isSmallPhone ? 14 : 16,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES')
                        .format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: dateSize,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ESTADÍSTICAS GRID ====================
  Widget _buildStatsGrid(bool isSmallPhone, bool isPhone, bool isTablet, double maxWidth) {
    final stats = [
      {
        'label': 'Hoy',
        'value': _todayBookings.length.toString(),
        'icon': Icons.today_rounded,
        'gradient': [Color(0xFF2196F3), Color(0xFF64B5F6)],
      },
      {
        'label': 'Semana',
        'value': _weekBookings.length.toString(),
        'icon': Icons.event_note_rounded,
        'gradient': [Color(0xFF9C27B0), Color(0xFFBA68C8)],
      },
      {
        'label': 'Rating',
        'value': _averageRating.toStringAsFixed(1),
        'icon': Icons.star_rounded,
        'gradient': [Color(0xFFFFA726), Color(0xFFFFB74D)],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: isSmallPhone ? 8 : (isPhone ? 10 : 12),
        mainAxisSpacing: isSmallPhone ? 8 : (isPhone ? 10 : 12),
        childAspectRatio: isSmallPhone ? 0.95 : (isPhone ? 1.0 : 1.1),
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          stat['label'] as String,
          stat['value'] as String,
          stat['icon'] as IconData,
          stat['gradient'] as List<Color>,
          isSmallPhone,
          isPhone,
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> gradientColors,
    bool isSmallPhone,
    bool isPhone,
  ) {
    final iconSize = isSmallPhone ? 18.0 : (isPhone ? 20.0 : 24.0);
    final valueSize = isSmallPhone ? 18.0 : (isPhone ? 20.0 : 24.0);
    final labelSize = isSmallPhone ? 9.5 : (isPhone ? 10.5 : 12.0);
    final padding = isSmallPhone ? 10.0 : (isPhone ? 12.0 : 14.0);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors[0].withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.12),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallPhone ? 8 : (isPhone ? 10 : 12)),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.35),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          SizedBox(height: isSmallPhone ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== BOTÓN GESTIONAR CITAS ====================
  Widget _buildManageBookingsButton(bool isSmallPhone, bool isPhone, bool isTablet) {
    final padding = isSmallPhone ? 14.0 : (isPhone ? 16.0 : 18.0);
    final iconSize = isSmallPhone ? 20.0 : (isPhone ? 24.0 : 26.0);
    final titleSize = isSmallPhone ? 14.0 : (isPhone ? 15.0 : 17.0);
    final subtitleSize = isSmallPhone ? 10.0 : (isPhone ? 11.0 : 13.0);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onViewAllBookings,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withOpacity(0.12),
                AppColors.gold.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallPhone ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.gold.withOpacity(0.85)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: Colors.black,
                  size: iconSize,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestionar Citas',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ver y actualizar todas tus citas',
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: subtitleSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.gold,
                size: isSmallPhone ? 14 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CITAS DEL DÍA ====================
  Widget _buildTodaySection(bool isSmallPhone, bool isPhone, bool isTablet) {
    final headerPadding = isSmallPhone ? 12.0 : (isPhone ? 14.0 : 16.0);
    final titleSize = isSmallPhone ? 16.0 : (isPhone ? 18.0 : 20.0);
    final badgeSize = isSmallPhone ? 12.0 : (isPhone ? 14.0 : 15.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(headerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1976D2).withOpacity(0.15),
                Color(0xFF1976D2).withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color(0xFF2196F3).withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    color: Color(0xFF64B5F6),
                    size: isSmallPhone ? 18 : 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Citas de Hoy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallPhone ? 10 : 12,
                  vertical: isSmallPhone ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_todayBookings.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: badgeSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        _todayBookings.isEmpty
            ? _buildEmptyState(
                'No hay citas para hoy',
                Icons.event_busy_rounded,
                Color(0xFF2196F3),
                isSmallPhone,
                isPhone,
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _todayBookings.length,
                separatorBuilder: (_, __) => SizedBox(height: isSmallPhone ? 10 : 12),
                itemBuilder: (context, index) {
                  return _buildBookingCard(_todayBookings[index], isSmallPhone, isPhone);
                },
              ),
      ],
    );
  }

  // ==================== AGENDA SEMANAL ====================
  Widget _buildWeeklySection(bool isSmallPhone, bool isPhone, bool isTablet) {
    final headerPadding = isSmallPhone ? 12.0 : (isPhone ? 14.0 : 16.0);
    final titleSize = isSmallPhone ? 16.0 : (isPhone ? 18.0 : 20.0);
    final badgeSize = isSmallPhone ? 12.0 : (isPhone ? 14.0 : 15.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(headerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF7B1FA2).withOpacity(0.15),
                Color(0xFF7B1FA2).withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color(0xFF9C27B0).withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.view_week_rounded,
                    color: Color(0xFFBA68C8),
                    size: isSmallPhone ? 18 : 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Esta Semana',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallPhone ? 10 : 12,
                  vertical: isSmallPhone ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF9C27B0).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_weekBookings.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: badgeSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        _weekBookings.isEmpty
            ? _buildEmptyState(
                'No hay citas esta semana',
                Icons.event_available_rounded,
                Color(0xFF9C27B0),
                isSmallPhone,
                isPhone,
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _weekBookings.length,
                separatorBuilder: (_, __) => SizedBox(height: isSmallPhone ? 10 : 12),
                itemBuilder: (context, index) {
                  return _buildBookingCard(_weekBookings[index], isSmallPhone, isPhone);
                },
              ),
      ],
    );
  }

  // ==================== TARJETA DE CITA ====================
  Widget _buildBookingCard(dynamic booking, bool isSmallPhone, bool isPhone) {
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
      // Mantener valores por defecto
    }
    
    final estado = booking['estado'] ?? booking['status'] ?? 'SCHEDULED';
    
    Map<String, dynamic> statusInfo = {
      'color': Color(0xFFFF9800),
      'label': 'Pendiente',
      'icon': Icons.schedule_rounded,
    };
    
    if (estado == 'CONFIRMED') {
      statusInfo = {
        'color': Color(0xFF2196F3),
        'label': 'Confirmada',
        'icon': Icons.check_circle_rounded,
      };
    } else if (estado == 'COMPLETED') {
      statusInfo = {
        'color': Color(0xFF4CAF50),
        'label': 'Completada',
        'icon': Icons.task_alt_rounded,
      };
    } else if (estado == 'CANCELLED') {
      statusInfo = {
        'color': Color(0xFFF44336),
        'label': 'Cancelada',
        'icon': Icons.cancel_rounded,
      };
    }
    
    final padding = isSmallPhone ? 12.0 : (isPhone ? 14.0 : 16.0);
    final nameSize = isSmallPhone ? 13.0 : (isPhone ? 14.0 : 15.0);
    final serviceSize = isSmallPhone ? 10.0 : (isPhone ? 11.0 : 12.0);
    final statusSize = isSmallPhone ? 9.0 : (isPhone ? 10.0 : 11.0);
    final infoSize = isSmallPhone ? 10.0 : (isPhone ? 11.0 : 12.0);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (statusInfo['color'] as Color).withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (statusInfo['color'] as Color).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con cliente y estado
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallPhone ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.gold.withOpacity(0.85)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.black,
                  size: isSmallPhone ? 16 : 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$clienteNombre $clienteApellido',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: nameSize,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2),
                    Text(
                      servicioNombre,
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: serviceSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallPhone ? 8 : 10,
                  vertical: isSmallPhone ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: (statusInfo['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (statusInfo['color'] as Color).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusInfo['icon'] as IconData,
                      color: statusInfo['color'] as Color,
                      size: isSmallPhone ? 11 : 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      statusInfo['label'] as String,
                      style: TextStyle(
                        color: statusInfo['color'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: statusSize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Info de hora y fecha
          Container(
            padding: EdgeInsets.all(isSmallPhone ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF64B5F6),
                        size: isSmallPhone ? 14 : 16,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$startTime - $endTime',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: infoSize,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFFBA68C8),
                        size: isSmallPhone ? 14 : 16,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          fecha != null
                              ? DateFormat('d MMM', 'es_ES').format(fecha)
                              : 'Sin fecha',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: infoSize,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ESTADO VACÍO ====================
  Widget _buildEmptyState(
    String message,
    IconData icon,
    Color color,
    bool isSmallPhone,
    bool isPhone,
  ) {
    final padding = isSmallPhone ? 24.0 : (isPhone ? 28.0 : 32.0);
    final iconSize = isSmallPhone ? 36.0 : (isPhone ? 40.0 : 44.0);
    final textSize = isSmallPhone ? 12.0 : (isPhone ? 13.0 : 14.0);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallPhone ? 14 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color.withOpacity(0.5),
              size: iconSize,
            ),
          ),
          SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: textSize,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== CALIFICACIONES ====================
  Widget _buildRatingsSection(bool isSmallPhone, bool isPhone, bool isTablet) {
    final headerPadding = isSmallPhone ? 12.0 : (isPhone ? 14.0 : 16.0);
    final titleSize = isSmallPhone ? 16.0 : (isPhone ? 18.0 : 20.0);
    final badgeSize = isSmallPhone ? 12.0 : (isPhone ? 14.0 : 15.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(headerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF57C00).withOpacity(0.15),
                Color(0xFFF57C00).withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color(0xFFFFA726).withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFB74D),
                    size: isSmallPhone ? 18 : 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Calificaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallPhone ? 10 : 12,
                  vertical: isSmallPhone ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFFFA726).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_ratings.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: badgeSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        _ratings.isEmpty
            ? _buildEmptyState(
                'No tienes calificaciones',
                Icons.star_outline_rounded,
                Color(0xFFFFA726),
                isSmallPhone,
                isPhone,
              )
            : Column(
                children: [
                  _buildRatingsSummary(isSmallPhone, isPhone),
                  SizedBox(height: 14),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _ratings.take(5).length,
                    separatorBuilder: (_, __) => SizedBox(height: isSmallPhone ? 10 : 12),
                    itemBuilder: (context, index) {
                      return _buildRatingCard(_ratings[index], isSmallPhone, isPhone);
                    },
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildRatingsSummary(bool isSmallPhone, bool isPhone) {
    final padding = isSmallPhone ? 16.0 : (isPhone ? 18.0 : 20.0);
    final ratingSize = isSmallPhone ? 28.0 : (isPhone ? 32.0 : 36.0);
    final starSize = isSmallPhone ? 16.0 : (isPhone ? 18.0 : 20.0);
    final titleSize = isSmallPhone ? 11.0 : (isPhone ? 12.0 : 14.0);
    final countSize = isSmallPhone ? 14.0 : (isPhone ? 16.0 : 18.0);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Color(0xFFFFA726).withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFA726).withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallPhone ? 14 : 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFFA726).withOpacity(0.35),
                        blurRadius: 15,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ratingSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < _averageRating.floor()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: i < _averageRating.floor()
                          ? Color(0xFFFFA726)
                          : Colors.grey.shade700,
                      size: starSize,
                    );
                  }),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promedio',
                  style: TextStyle(
                    color: AppColors.gray,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '${_ratings.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: countSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'clientes',
                  style: TextStyle(
                    color: AppColors.gray,
                    fontSize: titleSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(dynamic rating, bool isSmallPhone, bool isPhone) {
    final clienteNombre = rating['clienteNombre'] ?? 'Cliente';
    final servicio = rating['servicio'] ?? 'Servicio';
    final estrellas = rating['estrellas'] ?? 0;
    final comentario = rating['comentario'] ?? '';
    
    final padding = isSmallPhone ? 12.0 : (isPhone ? 14.0 : 16.0);
    final nameSize = isSmallPhone ? 12.0 : (isPhone ? 13.0 : 14.0);
    final serviceSize = isSmallPhone ? 10.0 : (isPhone ? 11.0 : 12.0);
    final starSize = isSmallPhone ? 14.0 : (isPhone ? 15.0 : 16.0);
    final commentSize = isSmallPhone ? 10.0 : (isPhone ? 11.0 : 12.0);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color(0xFFFFA726).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CLIENTE y ESTRELLAS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallPhone ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFA726).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Color(0xFFFFA726),
                        size: isSmallPhone ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        clienteNombre,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: nameSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < estrellas ? Icons.star_rounded : Icons.star_border_rounded,
                    color: i < estrellas ? Color(0xFFFFA726) : Colors.grey.shade700,
                    size: starSize,
                  );
                }),
              ),
            ],
          ),
          
          // SERVICIO
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallPhone ? 8 : 10,
              vertical: isSmallPhone ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cut,
                  size: isSmallPhone ? 12 : 14,
                  color: Color(0xFFFFA726),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    servicio,
                    style: TextStyle(
                      color: Color(0xFFFFA726).withOpacity(0.8),
                      fontSize: serviceSize,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // COMENTARIO (si existe)
          if (comentario.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(isSmallPhone ? 8 : 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comentario,
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: commentSize,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
