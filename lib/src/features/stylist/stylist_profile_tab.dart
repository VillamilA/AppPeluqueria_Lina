import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../api/slots_api.dart';
import '../../data/services/token_storage.dart';
import '../../services/session_manager.dart';
import '../slots/schedule_hub_page.dart';
import '../profile/pages/change_password_page.dart';

class StylistProfileTab extends StatelessWidget {
  final String stylistName;
  final String stylistLastName;
  final String stylistEmail;
  final String stylistPhone;
  final String? profileImage;
  final String? stylistId;
  final String? token;
  final SlotsApi? slotsApi;

  const StylistProfileTab({
    super.key,
    required this.stylistName,
    required this.stylistLastName,
    required this.stylistEmail,
    required this.stylistPhone,
    this.profileImage,
    this.stylistId,
    this.token,
    this.slotsApi,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

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
              if (isDesktop)
                _buildDesktopLayout(context)
              else if (isTablet)
                _buildTabletLayout(context)
              else
                _buildMobileLayout(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildProfileCard(),
        ),
        SizedBox(width: 32),
        Expanded(
          flex: 3,
          child: _buildOptionsSection(context, isCompact: false),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildProfileCard(),
        SizedBox(height: 32),
        _buildOptionsSection(context, isCompact: false),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildProfileCard(),
        SizedBox(height: 24),
        _buildOptionsSection(context, isCompact: true),
      ],
    );
  }

  Widget _buildProfileCard() {
    final Color roleColor = AppColors.gold; // Color dorado del negocio

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade900, AppColors.charcoal],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: roleColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con rol
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              gradient: LinearGradient(
                colors: [roleColor.withOpacity(0.2), roleColor.withOpacity(0.05)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.cut, color: roleColor, size: 22),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Estilista Profesional',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Activo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Avatar y nombre
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [roleColor, roleColor.withOpacity(0.6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${stylistName.isNotEmpty ? stylistName[0] : ''}${stylistLastName.isNotEmpty ? stylistLastName[0] : ''}',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Nombre
                Text(
                  '$stylistName $stylistLastName',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),

                // Email
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, color: AppColors.gray, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        stylistEmail,
                        style: TextStyle(color: AppColors.gray, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info grid
          Container(
            margin: EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: roleColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.phone_outlined, color: roleColor, size: 20),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Teléfono', style: TextStyle(color: AppColors.gray, fontSize: 12)),
                      SizedBox(height: 2),
                      Text(
                        stylistPhone,
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(BuildContext context, {required bool isCompact}) {
    final Color roleColor = Color(0xFFFFD93D);

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
                  color: roleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Configuración',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Options
        if (isCompact)
          _buildCompactOptions(context)
        else
          _buildExpandedOptions(context),

        SizedBox(height: 32),

        // Logout button
        _buildLogoutButton(context),
      ],
    );
  }

  Widget _buildCompactOptions(BuildContext context) {
    return Column(
      children: [
        _buildOptionCard(
          icon: Icons.schedule,
          title: 'Gestionar Horarios',
          subtitle: 'Configura tu disponibilidad y servicios',
          color: AppColors.gold.withOpacity(0.8),
          onTap: () => _showCreateSlotDialog(context),
        ),
        SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.edit_square,
          title: 'Editar Perfil',
          subtitle: 'Actualiza tu información',
          color: Colors.grey.shade600,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Próximamente'), backgroundColor: Colors.blue),
          ),
        ),
        SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.lock_outline,
          title: 'Cambiar Contraseña',
          subtitle: 'Actualiza tu contraseña de acceso',
          color: AppColors.gold,
          onTap: () => _navigateToChangePassword(context),
        ),
      ],
    );
  }

  Widget _buildExpandedOptions(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 200,
          child: _buildOptionCard(
            icon: Icons.schedule,
            title: 'Horarios',
            subtitle: 'Disponibilidad',
            color: AppColors.gold.withOpacity(0.8),
            onTap: () => _showCreateSlotDialog(context),
            isGridItem: true,
          ),
        ),
        SizedBox(
          width: 200,
          child: _buildOptionCard(
            icon: Icons.edit_square,
            title: 'Editar Perfil',
            subtitle: 'Tus datos',
            color: Colors.grey.shade600,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Próximamente'), backgroundColor: Colors.blue),
            ),
            isGridItem: true,
          ),
        ),
        SizedBox(
          width: 200,
          child: _buildOptionCard(
            icon: Icons.lock_outline,
            title: 'Contraseña',
            subtitle: 'Seguridad',
            color: AppColors.gold,
            onTap: () => _navigateToChangePassword(context),
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
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
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

  Widget _buildLogoutButton(BuildContext context) {
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
          onTap: () => _showLogoutDialog(context),
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

  void _showLogoutDialog(BuildContext context) {
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
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateSlotDialog(BuildContext context) {
    print('🟦 StylistProfileTab._showCreateSlotDialog called');
    print('  - token exists: ${token != null}');
    print('  - slotsApi exists: ${slotsApi != null}');
    print('  - stylistId: $stylistId');
    
    if (token == null || stylistId == null) {
      print('❌ ERROR: Datos insuficientes');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Datos insuficientes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ Navegando a ScheduleHubPage');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleHubPage(
          token: token!,
          stylistId: stylistId!,
          stylistName: '$stylistName $stylistLastName',
          userRole: 'ESTILISTA',
        ),
      ),
    );
  }

  void _navigateToChangePassword(BuildContext context) {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Token no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordPage(token: token!),
      ),
    );
  }
}