import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';
import '../reports/reports_dashboard_page.dart';
import '../profile/pages/profile_page.dart';
import '../admin/payments_management_page.dart';
import '../admin/manage_users_page.dart';
import '../../data/services/token_storage.dart';

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
      _buildAdminTab(context, widget.user, isMobile),
      _buildProfileTab(isMobile),
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
              icon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Administrar',
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
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
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
            // Header Section
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 20,
                isMobile ? 16 : 24,
                isMobile ? 12 : 16,
              ),
              child: _buildWelcomeHeader(),
            ),
            
            // Divider
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Divider(
                color: AppColors.gold.withOpacity(0.2),
                thickness: 1,
                height: isMobile ? 12 : 16,
              ),
            ),
            
            // Grid de módulos (scrollable)
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: _buildHomeCardsGrid(isMobile, isLandscape),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final isSmallPhone = MediaQuery.of(context).size.height < 700;
    
    return Container(
      padding: EdgeInsets.all(isSmallPhone ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withOpacity(0.15),
            AppColors.gold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar con ícono
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.gold, AppColors.gold.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.black,
              size: 26,
            ),
          ),
          SizedBox(width: 16),
          
          // Texto de bienvenida
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${widget.user['nombre'] ?? 'Administrador'}',
                  style: TextStyle(
                    color: AppColors.gray.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeCardsGrid(bool isMobile, bool isLandscape) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determinar número de columnas basado en tamaño de pantalla
    int crossAxisCount = 2;
    if (screenWidth > 900) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    }
    
    final cards = [
      _HomeCardModel(
        icon: Icons.admin_panel_settings_rounded,
        title: 'Administrar',
        subtitle: 'Gestiona tu peluquería',
        onTap: () => setState(() => _currentIndex = 1),
        color: AppColors.gold,
      ),
      _HomeCardModel(
        icon: Icons.payment_rounded,
        title: 'Pagos',
        subtitle: 'Gestiona transacciones',
        onTap: () {
          final token = widget.user['accessToken'] ?? widget.user['token'] ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentsManagementPage(
                token: token,
              ),
            ),
          );
        },
        color: AppColors.gold,
      ),
      _HomeCardModel(
        icon: Icons.assessment_rounded,
        title: 'Reportes',
        subtitle: 'Ver análisis y datos',
        onTap: () {
          final token = widget.user['accessToken'] ?? widget.user['token'] ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportsDashboardPage(
                token: token,
                userRole: 'ADMIN',
              ),
            ),
          );
        },
        color: AppColors.gold,
      ),
      _HomeCardModel(
        icon: Icons.account_circle_rounded,
        title: 'Mi Perfil',
        subtitle: 'Editar información',
        onTap: () => setState(() => _currentIndex = 2),
        color: AppColors.gold,
      ),
    ];

    return GridView.builder(
      physics: BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _buildGridCard(cards[index], isMobile);
      },
    );
  }

  Widget _buildGridCard(_HomeCardModel card, bool isMobile) {
    return GestureDetector(
      onTap: card.onTap,
      child: Container(
        decoration: BoxDecoration(
          // Fondo con gradiente
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              card.color.withOpacity(0.25),
              card.color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          
          // Borde dorado
          border: Border.all(
            color: card.color.withOpacity(0.6),
            width: 2,
          ),
          
          // Sombra profesional
          boxShadow: [
            BoxShadow(
              color: card.color.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Patrón decorativo - Círculo superior derecho
              Positioned(
                top: -25,
                right: -25,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.color.withOpacity(0.12),
                  ),
                ),
              ),
              
              // Patrón decorativo - Círculo inferior izquierdo
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.color.withOpacity(0.08),
                  ),
                ),
              ),
              
              // Contenido principal
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Contenedor del ícono con efecto radial
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            card.color.withOpacity(0.4),
                            card.color.withOpacity(0.15),
                          ],
                          radius: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: card.color.withOpacity(0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        card.icon,
                        color: card.color,
                        size: 36,
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Título
                    Text(
                      card.title,
                      style: TextStyle(
                        color: card.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Subtítulo
                    Flexible(
                      child: Text(
                        card.subtitle,
                        style: TextStyle(
                          color: AppColors.gray.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
        icon: Icons.person_rounded,
        title: 'Clientes',
        subtitle: 'Gestiona clientes',
        route: '/admin/clients',
        color: AppColors.gold,
      ),
      _AdminGridCard(
        icon: Icons.manage_accounts_rounded,
        title: 'Gerentes',
        subtitle: 'Gestiona gerentes',
        route: '/admin/managers',
        color: Color(0xFFD4AF37), // Oro oscuro
      ),
      _AdminGridCard(
        icon: Icons.group_rounded,
        title: 'Activación de Usuarios',
        subtitle: 'Habilita / Deshabilita los usuarios',
        route: '/admin/manage-users',
        color: AppColors.gold,
      ),
      _AdminGridCard(
        icon: Icons.design_services_rounded,
        title: 'Servicios',
        subtitle: 'Gestiona servicios',
        route: '/admin/services',
        color: Color(0xFFB8860B), // Dorado oscuro
      ),
      _AdminGridCard(
        icon: Icons.content_cut_rounded,
        title: 'Estilistas',
        subtitle: 'Gestiona estilistas',
        route: '/admin/stylists',
        color: Color(0xFFDAA520), // Goldenrod
      ),
      _AdminGridCard(
        icon: Icons.calendar_month_rounded,
        title: 'Reservas',
        subtitle: 'Gestiona reservas',
        route: '/admin/bookings',
        color: Color(0xFFFFD700), // Dorado brillante
      ),
      _AdminGridCard(
        icon: Icons.payments_rounded,
        title: 'Pagos',
        subtitle: 'Confirmar transferencias',
        route: '/admin/payments',
        color: Color(0xFF66BB6A), // Verde
      ),
      _AdminGridCard(
        icon: Icons.star_rounded,
        title: 'Calificaciones',
        subtitle: 'Gestionar calificaciones',
        route: '/admin/ratings',
        color: Colors.amber,
      ),
      _AdminGridCard(
        icon: Icons.schedule_rounded,
        title: 'Horario del Negocio',
        subtitle: 'Gestiona el horario general',
        route: '/admin/business-hours',
        color: Color(0xFFCD7F32), // Bronce
      ),
      _AdminGridCard(
        icon: Icons.category_rounded,
        title: 'Catálogos',
        subtitle: 'Gestiona catálogos de servicios',
        route: '/admin/catalogs',
        color: Color(0xFFC0C0C0), // Plateado
      ),
      _AdminGridCard(
        icon: Icons.assessment_rounded,
        title: 'Reportes',
        subtitle: 'Ver análisis y datos',
        route: '/admin/reports',
        color: Color(0xFFB87333), // Cobre
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32, vertical: 16),
            child: Column(
              children: [
                // Header simple y elegante SIN CAJA
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gold, AppColors.gold.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Módulos de Administración',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gestiona todos los aspectos del negocio',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Grid de módulos
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final crossAxisCount = screenWidth > 600 ? 3 : 2;
                    final spacing = 16.0;
                    final totalSpacing = spacing * (crossAxisCount - 1);
                    final availableWidth = screenWidth - totalSpacing;
                    final cardWidth = availableWidth / crossAxisCount;
                    final childAspectRatio = cardWidth / (cardWidth * 1.2);
                    
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: childAspectRatio,
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
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
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
    return GestureDetector(
      onTap: () {
        if (card.route == '/admin/reports') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportsDashboardPage(
                token: token,
                userRole: 'ADMIN',
              ),
            ),
          );
        } else if (card.route == '/admin/manage-users') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageUsersPage(
                token: token,
                userRole: 'ADMIN',
              ),
            ),
          );
        } else if (card.route == '/admin/business-hours' || card.route == '/admin/ratings') {
          Navigator.pushNamed(
            context,
            card.route,
            arguments: {'token': token, 'userRole': 'ADMIN'},
          );
        } else {
          Navigator.pushNamed(context, card.route, arguments: token);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              card.color.withOpacity(0.3),
              card.color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: card.color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: card.color.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Patrón decorativo
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.color.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.color.withOpacity(0.08),
                  ),
                ),
              ),
              // Contenido
              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ícono
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              card.color.withOpacity(0.4),
                              card.color.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: card.color.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          card.icon,
                          color: card.color,
                          size: 32,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    // Título
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        card.title,
                        style: TextStyle(
                          color: card.color,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Subtítulo
                    Flexible(
                      child: Text(
                        card.subtitle,
                        style: TextStyle(
                          color: AppColors.gray.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(bool isMobile) {
    if (_token.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    return ProfilePage(
      token: _token,
      user: widget.user,
      userRole: 'admin',
    );
  }
}
