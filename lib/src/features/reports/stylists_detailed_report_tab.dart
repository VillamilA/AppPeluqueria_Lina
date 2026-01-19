import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import '../../api/reports_api.dart';
import '../../core/theme/app_theme.dart';

class StylistsDetailedReportTab extends StatefulWidget {
  final String token;
  final String userRole;
  
  const StylistsDetailedReportTab({
    super.key,
    required this.token,
    required this.userRole,
  });

  @override
  State<StylistsDetailedReportTab> createState() => _StylistsDetailedReportTabState();
}

class _StylistsDetailedReportTabState extends State<StylistsDetailedReportTab> {
  bool isLoading = true;
  List<dynamic> stylistReports = [];
  String errorMessage = '';
  
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  bool _isCustomDateRange = false;

  @override
  void initState() {
    super.initState();
    _fetchDetailedReport();
  }

  Future<void> _fetchDetailedReport({DateTime? fromDate, DateTime? toDate}) async {
    try {
      setState(() => isLoading = true);
      
      final api = ReportsApi(ApiClient.instance);
      final now = DateTime.now();
      final from = fromDate ?? now.subtract(Duration(days: 30));
      final to = toDate ?? now;
      
      final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final toStr = '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
      
      final response = await api.getStylistsDetailedReport(
        token: widget.token,
        fromDate: fromStr,
        toDate: toStr,
      );

      print('[STYLISTS_DETAILED] Status: ${response.statusCode}');
      print('[STYLISTS_DETAILED] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          stylistReports = (data['reports'] as List<dynamic>?) ?? [];
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar reportes de estilistas';
          isLoading = false;
        });
      }
    } catch (e) {
      print('[STYLISTS_DETAILED] Error: $e');
      setState(() {
        errorMessage = 'Error al conectar';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchDetailedReport,
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
              onPressed: _fetchDetailedReport,
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
            if (stylistReports.isEmpty)
              _buildEmptyState()
            else
              ..._buildStylistCards(),
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
                      ? () => _fetchDetailedReport(
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
                    _fetchDetailedReport();
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
      setState(() {
        _selectedFromDate = picked;
        _isCustomDateRange = true;
      });
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
      setState(() {
        _selectedToDate = picked;
        _isCustomDateRange = true;
      });
    }
  }

  Widget _buildReportHeader() {
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
                    'Reporte de Estilistas',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${stylistReports.length} estilista(s)',
                    style: TextStyle(color: AppColors.gray, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.people, color: AppColors.gold, size: 40),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.people_outline, color: AppColors.gold, size: 64),
          SizedBox(height: 16),
          Text(
            'No hay datos disponibles',
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStylistCards() {
    return stylistReports.map((report) {
      if (report is! Map) return SizedBox.shrink();

      final stylist = report['stylist'] as Map<String, dynamic>? ?? {};
      final earnings = report['earnings'] as Map<String, dynamic>? ?? {};
      final ratings = report['ratings'] as Map<String, dynamic>? ?? {};
      final bookingsByStatus = report['bookingsByStatus'] as List<dynamic>? ?? [];
      final topServices = report['topServices'] as List<dynamic>? ?? [];
      final extra = report['extra'] as Map<String, dynamic>? ?? {};

      final stylistName = stylist['name'] ?? 'N/A';
      final totalRevenue = ((earnings['totalRevenue'] ?? 0.0) as num).toDouble();
      final paidBookings = (earnings['paidBookings'] ?? 0) as int;
      final avgTicket = ((earnings['avgTicket'] ?? 0.0) as num).toDouble();
      final avgRating = ((ratings['avgRating'] ?? 0.0) as num).toDouble();
      final ratingsCount = (ratings['ratingsCount'] ?? 0) as int;
      final uniqueClients = (extra['uniqueClients'] ?? 0) as int;

      // Contar citas por estado
      int scheduledCount = 0;
      int pendingCount = 0;
      int confirmedCount = 0;
      int completedCount = 0;
      int cancelledCount = 0;
      int noShowCount = 0;
      
      for (var status in bookingsByStatus) {
        if (status is Map) {
          final statusId = (status['_id'] ?? '').toString().toUpperCase().trim();
          final count = (status['count'] ?? 0) as int;
          
          if (statusId == 'SCHEDULED') scheduledCount = count;
          else if (statusId == 'PENDING_STYLIST_CONFIRMATION') pendingCount = count;
          else if (statusId == 'CONFIRMED') confirmedCount = count;
          else if (statusId == 'COMPLETED') completedCount = count;
          else if (statusId == 'CANCELLED') cancelledCount = count;
          else if (statusId == 'NO_SHOW') noShowCount = count;
        }
      }

      return Column(
        children: [
          _buildStylistCard(
            name: stylistName,
            totalRevenue: totalRevenue,
            paidBookings: paidBookings,
            avgTicket: avgTicket,
            avgRating: avgRating,
            ratingsCount: ratingsCount,
            uniqueClients: uniqueClients,
            scheduledCount: scheduledCount,
            pendingCount: pendingCount,
            confirmedCount: confirmedCount,
            completedCount: completedCount,
            cancelledCount: cancelledCount,
            noShowCount: noShowCount,
            topServices: topServices,
          ),
          SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  Widget _buildStylistCard({
    required String name,
    required double totalRevenue,
    required int paidBookings,
    required double avgTicket,
    required double avgRating,
    required int ratingsCount,
    required int uniqueClients,
    required int scheduledCount,
    required int pendingCount,
    required int confirmedCount,
    required int completedCount,
    required int cancelledCount,
    required int noShowCount,
    required List<dynamic> topServices,
  }) {
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
          // Encabezado con nombre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⭐ ${avgRating.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // KPIs
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.4,
            children: [
              _buildMiniKPI('Ingresos', '\$${totalRevenue.toStringAsFixed(2)}', Colors.green),
              _buildMiniKPI('Completadas', '$completedCount', Colors.green),
              _buildMiniKPI('Programadas', '$scheduledCount', Colors.blue),
              _buildMiniKPI('Confirmadas', '$confirmedCount', Colors.purple),
              _buildMiniKPI('Pendientes', '$pendingCount', Colors.amber),
              _buildMiniKPI('Canceladas', '$cancelledCount', Colors.red),
              _buildMiniKPI('No-show', '$noShowCount', Colors.grey),
              _buildMiniKPI('Clientes', '$uniqueClients', Colors.cyan),
              _buildMiniKPI('Ticket Prom.', '\$${avgTicket.toStringAsFixed(2)}', Colors.orange),
            ],
          ),
          SizedBox(height: 16),
          // Top servicios
          if (topServices.isNotEmpty) ...[
            Text(
              'Top Servicios',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...topServices.take(3).map((service) {
              final serviceName = service['serviceName'] ?? 'N/A';
              final revenue = (service['totalRevenue'] ?? 0.0) as num;
              final count = service['bookingsCount'] ?? 0;
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        style: TextStyle(color: AppColors.gray, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${revenue.toStringAsFixed(2)} ($count)',
                      style: TextStyle(
                        color: Colors.green.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniKPI(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadPdfSection() {
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _downloadStylistsReportPdf,
            icon: Icon(Icons.download),
            label: Text(
              'Descargar PDF de Estilistas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
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
