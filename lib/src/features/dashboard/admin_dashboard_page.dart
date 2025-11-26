import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminDashboardPage({super.key, required this.user});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      _buildUsersTab(),
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Center(child: Text('Bienvenido, ${widget.user['nombre'] ?? ''}', style: TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold)));
  }

  Widget _buildUsersTab() {
    return Center(child: Text('Usuarios', style: TextStyle(color: AppColors.gold)));
  }

  Widget _buildProfileTab() {
    return Center(child: Text('Perfil', style: TextStyle(color: AppColors.gold)));
  }
}
