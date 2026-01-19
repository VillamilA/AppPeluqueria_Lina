import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../api/api_client.dart';
import '../../../core/theme/app_theme.dart';
// import 'stylist_services_schedule_page.dart'; // TODO: archivo no existe

/// Página intermedia para elegir qué tipo de horario configurar
/// - Horario de Trabajo (franjas generales por día)
/// - Horario de Servicios (slots específicos para servicios)
class StylistScheduleOptionsPage extends StatefulWidget {
  final String token;
  final String stylistId;
  final String stylistName;
  final String userRole;

  const StylistScheduleOptionsPage({
    super.key,
    required this.token,
    required this.stylistId,
    required this.stylistName,
    required this.userRole,
  });

  @override
  State<StylistScheduleOptionsPage> createState() => _StylistScheduleOptionsPageState();
}

class _StylistScheduleOptionsPageState extends State<StylistScheduleOptionsPage> {
  bool _loading = true;
  bool _hasServices = false;
  String _servicesList = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkStylistServices();
  }

  Future<void> _checkStylistServices() async {
    setState(() => _loading = true);
    try {
      // Obtener datos completos del estilista (ADMIN) - GET /api/v1/users/:id
      final res = await ApiClient.instance.get(
        '/api/v1/users/${widget.stylistId}',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        final stylist = jsonDecode(res.body);

        // Verificar si tiene servicios asignados (servicesOffered es lista de IDs)
        final servicesOffered = stylist['servicesOffered'] as List? ?? [];
        
        setState(() {
          _hasServices = servicesOffered.isNotEmpty;
          if (_hasServices) {
            // Si recibimos objetos con 'nombre', usamos eso. Si no, mostramos cantidad
            if (servicesOffered.isNotEmpty && servicesOffered.first is Map) {
              _servicesList = servicesOffered
                  .map((s) => (s as Map)['nombre'] ?? 'Servicio')
                  .join(', ');
            } else {
              _servicesList = '${servicesOffered.length} servicios asignados';
            }
          } else {
            _errorMessage = 'Este estilista no tiene servicios asignados';
          }
          _loading = false;
        });
      } else if (res.statusCode == 403) {
        setState(() {
          _errorMessage = 'No tienes permiso para ver este estilista';
          _loading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _errorMessage = 'Estilista no encontrado';
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al obtener información del estilista';
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gestionar Horarios - ${widget.stylistName}',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            )
          : _hasServices
              ? _buildScheduleOptions()
              : _buildNoServicesError(),
    );
  }

  Widget _buildScheduleOptions() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Servicios Asignados',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _servicesList,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Opción: Crear Slots de Servicios
          _buildScheduleOptionCard(
            title: 'Crear Slots de Servicios',
            description:
                'Genera disponibilidad (slots) para servicios específicos. El sistema automáticamente calcula los horarios basado en la duración del servicio.',
            icon: Icons.event_available,
            iconColor: Colors.green,
            onTap: () {
              // Mostrar mensaje informativo
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.charcoal,
                  title: Text(
                    'ℹ️ Cómo Funcionan los Slots',
                    style: TextStyle(color: AppColors.gold),
                  ),
                  content: Text(
                    'Selecciona un servicio y especifica las horas que el estilista está disponible.\n\n'
                    'El sistema automáticamente generará slots (franjas de citas) basado en:\n'
                    '• Duración del servicio\n'
                    '• + 30 minutos de descanso entre citas\n\n'
                    'Ejemplo:\n'
                    'Servicio: Corte (60 min)\n'
                    'Horas: 09:00 - 18:00\n'
                    'Slots generados: 09:00, 10:30, 12:00, 13:30, 15:00, 16:30',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Entendido', style: TextStyle(color: AppColors.charcoal)),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 32),

          // Info box
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 ¿Cuál es la diferencia?',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Horario de Trabajo: Define qué días y horas trabaja el estilista\n'
                  '• Horario de Servicios: Crea slots específicos para que clientes agenden servicios\n\n'
                  'Primero configura el horario de trabajo, luego crea los slots para servicios.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(color: AppColors.gold.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.gold.withOpacity(0.6),
                  size: 18,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoServicesError() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40),
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Sin Servicios Asignados',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Para gestionar horarios, primero debes asignar servicios a este estilista',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Volver atrás y dejar que el usuario edite el estilista
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Edita el estilista para asignarle servicios',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: Icon(Icons.edit),
            label: Text('Editar Estilista'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.charcoal,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
