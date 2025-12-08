import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';

class _HomeCardModel {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  _HomeCardModel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });
}

class _AdminGridCard {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  _AdminGridCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}

class AdminDashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminDashboardPage({super.key, required this.user});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 1; // Mostrar el tab de usuarios por defecto

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final tabs = [
      _buildHomeTab(isMobile),
      _buildAdminTab(context, widget.user, isMobile),
      _buildProfileTab(isMobile),
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
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Administrar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(bool isMobile) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            SizedBox(height: isMobile ? 24 : 32),
            Icon(Icons.verified_user, color: AppColors.gold, size: isMobile ? 48 : 64),
            SizedBox(height: 20),
            Text(
              '¡Bienvenido!',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '${widget.user['nombre'] ?? 'Administrador'}',
              style: TextStyle(
                color: AppColors.gray,
                fontSize: isMobile ? 16 : 18,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            _buildHomeCardsGrid(isMobile),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCardsGrid(bool isMobile) {
    final cards = [
      _HomeCardModel(
        icon: Icons.admin_panel_settings,
        title: 'Administrar',
        subtitle: 'Gestiona tu peluquería',
        onTap: () => setState(() => _currentIndex = 1),
        color: AppColors.gold,
      ),
      _HomeCardModel(
        icon: Icons.bar_chart,
        title: 'Estadísticas',
        subtitle: 'Ver rendimiento',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estadísticas - Próximamente', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange,
          ),
        ),
        color: Colors.orange,
      ),
      _HomeCardModel(
        icon: Icons.account_circle,
        title: 'Mi Perfil',
        subtitle: 'Editar información',
        onTap: () => setState(() => _currentIndex = 2),
        color: Colors.blueAccent,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 0.85 : 0.95,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _buildGridCard(cards[index], isMobile);
      },
    );
  }

  Widget _buildGridCard(_HomeCardModel card, bool isMobile) {
    return Card(
      color: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: card.onTap,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 18),
                decoration: BoxDecoration(
                  color: card.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  card.icon,
                  color: card.color,
                  size: isMobile ? 36 : 40,
                ),
              ),
              SizedBox(height: 12),
              Text(
                card.title,
                style: TextStyle(
                  color: card.color,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 15 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                card.subtitle,
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: isMobile ? 12 : 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTab(BuildContext context, Map<String, dynamic> user, bool isMobile) {
    final token = user['accessToken'] ?? user['token'] ?? '';
    print('🔐 AdminDashboardPage Token: $token');
    print('🔐 User data: $user');
    final adminCards = [
      _AdminGridCard(
        icon: Icons.person,
        title: 'Clientes',
        subtitle: 'Gestiona clientes',
        route: '/admin/clients',
        color: Colors.blueAccent,
      ),
      _AdminGridCard(
        icon: Icons.manage_accounts,
        title: 'Gerentes',
        subtitle: 'Gestiona gerentes',
        route: '/admin/managers',
        color: Colors.purpleAccent,
      ),
      _AdminGridCard(
        icon: Icons.design_services,
        title: 'Servicios',
        subtitle: 'Gestiona servicios',
        route: '/admin/services',
        color: Colors.greenAccent,
      ),
      _AdminGridCard(
        icon: Icons.cut,
        title: 'Estilistas',
        subtitle: 'Gestiona estilistas',
        route: '/admin/stylists',
        color: Colors.pinkAccent,
      ),
      _AdminGridCard(
        icon: Icons.calendar_month,
        title: 'Reservas',
        subtitle: 'Gestiona reservas',
        route: '/admin/bookings',
        color: AppColors.gold,
      ),
      _AdminGridCard(
        icon: Icons.schedule,
        title: 'Horarios',
        subtitle: 'Gestiona horarios de estilistas',
        route: '/admin/slots',
        color: Colors.orangeAccent,
      ),
      _AdminGridCard(
        icon: Icons.category,
        title: 'Catálogos',
        subtitle: 'Gestiona catálogos de servicios',
        route: '/admin/catalogs',
        color: Colors.tealAccent,
      ),
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            Text(
              'Módulos de Administración',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isMobile ? 0.85 : 0.95,
              ),
              itemCount: adminCards.length,
              itemBuilder: (context, index) {
                final card = adminCards[index];
                return _buildAdminGridCard(
                  context,
                  card: card,
                  token: token,
                  isMobile: isMobile,
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminGridCard(
    BuildContext context, {
    required _AdminGridCard card,
    required String token,
    required bool isMobile,
  }) {
    return Card(
      color: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, card.route, arguments: token),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 18),
                decoration: BoxDecoration(
                  color: card.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  card.icon,
                  color: card.color,
                  size: isMobile ? 36 : 40,
                ),
              ),
              SizedBox(height: 12),
              Text(
                card.title,
                style: TextStyle(
                  color: card.color,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 15 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                card.subtitle,
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: isMobile ? 12 : 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, color: AppColors.gold, size: isMobile ? 48 : 64),
            SizedBox(height: 24),
            Text(
              'Perfil de administrador',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Aquí puedes editar tu información personal.',
              style: TextStyle(
                color: AppColors.gray,
                fontSize: isMobile ? 14 : 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
