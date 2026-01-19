import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../api/slots_api.dart';
import '../../api/api_client.dart';
import '../../data/services/token_storage.dart';
import '../../services/session_manager.dart';
import '../slots/schedule_hub_page.dart';
import '../profile/pages/change_password_page.dart';
import 'widgets/edit_stylist_profile_section.dart';

class StylistProfileTab extends StatefulWidget {
  final String stylistName;
  final String stylistLastName;
  final String stylistEmail;
  final String stylistPhone;
  final String? profileImage;
  final String? stylistId;
  final String? token;
  final SlotsApi? slotsApi;
  final Map<String, dynamic>? stylistData; // Datos completos del estilista

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
    this.stylistData,
  });

  @override
  State<StylistProfileTab> createState() => _StylistProfileTabState();
}

class _StylistProfileTabState extends State<StylistProfileTab> {
  late String stylistName;
  late String stylistLastName;
  late String stylistEmail;
  late String stylistPhone;
  late String? stylistId;
  late String? token;
  late SlotsApi? slotsApi;
  late Map<String, dynamic>? stylistData;

  @override
  void initState() {
    super.initState();
    // Copiar datos iniciales
    stylistName = widget.stylistName;
    stylistLastName = widget.stylistLastName;
    stylistEmail = widget.stylistEmail;
    stylistPhone = widget.stylistPhone;
    stylistId = widget.stylistId;
    token = widget.token;
    slotsApi = widget.slotsApi;
    stylistData = widget.stylistData;
  }

  Future<void> _reloadProfileFromAPI() async {
    if (token == null || token!.isEmpty) {
      print('❌ No token available para recargar perfil');
      return;
    }

    try {
      print('🔄 Recargando perfil desde API...');
      
      final response = await ApiClient.instance.get(
        '/api/v1/users/me',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final user = json['data'] ?? json;
        
        setState(() {
          stylistName = user['nombre'] ?? stylistName;
          stylistLastName = user['apellido'] ?? stylistLastName;
          stylistEmail = user['email'] ?? stylistEmail;
          stylistPhone = user['telefono'] ?? stylistPhone;
          stylistData = {...?stylistData, ...user};
          
          print('✅ Perfil recargado correctamente');
          print('  - Nombre: $stylistName');
          print('  - Apellido: $stylistLastName');
          print('  - Teléfono: $stylistPhone');
        });
      } else {
        print('❌ Error recargando perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al recargar perfil: $e');
    }
  }

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
    final Color roleColor = AppColors.gold; // Color dorado

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.charcoal,
            AppColors.charcoal.withOpacity(0.8),
          ],
        ),
        border: Border.all(
          color: roleColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado con rol y icono
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [
                  roleColor.withOpacity(0.2),
                  roleColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.cut,
                        color: roleColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Estilista',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Perfil Verificado',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar y nombre
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 16, left: 20, right: 20),
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
                      colors: [
                        roleColor,
                        roleColor.withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${stylistName.isNotEmpty ? stylistName[0] : ''}${stylistLastName.isNotEmpty ? stylistLastName[0] : ''}',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nombre completo
                Text(
                  '$stylistName $stylistLastName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Email
                Text(
                  stylistEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Información de contacto
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: roleColor.withOpacity(0.15),
              ),
            ),
            child: Column(
              children: [
                // Teléfono
                _buildInfoItem(
                  icon: Icons.phone,
                  label: 'Teléfono',
                  value: stylistPhone,
                  color: roleColor,
                ),
                const SizedBox(height: 12),
                Divider(
                  color: roleColor.withOpacity(0.2),
                  height: 1,
                ),
                const SizedBox(height: 12),

                // Género
                _buildInfoItem(
                  icon: Icons.person_outline,
                  label: 'Género',
                  value: _getGeneroLabel(),
                  color: roleColor,
                  isCompact: true,
                ),
              ],
            ),
          ),

          // Espaciador
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCompact = false,
  }) {
    if (isCompact) {
      return Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGeneroLabel() {
    if (stylistData == null) return 'Otro';
    final genero = stylistData!['genero'] ?? 'O';
    switch (genero) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Femenino';
      default:
        return 'Otro';
    }
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
          onTap: () => _navigateToEditProfile(context),
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
            onTap: () => _navigateToEditProfile(context),
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

  void _navigateToEditProfile(BuildContext context) {
    if (token == null || stylistData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Datos insuficientes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🟦 StylistProfileTab._navigateToEditProfile called');
    print('  - token exists: true');
    print('  - stylistData exists: true');
    print('  - Datos: ${stylistData!.keys.toList()}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStylistProfilePage(
          token: token!,
          stylist: stylistData!,
          onSuccess: () {
            print('✅ Perfil actualizado en backend');
            // Recargar perfil desde la API
            _reloadProfileFromAPI();
          },
        ),
      ),
    ).then((result) {
      print('🔄 Regresando de EditStylistProfilePage...');
      // Recargar nuevamente por si acaso
      _reloadProfileFromAPI();
    });
  }
}

// ===== PÁGINA DE EDICIÓN DE PERFIL =====
class EditStylistProfilePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> stylist;
  final VoidCallback? onSuccess;

  const EditStylistProfilePage({
    super.key,
    required this.token,
    required this.stylist,
    this.onSuccess,
  });

  @override
  State<EditStylistProfilePage> createState() => _EditStylistProfilePageState();
}

class _EditStylistProfilePageState extends State<EditStylistProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: EditStylistProfileSection(
          token: widget.token,
          stylist: widget.stylist,
          onSuccess: widget.onSuccess,
        ),
      ),
    );
  }
}