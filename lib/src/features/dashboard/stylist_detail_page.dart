import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import '../../api/stylists_api.dart';
import '../../api/slots_api.dart';
import '../../api/bookings_api.dart';
import '../../core/theme/app_theme.dart';

class StylistDetailPage extends StatefulWidget {
  final Map<String, dynamic> stylist;
  final String token;

  const StylistDetailPage({
    super.key,
    required this.stylist,
    required this.token,
  });

  @override
  State<StylistDetailPage> createState() => _StylistDetailPageState();
}

class _StylistDetailPageState extends State<StylistDetailPage> {
  bool isLoading = true;
  List<dynamic> catalogs = [];
  List<dynamic> schedules = [];
  List<dynamic> slots = [];
  String errorMessage = '';
  late String stylistId;
  late String token;

  @override
  void initState() {
    super.initState();
    _loadStylistDetails();
  }

  Future<void> _loadStylistDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Intentar obtener _id primero, luego id
      stylistId = widget.stylist['_id'] ?? widget.stylist['id'];
      token = widget.token;
      
      if (stylistId.isEmpty) {
        throw Exception('No se encontró ID del estilista');
      }
      
      print('🔍 Stylist ID type: ${stylistId.runtimeType}');
      print('🔍 Stylist ID value: $stylistId');
      
      // Cargar catálogos del estilista
      final catalogsResponse = await StylistsApi(ApiClient.instance)
          .getStylistCatalogs(stylistId: stylistId, token: widget.token);
      
      if (catalogsResponse.statusCode == 200) {
        final catalogsData = jsonDecode(catalogsResponse.body);
        print('📦 Catalogs Response: $catalogsData');
        
        // Manejar diferentes formatos de respuesta
        if (catalogsData is Map) {
          catalogs = (catalogsData['catalogs'] ?? catalogsData['data'] ?? []) as List;
        } else if (catalogsData is List) {
          catalogs = catalogsData;
        }
        
        print('📋 Catalogs loaded: ${catalogs.length} items');
      }

      // Cargar horarios del estilista
      final scheduleResponse = await SlotsApi(ApiClient.instance)
          .getStylistSchedule(token: widget.token, stylistId: stylistId);
      
      print('📅 Schedule Response Status: ${scheduleResponse.statusCode}');
      print('📅 Schedule Response Body: ${scheduleResponse.body}');
      
      if (scheduleResponse.statusCode == 200 || scheduleResponse.statusCode == 201) {
        try {
          final scheduleData = jsonDecode(scheduleResponse.body);
          print('📅 Parsed Schedule Data: $scheduleData');
          
          // Manejar diferentes formatos de respuesta
          if (scheduleData is Map) {
            // Intenta múltiples claves posibles
            if (scheduleData.containsKey('schedules')) {
              schedules = scheduleData['schedules'] ?? [];
            } else if (scheduleData.containsKey('data')) {
              schedules = scheduleData['data'] ?? [];
            } else if (scheduleData.containsKey('schedule')) {
              schedules = [scheduleData['schedule']];
            } else {
              // Si es un objeto directo de schedule
              schedules = [scheduleData];
            }
          } else if (scheduleData is List) {
            schedules = scheduleData;
          }
          
          print('📋 Final Schedules Count: ${schedules.length}');
          print('📋 Schedules: $schedules');
        } catch (e) {
          print('❌ Error parsing schedules: $e');
          print('📋 Response body: ${scheduleResponse.body}');
        }
      } else {
        print('⚠️ Schedule endpoint returned: ${scheduleResponse.statusCode}');
      }

      // Cargar slots activos del estilista
      final slotsResponse = await SlotsApi(ApiClient.instance)
          .getSlots(stylistId: stylistId, token: widget.token);
      
      if (slotsResponse.statusCode == 200) {
        final slotsData = jsonDecode(slotsResponse.body);
        slots = slotsData['slots'] ?? [];
        // Filtrar solo slots activos
        slots = slots.where((slot) => slot['activo'] == true).toList();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar información del estilista: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.stylist['nombre'] ?? '';
    final apellido = widget.stylist['apellido'] ?? '';
    final fullName = '$nombre $apellido'.trim();
    final image = widget.stylist['image'];
    final email = widget.stylist['email'] ?? '';
    final especialidad = widget.stylist['especialidad'] ?? '';
    final rating = widget.stylist['rating'] ?? 5.0;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fullName,
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _loadStylistDetails,
                          child: Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con foto y detalles del estilista
                          _buildStylistHeader(
                            fullName,
                            image,
                            email,
                            especialidad,
                            rating,
                          ),
          SizedBox(height: 16),
          
          // Sección de Catálogos
          _buildSectionTitle('Catálogos y Servicios'),
          SizedBox(height: 8),
          _buildCatalogsSection(),
          SizedBox(height: 16),
          
          // Sección de Horarios
          _buildSectionTitle('Horario de Trabajo'),
          SizedBox(height: 8),
          _buildSchedulesSection(),
          SizedBox(height: 16),
          
          // Sección de Slots Disponibles
          _buildSectionTitle('Slots Disponibles'),
          SizedBox(height: 8),
          _buildSlotsSection(),
                        ],
                      ),
                    ),
                    // Botón de Reservar a la vista
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.charcoal,
                          border: Border(
                            top: BorderSide(
                              color: AppColors.gold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: slots.isEmpty ? null : () => _showBookingBottomSheet(fullName),
                          icon: Icon(Icons.event_available, size: 20),
                          label: Text(
                            'Reservar Cita',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStylistHeader(
    String fullName,
    String? image,
    String email,
    String especialidad,
    double rating,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.charcoal, AppColors.charcoal.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          // Foto del estilista
          CircleAvatar(
            radius: 35,
            backgroundImage: image != null && image.isNotEmpty
                ? NetworkImage(image)
                : null,
            child: image == null || image.isEmpty
                ? Icon(Icons.person, color: AppColors.gold, size: 35)
                : null,
          ),
          SizedBox(width: 12),
          // Información del estilista
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (especialidad.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      especialidad,
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                SizedBox(height: 4),
                // Rating - Compacto
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      color: index < rating.toInt() ? AppColors.gold : AppColors.gray,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Icon(Icons.label, color: AppColors.gold, size: 18),
        SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogsSection() {
    if (catalogs.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.charcoal.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No hay catálogos disponibles.',
            style: TextStyle(color: AppColors.gray),
          ),
        ),
      );
    }

    return Column(
      children: catalogs.map((catalog) {
        final catalogName = catalog['nombre'] ?? 'Catálogo';
        final services = catalog['services'] ?? [];
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.charcoal.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1),
          ),
          child: ExpansionTile(
            title: Text(
              catalogName,
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: Icon(Icons.folder, color: AppColors.gold),
            iconColor: AppColors.gold,
            collapsedIconColor: AppColors.gold,
            children: [
              if (services.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay servicios en este catálogo.',
                    style: TextStyle(color: AppColors.gray),
                  ),
                )
              else
                ...services.map<Widget>((service) {
                  final serviceName = service['nombre'] ?? 'Servicio';
                  final precio = service['precio'] ?? 0;
                  final duracion = service['duracionMin'] ?? 0;
                  final descripcion = service['descripcion'] ?? '';
                  
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                serviceName,
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.gold, AppColors.gold.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$$precio',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (descripcion.isNotEmpty) ...[
                          SizedBox(height: 6),
                          Text(
                            descripcion,
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.gray, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '$duracion min',
                              style: TextStyle(color: AppColors.gray, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSchedulesSection() {
    print('🔍 _buildSchedulesSection - Schedules Count: ${schedules.length}');
    print('🔍 Schedules Data: $schedules');
    
    if (schedules.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.charcoal.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.schedule, color: AppColors.gray, size: 30),
              SizedBox(height: 8),
              Text(
                'No hay horarios configurados.',
                style: TextStyle(color: AppColors.gray, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final dayNames = {
      'LUNES': 'Lunes',
      'MARTES': 'Martes',
      'MIERCOLES': 'Miércoles',
      'JUEVES': 'Jueves',
      'VIERNES': 'Viernes',
      'SABADO': 'Sábado',
      'DOMINGO': 'Domingo',
      1: 'Lunes',
      2: 'Martes',
      3: 'Miércoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sábado',
      0: 'Domingo',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: schedules.map<Widget>((schedule) {
          try {
            final dayOfWeek = schedule['dayOfWeek'];
            final dayName = (dayNames[dayOfWeek] ?? dayNames[int.tryParse(dayOfWeek.toString()) ?? 0] ?? 'Día $dayOfWeek');
            final slotsData = schedule['slots'] ?? [];
            final slots = (slotsData is List) ? slotsData : [];
            
            print('📅 Processing Schedule: dayOfWeek=$dayOfWeek, dayName=$dayName, slotsCount=${slots.length}');
            
            return Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.gold.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      dayName,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: slots.isEmpty
                        ? Text(
                            'Sin horario',
                            style: TextStyle(color: AppColors.gray, fontSize: 12),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: slots.map<Widget>((slot) {
                              final start = slot['start']?.toString() ?? '';
                              final end = slot['end']?.toString() ?? '';
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: AppColors.gold.withOpacity(0.4),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  '$start - $end',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            );
          } catch (e) {
            print('❌ Error building schedule item: $e');
            return SizedBox.shrink();
          }
        }).toList(),
      ),
    );
  }

  Widget _buildSlotsSection() {
    if (slots.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.charcoal.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No hay slots disponibles actualmente.',
            style: TextStyle(color: AppColors.gray),
          ),
        ),
      );
    }

    // Agrupar slots por día
    Map<String, List<dynamic>> slotsByDay = {};
    for (var slot in slots) {
      final dayOfWeek = slot['dayOfWeek']?.toString() ?? 'unknown';
      if (!slotsByDay.containsKey(dayOfWeek)) {
        slotsByDay[dayOfWeek] = [];
      }
      slotsByDay[dayOfWeek]!.add(slot);
    }

    final dayNames = {
      '1': 'Lunes',
      '2': 'Martes',
      '3': 'Miércoles',
      '4': 'Jueves',
      '5': 'Viernes',
      '6': 'Sábado',
      '0': 'Domingo',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: slotsByDay.entries.map<Widget>((entry) {
          final dayOfWeek = entry.key;
          final daySlots = entry.value;
          final dayName = dayNames[dayOfWeek] ?? 'Día $dayOfWeek';
          
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.gold.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: daySlots.map<Widget>((slot) {
                    final start = slot['start'] ?? '';
                    final end = slot['end'] ?? '';
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withOpacity(0.3),
                            AppColors.gold.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.gold,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '$start - $end',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showBookingBottomSheet(String stylistName) {
    String? selectedService;
    String? selectedSlot;
    final List<Map<String, dynamic>> availableServices = [];

    // Obtener servicios del estilista
    for (var catalog in catalogs) {
      // Verificar que catalog es un Map
      if (catalog is! Map<String, dynamic>) {
        print('⚠️ Catalog no es un Map: ${catalog.runtimeType}');
        continue;
      }
      
      final services = catalog['services'] ?? [];
      // Verificar que services es una Lista
      if (services is! List) {
        print('⚠️ Services no es una Lista: ${services.runtimeType}');
        continue;
      }
      
      for (var service in services) {
        if (service is Map<String, dynamic>) {
          availableServices.add({
            ...service,
            'catalogName': catalog['nombre'] ?? 'Catálogo'
          });
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.charcoal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isBooking = false;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reservar Cita',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Con $stylistName',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.gray),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Seleccionar Servicio
                  Text(
                    'Seleccionar Servicio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.charcoal.withOpacity(0.5),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        'Elige un servicio',
                        style: TextStyle(color: AppColors.gray),
                      ),
                      value: selectedService,
                      dropdownColor: AppColors.charcoal,
                      style: TextStyle(color: AppColors.gold),
                      underline: SizedBox(),
                      items: availableServices.map<DropdownMenuItem<String>>((service) {
                        final serviceName = service['nombre'] ?? 'Servicio';
                        final precio = service['precio'] ?? 0;
                        final catalogName = service['catalogName'] ?? '';
                        final serviceId = service['_id'] ?? service['id'] ?? '';
                        
                        return DropdownMenuItem<String>(
                          value: serviceId,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      serviceName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: AppColors.gold),
                                    ),
                                    Text(
                                      catalogName,
                                      style: TextStyle(
                                        color: AppColors.gray,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$$precio',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedService = value;
                          selectedSlot = null; // Reset slot when service changes
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 24),

                  // Seleccionar Slot (solo si hay servicio seleccionado)
                  if (selectedService != null) ...[
                    Text(
                      'Seleccionar Disponibilidad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (slots.isEmpty)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'No hay slots disponibles en este momento',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.charcoal.withOpacity(0.5),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text(
                            'Elige un horario',
                            style: TextStyle(color: AppColors.gray),
                          ),
                          value: selectedSlot,
                          dropdownColor: AppColors.charcoal,
                          style: TextStyle(color: AppColors.gold),
                          underline: SizedBox(),
                          items: slots.map<DropdownMenuItem<String>>((slot) {
                            final start = slot['start'] ?? '';
                            final end = slot['end'] ?? '';
                            final dayOfWeek = slot['dayOfWeek']?.toString() ?? '';
                            final slotId = slot['_id'] ?? slot['id'] ?? '$start-$end';
                            final dayNames = {
                              '1': 'Lunes',
                              '2': 'Martes',
                              '3': 'Miércoles',
                              '4': 'Jueves',
                              '5': 'Viernes',
                              '6': 'Sábado',
                              '0': 'Domingo',
                            };
                            final dayName = dayNames[dayOfWeek] ?? 'Día $dayOfWeek';
                            
                            return DropdownMenuItem<String>(
                              value: slotId,
                              child: Text(
                                '$dayName - $start a $end',
                                style: TextStyle(color: AppColors.gold),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSlot = value;
                            });
                          },
                        ),
                      ),
                    SizedBox(height: 24),
                  ],

                  // Resumen de la reserva
                  if (selectedService != null && selectedSlot != null) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de la Cita',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildSummaryRow('Estilista:', stylistName),
                          _buildSummaryRow(
                            'Servicio:',
                            availableServices
                                .firstWhere(
                                  (s) => (s['_id'] ?? s['id']) == selectedService,
                                  orElse: () => {},
                                )['nombre'] ??
                                'Servicio',
                          ),
                          _buildSummaryRow(
                            'Horario:',
                            () {
                              final slot = slots.firstWhere(
                                (s) => (s['_id'] ?? s['id'] ?? '${s['start']}-${s['end']}') == selectedSlot,
                                orElse: () => {},
                              );
                              return slot.isEmpty ? 'Horario' : '${slot['start']} a ${slot['end']}';
                            }(),
                          ),
                          _buildSummaryRow(
                            'Precio:',
                            '\$${availableServices.firstWhere((s) => (s['_id'] ?? s['id']) == selectedService, orElse: () => {})['precio'] ?? 0}',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Botón de Reservar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppColors.gray.withOpacity(0.3),
                      ),
                      onPressed: (selectedService == null || selectedSlot == null || isBooking)
                          ? null
                          : () async {
                              setState(() => isBooking = true);
                              await _createBooking(
                                ctx,
                                selectedService!,
                                selectedSlot!,
                                stylistName,
                              );
                              setState(() => isBooking = false);
                            },
                      icon: isBooking
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.check_circle, size: 20),
                      label: Text(
                        isBooking ? 'Creando cita...' : 'Confirmar Reserva',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBooking(
    BuildContext context,
    String serviceId,
    String slotId,
    String stylistName,
  ) async {
    try {
      final bookingsApi = BookingsApi(ApiClient.instance);
      
      // Encontrar el slot completo
      final selectedSlotData = slots.firstWhere(
        (s) => (s['_id'] ?? s['id'] ?? '${s['start']}-${s['end']}') == slotId,
        orElse: () => {},
      );

      if (selectedSlotData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No se encontró el slot seleccionado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final bookingData = {
        'stylistId': stylistId,
        'serviceId': serviceId,
        'slotId': slotId,
        'dayOfWeek': selectedSlotData['dayOfWeek']?.toString() ?? '0',
        'startTime': selectedSlotData['start'] ?? '',
        'endTime': selectedSlotData['end'] ?? '',
        'status': 'pending',
      };

      print('📋 Creando reserva con datos: $bookingData');

      final response = await bookingsApi.createBooking(bookingData, token: token);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ¡Cita reservada exitosamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        // Opcionalmente, navegar a la página de historial de citas
        // Navigator.pushNamed(context, '/bookings');
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Error al crear la cita';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error al crear booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
