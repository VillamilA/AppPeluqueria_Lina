import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../api/api_client.dart';
import '../../../api/slots_api.dart';
import '../../../core/theme/app_theme.dart';

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
  late SlotsApi _slotsApi;
  
  // Para mostrar preview de horarios
  String? _selectedStylistId;
  Map<dynamic, dynamic>? _selectedStylistData;
  List<dynamic> _selectedStylistSchedules = [];
  bool _loadingSchedules = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _slotsApi = SlotsApi(ApiClient.instance);
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
      // GET /api/v1/slots?stylistId={id} para obtener todos los slots del estilista
      final res = await ApiClient.instance.get(
        '/api/v1/slots?stylistId=$stylistId&onlyActive=true&limit=500',
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        // El backend retorna un array de slots directamente
        List<dynamic> slots = [];
        if (data is List) {
          slots = data;
        } else if (data is Map && data.containsKey('data')) {
          slots = data['data'] as List? ?? [];
        }
        
        print('� Slots recargados para $stylistId: ${slots.length} slots');
        
        setState(() {
          _selectedStylistSchedules = slots;
          _loadingSchedules = false;
        });
      } else {
        print('❌ Error loading slots: ${res.statusCode}');
        setState(() {
          _selectedStylistSchedules = [];
          _loadingSchedules = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching slots: $e');
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
    final servicesOffered = _selectedStylistData!['servicesOffered'] as List? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER ESTILISTA =====
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
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
                      SizedBox(height: 8),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.gold, size: 28),
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
          ),
          SizedBox(height: 18),

          // ===== SECCIÓN: SERVICIOS QUE OFRECE =====
          _buildSectionTitle('💼 Servicios que Ofrece'),
          SizedBox(height: 12),
          _buildServicesSection(servicesOffered),
          SizedBox(height: 24),

          // ===== SECCIÓN: HORARIOS DE TRABAJO =====
          _buildSectionTitle('⏰ Horarios de Trabajo'),
          SizedBox(height: 12),
          _loadingSchedules
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                )
              : _buildSchedulesPreview(),
          SizedBox(height: 28),

          // ===== BOTONES DE ACCIÓN =====
          _buildActionButtons(servicesOffered),
        ],
      ),
    );
  }

  Widget _buildServicesSection(List<dynamic> servicesOffered) {
    if (servicesOffered.isEmpty) {
      return Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.15),
          border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sin servicios asignados',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: servicesOffered.map((service) {
        final serviceId = service is String ? service : (service['_id'] ?? service['id'] ?? '');
        final serviceName = service is Map ? (service['nombre'] ?? service['name'] ?? 'Servicio') : 'Servicio ID: $serviceId';
        
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.2),
            border: Border.all(color: AppColors.gold.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppColors.gold, size: 16),
              SizedBox(width: 6),
              Text(
                serviceName.toString(),
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSchedulesPreview() {
    if (_selectedStylistSchedules.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.15),
          border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Este estilista aún no tiene slots (citas disponibles) configurados',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar slots por día de semana
    final Map<String, List<Map<String, dynamic>>> slotsByDay = {};
    final dayOrder = ['LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO'];
    
    for (final slot in _selectedStylistSchedules) {
      final dayOfWeek = (slot['dayOfWeek'] ?? 'N/A').toString().toUpperCase();
      if (!slotsByDay.containsKey(dayOfWeek)) {
        slotsByDay[dayOfWeek] = [];
      }
      slotsByDay[dayOfWeek]!.add(slot);
    }

    // Ordenar días lógicamente
    final sortedDays = slotsByDay.keys.toList()
      ..sort((a, b) => dayOrder.indexOf(a).compareTo(dayOrder.indexOf(b)));

    return Column(
      children: sortedDays.map((dayOfWeek) {
        final slots = slotsByDay[dayOfWeek] ?? [];
        final dayName = _getDayName(dayOfWeek);

        // Contar slots únicos por servicio
        final Map<String, int> serviceCount = {};
        for (final slot in slots) {
          final serviceName = _getServiceName(slot);
          serviceCount[serviceName] = (serviceCount[serviceName] ?? 0) + 1;
        }

        return Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del día
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${slots.length} slots',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              
              // Servicios disponibles
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: serviceCount.entries.map((entry) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${entry.key} (${entry.value})',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 8),
              
              // Primeros 3 horarios
              ...slots.take(3).map<Widget>((slot) {
                final startMin = _convertMinutesToTime(slot['startMin'] ?? 0);
                final endMin = _convertMinutesToTime(slot['endMin'] ?? 0);
                final serviceName = _getServiceName(slot);
                
                return Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.gold, size: 14),
                      SizedBox(width: 6),
                      Text(
                        '$startMin - $endMin',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '($serviceName)',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              // Si hay más de 3 slots, mostrar "más"
              if (slots.length > 3)
                Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '+${slots.length - 3} más',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getServiceName(Map<String, dynamic> slot) {
    if (slot['service'] is Map) {
      return slot['service']['nombre'] ?? slot['service']['name'] ?? 'Servicio';
    }
    return 'Servicio';
  }

  String _convertMinutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButtons(List<dynamic> servicesOffered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón: Crear Slots de Servicios
        ElevatedButton.icon(
          onPressed: () {
            _showCreateServiceSlotDialog(servicesOffered);
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

  void _showCreateServiceSlotDialog(List<dynamic> servicesOffered) {
    showDialog(
      context: context,
      builder: (BuildContext context) => CreateServiceSlotDialog(
        token: widget.token,
        stylistId: _selectedStylistId!,
        stylistName: '${_selectedStylistData!['nombre']} ${_selectedStylistData!['apellido']}',
        slotsApi: _slotsApi,
        stylistServices: servicesOffered,
        onSlotCreated: () {
          // Recargar horarios al crear un nuevo slot
          _fetchStylistSchedules(_selectedStylistId!);
        },
      ),
    );
  }
}

/// Diálogo para crear slots de servicios para un estilista
class CreateServiceSlotDialog extends StatefulWidget {
  final String token;
  final String stylistId;
  final String stylistName;
  final SlotsApi slotsApi;
  final List<dynamic> stylistServices;
  final VoidCallback onSlotCreated;

  const CreateServiceSlotDialog({
    super.key,
    required this.token,
    required this.stylistId,
    required this.stylistName,
    required this.slotsApi,
    required this.stylistServices,
    required this.onSlotCreated,
  });

  @override
  State<CreateServiceSlotDialog> createState() => _CreateServiceSlotDialogState();
}

class _CreateServiceSlotDialogState extends State<CreateServiceSlotDialog> {
  // Variables de formulario
  List<dynamic> _services = [];
  String? _selectedServiceId;
  String? _selectedDayOfWeek = 'LUNES';
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 17, minute: 0);

  // Control
  bool _loadingServices = true;
  bool _isCreating = false;
  String? _errorMessage;

  final Map<String, String> _daysOfWeek = {
    'LUNES': 'Lunes',
    'MARTES': 'Martes',
    'MIERCOLES': 'Miércoles',
    'JUEVES': 'Jueves',
    'VIERNES': 'Viernes',
    'SABADO': 'Sábado',
    'DOMINGO': 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        _loadingServices = true;
        _errorMessage = null;
      });

      final response = await ApiClient.instance.get(
        '/api/v1/services',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List servicesList = [];

        if (data is List) {
          servicesList = data;
        } else if (data is Map && data['data'] != null) {
          servicesList = data['data'] is List ? data['data'] : [];
        }

        // Filtrar servicios para mostrar solo los del estilista
        List<dynamic> filteredServices = [];
        if (widget.stylistServices.isNotEmpty) {
          final stylistServiceIds = widget.stylistServices.map((s) {
            if (s is String) return s;
            if (s is Map) return s['_id'] ?? s['id'];
            return null;
          }).toList();

          filteredServices = servicesList.where((service) {
            final serviceId = service['_id'] ?? service['id'];
            return stylistServiceIds.contains(serviceId);
          }).toList();
        } else {
          // Si no hay servicios asignados, mostrar todos
          filteredServices = servicesList;
        }

        setState(() {
          _services = filteredServices;
          _loadingServices = false;
          if (_services.isNotEmpty && _selectedServiceId == null) {
            _selectedServiceId = _services[0]['_id'] ?? _services[0]['id'];
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar servicios: ${response.statusCode}';
          _loadingServices = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _loadingServices = false;
      });
    }
  }

  Future<void> _createSlot() async {
    // Validar servicio
    if (_selectedServiceId == null) {
      setState(() => _errorMessage = 'Selecciona un servicio');
      return;
    }

    // Validar que hora inicio < hora fin
    if (_startTime.hour > _endTime.hour || 
        (_startTime.hour == _endTime.hour && _startTime.minute >= _endTime.minute)) {
      setState(() => _errorMessage = 'La hora de inicio debe ser menor que la hora de fin');
      return;
    }

    final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

    final slotData = {
      'stylistId': widget.stylistId,
      'serviceId': _selectedServiceId,
      'dayOfWeek': _selectedDayOfWeek,
      'dayStart': startTimeStr,
      'dayEnd': endTimeStr,
    };

    print('📤 Creando slot: $slotData');

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final response = await widget.slotsApi.createSlots(
        slotData,
        token: widget.token,
      );

      print('📥 Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Slot creado exitosamente en $startTimeStr - $endTimeStr'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          widget.onSlotCreated();
          Navigator.pop(context);
        }
      } else if (response.statusCode == 409) {
        // Error 409 Conflict - Slot duplicado o conflicto de horarios
        String errorMsg = 'Este slot ya existe o hay un conflicto de horarios.';
        try {
          final errData = jsonDecode(response.body);
          if (errData['message'] != null) {
            errorMsg = errData['message'].toString();
          }
        } catch (e) {
          print('Error parsing 409 response: $e');
        }
        setState(() => _errorMessage = '⚠️ Conflicto (409): $errorMsg');
      } else if (response.statusCode == 400) {
        // Error 400 Bad Request - Datos inválidos
        String errorMsg = 'Datos inválidos.';
        try {
          final errData = jsonDecode(response.body);
          if (errData['message'] != null) {
            errorMsg = errData['message'].toString();
          }
        } catch (e) {
          print('Error parsing 400 response: $e');
        }
        setState(() => _errorMessage = '❌ Datos inválidos (400): $errorMsg');
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode}. Verifica los datos e intenta de nuevo.';
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.charcoal,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Crear Slot de Servicio',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.gold),
            onPressed: () => Navigator.pop(context),
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== INFO ESTILISTA =====
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: AppColors.gold, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.stylistName,
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),

            // ===== ERROR MESSAGE =====
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // ===== SERVICIO =====
            _buildFormField(
              label: '📋 Servicio',
              child: _loadingServices
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                        strokeWidth: 2,
                      ),
                    )
                  : _services.isEmpty
                      ? Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'No hay servicios disponibles',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedServiceId,
                            isExpanded: true,
                            underline: SizedBox(),
                            dropdownColor: AppColors.charcoal,
                            style: TextStyle(color: Colors.white, fontSize: 13),
                            items: _services.map<DropdownMenuItem<String>>((service) {
                              final id = service['_id'] ?? service['id'];
                              final nombre = service['nombre'] ?? service['name'] ?? 'Servicio';
                              return DropdownMenuItem<String>(
                                value: id.toString(),
                                child: Text(nombre.toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedServiceId = value);
                            },
                          ),
                        ),
            ),

            // ===== DÍA DE LA SEMANA =====
            _buildFormField(
              label: '📅 Día de la Semana',
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedDayOfWeek,
                  isExpanded: true,
                  underline: SizedBox(),
                  dropdownColor: AppColors.charcoal,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  items: _daysOfWeek.keys.map<DropdownMenuItem<String>>((day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(_daysOfWeek[day]!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedDayOfWeek = value);
                  },
                ),
              ),
            ),

            // ===== HORAS =====
            Row(
              children: [
                // Hora Inicio
                Expanded(
                  child: _buildFormField(
                    label: '⏰ Inicio',
                    child: GestureDetector(
                      onTap: _selectStartTime,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(_startTime),
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            Icon(Icons.access_time, color: AppColors.gold, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Hora Fin
                Expanded(
                  child: _buildFormField(
                    label: '⏰ Fin',
                    child: GestureDetector(
                      onTap: _selectEndTime,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(_endTime),
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            Icon(Icons.access_time, color: AppColors.gold, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createSlot,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.charcoal,
            disabledBackgroundColor: Colors.grey[600],
          ),
          child: _isCreating
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.charcoal),
                  ),
                )
              : Text('Crear Slot', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        SizedBox(height: 6),
        child,
        SizedBox(height: 14),
      ],
    );
  }
}
