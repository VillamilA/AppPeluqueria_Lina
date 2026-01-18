import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../api/reports_api.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/reports_service.dart';
import '../../data/models/report_models.dart';
import 'widgets/report_charts.dart';

class ReportsDashboardPage extends StatefulWidget {
  final String token;
  final String userRole;

  const ReportsDashboardPage({
    super.key,
    required this.token,
    required this.userRole,
  });

  @override
  State<ReportsDashboardPage> createState() => _ReportsDashboardPageState();
}

class _ReportsDashboardPageState extends State<ReportsDashboardPage> with SingleTickerProviderStateMixin {
  late ReportsService _reportsService;
  late TabController _tabController;
  
  late DateTime _fromDate;
  late DateTime _toDate;

  bool _isLoading = false;
  String? _errorMessage;

  SummaryReport? _summaryReport;
  StylistReport? _stylistReport;

  String _selectedPeriod = '30d';

  @override
  void initState() {
    super.initState();
    _reportsService = ReportsService(ReportsApi(ApiClient.instance));
    _toDate = DateTime.now();
    _fromDate = _toDate.subtract(const Duration(days: 30));
    
    final tabCount = widget.userRole == 'ESTILISTA' ? 1 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
    
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case '7d':
          _fromDate = DateTime.now().subtract(const Duration(days: 7));
          _toDate = DateTime.now();
          break;
        case '30d':
          _fromDate = DateTime.now().subtract(const Duration(days: 30));
          _toDate = DateTime.now();
          break;
        case '90d':
          _fromDate = DateTime.now().subtract(const Duration(days: 90));
          _toDate = DateTime.now();
          break;
        case 'custom':
          _selectDateRange();
          return;
      }
    });
    _loadData();
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.userRole == 'ESTILISTA') {
        await _loadMyReport();
      } else {
        await _loadSummaryReport();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSummaryReport() async {
    try {
      final summary = await _reportsService.getSummary(
        widget.token,
        _formatDate(_fromDate),
        _formatDate(_toDate),
      );
      setState(() {
        _summaryReport = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStylistReport() async {
    try {
      final report = await _reportsService.getStylistsReport(
        widget.token,
        _formatDate(_fromDate),
        _formatDate(_toDate),
      );
      setState(() {
        _stylistReport = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMyReport() async {
    try {
      final report = await _reportsService.getMyReport(
        widget.token,
        _formatDate(_fromDate),
        _formatDate(_toDate),
      );
      setState(() {
        _stylistReport = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    final TextEditingController nameController = TextEditingController(
      text: 'Reporte_${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
    );

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF2C2C2C), AppColors.charcoal],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.3),
                      AppColors.gold.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, size: 48, color: AppColors.gold),
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Generar PDF?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El reporte se descargará en tu dispositivo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre del archivo',
                  labelStyle: const TextStyle(color: AppColors.gold),
                  hintText: 'Ej: Reporte_Enero_2026',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  prefixIcon: const Icon(Icons.edit, color: AppColors.gold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.gold, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[700]!),
                        ),
                      ),
                      child: Text('Cancelar', style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.charcoal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: AppColors.gold.withOpacity(0.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Generar PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final String fileName = nameController.text.trim();
    if (fileName.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      String filePath;
      if (widget.userRole == 'ESTILISTA') {
        filePath = await _reportsService.downloadMyPdf(widget.token, _formatDate(_fromDate), _formatDate(_toDate));
      } else if (_tabController.index == 0) {
        filePath = await _reportsService.downloadGeneralPdf(widget.token, _formatDate(_fromDate), _formatDate(_toDate));
      } else {
        filePath = await _reportsService.downloadStylistsPdf(widget.token, _formatDate(_fromDate), _formatDate(_toDate));
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('¡PDF generado!', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Guardado como: $fileName.pdf', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Abrir',
              textColor: AppColors.gold,
              onPressed: () => _reportsService.openPdfFile(filePath),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.charcoal,
              surface: const Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _selectedPeriod = 'custom';
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        toolbarHeight: 70,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Reportes y Análisis',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: AppColors.gold),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                tooltip: 'Exportar PDF',
                color: Colors.black,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: _isLoading ? null : _downloadPdf,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(86),
          child: Column(
            children: [
              if (widget.userRole != 'ESTILISTA')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 2.5,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: Colors.grey[500],
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    onTap: (index) {
                      if (index == 0) {
                        _loadSummaryReport();
                      } else {
                        _loadStylistReport();
                      }
                    },
                    tabs: const [
                      Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'General', height: 38),
                      Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: 'Estilistas', height: 38),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip('7d', '7 días'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('30d', '30 días'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('90d', '90 días'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('custom', 'Personalizado', icon: Icons.date_range_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.gold.withOpacity(0.2), AppColors.gold.withOpacity(0.05)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(color: AppColors.gold, strokeWidth: 3),
                  ),
                  const SizedBox(height: 20),
                  Text('Cargando reportes...', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                        ),
                        const SizedBox(height: 20),
                        const Text('Error al cargar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.charcoal,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : widget.userRole == 'ESTILISTA'
                  ? _buildMyReportView()
                  : TabBarView(controller: _tabController, children: [_buildSummaryView(), _buildStylistsView()]),
    );
  }

  Widget _buildPeriodChip(String value, String label, {IconData? icon}) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _changePeriod(value);
      },
      backgroundColor: const Color(0xFF3A3A3A),
      selectedColor: AppColors.gold,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.gold : AppColors.gold.withOpacity(0.5), width: 1.5),
      ),
      elevation: isSelected ? 4 : 0,
      shadowColor: AppColors.gold.withOpacity(0.3),
    );
  }

  Widget _buildSummaryView() {
    if (_summaryReport == null) {
      return Center(child: Text('No hay datos', style: TextStyle(color: Colors.grey[400])));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Período: ${DateFormat('dd MMM').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}', icon: Icons.calendar_today_rounded),
            const SizedBox(height: 16),
            _buildKpiGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader('Tendencia de Ingresos', icon: Icons.trending_up_rounded),
            const SizedBox(height: 12),
            _buildModernCard(child: RevenueLineChart(data: _summaryReport!.revenueByDay)),
            const SizedBox(height: 24),
            _buildSectionHeader('Top Estilistas', icon: Icons.stars_rounded),
            const SizedBox(height: 12),
            _buildModernCard(child: StylistRevenueBarChart(data: _summaryReport!.revenueByStylist)),
            const SizedBox(height: 24),
            _buildSectionHeader('Estado de Citas', icon: Icons.pie_chart_rounded),
            const SizedBox(height: 12),
            _buildModernCard(
              child: Column(
                children: [
                  BookingsStatusPieChart(data: _summaryReport!.bookingsByStatus),
                  const SizedBox(height: 16),
                  _buildStatusLegend(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Top Servicios', icon: Icons.favorite_rounded),
                      const SizedBox(height: 12),
                      _buildModernCard(child: TopServicesList(services: _summaryReport!.topServices)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Ratings', icon: Icons.star_rounded),
                      const SizedBox(height: 12),
                      _buildModernCard(child: StylistRatingsList(ratings: _summaryReport!.ratingsByStylist)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildKpiCard('Ingresos Totales', '\$${_summaryReport!.totals.totalRevenue.toStringAsFixed(0)}', Icons.attach_money_rounded, Colors.green),
        _buildKpiCard('Citas Pagadas', '${_summaryReport!.totals.totalPaidBookings}', Icons.check_circle_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedPeriod == '7d' ? '7D' : _selectedPeriod == '30d' ? '30D' : '90D',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStylistsView() {
    if (_stylistReport == null || _stylistReport!.reports.isEmpty) {
      return Center(child: Text('No hay datos', style: TextStyle(color: Colors.grey[400])));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stylistReport!.reports.length,
      itemBuilder: (context, index) => _buildStylistCard(_stylistReport!.reports[index]),
    );
  }

  Widget _buildStylistCard(StylistDetail stylist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2C2C2C), AppColors.charcoal],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.gold,
            child: Text(stylist.stylist.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
          ),
          title: Text(stylist.stylist.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gold)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('\$${stylist.earnings.totalRevenue.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[300])),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(stylist.ratings.avgRating.toStringAsFixed(1), style: TextStyle(fontSize: 14, color: Colors.grey[300])),
              ],
            ),
          ),
          iconColor: AppColors.gold,
          collapsedIconColor: Colors.grey[500],
          children: [_buildStylistDetailContent(stylist)],
        ),
      ),
    );
  }

  Widget _buildStylistDetailContent(StylistDetail stylist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.gold, height: 1),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSmallKpi('Citas', '${stylist.earnings.paidBookings}', Icons.event_available),
            _buildSmallKpi('Ticket', '\$${stylist.earnings.avgTicket.toStringAsFixed(0)}', Icons.receipt_long),
            _buildSmallKpi('Clientes', '${stylist.extra.uniqueClients}', Icons.people),
          ],
        ),
        if (stylist.extra.peakHour != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('⏰ ${stylist.extra.peakHour}', Colors.blue),
              _buildChip('📅 ${stylist.extra.peakWeekday ?? "N/A"}', Colors.purple),
              _buildChip('❌ ${stylist.extra.cancelRatePct.toStringAsFixed(1)}%', Colors.orange),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSmallKpi(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMyReportView() {
    if (_stylistReport == null || _stylistReport!.reports.isEmpty) {
      return Center(child: Text('No hay datos', style: TextStyle(color: Colors.grey[400])));
    }

    final myData = _stylistReport!.reports.first;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gold.withOpacity(0.3), AppColors.gold.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.gold,
                  child: Text(myData.stylist.name[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
                ),
                const SizedBox(height: 12),
                Text(myData.stylist.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.gold)),
                Text(myData.stylist.email ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildStylistDetailContent(myData),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.gold),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gold, letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2C2C2C), AppColors.charcoal],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildStatusLegend() {
    final statuses = [
      {'label': 'Completado', 'color': Colors.green, 'icon': Icons.check_circle},
      {'label': 'Pendiente', 'color': Colors.orange, 'icon': Icons.schedule},
      {'label': 'Cancelado', 'color': Colors.red, 'icon': Icons.cancel},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: statuses.map((status) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (status['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (status['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status['icon'] as IconData, size: 14, color: status['color'] as Color),
              const SizedBox(width: 6),
              Text(status['label'] as String, style: TextStyle(fontSize: 12, color: status['color'] as Color, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
