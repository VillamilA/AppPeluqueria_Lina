import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';
import '../../api/slots_api.dart';
import '../../api/api_client.dart';
import '../stylist/stylist_home_tab.dart';
import '../stylist/stylist_bookings_tab.dart';
import '../stylist/stylist_catalogs_tab.dart';
import '../stylist/stylist_profile_tab.dart';

class StylistDashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const StylistDashboardPage({super.key, required this.user});

  @override
  State<StylistDashboardPage> createState() => _StylistDashboardPageState();
}

class _StylistDashboardPageState extends State<StylistDashboardPage> {
  int _currentIndex = 0;
  late String _token;
  late String _stylistId;
  late String _stylistName;
  late String _stylistLastName;
  late String _stylistEmail;
  late String _stylistPhone;
  late SlotsApi _slotsApi;

  @override
  void initState() {
    super.initState();
    _token = widget.user['accessToken'] ?? widget.user['token'] ?? '';
    _stylistId = widget.user['id'] ?? '';
    _stylistName = widget.user['nombre'] ?? 'Estilista';
    _stylistLastName = widget.user['apellido'] ?? '';
    _stylistEmail = widget.user['email'] ?? '';
    _stylistPhone = widget.user['telefono'] ?? '';
    _slotsApi = SlotsApi(ApiClient.instance);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    final tabs = [
      _buildHomeTab(),
      _buildBookingsTab(),
      _buildCatalogsTab(),
      _buildProfileTab(),
    ];
    
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(child: tabs[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gold,
              AppColors.gold.withOpacity(0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black.withOpacity(0.5),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 12 : 10,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isTablet ? 11 : 9,
            ),
            selectedIconTheme: IconThemeData(
              size: isTablet ? 26 : 22,
            ),
            unselectedIconTheme: IconThemeData(
              size: isTablet ? 24 : 20,
            ),
            onTap: (i) => setState(() => _currentIndex = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded),
                label: 'Citas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.content_cut_rounded),
                label: 'Servicios',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return StylistHomeTab(
      token: _token,
      stylistName: _stylistName,
      stylistLastName: _stylistLastName,
      onViewAllBookings: () {
        setState(() => _currentIndex = 1);
      },
    );
  }

  Widget _buildBookingsTab() {
    return StylistBookingsTab(token: _token);
  }

  Widget _buildCatalogsTab() {
    return StylistCatalogsTab(
      stylistId: _stylistId,
      token: _token,
    );
  }

  Widget _buildProfileTab() {
    return StylistProfileTab(
      stylistName: _stylistName,
      stylistLastName: _stylistLastName,
      stylistEmail: _stylistEmail,
      stylistPhone: _stylistPhone,
      stylistId: _stylistId,
      token: _token,
      slotsApi: _slotsApi,
    );
  }
}
