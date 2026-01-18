import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'stylist_schedule_management_page.dart';
//import 'stylist_services_schedule_page.dart';

/// Módulo: Gestión de Horario Estilista (en tab Administrar)
/// Permite seleccionar un estilista y luego configurar sus horarios
class StylistScheduleManagementModule extends StatefulWidget {
  final String token;
  final String userRole;

  const StylistScheduleManagementModule({
    super.key,
    required this.token,
    required this.userRole,
  });

  @override
  State<StylistScheduleManagementModule> createState() =>
      _StylistScheduleManagementModuleState();
}

class _StylistScheduleManagementModuleState
    extends State<StylistScheduleManagementModule> {
  List<dynamic> _stylists = [];
  List<dynamic> _filteredStylists = [];
  bool _loading = true;
  String _searchQuery = '';
  late TextEditingController _searchController;
  
  // Para mostrar preview de horarios
  String? _selectedStylistId;
  Map<dynamic, dynamic>? _selectedStylistData;
  List<dynamic> _selectedStylistSchedules = [];
  bool _loadingSchedules = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchStylists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStylists() async {
    setState(() => _loading = true);
    try {
      // GET /api/v1/stylists - Lista todos los estilistas activos (PÚBLICO)
      final res = await ApiClient.instance.get(
        '/api/v1/stylists',
      );

      if (res.statusCode == 200) {
        final allUsers = (res.body.startsWith('['))
            ? jsonDecode(res.body) as List
            : (jsonDecode(res.body) as Map)['data'] as List? ?? [];

        // Filtrar solo estilistas (por si acaso, aunque el endpoint debería retornar solo estilistas)
        final stylistsList = allUsers.where((user) {
          final role = (user['role'] ?? '').toString().toUpperCase();
          return role == 'ESTILISTA';
        }).toList();

        setState(() {
          _stylists = stylistsList;
          _applyFilter();
          _loading = false;
        });
      } else {
        setState(() {
          _stylists = [];
          _loading = false;
        });
        _showNotification('Error al obtener estilistas', Colors.red);
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _stylists = [];
        _loading = false;
      });
      _showNotification('Error: $e', Colors.red);
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      setState(() => _filteredStylists = _stylists);
    } else {
      final query = _searchQuery.toLowerCase();
      setState(() {
        _filteredStylists = _stylists.where((s) {
          final nombre = (s['nombre'] ?? '').toString().toLowerCase();
          final apellido = (s['apellido'] ?? '').toString().toLowerCase();
          final email = (s['email'] ?? '').toString().toLowerCase();
          return nombre.contains(query) ||
              apellido.contains(query) ||
              email.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _fetchStylistSchedules(String stylistId) async {
    setState(() => _loadingSchedules = true);
    try {
      // GET /api/v1/schedules/stylist/:stylistId
      final res = await ApiClient.instance.get(
        '/api/v1/schedules/stylist/$stylistId',
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        // Manejar ambos formatos: array directo o envuelto
        List<dynamic> schedules = [];
        if (data is List) {
          schedules = data;
        } else if (data is Map && data.containsKey('schedules')) {
          schedules = data['schedules'] as List? ?? [];
        } else if (data is Map && data.containsKey('data')) {
          schedules = data['data'] as List? ?? [];
        }
        
        setState(() {
          _selectedStylistSchedules = schedules;
          _loadingSchedules = false;
        });
      } else {
        setState(() {
          _selectedStylistSchedules = [];
          _loadingSchedules = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching schedules: $e');
      setState(() {
        _selectedStylistSchedules = [];
        _loadingSchedules = false;
      });
    }
  }

  void _showNotification(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        title: Text(
          'Gestión de Horarios',
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
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _applyFilter();
                    },
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar estilista...',
                      hintStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.search, color: AppColors.gold),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.gold.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.gold),
                      ),
                    ),
                  ),
                ),
                // Content: Lista o Preview
                Expanded(
                  child: _selectedStylistId == null
                      ? _buildStylistsList()
                      : _buildStylistPreview(),
                ),
              ],
            ),
    );
  }

  Widget _buildStylistsList() {
    return _filteredStylists.isEmpty
        ? Center(
            child: Text(
              'No hay estilistas',
              style: TextStyle(color: Colors.white60),
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredStylists.length,
            itemBuilder: (context, index) {
              final stylist = _filteredStylists[index];
              return _buildStylistCard(stylist);
            },
          );
  }

  Widget _buildStylistPreview() {
    if (_selectedStylistData == null) {
      return Center(child: Text('Error cargando datos'));
    }

    final nombre = _selectedStylistData!['nombre'] ?? '';
    final apellido = _selectedStylistData!['apellido'] ?? '';
    final email = _selectedStylistData!['email'] ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nombre del estilista
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nombre $apellido',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.gold),
                      onPressed: () {
                        setState(() {
                          _selectedStylistId = null;
                          _selectedStylistData = null;
                          _selectedStylistSchedules = [];
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Horarios de Trabajo
          _buildSectionTitle('⏰ Horarios de Trabajo'),
          SizedBox(height: 12),
          _loadingSchedules
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                )
              : _buildSchedulesPreview(),
          SizedBox(height: 24),

          // Botones de acción
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSchedulesPreview() {
    if (_selectedStylistSchedules.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '⚠️ Este estilista aún no tiene horarios configurados',
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    return Column(
      children: _selectedStylistSchedules.asMap().entries.map((entry) {
        final schedule = entry.value;
        final dayOfWeek = schedule['dayOfWeek'] ?? 'N/A';
        final slots = schedule['slots'] as List? ?? [];
        
        // Convertir día numérico a nombre
        final dayName = _getDayName(dayOfWeek);

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              if (slots.isEmpty)
                Text(
                  'Sin horarios',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                )
              else
                ...slots.map((slot) {
                  final start = slot['start'] ?? slot['startTime'] ?? '00:00';
                  final end = slot['end'] ?? slot['endTime'] ?? '00:00';
                  return Text(
                    '${start} - ${end}',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  );
                }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón: Editar Horarios de Trabajo
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StylistScheduleManagementPage(
                  token: widget.token,
                  stylistId: _selectedStylistId!,
                  stylistName:
                      '${_selectedStylistData!['nombre']} ${_selectedStylistData!['apellido']}',
                  userRole: widget.userRole,
                ),
              ),
            ).then((_) {
              // Recargar horarios al volver
              _fetchStylistSchedules(_selectedStylistId!);
            });
          },
          icon: Icon(Icons.edit),
          label: Text('Editar Horarios de Trabajo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.charcoal,
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        SizedBox(height: 12),

        // Botón: Crear Slots de Servicios
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to StylistServicesSchedulePage when it exists
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Página de servicios no disponible aún'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          icon: Icon(Icons.add_circle),
          label: Text('Crear Slots de Servicios'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
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

  String _getDayName(dynamic dayOfWeek) {
    final dayMap = {
      0: 'Lunes',
      1: 'Martes',
      2: 'Miércoles',
      3: 'Jueves',
      4: 'Viernes',
      5: 'Sábado',
      6: 'Domingo',
      'LUNES': 'Lunes',
      'MARTES': 'Martes',
      'MIERCOLES': 'Miércoles',
      'JUEVES': 'Jueves',
      'VIERNES': 'Viernes',
      'SABADO': 'Sábado',
      'DOMINGO': 'Domingo',
    };
    return dayMap[dayOfWeek]?.toString() ?? dayOfWeek.toString();
  }

  Widget _buildStylistCard(dynamic stylist) {
    final isActive = stylist['isActive'] != false;
    final nombre = stylist['nombre'] ?? '';
    final apellido = stylist['apellido'] ?? '';
    final email = stylist['email'] ?? '';
    final especializacion = stylist['especializacion'] ?? 'N/A';
    // Obtener servicios de servicesOffered (array de IDs o de objetos)
    final servicesOffered = stylist['servicesOffered'] as List? ?? [];
    final stylistId = stylist['_id'] ?? stylist['id'] ?? '';
    final hasServices = servicesOffered.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // Al hacer tap, mostrar preview con horarios
        setState(() {
          _selectedStylistId = stylistId;
          _selectedStylistData = stylist;
          _selectedStylistSchedules = [];
        });
        _fetchStylistSchedules(stylistId);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(
            color: isActive
                ? AppColors.gold.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$nombre $apellido',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Email
            Row(
              children: [
                Icon(Icons.email, color: AppColors.gold.withOpacity(0.6), size: 14),
                SizedBox(width: 6),
                Text(
                  email,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 6),

            // Especialización
            Row(
              children: [
                Icon(Icons.star, color: AppColors.gold.withOpacity(0.6), size: 14),
                SizedBox(width: 6),
                Text(
                  especializacion,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Servicios asignados
            if (!hasServices)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '⚠️ Sin servicios asignados',
                  style: TextStyle(color: Colors.orange, fontSize: 11),
                ),
              )
            else
              Text(
                'Servicios: ${servicesOffered.length} asignados',
                style: TextStyle(color: Colors.white60, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 12),

            // Flecha para indicar que es clickeable
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.arrow_forward_ios, color: AppColors.gold, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
