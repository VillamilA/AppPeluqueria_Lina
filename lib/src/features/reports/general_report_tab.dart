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
    
    final totalRevenue = (totals['totalRevenue'] ?? 0.0) as num;
    final totalBookings = (totals['totalBookings'] ?? 0) as num;
    
    // Contar citas completadas
    int completedBookings = 0;
    for (var status in bookingsByStatus) {
      if (status is Map && status['_id'] == 'COMPLETED') {
        completedBookings = status['count'] ?? 0;
      }
    }

    // Obtener el servicio más usado
    String topServiceName = 'N/A';
    int topServiceCount = 0;
    if (topServices.isNotEmpty && topServices[0] is Map) {
      topServiceName = topServices[0]['serviceName'] ?? 'N/A';
      topServiceCount = topServices[0]['bookingsCount'] ?? 0;
    }

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
          value: '${totalBookings.toInt()}',
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
    
    // Mapear estados a conteos
    Map<String, int> statusCounts = {
      'COMPLETED': 0,
      'SCHEDULED': 0,
      'CANCELLED': 0,
    };
    
    for (var status in bookingsByStatus) {
      if (status is Map) {
        final statusId = status['_id'] ?? '';
        final count = status['count'] ?? 0;
        if (statusCounts.containsKey(statusId)) {
          statusCounts[statusId] = count;
        }
      }
    }

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
                'Completadas',
                statusCounts['COMPLETED'] ?? 0,
                Colors.green.shade400,
                Icons.check_circle,
              ),
              Divider(color: AppColors.gold.withOpacity(0.2), height: 20),
              _buildStatusMetricRow(
                'Programadas',
                statusCounts['SCHEDULED'] ?? 0,
                Colors.blue.shade400,
                Icons.calendar_today,
              ),
              Divider(color: AppColors.gold.withOpacity(0.2), height: 20),
              _buildStatusMetricRow(
                'Canceladas',
                statusCounts['CANCELLED'] ?? 0,
                Colors.red.shade400,
                Icons.cancel,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMetricRow(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.gray, fontSize: 14),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
