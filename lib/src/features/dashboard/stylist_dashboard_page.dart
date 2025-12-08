import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';
import '../../api/slots_api.dart';
import '../../api/api_client.dart';
import '../stylist/stylist_home_tab.dart';
import '../stylist/stylist_bookings_tab.dart';
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
    final tabs = [
      _buildHomeTab(),
      _buildBookingsTab(),
      _buildProfileTab(),
    ];
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(child: tabs[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.gray,
        backgroundColor: AppColors.charcoal,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
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
