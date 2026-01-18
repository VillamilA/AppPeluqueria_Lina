import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../api/reports_api.dart';
import '../../core/theme/app_theme.dart';

class StoreIncomeReportTab extends StatefulWidget {
  final String token;
  const StoreIncomeReportTab({super.key, required this.token});

  @override
  State<StoreIncomeReportTab> createState() => _StoreIncomeReportTabState();
}

class _StoreIncomeReportTabState extends State<StoreIncomeReportTab> {
  bool isLoading = true;
  Map<String, dynamic> reportData = {};
  String errorMessage = '';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    selectedStartDate = DateTime.now().subtract(Duration(days: 30));
    selectedEndDate = DateTime.now();
    _fetchStoreIncomeReport();
  }

  Future<void> _fetchStoreIncomeReport() async {
    try {
      setState(() => isLoading = true);
      
      final api = ReportsApi(ApiClient.instance);
      
      final fromStr = '${selectedStartDate!.year}-${selectedStartDate!.month.toString().padLeft(2, '0')}-${selectedStartDate!.day.toString().padLeft(2, '0')}';
      final toStr = '${selectedEndDate!.year}-${selectedEndDate!.month.toString().padLeft(2, '0')}-${selectedEndDate!.day.toString().padLeft(2, '0')}';

      final response = await api.getRevenueReport(
        token: widget.token,
        fromDate: fromStr,
        toDate: toStr,
      );

      print('[STORE_INCOME] Status: ${response.statusCode}');
      print('[STORE_INCOME] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          reportData = (data as Map<String, dynamic>?) ?? {};
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar el reporte de ingresos';
          isLoading = false;
        });
      }
    } catch (e) {
      print('[STORE_INCOME] Error: $e');
      setState(() {
        errorMessage = 'Error al conectar';
        isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.charcoal,
              onSurface: AppColors.gray,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedStartDate = picked);
      _fetchStoreIncomeReport();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedEndDate ?? DateTime.now(),
      firstDate: selectedStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.charcoal,
              onSurface: AppColors.gray,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedEndDate = picked);
      _fetchStoreIncomeReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchStoreIncomeReport,
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
              onPressed: _fetchStoreIncomeReport,
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
            _buildReportHeader(),
            SizedBox(height: 16),
            _buildDateFilterRow(),
            SizedBox(height: 24),
            _buildIncomeSection(),
            SizedBox(height: 24),
            _buildDetailedMetrics(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresos del Local',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Resumen de ingresos totales',
                style: TextStyle(color: AppColors.gray, fontSize: 14),
              ),
            ],
          ),
        ),
        Icon(Icons.store, color: AppColors.gold, size: 40),
      ],
    );
  }

  Widget _buildDateFilterRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
              padding: EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: () => _selectStartDate(context),
            icon: Icon(Icons.calendar_today, color: AppColors.gold, size: 18),
            label: Text(
              selectedStartDate != null
                  ? DateFormat('d MMM', 'es_ES').format(selectedStartDate!)
                  : 'Desde',
              style: TextStyle(color: AppColors.gold, fontSize: 12),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
              padding: EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: () => _selectEndDate(context),
            icon: Icon(Icons.calendar_today, color: AppColors.gold, size: 18),
            label: Text(
              selectedEndDate != null
                  ? DateFormat('d MMM', 'es_ES').format(selectedEndDate!)
                  : 'Hasta',
              style: TextStyle(color: AppColors.gold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeSection() {
    final totalIncome = reportData['totalIncome'] ?? 0.0;
    final expenses = reportData['expenses'] ?? 0.0;
    final netIncome = totalIncome - expenses;
    final profitMargin = totalIncome > 0 ? (netIncome / totalIncome * 100) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade900,
            Colors.green.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresos Totales',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${totalIncome.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(Icons.attach_money, color: Colors.white, size: 48),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.white30,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gastos',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${expenses.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Ganancia Neta',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${netIncome.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.yellow.shade200, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Margen',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${profitMargin.toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    final completedBookings = reportData['completedBookings'] ?? 0;
    final averagePerBooking = reportData['averagePerBooking'] ?? 0.0;
    final daysPeriod = selectedEndDate?.difference(selectedStartDate!).inDays ?? 0;
    final incomePerDay = daysPeriod > 0 ? ((reportData['totalIncome'] ?? 0.0) / daysPeriod) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas Detalladas',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildMetricCard(
              title: 'Citas Completadas',
              value: '$completedBookings',
              icon: Icons.check_circle,
              color: Colors.blue.shade700,
            ),
            _buildMetricCard(
              title: 'Promedio por Cita',
              value: '\$${averagePerBooking.toStringAsFixed(2)}',
              icon: Icons.trending_up,
              color: Colors.orange.shade700,
            ),
            _buildMetricCard(
              title: 'Ingreso Diario',
              value: '\$${incomePerDay.toStringAsFixed(2)}',
              icon: Icons.calendar_today,
              color: Colors.purple.shade700,
            ),
            _buildMetricCard(
              title: 'Período',
              value: '$daysPeriod días',
              icon: Icons.date_range,
              color: Colors.red.shade700,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
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
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
