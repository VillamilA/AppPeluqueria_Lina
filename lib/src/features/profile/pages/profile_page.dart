import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/token_storage.dart';
import '../../../services/session_manager.dart';
import '../../../providers/user_provider.dart';
import '../pages/edit_profile_page.dart';
import '../pages/change_password_page.dart';
import '../pages/booking_history_page.dart';
import '../pages/payment_history_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? user;
  final String? userRole;

  const ProfilePage({
    super.key,
    required this.token,
    this.user,
    this.userRole,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // ✅ Cargar perfil del Provider
    final userProvider = context.read<UserProvider>();
    userProvider.loadMyProfile(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    final userRole = widget.userRole ?? 'client';
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : (isTablet ? 32 : 20),
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 700),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(context),
                      SizedBox(height: isTablet ? 32 : 24),
                      
                      // Layout responsive
                      if (isDesktop)
                        _buildDesktopLayout(userRole)
                      else if (isTablet)
                        _buildTabletLayout(userRole)
                      else
                        _buildMobileLayout(userRole),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Mi Perfil',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(String userRole) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: Profile Card
        Expanded(
          flex: 2,
          child: _buildProfileCard(userRole),
        ),
        SizedBox(width: 32),
        // Columna derecha: Options
        Expanded(
          flex: 3,
          child: _buildOptionsSection(userRole, isCompact: false),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(String userRole) {
    return Column(
      children: [
        _buildProfileCard(userRole),
        SizedBox(height: 32),
        _buildOptionsSection(userRole, isCompact: false),
      ],
    );
  }

  Widget _buildMobileLayout(String userRole) {
    return Column(
      children: [
        _buildProfileCard(userRole),
        SizedBox(height: 24),
        _buildOptionsSection(userRole, isCompact: true),
      ],
    );
  }

  /// ✅ Usa Consumer para mostrar datos actualizados del Provider
  Widget _buildProfileCard(String userRole) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        final user = userProvider.currentUser;
        if (user == null) {
          return Center(
            child: Text(
              'No hay datos de perfil',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final nombre = user.nombre;
        final apellido = user.apellido;
        final email = user.email;
        final telefono = user.telefono ?? 'No disponible';
        
        final roleColor = _getRoleColor(userRole);
        final roleLabel = _getRoleLabel(userRole);
        final roleIcon = _getRoleIcon(userRole);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade900,
                AppColors.charcoal,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de rol
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: roleColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, color: roleColor, size: 16),
                    SizedBox(width: 6),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Nombre y Apellido
              Text(
                '$nombre $apellido',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              // Email
              Text(
                email,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20),

              // Divider
              Container(
                height: 1,
                color: Colors.grey.shade700,
              ),
              SizedBox(height: 20),

              // Detalles
              _buildProfileDetail(Icons.phone, 'Teléfono', telefono),
              SizedBox(height: 12),
              _buildProfileDetail(
                Icons.wc,
                'Género',
                _getGeneroLabel(user.genero),
              ),
              SizedBox(height: 20),

              // Botón Editar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('EDITAR PERFIL'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          token: widget.token,
                          user: user.toJson(),
                          userRole: userRole,
                        ),
                      ),
                    ).then((_) {
                      // ✅ Recargar perfil después de editar
                      print('🔄 Recargando perfil después de editar...');
                      userProvider.loadMyProfile(widget.token);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.charcoal,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getGeneroLabel(String? genero) {
    switch (genero) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Femenino';
      case 'O':
        return 'Otro';
      default:
        return 'No especificado';
    }
  }





  Widget _buildOptionsSection(String userRole, {required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Configuración & Historial',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Options grid
        if (isCompact)
_buildCompactOptions(userRole)
      else
        _buildExpandedOptions(userRole),

        SizedBox(height: 32),

        // Logout button
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildCompactOptions(String userRole) {
    return Column(
      children: [
        _buildOptionCard(
          icon: Icons.lock_outline,
          title: 'Cambiar Contraseña',
          subtitle: 'Actualiza tu contraseña de acceso',
          color: AppColors.gold,
          onTap: () => _navigateToChangePassword(),
        ),
        SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.event_note,
          title: 'Mis Citas',
          subtitle: 'Historial de reservaciones',
          color: AppColors.gold,
          onTap: () => _navigateToBookingHistory(),
        ),
        SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.payment,
          title: 'Historial de Pagos',
          subtitle: 'Transacciones realizadas',
          color: AppColors.gold,
          onTap: () => _navigateToPaymentHistory(),
        ),
      ],
    );
  }

  Widget _buildExpandedOptions(String userRole) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 200,
          child: _buildOptionCard(
            icon: Icons.lock_outline,
            title: 'Contraseña',
            subtitle: 'Seguridad',
            color: AppColors.gold,
            onTap: () => _navigateToChangePassword(),
            isGridItem: true,
          ),
        ),
        SizedBox(
          width: 200,
          child: _buildOptionCard(
            icon: Icons.event_note,
            title: 'Mis Citas',
            subtitle: 'Historial',
            color: AppColors.gold,
            onTap: () => _navigateToBookingHistory(),
            isGridItem: true,
          ),
        ),
        SizedBox(
          width: 200,
          child: _buildOptionCard(
            icon: Icons.payment,
            title: 'Pagos',
            subtitle: 'Transacciones',
            color: AppColors.gold,
            onTap: () => _navigateToPaymentHistory(),
            isGridItem: true,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isGridItem = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isGridItem ? 20 : 16),
            child: isGridItem
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppColors.gray, fontSize: 12),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(color: AppColors.gray, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: color, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFE63946)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF6B6B).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout, color: Colors.red, size: 24),
            ),
            SizedBox(width: 12),
            Text('¿Cerrar Sesión?', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          'Tendrás que volver a iniciar sesión para acceder a tu cuenta.',
          style: TextStyle(color: AppColors.gray, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              SessionManager().stopSession();
              await TokenStorage.instance.clearTokens();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordPage(token: widget.token),
      ),
    );
  }

  void _navigateToBookingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingHistoryPage(
          token: widget.token,
          userRole: widget.userRole ?? 'client',
        ),
      ),
    );
  }

  void _navigateToPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentHistoryPage(token: widget.token),
      ),
    );
  }

  // Helper methods
  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Color(0xFFFF6B6B);
      case 'gerente':
      case 'manager':
        return Color(0xFF4ECDC4);
      case 'stylist':
        return Color(0xFFFFD93D);
      default:
        return AppColors.gold;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'gerente':
      case 'manager':
        return 'Gerente';
      case 'stylist':
        return 'Estilista';
      default:
        return 'Cliente';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'gerente':
      case 'manager':
        return Icons.business;
      case 'stylist':
        return Icons.cut;
      default:
        return Icons.person;
    }
  }

}
