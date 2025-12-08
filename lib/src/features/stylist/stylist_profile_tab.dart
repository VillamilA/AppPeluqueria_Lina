import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../api/slots_api.dart';
import '../slots/create_slot_dialog.dart';

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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24),
            _buildSectionTitle('Información Personal'),
            SizedBox(height: 12),
            _buildInfoCard('Nombre', '$stylistName $stylistLastName'),
            SizedBox(height: 8),
            _buildInfoCard('Email', stylistEmail),
            SizedBox(height: 8),
            _buildInfoCard('Teléfono', stylistPhone),
            SizedBox(height: 24),
            _buildSectionTitle('Configuración'),
            SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.edit,
              title: 'Editar Perfil',
              subtitle: 'Actualiza tu información',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Próximamente')),
              ),
            ),
            SizedBox(height: 8),
            _buildOptionTile(
              icon: Icons.lock,
              title: 'Cambiar Contraseña',
              subtitle: 'Actualiza tu contraseña',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Próximamente')),
              ),
            ),
            SizedBox(height: 8),
            _buildOptionTile(
              icon: Icons.notifications,
              title: 'Notificaciones',
              subtitle: 'Configura tus preferencias',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Próximamente')),
              ),
            ),
            SizedBox(height: 8),
            _buildOptionTile(
              icon: Icons.schedule,
              title: 'Gestionar Horarios',
              subtitle: 'Crea y edita tus horarios disponibles',
              onTap: () => _showCreateSlotDialog(context),
            ),
            SizedBox(height: 8),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.charcoal, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.gold,
            child: Icon(Icons.person, color: Colors.black, size: 60),
          ),
          SizedBox(height: 16),
          Text(
            '$stylistName $stylistLastName',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Estilista Profesional',
            style: TextStyle(color: AppColors.gray, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.gold,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.gray, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.gray, fontSize: 11),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, color: AppColors.gray, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(Icons.logout),
        label: Text(
          'Cerrar Sesión',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cerrando sesión...')),
          );
        },
      ),
    );
  }

  void _showCreateSlotDialog(BuildContext context) {
    print('🟦 StylistProfileTab._showCreateSlotDialog called');
    print('  - token exists: ${token != null}');
    print('  - slotsApi exists: ${slotsApi != null}');
    print('  - stylistId: $stylistId');
    
    if (token == null || slotsApi == null || stylistId == null) {
      print('❌ ERROR: Datos insuficientes');
      print('  - token: ${token == null ? 'NULL' : 'OK'}');
      print('  - slotsApi: ${slotsApi == null ? 'NULL' : 'OK'}');
      print('  - stylistId: ${stylistId == null ? 'NULL' : 'OK'}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Datos insuficientes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ Abriendo CreateSlotDialog con:');
    print('  - stylistId: $stylistId');
    print('  - token: ${token!.substring(0, 20)}...');
    print('  - userRole: ESTILISTA');
    
    showDialog(
      context: context,
      builder: (context) => CreateSlotDialog(
        slotsApi: slotsApi!,
        token: token!,
        initialStylistId: stylistId,
        userRole: 'ESTILISTA',
      ),
    );
  }
}