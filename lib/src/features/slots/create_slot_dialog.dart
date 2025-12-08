import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../api/api_client.dart';
import '../../api/slots_api.dart';

class CreateSlotDialog extends StatefulWidget {
  final SlotsApi slotsApi;
  final String token;
  final String? initialStylistId;
  final String userRole;

  const CreateSlotDialog({super.key, 
    required this.slotsApi,
    required this.token,
    this.initialStylistId,
    required this.userRole,
  });

  @override
  State<CreateSlotDialog> createState() => _CreateSlotDialogState();
}

class _CreateSlotDialogState extends State<CreateSlotDialog> {
  // Stylists
  List<Map<String, dynamic>> stylists = [];
  String? selectedStylistId;
  bool isLoadingStylists = true;

  // Services
  List<Map<String, dynamic>> services = [];
  String? selectedServiceId;
  bool isLoadingServices = false;

  // Schedule
  late String selectedDay;
  late TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay endTime = TimeOfDay(hour: 17, minute: 0);
  Map<String, dynamic>? existingSchedule;
  bool hasExistingSchedule = false;

  bool isCreating = false;
  String? errorMsg;

  final Map<String, String> daysOfWeek = {
    'Lunes': 'LUNES',
    'Martes': 'MARTES',
    'Miércoles': 'MIERCOLES',
    'Jueves': 'JUEVES',
    'Viernes': 'VIERNES',
    'Sábado': 'SABADO',
    'Domingo': 'DOMINGO',
  };

  @override
  void initState() {
    super.initState();
    selectedDay = 'Lunes';
    selectedStylistId = widget.initialStylistId;
    _loadStylists();
    print('🟦 CreateSlotDialog INIT:');
    print('  - initialStylistId: ${widget.initialStylistId}');
    print('  - token: ${widget.token.substring(0, 20)}...');
    print('  - userRole: ${widget.userRole}');
  }


  Future<void> _loadStylists() async {
    try {
      print('📋 Cargando estilistas...');
      setState(() {
        isLoadingStylists = true;
        errorMsg = null;
      });

      final response = await ApiClient.instance.get(
        '/api/v1/stylists',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('📥 Decoded data type: ${data.runtimeType}');
          print('📥 Decoded data: $data');
          
          List stylistsList = [];
          
          if (data is List) {
            print('✅ Data es List directa');
            stylistsList = data;
          } else if (data is Map && data['data'] != null) {
            print('✅ Data es Map con propiedad "data"');
            final dataField = data['data'];
            print('   - data["data"] type: ${dataField.runtimeType}');
            print('   - data["data"] value: $dataField');
            
            if (dataField is List) {
              print('   - Es una List');
              stylistsList = dataField;
            } else if (dataField is Map) {
              print('   - Es un Map individual, envolviendo en lista');
              stylistsList = [dataField];
            }
          } else if (data is Map) {
            print('✅ Data es Map sin propiedad "data"');
            stylistsList = [data];
          }

          print('✅ Estilistas a procesar: ${stylistsList.length}');
          print('✅ Contenido: $stylistsList');

          setState(() {
            stylists = List<Map<String, dynamic>>.from(
              stylistsList.map((s) {
                print('   Procesando: ${s.runtimeType} = $s');
                return s is Map ? s : {};
              })
            );
            
            print('✅ Stylists lista final: ${stylists.length} elementos');
            for (int i = 0; i < stylists.length; i++) {
              print('   [$i] ${stylists[i]['nombre']} - ID: ${stylists[i]['_id']}');
            }
            
            // Si no hay stylistId inicial, seleccionar el primero
            if (selectedStylistId == null && stylists.isNotEmpty) {
              selectedStylistId = stylists[0]['_id'];
              print('✅ Stylist seleccionado por defecto: $selectedStylistId');
            }
            
            isLoadingStylists = false;
          });

          // Cargar servicios y horarios existentes si hay stylist seleccionado
          if (selectedStylistId != null) {
            await _loadServicesAndSchedule();
          }
        } catch (parseError, st) {
          print('❌ ERROR al parsear JSON: $parseError');
          print('Stack: $st');
          setState(() {
            isLoadingStylists = false;
            errorMsg = 'Error al parsear respuesta: $parseError';
          });
        }
      } else {
        print('❌ Error al cargar estilistas: ${response.statusCode}');
        setState(() {
          isLoadingStylists = false;
          errorMsg = 'Error al cargar estilistas (${response.statusCode})';
        });
      }
    } catch (e, st) {
      print('❌ Excepción al cargar estilistas: $e');
      print('Stack trace: $st');
      setState(() {
        isLoadingStylists = false;
        errorMsg = 'Error: $e';
      });
    }
  }

  Future<void> _loadServicesAndSchedule() async {
    if (selectedStylistId == null) return;

    try {
      print('📋 Cargando servicios y horarios para: $selectedStylistId');
      setState(() {
        isLoadingServices = true;
        errorMsg = null;
      });

      // Cargar servicios
      final servicesResponse = await ApiClient.instance.get(
        '/api/v1/services?active=true',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('📥 Services Response: ${servicesResponse.statusCode}');

      if (servicesResponse.statusCode == 200) {
        final serviceData = jsonDecode(servicesResponse.body);
        final serviceList = serviceData is List ? serviceData : (serviceData['data'] ?? []);

        print('✅ Servicios recibidos: ${serviceList.length}');

        final newServices = List<Map<String, dynamic>>.from(
          serviceList.map((s) => {
            '_id': s['_id'] ?? s['id'] ?? '',
            'nombre': s['nombre'] ?? s['name'] ?? 'Sin nombre',
          }),
        );

        // Cargar horarios existentes
        final scheduleResponse = await ApiClient.instance.get(
          '/api/v1/schedules/stylist/$selectedStylistId',
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        print('📥 Schedule Response: ${scheduleResponse.statusCode}');

        bool existSchedule = false;
        Map<String, dynamic>? schedule;

        if (scheduleResponse.statusCode == 200) {
          final scheduleData = jsonDecode(scheduleResponse.body);
          final scheduleList = scheduleData is List ? scheduleData : (scheduleData['data'] ?? []);
          
          if (scheduleList.isNotEmpty) {
            schedule = scheduleList[0];
            existSchedule = true;
            print('📅 Horario existente encontrado: ${schedule!['dayOfWeek']}');
          }
        }

        setState(() {
          services = newServices;
          if (services.isNotEmpty) {
            selectedServiceId = services[0]['_id'];
          }
          hasExistingSchedule = existSchedule;
          existingSchedule = schedule;
          isLoadingServices = false;
        });
      } else {
        setState(() {
          isLoadingServices = false;
          errorMsg = 'Error al cargar servicios';
        });
      }
    } catch (e) {
      print('❌ Excepción: $e');
      setState(() {
        isLoadingServices = false;
        errorMsg = 'Error: $e';
      });
    }
  }


  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (picked != null) {
      setState(() {
        startTime = picked;
        if (endTime.hour <= startTime.hour) {
          endTime = TimeOfDay(hour: startTime.hour + 1, minute: 0);
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: endTime,
    );
    if (picked != null && picked.hour > startTime.hour) {
      setState(() => endTime = picked);
    } else if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La hora final debe ser posterior a la inicial'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createSlot() async {
    if (selectedStylistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes seleccionar un estilista'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes seleccionar un servicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isCreating = true;
      errorMsg = null;
    });

    final dayOfWeekUpper = daysOfWeek[selectedDay] ?? 'LUNES';
    final dayStartStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final dayEndStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    final data = {
      'stylistId': selectedStylistId,
      'serviceId': selectedServiceId,
      'dayOfWeek': dayOfWeekUpper,
      'dayStart': dayStartStr,
      'dayEnd': dayEndStr,
    };

    print('🟦 CREATE SLOT - Datos:');
    print('  - stylistId: $selectedStylistId');
    print('  - serviceId: $selectedServiceId');
    print('  - dayOfWeek: $dayOfWeekUpper');
    print('  - dayStart: $dayStartStr');
    print('  - dayEnd: $dayEndStr');

    try {
      final response = await widget.slotsApi.createSlots(data, token: widget.token);

      print('📥 Response: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Horario creado exitosamente');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Horario creado exitosamente'),
              backgroundColor: AppColors.gold,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        print('❌ Error: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ?? 'Error desconocido';
          setState(() => this.errorMsg = 'Error: ${response.statusCode} - $errorMsg');
        } catch (_) {
          setState(() => errorMsg = 'Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Excepción: $e');
      setState(() => errorMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.charcoal,
      title: Text(
        hasExistingSchedule ? 'Modificar Horario Existente' : 'Crear Nuevo Horario',
        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de Estilista
              Text(
                'Selecciona un estilista',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              isLoadingStylists
                  ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : stylists.isEmpty
                      ? Text(
                          'No hay estilistas disponibles',
                          style: TextStyle(color: AppColors.gray),
                        )
                      : DropdownButton<String>(
                          dropdownColor: Colors.grey.shade900,
                          value: selectedStylistId,
                          isExpanded: true,
                          onChanged: (value) async {
                            setState(() {
                              selectedStylistId = value;
                              hasExistingSchedule = false;
                              existingSchedule = null;
                              isLoadingServices = true;
                            });
                            await _loadServicesAndSchedule();
                          },
                          items: stylists
                              .map((stylist) => DropdownMenuItem<String>(
                                    value: stylist['_id'] as String,
                                    child: Text(
                                      '${stylist['nombre']} ${stylist['apellido']}',
                                      style: TextStyle(color: AppColors.gold),
                                    ),
                                  ))
                              .toList(),
                        ),
              SizedBox(height: 16),

              // Mostrar si existe horario previo
              if (hasExistingSchedule && existingSchedule != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Horario existente',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${existingSchedule!['dayOfWeek']}: ${existingSchedule!['dayStart']} - ${existingSchedule!['dayEnd']}',
                        style: TextStyle(color: AppColors.gray, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Puedes modificar los horarios a continuación',
                        style: TextStyle(color: AppColors.gray, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Selector de Servicio
              if (!isLoadingServices) ...[
                Text(
                  'Selecciona un servicio',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                services.isEmpty
                    ? Text('No hay servicios disponibles', style: TextStyle(color: AppColors.gray))
                    : DropdownButton<String>(
                        dropdownColor: Colors.grey.shade900,
                        value: selectedServiceId,
                        isExpanded: true,
                        onChanged: (value) => setState(() => selectedServiceId = value),
                        items: services
                            .map((service) => DropdownMenuItem<String>(
                                  value: service['_id'] as String,
                                  child: Text(
                                    service['nombre'],
                                    style: TextStyle(color: AppColors.gold),
                                  ),
                                ))
                            .toList(),
                      ),
                SizedBox(height: 16),

                // Selector de Día
                Text(
                  'Día de la semana',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                DropdownButton<String>(
                  dropdownColor: Colors.grey.shade900,
                  value: selectedDay,
                  isExpanded: true,
                  onChanged: (value) => setState(() => selectedDay = value ?? 'Lunes'),
                  items: daysOfWeek.keys
                      .map((day) => DropdownMenuItem(
                            value: day,
                            child: Text(day, style: TextStyle(color: AppColors.gold)),
                          ))
                      .toList(),
                ),
                SizedBox(height: 16),

                // Hora inicio
                Text(
                  'Hora de inicio: ${startTime.format(context)}',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _selectStartTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold.withOpacity(0.2),
                    foregroundColor: AppColors.gold,
                    side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                  ),
                  child: Text('Seleccionar Inicio'),
                ),
                SizedBox(height: 16),

                // Hora fin
                Text(
                  'Hora de fin: ${endTime.format(context)}',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _selectEndTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold.withOpacity(0.2),
                    foregroundColor: AppColors.gold,
                    side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                  ),
                  child: Text('Seleccionar Fin'),
                ),
              ] else
                Center(child: CircularProgressIndicator(color: AppColors.gold)),

              // Error message
              if (errorMsg != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    errorMsg!,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: AppColors.gray)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.charcoal,
          ),
          onPressed: isCreating ? null : _createSlot,
          child: isCreating
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : Text(
                  hasExistingSchedule ? 'Modificar' : 'Crear',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
