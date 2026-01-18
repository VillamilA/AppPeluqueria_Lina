import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../business_hours_management_page.dart';
import 'stylist_schedule_management_module.dart';

/// Página de opciones de horarios para GERENTE
/// Permite elegir entre:
/// 1. Establecer Horario del Negocio (horarios de atención del local)
/// 2. Establecer Horarios de Estilistas (horarios de trabajo + slots de servicios)
class GerenteScheduleOptionsPage extends StatefulWidget {
  final String token;
  final String userRole;

  const GerenteScheduleOptionsPage({
    super.key,
    required this.token,
    required this.userRole,
  });

  @override
  State<GerenteScheduleOptionsPage> createState() => _GerenteScheduleOptionsPageState();
}

class _GerenteScheduleOptionsPageState extends State<GerenteScheduleOptionsPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(
          title: Text('Gestionar Horarios',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.charcoal,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.gold),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                '🕐 Opciones de Horarios',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Selecciona qué tipo de horario deseas configurar',
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
              SizedBox(height: 28),

              // Opción 1: Horario del Negocio
              _buildOptionCard(
                title: 'Horario del Negocio',
                description: 'Establece el horario de apertura y cierre del local para cada día de la semana',
                icon: Icons.store_rounded,
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BusinessHoursManagementPage(
                        token: widget.token,
                        userRole: widget.userRole,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),

              // Opción 2: Horarios de Estilistas
              _buildOptionCard(
                title: 'Horarios de Estilistas',
                description: 'Configura los horarios de trabajo y slots de disponibilidad para cada estilista',
                icon: Icons.people_rounded,
                iconColor: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StylistScheduleManagementModule(
                        token: widget.token,
                        userRole: widget.userRole,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 28),

              // Info box
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_rounded, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '¿Cuál es la diferencia?',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '📍 Horario del Negocio: Define qué horas está abierto tu local (lunes a domingo).\n\n'
                      '👤 Horarios de Estilistas: Configura cuándo trabaja cada estilista y crea espacios disponibles para que los clientes agenden servicios.',
                      style: TextStyle(
                        color: Colors.blue.shade200,
                        fontSize: 12,
                        height: 1.6,
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

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios, color: AppColors.gold, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
