import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';
import '../reports/reports_dashboard_page.dart';
import '../profile/pages/profile_page.dart';
import '../../data/services/token_storage.dart';

class _ManagerCard {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;
  final bool enabled;

  _ManagerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
    required this.enabled,
  });
}

class ManagerDashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ManagerDashboardPage({super.key, required this.user});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  int _currentIndex = 0;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await TokenStorage.instance.getAccessToken();
    if (mounted) {
      setState(() => _token = token ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final tabs = [
      _buildHomeTab(isMobile),
      _buildManageTab(isMobile),
      _buildReportsTab(),
      _buildProfileTab(),
    ];
    
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.gold.withOpacity(0.2), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.gray,
          backgroundColor: AppColors.charcoal,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          iconSize: 24,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_center_rounded),
              label: 'Gestionar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_rounded),
              label: 'Reportes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.charcoal,
            Colors.black87,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32, vertical: 16),
            child: Column(
              children: [
                // Header elegante
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B7355).withOpacity(0.2), // Marrón cálido
                        const Color(0xFF8B7355).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF8B7355).withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      // Icono de gerente
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B7355).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.business_center_rounded,
                          color: const Color(0xFF8B7355),
                          size: isMobile ? 36 : 42,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '¡Bienvenido, Gerente!',
                        style: TextStyle(
                          color: const Color(0xFF8B7355),
                          fontSize: isMobile ? 22 : 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.user['nombre'] ?? 'Gerente',
                        style: TextStyle(
                          color: AppColors.gray,
                          fontSize: isMobile ? 15 : 17,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B7355).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Administrador Delegado',
                          style: TextStyle(
                            color: const Color(0xFF8B7355),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Accesos rápidos
                Text(
                  'Accesos Rápidos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildQuickAccessCards(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCards(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.3 : 1.5,
      children: [
        _buildQuickCard(
          icon: Icons.assessment_rounded,
          title: 'Reportes',
          color: Colors.green,
          onTap: () => setState(() => _currentIndex = 2),
        ),
        _buildQuickCard(
          icon: Icons.business_center_rounded,
          title: 'Gestionar',
          color: const Color(0xFF8B7355),
          onTap: () => setState(() => _currentIndex = 1),
        ),
        _buildQuickCard(
          icon: Icons.calendar_today_rounded,
          title: 'Reservas',
          color: AppColors.gold,
          onTap: () {
            final token = _token.isNotEmpty ? _token : (widget.user['accessToken'] ?? widget.user['token'] ?? '');
            Navigator.pushNamed(context, '/admin/bookings', arguments: token);
          },
        ),
        _buildQuickCard(
          icon: Icons.payments_rounded,
          title: 'Pagos',
          color: const Color(0xFF66BB6A),
          onTap: () {
            final token = _token.isNotEmpty ? _token : (widget.user['accessToken'] ?? widget.user['token'] ?? '');
            Navigator.pushNamed(context, '/admin/payments', arguments: token);
          },
        ),
        _buildQuickCard(
          icon: Icons.schedule_rounded,
          title: 'Horarios',
          color: Colors.blue,
          onTap: () {
            final token = _token.isNotEmpty ? _token : (widget.user['accessToken'] ?? widget.user['token'] ?? '');
            Navigator.pushNamed(context, '/admin/schedule-options', arguments: token);
          },
        ),
        _buildQuickCard(
          icon: Icons.person_rounded,
          title: 'Perfil',
          color: Colors.blueAccent,
          onTap: () => setState(() => _currentIndex = 3),
        ),
      ],
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageTab(bool isMobile) {
    final token = _token.isNotEmpty ? _token : (widget.user['accessToken'] ?? widget.user['token'] ?? '');
    
    final cards = [
      _ManagerCard(
        icon: Icons.supervisor_account_rounded,
        title: 'Usuarios',
        subtitle: 'Gestionar usuarios',
        route: '/admin/users',
        color: Colors.blue,
        enabled: true,
      ),
      _ManagerCard(
        icon: Icons.content_cut_rounded,
        title: 'Estilistas',
        subtitle: 'Gestionar estilistas',
        route: '/admin/stylists',
        color: Colors.purple,
        enabled: true,
      ),
      _ManagerCard(
        icon: Icons.spa_rounded,
        title: 'Servicios',
        subtitle: 'Administrar servicios',
        route: '/admin/services',
        color: Colors.pink,
        enabled: true,
      ),
      _ManagerCard(
        icon: Icons.calendar_today_rounded,
        title: 'Reservas',
        subtitle: 'Gestionar reservas',
        route: '/admin/bookings',
        color: AppColors.gold,
        enabled: true,
      ),
      _ManagerCard(
        icon: Icons.schedule_rounded,
        title: 'Horarios',
        subtitle: 'Configurar horarios',
        route: '/admin/schedule-options',
        color: Colors.indigo,
        enabled: true,
      ),
      _ManagerCard(
        icon: Icons.payments_rounded,
        title: 'Pagos',
        subtitle: 'Confirmar transferencias',
        route: '/admin/payments',
        color: const Color(0xFF66BB6A),
        enabled: true,
      ),
      _ManagerCard(
        icon: Icons.category_rounded,
        title: 'Catálogo',
        subtitle: 'Gestionar catálogo',
        route: '/admin/catalog',
        color: Colors.orange,
        enabled: true,
      ),
      _ManagerCard(
        icon: Icons.star_rounded,
        title: 'Calificaciones',
        subtitle: 'Ver calificaciones',
        route: '/admin/ratings',
        color: Colors.amber,
        enabled: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.charcoal,
            Colors.black87,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                border: Border(
                  bottom: BorderSide(color: AppColors.gold.withOpacity(0.2), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7355).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      color: const Color(0xFF8B7355),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panel de Gestión',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Administra tu peluquería',
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Grid de opciones
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isMobile ? 1.0 : 1.2,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return _buildManagerCard(card, token);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerCard(_ManagerCard card, String token) {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: card.enabled ? () {
          // Para ratings, pasar token y userRole
          if (card.route == '/admin/ratings') {
            final userRole = widget.user['role'] ?? 'ADMIN';
            Navigator.pushNamed(context, card.route, arguments: {
              'token': token,
              'userRole': userRole,
            });
          } else {
            Navigator.pushNamed(context, card.route, arguments: token);
          }
        } : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: card.enabled ? 1.0 : 0.5,
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: card.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        card.icon,
                        color: card.color,
                        size: 32,
                      ),
                    ),
                    if (!card.enabled)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.lock, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  card.title,
                  style: TextStyle(
                    color: card.color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  card.subtitle,
                  style: TextStyle(
                    color: AppColors.gray,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!card.enabled) ...[
                  SizedBox(height: 8),
                  Text(
                    'Próximamente',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    final token = _token.isNotEmpty ? _token : (widget.user['accessToken'] ?? widget.user['token'] ?? '');
    return ReportsDashboardPage(
      token: token,
      userRole: 'GERENTE',
    );
  }

  Widget _buildProfileTab() {
    if (_token.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    return ProfilePage(
      token: _token,
      user: widget.user,
      userRole: 'gerente',
    );
  }
}
