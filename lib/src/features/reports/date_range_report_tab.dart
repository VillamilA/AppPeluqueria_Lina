import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../api/reports_api.dart';
import '../../core/theme/app_theme.dart';
import '../common/dialogs/app_dialogs.dart';

class DateRangeReportTab extends StatefulWidget {
  final String token;
  const DateRangeReportTab({super.key, required this.token});

  @override
  State<DateRangeReportTab> createState() => _DateRangeReportTabState();
}

class _DateRangeReportTabState extends State<DateRangeReportTab> {
  bool isLoading = false;
  Map<String, dynamic> reportData = {};
  String errorMessage = '';
  
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    selectedStartDate = DateTime.now().subtract(Duration(days: 30));
    selectedEndDate = DateTime.now();
  }

  Future<void> _fetchReportByDateRange() async {
    if (selectedStartDate == null || selectedEndDate == null) {
      AppDialogHelper.showError(
        context,
        title: 'Error',
        message: 'Por favor selecciona un rango de fechas',
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      
      final api = ReportsApi(ApiClient.instance);
      
      final fromStr = '${selectedStartDate!.year}-${selectedStartDate!.month.toString().padLeft(2, '0')}-${selectedStartDate!.day.toString().padLeft(2, '0')}';
      final toStr = '${selectedEndDate!.year}-${selectedEndDate!.month.toString().padLeft(2, '0')}-${selectedEndDate!.day.toString().padLeft(2, '0')}';

      final response = await api.getSummaryReport(
        token: widget.token,
        fromDate: fromStr,
        toDate: toStr,
      );

      print('[DATE_REPORT] Status: ${response.statusCode}');
      print('[DATE_REPORT] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          reportData = (data as Map<String, dynamic>?) ?? {};
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar el reporte';
        });
      }
    } catch (e) {
      print('[DATE_REPORT] Error: $e');
      setState(() => errorMessage = 'Error al conectar');
    } finally {
      setState(() => isLoading = false);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            _buildReportHeader(),
            SizedBox(height: 24),
            _buildDateRangeSelector(),
            SizedBox(height: 24),
            if (reportData.isNotEmpty) ...[
              _buildReportContent(),
              SizedBox(height: 24),
            ] else if (errorMessage.isNotEmpty)
              _buildErrorState(),
          ],
        ),
      ),
    );
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
                    'Reporte por Fecha',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Filtra por rango de fechas',
                    style: TextStyle(color: AppColors.gray, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.date_range, color: AppColors.gold, size: 40),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona un rango de fechas',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'Desde',
                  date: selectedStartDate,
                  onPressed: () => _selectStartDate(context),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: 'Hasta',
                  date: selectedEndDate,
                  onPressed: () => _selectEndDate(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: isLoading ? null : _fetchReportByDateRange,
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Generar Reporte'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    DateTime? date,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.gray, fontSize: 12),
        ),
        SizedBox(height: 4),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onPressed,
          child: Text(
            date != null ? DateFormat('d MMM yyyy', 'es_ES').format(date) : 'Seleccionar',
            style: TextStyle(color: AppColors.gold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 12),
          Text(
            errorMessage,
            style: TextStyle(color: Colors.red.shade300, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    final totalIncome = reportData['totalIncome'] ?? 0.0;
    final completedBookings = reportData['completedBookings'] ?? 0;
    final averagePerBooking = reportData['averagePerBooking'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados del Reporte',
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
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              title: 'Ingresos',
              value: '\$${totalIncome.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.green.shade700,
            ),
            _buildStatCard(
              title: 'Citas',
              value: '$completedBookings',
              icon: Icons.check_circle,
              color: Colors.blue.shade700,
            ),
            _buildStatCard(
              title: 'Promedio/Cita',
              value: '\$${averagePerBooking.toStringAsFixed(2)}',
              icon: Icons.trending_up,
              color: Colors.orange.shade700,
            ),
            _buildStatCard(
              title: 'Período',
              value: '${DateFormat('d MMM', 'es_ES').format(selectedStartDate!)} - ${DateFormat('d MMM', 'es_ES').format(selectedEndDate!)}',
              icon: Icons.calendar_today,
              color: Colors.purple.shade700,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
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
