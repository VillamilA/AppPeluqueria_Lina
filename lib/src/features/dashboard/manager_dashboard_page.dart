import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';

class ManagerDashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ManagerDashboardPage({super.key, required this.user});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      _buildBookingsTab(),
      _buildServicesTab(),
      _buildProfileTab(),
    ];
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.gray,
        backgroundColor: AppColors.charcoal,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.content_cut), label: 'Servicios'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Center(child: Text('Bienvenido, ${widget.user['nombre'] ?? ''}', style: TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold)));
  }

  Widget _buildBookingsTab() {
    return Center(child: Text('Citas', style: TextStyle(color: AppColors.gold)));
  }

  Widget _buildServicesTab() {
    return Center(child: Text('Servicios', style: TextStyle(color: AppColors.gold)));
  }

  Widget _buildProfileTab() {
    return Center(child: Text('Perfil', style: TextStyle(color: AppColors.gold)));
  }
}
