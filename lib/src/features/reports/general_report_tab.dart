import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import '../../api/reports_api.dart';
import '../../core/theme/app_theme.dart';

class GeneralReportTab extends StatefulWidget {
  final String token;
  const GeneralReportTab({super.key, required this.token});

  @override
  State<GeneralReportTab> createState() => _GeneralReportTabState();
}

class _GeneralReportTabState extends State<GeneralReportTab> {
  bool isLoading = true;
  Map<String, dynamic> reportData = {};
  String errorMessage = '';
  
  // Filtro de fechas
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  bool _isCustomDateRange = false;

  @override
  void initState() {
    super.initState();
    _fetchGeneralReport();
  }

  Future<void> _fetchGeneralReport({DateTime? fromDate, DateTime? toDate}) async {
    try {
      setState(() => isLoading = true);
      
      final api = ReportsApi(ApiClient.instance);
      final now = DateTime.now();
      final from = fromDate ?? now.subtract(Duration(days: 30));
      final to = toDate ?? now;
      
      final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final toStr = '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
      
      final response = await api.getSummaryReport(
        token: widget.token,
        fromDate: fromStr,
        toDate: toStr,
      );

      print('[GENERAL_REPORT] Status: ${response.statusCode}');
      print('[GENERAL_REPORT] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // DEBUG: Imprimir los datos recibidos
        print('=== GENERAL_REPORT DEBUG ===');
        print('Data keys: ${(data as Map).keys.toList()}');
        
        if (data['bookingsByStatus'] != null) {
          print('bookingsByStatus:');
          for (var status in data['bookingsByStatus']) {
            print('  - ${status}');
          }
        } else {
          print('bookingsByStatus es NULL');
        }
        
        if (data['totals'] != null) {
          print('totals: ${data['totals']}');
        }
        
        setState(() {
          reportData = (data as Map<String, dynamic>?) ?? {};
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar el reporte general';
          isLoading = false;
        });
      }
    } catch (e) {
      print('[GENERAL_REPORT] Error: $e');
      setState(() {
        errorMessage = 'Error al conectar';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchGeneralReport,
      color: AppColors.gold,
      backgroundColor: AppColors.charcoal,
      child: isLoading
          ? _buildLoadingState()
          : errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildReportContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppColors.gold),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(color: AppColors.gray, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: _fetchGeneralReport,
              child: Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            _buildDateFilterSection(),
            SizedBox(height: 24),
            _buildReportHeader(),
            SizedBox(height: 24),
            _buildKPICards(),
            SizedBox(height: 24),
            _buildDetailedMetrics(),
            SizedBox(height: 24),
            _buildRevenueByDaySection(),
            SizedBox(height: 24),
            _buildRevenueByStylistSection(),
            SizedBox(height: 24),
            _buildRatingsByStylistSection(),
            SizedBox(height: 24),
            _buildDownloadPdfSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrar por Fechas',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  label: 'Desde',
                  date: _selectedFromDate,
                  onTap: () => _selectFromDate(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerField(
                  label: 'Hasta',
                  date: _selectedToDate,
                  onTap: () => _selectToDate(),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: (_selectedFromDate != null && _selectedToDate != null)
                      ? () => _fetchGeneralReport(
                            fromDate: _selectedFromDate,
                            toDate: _selectedToDate,
                          )
                      : null,
                  child: Text(
                    'Aplicar Filtro',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_isCustomDateRange) ...[
                SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedFromDate = null;
                      _selectedToDate = null;
                      _isCustomDateRange = false;
                    });
                    _fetchGeneralReport();
                  },
                  child: Text('Limpiar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.gray,
                fontSize: 11,
              ),
            ),
            SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Seleccionar',
              style: TextStyle(
                color: date != null ? Colors.white : AppColors.gray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              surface: AppColors.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedFromDate = picked);
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedToDate ?? DateTime.now(),
      firstDate: _selectedFromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              surface: AppColors.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedToDate = picked);
    }
  }

  Widget _buildReportHeader() {
    final range = reportData['range'] as Map<String, dynamic>? ?? {};
    final label = range['label'] ?? 'Período actual';
    
    return Column(
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
                    'Reporte General',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(color: AppColors.gray, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.assessment, color: AppColors.gold, size: 40),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICards() {
    final totals = reportData['totals'] as Map<String, dynamic>? ?? {};
    final bookingsByStatus = reportData['bookingsByStatus'] as List<dynamic>? ?? [];
    final topServices = reportData['topServices'] as List<dynamic>? ?? [];
    
    final totalRevenue = ((totals['totalRevenue'] ?? 0.0) as num).toDouble();
    final totalPaidBookings = (totals['totalPaidBookings'] ?? 0) as int;
    
    // Contar citas completadas
    int completedBookings = 0;
    for (var status in bookingsByStatus) {
      if (status is Map) {
        final statusId = (status['_id'] ?? '').toString().toUpperCase().trim();
        if (statusId == 'COMPLETED') {
          completedBookings = (status['count'] ?? 0) as int;
        }
      }
    }

    // Obtener el servicio más usado
    String topServiceName = 'N/A';
    int topServiceCount = 0;
    if (topServices.isNotEmpty && topServices[0] is Map) {
      topServiceName = topServices[0]['serviceName'] ?? 'N/A';
      topServiceCount = (topServices[0]['bookingsCount'] ?? 0) as int;
    }
    
    print('[KPI_CARDS DEBUG]');
    print('  totalRevenue: $totalRevenue');
    print('  totalPaidBookings: $totalPaidBookings');
    print('  completedBookings: $completedBookings');
    print('  topServiceName: $topServiceName');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildKPICard(
          title: 'Ingresos',
          value: '\$${totalRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.green.shade700,
        ),
        _buildKPICard(
          title: 'Citas Completadas',
          value: '$completedBookings',
          icon: Icons.check_circle,
          color: Colors.blue.shade700,
        ),
        _buildKPICard(
          title: 'Total de Citas',
          value: '${totalPaidBookings.toInt()}',
          icon: Icons.calendar_today,
          color: Colors.orange.shade700,
        ),
        _buildTopServiceCard(
          serviceName: topServiceName,
          bookingsCount: topServiceCount,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServiceCard({
    required String serviceName,
    required int bookingsCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade700.withOpacity(0.3), width: 1),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star, color: Colors.purple.shade700, size: 32),
          SizedBox(height: 12),
          Text(
            'Top Servicio',
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  serviceName,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '$bookingsCount citas',
                  style: TextStyle(
                    color: Colors.purple.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    final bookingsByStatus = reportData['bookingsByStatus'] as List<dynamic>? ?? [];
    
    // Mapear estados a conteos con orden específico
    Map<String, int> statusCounts = {
      'SCHEDULED': 0,
      'PENDING_STYLIST_CONFIRMATION': 0,
      'CONFIRMED': 0,
      'COMPLETED': 0,
      'CANCELLED': 0,
      'NO_SHOW': 0,
    };
    
    print('🔍 DEBUG _buildDetailedMetrics:');
    print('  - bookingsByStatus list length: ${bookingsByStatus.length}');
    print('  - Raw data: $bookingsByStatus');
    
    for (var status in bookingsByStatus) {
      if (status is Map) {
        final statusId = (status['_id'] ?? 'UNKNOWN').toString().toUpperCase().trim();
        final count = (status['count'] ?? 0) as int;
        
        print('  - Status encontrado: "$statusId" = $count citas');
        
        // Buscar coincidencia en el mapa (flexible)
        bool found = false;
        for (var key in statusCounts.keys) {
          if (key.toUpperCase() == statusId) {
            statusCounts[key] = count;
            found = true;
            print('    ✅ Mapeado a: $key');
            break;
          }
        }
        
        if (!found) {
          print('    ⚠️  Status "$statusId" NO coincide con ninguno esperado');
        }
      }
    }
    
    print('  - statusCounts final: $statusCounts');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado de Citas',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusMetricRow(
                '📅 SCHEDULED',
                'Programada',
                statusCounts['SCHEDULED'] ?? 0,
                Colors.blue.shade400,
                Icons.calendar_today,
              ),
              Divider(color: AppColors.gold.withOpacity(0.2), height: 20),
              _buildStatusMetricRow(
                '⏳ PENDING_STYLIST_CONFIRMATION',
                'Esperando confirmación del estilista',
                statusCounts['PENDING_STYLIST_CONFIRMATION'] ?? 0,
                Colors.amber.shade400,
                Icons.schedule,
              ),
              Divider(color: AppColors.gold.withOpacity(0.2), height: 20),
              _buildStatusMetricRow(
                '✅ CONFIRMED',
                'Confirmada por estilista',
                statusCounts['CONFIRMED'] ?? 0,
                Colors.purple.shade400,
                Icons.task_alt,
              ),
              Divider(color: AppColors.gold.withOpacity(0.2), height: 20),
              _buildStatusMetricRow(
                '🎉 COMPLETED',
                'Finalizada y pagada',
                statusCounts['COMPLETED'] ?? 0,
                Colors.green.shade400,
                Icons.check_circle,
              ),
              Divider(color: AppColors.gold.withOpacity(0.2), height: 20),
              _buildStatusMetricRow(
                '❌ CANCELLED',
                'Cancelada',
                statusCounts['CANCELLED'] ?? 0,
                Colors.red.shade400,
                Icons.cancel,
              ),
              Divider(color: AppColors.gold.withOpacity(0.2), height: 20),
              _buildStatusMetricRow(
                '🚫 NO_SHOW',
                'Cliente no asistió',
                statusCounts['NO_SHOW'] ?? 0,
                Colors.grey.shade400,
                Icons.no_meeting_room,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMetricRow(
    String label,
    String description,
    int count,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueByDaySection() {
    final revenueByDay = reportData['revenueByDay'] as List<dynamic>? ?? [];
    
    if (revenueByDay.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresos por Día',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTableHeader(['Fecha', 'Ingresos', 'Citas']),
              SizedBox(height: 8),
              ...revenueByDay.take(10).map((item) {
                if (item is! Map) return SizedBox.shrink();
                final day = item['day'] ?? 'N/A';
                final total = ((item['total'] ?? 0.0) as num).toDouble();
                final count = (item['count'] ?? 0) as int;
                
                return Column(
                  children: [
                    _buildTableRow([day, '\$${total.toStringAsFixed(2)}', '$count']),
                    Divider(color: AppColors.gold.withOpacity(0.1), height: 1),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueByStylistSection() {
    final revenueByStylist = reportData['revenueByStylist'] as List<dynamic>? ?? [];
    
    if (revenueByStylist.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresos por Estilista',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTableHeader(['Estilista', 'Ingresos', 'Citas']),
              SizedBox(height: 8),
              ...revenueByStylist.map((item) {
                if (item is! Map) return SizedBox.shrink();
                final name = item['stylistName'] ?? 'N/A';
                final revenue = ((item['totalRevenue'] ?? 0.0) as num).toDouble();
                final count = (item['bookingsCount'] ?? 0) as int;
                
                return Column(
                  children: [
                    _buildTableRow([name, '\$${revenue.toStringAsFixed(2)}', '$count']),
                    Divider(color: AppColors.gold.withOpacity(0.1), height: 1),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsByStylistSection() {
    final ratingsByStylist = reportData['ratingsByStylist'] as List<dynamic>? ?? [];
    
    if (ratingsByStylist.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ratings por Estilista',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTableHeader(['Estilista', 'Rating', 'Reseñas']),
              SizedBox(height: 8),
              ...ratingsByStylist.map((item) {
                if (item is! Map) return SizedBox.shrink();
                final name = item['stylistName'] ?? 'N/A';
                final rating = ((item['avgRating'] ?? 0.0) as num).toDouble();
                final count = (item['ratingsCount'] ?? 0) as int;
                
                return Column(
                  children: [
                    _buildTableRow([name, '⭐ ${rating.toStringAsFixed(1)}', '$count']),
                    Divider(color: AppColors.gold.withOpacity(0.1), height: 1),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    return Row(
      children: headers.map((header) {
        return Expanded(
          child: Text(
            header,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableRow(List<String> values) {
    return Row(
      children: values.map((value) {
        return Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDownloadPdfSection() {
    final range = reportData['range'] as Map<String, dynamic>? ?? {};
    final label = range['label'] ?? 'Período actual';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descargas',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _downloadGeneralReportPdf,
                icon: Icon(Icons.download),
                label: Text(
                  'Descargar PDF',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _downloadStylistsReportPdf,
                icon: Icon(Icons.description),
                label: Text(
                  'Estilistas PDF',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          'Período: $label',
          style: TextStyle(
            color: AppColors.gray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _downloadGeneralReportPdf() async {
    try {
      final now = DateTime.now();
      final from = _selectedFromDate ?? now.subtract(Duration(days: 30));
      final to = _selectedToDate ?? now;
      
      final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final toStr = '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
      
      final api = ReportsApi(ApiClient.instance);
      final response = await api.downloadGeneralReportPdf(
        token: widget.token,
        fromDate: fromStr,
        toDate: toStr,
      );

      if (response.statusCode == 200) {
        _showSuccessDialog('PDF descargado correctamente');
      } else {
        _showErrorDialog('Error al descargar el PDF');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _downloadStylistsReportPdf() async {
    try {
      final now = DateTime.now();
      final from = _selectedFromDate ?? now.subtract(Duration(days: 30));
      final to = _selectedToDate ?? now;
      
      final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final toStr = '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
      
      final api = ReportsApi(ApiClient.instance);
      final response = await api.downloadStylistsReportPdf(
        token: widget.token,
        fromDate: fromStr,
        toDate: toStr,
      );

      if (response.statusCode == 200) {
        _showSuccessDialog('PDF de estilistas descargado correctamente');
      } else {
        _showErrorDialog('Error al descargar el PDF');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
