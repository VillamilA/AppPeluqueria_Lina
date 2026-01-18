import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../api/slots_api.dart';
import '../../api/services_api.dart';
import '../../api/api_client.dart';
import '../../data/models/schedule_models.dart';
import 'dart:convert';

class ScheduleManagementPage extends StatefulWidget {
  final String token;
  final String stylistId;
  final String stylistName;

  const ScheduleManagementPage({
    super.key,
    required this.token,
    required this.stylistId,
    required this.stylistName,
  });

  @override
  State<ScheduleManagementPage> createState() => _ScheduleManagementPageState();
}

class _ScheduleManagementPageState extends State<ScheduleManagementPage> {
  late SlotsApi _slotsApi;
  late ServicesApi _servicesApi;
  
  // PASO 1: Horarios base
  final Map<int, bool> _dayEnabled = {};
  final Map<int, TimeOfDay> _dayStartTime = {};
  final Map<int, TimeOfDay> _dayEndTime = {};
  
  // PASO 2: Slots generados
  List<AvailabilitySlot> _generatedSlots = [];
  String? _selectedServiceId;
  DateTime? _selectedDate;
  
  // Servicios disponibles
  List<dynamic> _services = [];
  bool _loadingServices = true;

  final List<String> _weekdays = [
    'DOMINGO',
    'LUNES',
    'MARTES',
    'MIERCOLES',
    'JUEVES',
    'VIERNES',
    'SABADO'
  ];

  @override
  void initState() {
    super.initState();
    _slotsApi = SlotsApi(ApiClient.instance);
    _servicesApi = ServicesApi(ApiClient.instance);
    _initializeDays();
    _loadServices();
  }

  void _initializeDays() {
    for (int i = 0; i < 7; i++) {
      _dayEnabled[i] = true;
      _dayStartTime[i] = TimeOfDay(hour: 9, minute: 0);
      _dayEndTime[i] = TimeOfDay(hour: 18, minute: 0);
    }
  }

  Future<void> _loadServices() async {
    try {
      print('📋 Cargando servicios...');
      final response = await _servicesApi.listServices(token: widget.token);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 Response type: ${data.runtimeType}');
        print('🔍 Response content: $data');
        
        List<dynamic> servicesList = [];
        
        // Manejar diferentes formatos de respuesta
        if (data is List) {
          // Si es un array directo
          servicesList = data;
        } else if (data is Map) {
          // Si es un objeto con 'data' o 'services'
          if (data.containsKey('data') && data['data'] is List) {
            servicesList = data['data'];
          } else if (data.containsKey('services') && data['services'] is List) {
            servicesList = data['services'];
          }
        }
        
        setState(() {
          _services = servicesList;
          _loadingServices = false;
        });
        print('✅ Servicios cargados: ${_services.length}');
      } else {
        setState(() => _loadingServices = false);
        print('❌ Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error cargando servicios: $e');
      setState(() => _loadingServices = false);
    }
  }

  Future<void> _saveSchedule(int dayOfWeek) async {
    try {
      if (!_dayEnabled[dayOfWeek]!) return;

      final startTime = _dayStartTime[dayOfWeek]!;
      final endTime = _dayEndTime[dayOfWeek]!;

      final scheduleData = {
        'stylistId': widget.stylistId,
        'dayOfWeek': dayOfWeek,
        'slots': [
          {
            'start':
                '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
            'end':
                '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
          }
        ],
      };

      print('💾 Guardando schedule para día $dayOfWeek');

      final response = await _slotsApi.updateStylistSchedule(
        scheduleData: scheduleData,
        token: widget.token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Schedule guardado exitosamente');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Horario guardado: ${_weekdays[dayOfWeek]}'),
              backgroundColor: Colors.green.shade600,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error guardando schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _generateSlots() async {
    try {
      if (_selectedServiceId == null || _selectedDate == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Selecciona servicio y fecha'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      int dayIndex = _selectedDate!.weekday % 7;
      String dayOfWeek = _weekdays[dayIndex];

      final startTime = _dayStartTime[dayIndex];
      final endTime = _dayEndTime[dayIndex];

      if (startTime == null || endTime == null) {
        throw Exception('Horario no configurado para $dayOfWeek');
      }

      final generateRequest = GenerateSlotsRequest(
        stylistId: widget.stylistId,
        serviceId: _selectedServiceId!,
        dayOfWeek: dayOfWeek,
        dayStart:
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        dayEnd:
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      );

      print('🔄 Generando slots...');

      final response = await _slotsApi.createSlots(
        generateRequest.toJson(),
        token: widget.token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final slots = (data['data'] as List?)
            ?.map((s) => AvailabilitySlot.fromJson(s))
            .toList() ?? [];

        if (mounted) {
          setState(() {
            _generatedSlots = slots;
          });

          print('✅ Slots generados: ${slots.length}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${slots.length} espacios generados'),
              backgroundColor: Colors.green.shade600,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error generando slots: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 360;
    final isPhone = size.width < 600;
    
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Gestionar Horarios',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: isSmallPhone ? 18 : 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallPhone ? 12 : 16,
            vertical: isSmallPhone ? 16 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PASO 1: Turno Semanal
              _buildScheduleSection(isSmallPhone, isPhone),
              SizedBox(height: isSmallPhone ? 24 : 32),

              // PASO 2: Generar Disponibilidad
              _buildGenerateSlotSection(isSmallPhone, isPhone),
              SizedBox(height: isSmallPhone ? 24 : 32),

              // Slots Generados
              if (_generatedSlots.isNotEmpty)
                _buildGeneratedSlotsSection(isSmallPhone, isPhone),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSection(bool isSmallPhone, bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isSmallPhone ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallPhone ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.gold.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: Colors.black,
                  size: isSmallPhone ? 20 : 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turno Semanal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallPhone ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Define tu horario base para cada día',
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: isSmallPhone ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallPhone ? 16 : 20),
          
          // Días de la semana
          ..._weekdays.asMap().entries.map((entry) {
            int dayIndex = entry.key;
            String dayName = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: isSmallPhone ? 10 : 12),
              child: _buildDayRow(dayIndex, dayName, isSmallPhone, isPhone),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayRow(int dayIndex, String dayName, bool isSmallPhone, bool isPhone) {
    final isEnabled = _dayEnabled[dayIndex] ?? true;
    final startTime = _dayStartTime[dayIndex] ?? TimeOfDay(hour: 9, minute: 0);
    final endTime = _dayEndTime[dayIndex] ?? TimeOfDay(hour: 18, minute: 0);

    return Container(
      padding: EdgeInsets.all(isSmallPhone ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? AppColors.gold.withOpacity(0.3) : Colors.grey.shade700,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Fila 1: Toggle y Nombre
          Row(
            children: [
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _dayEnabled[dayIndex] = value;
                    });
                  },
                  activeThumbColor: AppColors.gold,
                  inactiveThumbColor: Colors.grey.shade600,
                ),
              ),
              SizedBox(width: 8),
              Text(
                dayName,
                style: TextStyle(
                  color: isEnabled ? Colors.white : AppColors.gray,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallPhone ? 13 : 14,
                ),
              ),
            ],
          ),
          
          if (isEnabled) ...[
            SizedBox(height: isSmallPhone ? 10 : 12),
            // Fila 2: Hora inicio, Hora fin, Botón guardar
            Row(
              children: [
                // Hora Inicio
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (time != null) {
                        setState(() {
                          _dayStartTime[dayIndex] = time;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallPhone ? 10 : 12,
                        vertical: isSmallPhone ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Inicio',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: isSmallPhone ? 10 : 11,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            startTime.format(context),
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: isSmallPhone ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: isSmallPhone ? 8 : 10),
                
                // Hora Fin
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (time != null) {
                        setState(() {
                          _dayEndTime[dayIndex] = time;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallPhone ? 10 : 12,
                        vertical: isSmallPhone ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Fin',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: isSmallPhone ? 10 : 11,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            endTime.format(context),
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: isSmallPhone ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: isSmallPhone ? 8 : 10),
                
                // Botón Guardar
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gold, AppColors.gold.withOpacity(0.85)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _saveSchedule(dayIndex),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallPhone ? 10 : 12),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.black,
                          size: isSmallPhone ? 18 : 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Cerrado',
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: isSmallPhone ? 11 : 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateSlotSection(bool isSmallPhone, bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isSmallPhone ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallPhone ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.gold.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  color: Colors.black,
                  size: isSmallPhone ? 20 : 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generar Disponibilidad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallPhone ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Crea espacios para que reserven',
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: isSmallPhone ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallPhone ? 18 : 22),

          // Fecha
          Text(
            'Fecha a generar:',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallPhone ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: AppColors.gold,
                    size: isSmallPhone ? 18 : 20),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 90)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Selecciona fecha',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? Colors.white
                            : AppColors.gray,
                        fontSize: isSmallPhone ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallPhone ? 16 : 20),

          // Servicio
          Text(
            'Servicio:',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallPhone ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          _loadingServices
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  ),
                )
              : Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedServiceId,
                    hint: Row(
                      children: [
                        Icon(Icons.cut_rounded,
                            color: AppColors.gold, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Selecciona servicio',
                          style: TextStyle(color: AppColors.gray),
                        ),
                      ],
                    ),
                    isExpanded: true,
                    underline: SizedBox(),
                    dropdownColor: Colors.grey.shade900,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallPhone ? 12 : 13,
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedServiceId = value;
                        });
                      }
                    },
                    items: _services.map((service) {
                      final serviceId = service['_id'] ?? '';
                      final serviceName = service['nombre'] ?? 'Sin nombre';
                      final duracion = service['duracionMin'] ?? 0;
                      
                      return DropdownMenuItem<String>(
                        value: serviceId,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.cut_rounded,
                                  color: AppColors.gold, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$serviceName ($duracion min)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallPhone ? 12 : 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
          SizedBox(height: isSmallPhone ? 18 : 24),

          // Botón generar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gold, AppColors.gold.withOpacity(0.85)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _generateSlots,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallPhone ? 14 : 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.black,
                        size: isSmallPhone ? 20 : 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Generar Espacios Disponibles',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallPhone ? 13 : 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedSlotsSection(bool isSmallPhone, bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isSmallPhone ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFFFA726).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFA726).withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFFFFA726), size: isSmallPhone ? 20 : 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Espacios generados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallPhone ? 15 : 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFFFA726).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_generatedSlots.length}',
                  style: TextStyle(
                    color: Color(0xFFFFA726),
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallPhone ? 12 : 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Para ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
            style: TextStyle(
              color: AppColors.gray,
              fontSize: isSmallPhone ? 11 : 12,
            ),
          ),
          SizedBox(height: isSmallPhone ? 14 : 18),
          
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _generatedSlots.length,
            separatorBuilder: (_, __) =>
                SizedBox(height: isSmallPhone ? 8 : 10),
            itemBuilder: (context, index) {
              final slot = _generatedSlots[index];
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallPhone ? 12 : 14,
                  vertical: isSmallPhone ? 12 : 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color(0xFFFFA726).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: AppColors.gold,
                            size: isSmallPhone ? 16 : 18),
                        SizedBox(width: 10),
                        Text(
                          '${slot.start} - ${slot.end}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallPhone ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Color(0xFF4CAF50).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Disponible',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: isSmallPhone ? 10 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
