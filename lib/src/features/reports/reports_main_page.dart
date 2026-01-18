import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'general_report_tab.dart';
import 'date_range_report_tab.dart';
import 'stylist_income_report_tab.dart';

class ReportsMainPage extends StatefulWidget {
  final String token;
  const ReportsMainPage({super.key, required this.token});

  @override
  State<ReportsMainPage> createState() => _ReportsMainPageState();
}

class _ReportsMainPageState extends State<ReportsMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportes',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Análisis de datos y desempeño',
              style: TextStyle(
                color: AppColors.gray,
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Column(
            children: [
              Divider(
                color: AppColors.gold.withOpacity(0.2),
                height: 1,
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.gold,
                indicatorWeight: 3,
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.gray,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.assessment, size: 20),
                    text: 'General',
                  ),
                  Tab(
                    icon: Icon(Icons.date_range, size: 20),
                    text: 'Por Fecha',
                  ),
                  Tab(
                    icon: Icon(Icons.trending_up, size: 20),
                    text: 'Estilistas',
                  ),
                 /* Tab(
                    icon: Icon(Icons.store, size: 20),
                    text: 'Local',
                  ),*/
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GeneralReportTab(token: widget.token),
          DateRangeReportTab(token: widget.token),
          StylistIncomeReportTab(token: widget.token),
          //StoreIncomeReportTab(token: widget.token),
        ],
      ),
    );
  }
}
