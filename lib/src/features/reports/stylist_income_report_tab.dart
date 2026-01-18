import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../api/reports_api.dart';
import '../../core/theme/app_theme.dart';

class StylistIncomeReportTab extends StatefulWidget {
  final String token;
  const StylistIncomeReportTab({super.key, required this.token});

  @override
  State<StylistIncomeReportTab> createState() => _StylistIncomeReportTabState();
}

class _StylistIncomeReportTabState extends State<StylistIncomeReportTab> {
  bool isLoading = true;
  List<dynamic> stylistData = [];
  String errorMessage = '';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    selectedStartDate = DateTime.now().subtract(Duration(days: 30));
    selectedEndDate = DateTime.now();
    _fetchStylistIncomeReport();
  }

  Future<void> _fetchStylistIncomeReport() async {
    try {
      setState(() => isLoading = true);
      
      final api = ReportsApi(ApiClient.instance);
      
      final fromStr = '${selectedStartDate!.year}-${selectedStartDate!.month.toString().padLeft(2, '0')}-${selectedStartDate!.day.toString().padLeft(2, '0')}';
      final toStr = '${selectedEndDate!.year}-${selectedEndDate!.month.toString().padLeft(2, '0')}-${selectedEndDate!.day.toString().padLeft(2, '0')}';

      final response = await api.getStylistsRevenueReport(
        token: widget.token,
        fromDate: fromStr,
        toDate: toStr,
      );

      print('[STYLIST_INCOME] Status: ${response.statusCode}');
      print('[STYLIST_INCOME] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          stylistData = data is List ? data : (data['stylists'] as List? ?? []);
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar el reporte de estilistas';
          isLoading = false;
        });
      }
    } catch (e) {
      print('[STYLIST_INCOME] Error: $e');
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
      _fetchStylistIncomeReport();
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
      _fetchStylistIncomeReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchStylistIncomeReport,
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
              onPressed: _fetchStylistIncomeReport,
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
            SizedBox(height: 16),
            _buildStylistList(),
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
                'Ingresos por Estilista',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${stylistData.length} estilistas',
                style: TextStyle(color: AppColors.gray, fontSize: 14),
              ),
            ],
          ),
        ),
        Icon(Icons.trending_up, color: AppColors.gold, size: 40),
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

  Widget _buildStylistList() {
    if (stylistData.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.person_off, color: AppColors.gray, size: 48),
              SizedBox(height: 12),
              Text(
                'No hay datos disponibles',
                style: TextStyle(color: AppColors.gray, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Calcular total
    double totalIncome = 0;
    for (var stylist in stylistData) {
      totalIncome += (stylist['totalIncome'] ?? 0.0) as double;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de total
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade900,
                Colors.green.shade700,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Row(
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(Icons.attach_money, color: Colors.white, size: 40),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Lista de estilistas
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: stylistData.length,
          itemBuilder: (context, index) {
            final stylist = stylistData[index];
            final income = (stylist['totalIncome'] ?? 0.0) as double;
            final bookings = stylist['completedBookings'] ?? 0;
            final percentage = totalIncome > 0 ? (income / totalIncome * 100) : 0.0;

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(12),
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
                              stylist['name'] ?? 'Sin nombre',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '$bookings citas completadas',
                              style: TextStyle(
                                color: AppColors.gray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${income.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green.shade400,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalIncome > 0 ? income / totalIncome : 0,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
