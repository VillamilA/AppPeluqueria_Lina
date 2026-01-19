import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../api/slots_api.dart';
import '../../core/theme/app_theme.dart';
import '../../services/business_hours_service.dart';

/// Hub de gestión de horarios para estilistas
/// Accesible por: ESTILISTA (su propio), ADMIN, GERENTE
class ScheduleHubPage extends StatefulWidget {
  final String token;
  final String stylistId;
  final String stylistName;
  final String userRole; // ESTILISTA, ADMIN, GERENTE

  const ScheduleHubPage({
    super.key,
    required this.token,
    required this.stylistId,
    required this.stylistName,
    required this.userRole,
  });

  @override
  State<ScheduleHubPage> createState() => _ScheduleHubPageState();
}

class _ScheduleHubPageState extends State<ScheduleHubPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Horarios',
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.stylistName,
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.gold, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configura primero el horario de trabajo general y luego los horarios específicos por servicio.',
                      style: TextStyle(color: AppColors.gold.withOpacity(0.8), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Opción 1: Horario de Trabajo General
            _buildOptionCard(
              icon: Icons.schedule,
              title: 'Horario de Trabajo',
              subtitle: 'Define los días y horas disponibles para trabajar',
              description: 'Configura tu disponibilidad general por día de la semana',
              color: AppColors.gold,
              onTap: () => _navigateToWorkSchedule(),
            ),
            
            SizedBox(height: 20),
            
            // Opción 2: Horarios por Servicio
            _buildOptionCard(
              icon: Icons.content_cut,
              title: 'Horarios por Servicio',
              subtitle: 'Configura horarios específicos para cada servicio',
              description: 'Define en qué horarios ofreces cada servicio del catálogo',
              color: Colors.grey.shade700,
              onTap: () => _navigateToServiceSchedule(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
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
                    Icon(Icons.arrow_forward_ios, color: color, size: 24),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppColors.gold, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          description,
                          style: TextStyle(color: AppColors.gray, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWorkSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkSchedulePage(
          token: widget.token,
          stylistId: widget.stylistId,
          stylistName: widget.stylistName,
          userRole: widget.userRole,
        ),
      ),
    );
  }

  void _navigateToServiceSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceSchedulePage(
          token: widget.token,
          stylistId: widget.stylistId,
          stylistName: widget.stylistName,
          userRole: widget.userRole,
        ),
      ),
    );
  }
}

/// Página para configurar el Horario de Trabajo General
/// PUT /api/v1/schedules/stylist
class WorkSchedulePage extends StatefulWidget {
  final String token;
  final String stylistId;
  final String stylistName;
  final String userRole;

  const WorkSchedulePage({
    super.key,
    required this.token,
    required this.stylistId,
    required this.stylistName,
    required this.userRole,
  });

  @override
  State<WorkSchedulePage> createState() => _WorkSchedulePageState();
}

class _WorkSchedulePageState extends State<WorkSchedulePage> {
  final SlotsApi _slotsApi = SlotsApi(ApiClient.instance);
  late BusinessHoursService _businessHoursService;
  Map<int, BusinessHours>? _businessHours;
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Horarios por día: dayOfWeek (0-6) -> List<{start, end}>
  final Map<int, List<Map<String, TimeOfDay>>> _schedule = {
    1: [], // Lunes
    2: [], // Martes
    3: [], // Miércoles
    4: [], // Jueves
    5: [], // Viernes
    6: [], // Sábado
    0: [], // Domingo
  };

  // Nombres para mostrar al usuario (índice = dayOfWeek numérico)
  final List<String> _dayNames = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  @override
  void initState() {
    super.initState();
    _businessHoursService = BusinessHoursService();
    _businessHoursService.initialize();
    _initializeData();
  }

  /// Carga datos en orden: primero horarios del negocio, luego schedule del estilista
  Future<void> _initializeData() async {
    try {
      print('📥 [SCHEDULE_HUB] Iniciando carga de datos...');
      
      // 1️⃣ PRIMERO cargar horarios del negocio
      await _loadBusinessHours();
      print('✅ [SCHEDULE_HUB] Horarios del negocio cargados');
      
      // 2️⃣ LUEGO cargar horario actual del estilista
      await _loadCurrentSchedule();
      print('✅ [SCHEDULE_HUB] Horario del estilista cargado');
    } catch (e) {
      print('❌ [SCHEDULE_HUB] Error durante inicialización: $e');
    }
  }

  Future<void> _loadCurrentSchedule() async {
    setState(() => _isLoading = true);
    try {
      final response = await _slotsApi.getStylistSchedule(
        token: widget.token,
        stylistId: widget.stylistId,
      );
      print('📥 Schedule response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // ✅ La respuesta es un ARRAY directo según el .md
        final data = jsonDecode(response.body);
        
        if (data is List) {
          // Parsear cada día en el array
          for (var daySchedule in data) {
            final dayOfWeek = daySchedule['dayOfWeek'] as int?;
            final slots = daySchedule['slots'] as List?;
            if (dayOfWeek != null && slots != null && slots.isNotEmpty) {
              _schedule[dayOfWeek] = slots.map<Map<String, TimeOfDay>>((slot) {
                return {
                  'start': _parseTime(slot['start'] ?? '09:00'),
                  'end': _parseTime(slot['end'] ?? '18:00'),
                };
              }).toList();
            }
          }
          print('✅ Horarios cargados: ${data.length} días con horarios');
        }
      } else if (response.statusCode == 404) {
        print('⚠️ Sin horarios configurados aún');
      }
    } catch (e) {
      print('⚠️ Error loading schedule: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📍 Cargar horarios del negocio
  Future<void> _loadBusinessHours() async {
    try {
      print('📥 [SCHEDULE_HUB] Cargando horarios del negocio...');
      final hours = await _businessHoursService.getBusinessHours();
      setState(() => _businessHours = hours);
      print('✅ [SCHEDULE_HUB] Horarios cargados: ${hours.length} días');
      print('🔍 [SCHEDULE_HUB] Claves del mapa: ${hours.keys.toList()}');
      for (var entry in hours.entries) {
        print('   📌 Día ${entry.key}: ${entry.value.openTime} - ${entry.value.closeTime}');
      }
    } catch (e) {
      print('❌ [SCHEDULE_HUB] Error cargando horarios del negocio: $e');
    }
  }

  TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSchedule(int dayOfWeek) async {
    print('🟢 [SCHEDULE_HUB] ¡LLAMÓ _saveSchedule para día $dayOfWeek!');
    setState(() => _isSaving = true);
    try {
      final slots = _schedule[dayOfWeek]!.map((slot) => {
        'start': _formatTime(slot['start']!),
        'end': _formatTime(slot['end']!),
      }).toList();

      // ✅ VALIDAR CADA SLOT CONTRA HORARIOS DEL NEGOCIO
      for (final slot in slots) {
        print('🔍 [SCHEDULE_HUB] Validando slot: ${slot['start']} - ${slot['end']}');
        
        final startParts = (slot['start'] as String).split(':');
        final endParts = (slot['end'] as String).split(':');
        
        final startTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
        final endTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );

        final validationError = await _validateTimeRangeWithBusinessHours(
          dayOfWeek,
          startTime,
          endTime,
        );

        if (validationError != null) {
          print('❌ [SCHEDULE_HUB] VALIDACIÓN FALLÓ: $validationError');
          if (mounted) {
            _showValidationDialog(
              isSuccess: false,
              message: validationError,
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      }
      
      print('✅ [SCHEDULE_HUB] TODAS LAS VALIDACIONES PASARON, procediendo a guardar...');
      
      // Mostrar mensaje de éxito en validación
      if (mounted) {
        _showValidationDialog(
          isSuccess: true,
          message: 'Validación correcta.\nGuardando horario...',
        );
      }

      // El backend siempre requiere stylistId en el body
      final body = <String, dynamic>{
        'stylistId': widget.stylistId,
        'dayOfWeek': dayOfWeek,
        'slots': slots,
        'exceptions': [],
      };

      print('📤 Saving schedule (Role: ${widget.userRole}): ${jsonEncode(body)}');
      
      final response = await _slotsApi.updateStylistSchedule(
        scheduleData: body,
        token: widget.token,
      );

      print('📥 Response: ${response.statusCode}');
      print('📋 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Horario de ${_dayNames[dayOfWeek]} guardado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error saving schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// ✅ VALIDAR QUE EL HORARIO ESTÉ DENTRO DEL RANGO DEL NEGOCIO
  Future<String?> _validateTimeRangeWithBusinessHours(
    int dayOfWeek,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    print('🔍 [VALIDACIÓN] Iniciando validación para día $dayOfWeek');
    print('🔍 [VALIDACIÓN] _businessHours es null? ${_businessHours == null}');
    print('🔍 [VALIDACIÓN] _businessHours keys: ${_businessHours?.keys.toList()}');
    
    if (_businessHours == null) {
      print('❌ [VALIDACIÓN] ERROR: Horarios del negocio no cargados');
      return '❌ Error: Horarios del negocio no cargados. Intenta recargar la página.';
    }

    final businessHour = _businessHours![dayOfWeek];
    print('🔍 [VALIDACIÓN] businessHour para día $dayOfWeek: $businessHour');
    print('🔍 [VALIDACIÓN] businessHour?.openTime: ${businessHour?.openTime}');
    print('🔍 [VALIDACIÓN] businessHour?.closeTime: ${businessHour?.closeTime}');
    
    if (businessHour == null) {
      print('❌ [VALIDACIÓN] ERROR: El negocio no atiende este día');
      return '❌ El negocio no atiende este día (Mapa vacío o día no configurado)';
    }

    // Validar que esté dentro del horario del negocio
    final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    
    final (isValid, errorMessage) = await _businessHoursService.validateStylistHours(
      dayOfWeek: dayOfWeek,
      startTime: startTimeStr,
      endTime: endTimeStr,
    );

    print('🔍 [VALIDACIÓN] Resultado: isValid=$isValid, error=$errorMessage');
    return isValid ? null : errorMessage;
  }

  /// Muestra un diálogo de validación en el centro de la pantalla
  void _showValidationDialog({
    required bool isSuccess,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Auto-cerrar después de 3 segundos
        Future.delayed(Duration(seconds: 3), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade700,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isSuccess
                    ? [Colors.green.shade600, Colors.green.shade700]
                    : [Colors.red.shade700, Colors.red.shade800],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono grande
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                // Título
                Text(
                  isSuccess ? '✅ Éxito' : '❌ Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                // Mensaje
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horario de Trabajo',
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.stylistName,
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Sección: RESUMEN DE HORARIOS ACTUALES
                _buildCurrentScheduleSummary(),
                SizedBox(height: 24),
                // Sección: EDITAR HORARIOS
                Text(
                  'Editar Horarios por Día',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                ..._buildAllDayCards(),
              ],
            ),
    );
  }

  Widget _buildDayCard(int dayOfWeek) {
    final slots = _schedule[dayOfWeek] ?? [];
    final hasSlots = slots.isNotEmpty;

    return Card(
      color: Colors.grey.shade900,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: hasSlots ? AppColors.gold.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            hasSlots ? Icons.check_circle : Icons.schedule,
            color: hasSlots ? AppColors.gold : AppColors.gray,
          ),
        ),
        title: Text(
          _dayNames[dayOfWeek],
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          hasSlots
              ? slots.map((s) => '${_formatTime(s['start']!)} - ${_formatTime(s['end']!)}').join(', ')
              : 'Sin horario configurado',
          style: TextStyle(color: AppColors.gray, fontSize: 12),
        ),
        iconColor: AppColors.gold,
        collapsedIconColor: AppColors.gray,
        children: [
          // Lista de slots
          if (slots.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No trabaja este día',
                style: TextStyle(color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...slots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    // Hora inicio
                    Expanded(
                      child: _buildTimeButton(
                        label: 'Inicio',
                        time: slot['start']!,
                        onTap: () async {
                          final time = await _showTimePicker(slot['start']!);
                          if (time != null) {
                            setState(() => _schedule[dayOfWeek]![index]['start'] = time);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: AppColors.gray, size: 16),
                    SizedBox(width: 8),
                    // Hora fin
                    Expanded(
                      child: _buildTimeButton(
                        label: 'Fin',
                        time: slot['end']!,
                        onTap: () async {
                          final time = await _showTimePicker(slot['end']!);
                          if (time != null) {
                            setState(() => _schedule[dayOfWeek]![index]['end'] = time);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    // Eliminar
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _schedule[dayOfWeek]!.removeAt(index));
                      },
                    ),
                  ],
                ),
              );
            }),
          
          SizedBox(height: 12),
          
          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: BorderSide(color: AppColors.gold),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(Icons.add),
                  label: Text('Agregar Horario'),
                  onPressed: () {
                    setState(() {
                      _schedule[dayOfWeek]!.add({
                        'start': TimeOfDay(hour: 9, minute: 0),
                        'end': TimeOfDay(hour: 18, minute: 0),
                      });
                    });
                  },
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                icon: _isSaving
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.save, color: Colors.white),
                label: Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _isSaving ? null : () => _saveSchedule(dayOfWeek),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: AppColors.gray, fontSize: 10)),
            SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScheduleSummary() {
    // Contar días con horarios
    int daysWithSchedule = 0;
    List<String> daysWithScheduleNames = [];
    for (int i = 0; i < 7; i++) {
      if (_schedule[i]!.isNotEmpty) {
        daysWithSchedule++;
        daysWithScheduleNames.add(_dayNames[i]);
      }
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withOpacity(0.15), AppColors.gold.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.gold, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Estado Actual',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Si no hay horarios
          if (daysWithSchedule == 0)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sin horarios configurados. Comienza configurando tu disponibilidad.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            // Mostrar días con horarios
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trabajas $daysWithSchedule días a la semana',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final dayOfWeek = index == 6 ? 0 : index + 1;
                    final slots = _schedule[dayOfWeek] ?? [];
                    final isWorking = slots.isNotEmpty;
                    
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isWorking ? AppColors.gold.withOpacity(0.25) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isWorking ? AppColors.gold : Colors.grey.shade700,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dayNames[dayOfWeek].substring(0, 3),
                            style: TextStyle(
                              color: isWorking ? AppColors.gold : AppColors.gray,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          if (isWorking) ...[
                            SizedBox(height: 4),
                            Text(
                              '${slots.length} horario${slots.length > 1 ? 's' : ''}',
                              style: TextStyle(color: AppColors.gold, fontSize: 9),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildAllDayCards() {
    return List.generate(7, (index) {
      final dayOfWeek = index == 6 ? 0 : index + 1;
      return _buildDayCard(dayOfWeek);
    });
  }

  Future<TimeOfDay?> _showTimePicker(TimeOfDay initialTime) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.gold, onSurface: AppColors.gold),
        ),
        child: child!,
      ),
    );
  }
}

/// Página para configurar Horarios por Servicio
/// POST /api/v1/slots/day
class ServiceSchedulePage extends StatefulWidget {
  final String token;
  final String stylistId;
  final String stylistName;
  final String userRole;

  const ServiceSchedulePage({
    super.key,
    required this.token,
    required this.stylistId,
    required this.stylistName,
    required this.userRole,
  });

  @override
  State<ServiceSchedulePage> createState() => _ServiceSchedulePageState();
}

class _ServiceSchedulePageState extends State<ServiceSchedulePage> {
  final SlotsApi _slotsApi = SlotsApi(ApiClient.instance);
  bool _isLoading = true;
  
  List<dynamic> _catalogs = []; // Catálogos asignados al estilista
  List<dynamic> _services = []; // Servicios del catálogo seleccionado
  List<dynamic> _existingSlots = []; // Slots ya creados
  Map<String, List<dynamic>> _slotsByService = {}; // ← NUEVO: Slots agrupados por serviceId
  
  String? _selectedCatalogId;
  String _debugLog = '';  // Para guardar logs en pantalla

  // Nombres para API (mayúsculas como espera POST /api/v1/slots/day)
  final List<String> _dayNames = ['DOMINGO', 'LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO'];
  // Nombres para mostrar al usuario
  final List<String> _dayLabels = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  void _addLog(String message) {
    final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    final logEntry = '[$timestamp] $message';
    
    // ← Actualizar log interno sin setState
    _debugLog += '\n$logEntry';
    if (_debugLog.split('\n').length > 50) {
      _debugLog = _debugLog.split('\n').skip(1).join('\n');
    }
    
    // ← Solo imprimir, NO setState
    print(logEntry);
  }

  @override
  void initState() {
    super.initState();
    // ← Diferir _loadData() hasta después del primer build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Cargar catálogos del estilista
      final catalogsRes = await ApiClient.instance.get(
        '/api/v1/stylists/${widget.stylistId}/catalogs',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      print('📚 Catalogs response: ${catalogsRes.statusCode}');
      print('📋 Body: ${catalogsRes.body}');
      
      if (catalogsRes.statusCode == 200) {
        final data = jsonDecode(catalogsRes.body);
        _catalogs = data is List ? data : (data['catalogs'] ?? data['data'] ?? []);
        print('✅ Catálogos cargados: ${_catalogs.length}');
      }
      
    } catch (e) {
      print('⚠️ Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _loadServicesFromCatalog(String catalogId) async {
    try {
      _addLog('🛠️ Cargando servicios para catálogo: $catalogId');
      
      final servicesRes = await ApiClient.instance.get(
        '/api/v1/catalog/$catalogId/services',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      _addLog('🛠️ Services response: ${servicesRes.statusCode}');
      
      if (servicesRes.statusCode == 200) {
        final data = jsonDecode(servicesRes.body);
        final List<dynamic> services = data is List ? data : (data['services'] ?? data['data'] ?? []);
        
        _addLog('✅ Servicios cargados: ${services.length}');
        
        // Actualizar servicios primero
        if (mounted) {
          setState(() {
            _services = services;
            _slotsByService.clear(); // Limpiar slots previos
          });
        }
        
        // ← Cargar slots para CADA servicio sin setState inmediato
        for (var service in services) {
          final serviceId = service['_id'];
          if (serviceId != null) {
            await _loadSlotsForService(serviceId);
          }
        }
        
        // ← Llamar setState() UNA SOLA VEZ al final para actualizar UI
        if (mounted) {
          setState(() {
            // Los slots ya están en _slotsByService, solo refrescamos UI
          });
        }
        
      } else {
        _addLog('⚠️ Error cargando servicios: ${servicesRes.statusCode}');
      }
    } catch (e) {
      _addLog('⚠️ Error: $e');
    }
  }

  /// ← NUEVO: Cargar slots ESPECÍFICOS para UN servicio
  /// NO llama setState() - eso lo hace _loadServicesFromCatalog()
  Future<void> _loadSlotsForService(String serviceId) async {
    try {
      _addLog('📥 Cargando slots para servicio: $serviceId');
      
      // ← IMPORTANTE: Pasar AMBOS parámetros (stylistId + serviceId)
      final slotsRes = await _slotsApi.getSlots(
        stylistId: widget.stylistId,
        serviceId: serviceId,
        token: widget.token,
      );
      
      if (slotsRes.statusCode == 200) {
        final data = jsonDecode(slotsRes.body);
        
        // Extraer slots (puede estar en 'data' o ser array directo)
        List<dynamic> slots = data is List ? data : (data['data'] ?? data['slots'] ?? []);
        
        _addLog('✅ Slots para servicio $serviceId: ${slots.length}');
        
        // Guardar en el Map agrupado por serviceId (SIN setState)
        _slotsByService[serviceId] = slots;
        
      } else {
        _addLog('⚠️ No hay slots para servicio $serviceId (${slotsRes.statusCode})');
        _slotsByService[serviceId] = [];
      }
    } catch (e) {
      _addLog('⚠️ Error cargando slots de servicio: $e');
      _slotsByService[serviceId] = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horarios por Servicio',
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.stylistName,
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ],
        ),
        actions: [
          // Debug log removido
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _catalogs.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // RESUMEN DE SLOTS CREADOS
                    if (_selectedCatalogId != null) _buildSlotsCreatedSummary(),
                    
                    // Selector de catálogo
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        border: Border(bottom: BorderSide(color: AppColors.gray.withOpacity(0.2))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selecciona un Catálogo',
                            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCatalogId,
                              isExpanded: true,
                              dropdownColor: Colors.grey.shade800,
                              hint: Text('Seleccionar catálogo', style: TextStyle(color: AppColors.gray)),
                              underline: SizedBox(),
                              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.gold),
                              items: _catalogs.map<DropdownMenuItem<String>>((catalog) {
                                return DropdownMenuItem<String>(
                                  value: catalog['_id'],
                                  child: Text(
                                    catalog['nombre'] ?? 'Sin nombre',
                                    style: TextStyle(color: AppColors.gold),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCatalogId = value;
                                  _services = [];
                                });
                                if (value != null) {
                                  _loadServicesFromCatalog(value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de servicios
                    Expanded(
                      child: _selectedCatalogId == null
                          ? Center(
                              child: Text(
                                'Selecciona un catálogo para ver los servicios',
                                style: TextStyle(color: AppColors.gray),
                              ),
                            )
                          : _services.isEmpty
                              ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                              : ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount: _services.length,
                                  itemBuilder: (context, index) => _buildServiceCard(_services[index]),
                                ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: AppColors.gray),
          SizedBox(height: 16),
          Text(
            'No hay catálogos asignados',
            style: TextStyle(color: AppColors.gray, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Asigna catálogos al estilista primero',
            style: TextStyle(color: AppColors.gray.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsCreatedSummary() {
    // ← NUEVO: Contar slots de TODOS los servicios (desde _slotsByService)
    Map<String, int> slotsByDay = {};
    int totalSlots = 0;
    
    // Iterar sobre todos los servicios y sus slots
    for (var serviceSlots in _slotsByService.values) {
      for (var slot in serviceSlots) {
        final dayOfWeek = slot['dayOfWeek'] ?? 0;
        final dayName = dayOfWeek is int 
            ? _dayLabels[dayOfWeek]
            : dayOfWeek.toString();
        
        slotsByDay[dayName] = (slotsByDay[dayName] ?? 0) + 1;
        totalSlots++;
      }
    }
    
    _addLog('📊 Resumen de slots: Total=$totalSlots, Por día: $slotsByDay');

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Slots Creados',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalSlots total',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          if (slotsByDay.isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slotsByDay.entries.map((entry) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        '${entry.value}',
                        style: TextStyle(color: Colors.green, fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ Aún no hay slots creados',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final serviceId = service['_id'];
    final serviceName = service['nombre'] ?? 'Sin nombre';
    final servicePrice = service['precio'] ?? 0;
    final serviceDuration = service['duracionMin'] ?? 0;
    
    // ← NUEVO: Obtener slots de ESTE servicio específico del Map
    final serviceSlots = _slotsByService[serviceId] ?? [];
    
    _addLog('🎯 Service: $serviceName ($serviceId) → ${serviceSlots.length} slots');

    return Card(
      color: Colors.grey.shade900,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.content_cut, color: Colors.purple),
        ),
        title: Text(
          serviceName,
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: EdgeInsets.only(top: 4, right: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '\$$servicePrice',
                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${serviceDuration}min',
                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            if (serviceSlots.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: EdgeInsets.only(top: 4, left: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${serviceSlots.length} horarios',
                  style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        iconColor: AppColors.gold,
        collapsedIconColor: AppColors.gray,
        children: [
          // SECCIÓN: SLOTS EXISTENTES
          if (serviceSlots.isEmpty)
            // Sin slots
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 32),
                  SizedBox(height: 12),
                  Text(
                    'No tienes slots configurados',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Comienza creando tu primer horario disponible para este servicio',
                    style: TextStyle(color: Colors.orange.withOpacity(0.7), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  // DEBUG INFO
                  SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(
                      '🔍 DEBUG INFO',
                      style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service ID: $serviceId',
                              style: TextStyle(color: AppColors.gold, fontSize: 9, fontFamily: 'monospace'),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Total slots en sistema: ${_existingSlots.length}',
                              style: TextStyle(color: Colors.cyan, fontSize: 9),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Slots encontrados para este servicio: ${serviceSlots.length}',
                              style: TextStyle(color: Colors.yellow, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            if (_existingSlots.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                'Primeros slots en sistema:',
                                style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                              ..._existingSlots.take(3).map((s) => Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '• serviceId: ${s['serviceId'] ?? 'NULL'}',
                                  style: TextStyle(color: Colors.red, fontSize: 8, fontFamily: 'monospace'),
                                ),
                              )).toList(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            // Con slots - mostrar desglose por día
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horarios Configurados',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 12),
                ..._buildSlotsByDay(serviceSlots),
              ],
            ),
          
          SizedBox(height: 16),
          
          // BOTÓN: AGREGAR NUEVO HORARIO
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(Icons.add, color: Colors.black),
              label: Text('Agregar Horario', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () => _showAddSlotDialog(service),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlotsByDay(List<dynamic> serviceSlots) {
    // Agrupar slots por día
    Map<String, List<Map<String, dynamic>>> slotsByDay = {};
    
    for (var slot in serviceSlots) {
      // slot tiene: {_id, stylistId, serviceId, dayOfWeek, startTime, endTime, available, ...}
      final dayOfWeek = slot['dayOfWeek'] ?? 'DESCONOCIDO';
      final dayKey = dayOfWeek.toString();
      
      if (!slotsByDay.containsKey(dayKey)) {
        slotsByDay[dayKey] = [];
      }
      
      slotsByDay[dayKey]!.add({
        'id': slot['_id'] ?? '',
        'start': slot['startTime'] ?? '', // startTime (not dayStart)
        'end': slot['endTime'] ?? '',     // endTime (not dayEnd)
        'available': slot['available'] ?? true,
        'full': slot, // guardar slot completo para referencia
      });
    }

    // Ordenar días de la semana
    final dayOrder = ['LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO'];
    final sortedDays = slotsByDay.keys.toList()..sort((a, b) {
      int indexA = dayOrder.indexOf(a);
      int indexB = dayOrder.indexOf(b);
      if (indexA == -1) indexA = 999;
      if (indexB == -1) indexB = 999;
      return indexA.compareTo(indexB);
    });

    // Construir widgets
    return sortedDays.map((day) {
      final slots = slotsByDay[day]!;
      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del día - CLICKEABLE
            GestureDetector(
              onTap: () => _showDayDetailsDialog(day, slots),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${slots.length} slot${slots.length > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Horarios del día
            ...slots.asMap().entries.map((entry) {
              final slot = entry.value;
              final isAvailable = slot['available'] ?? true;
              
              return Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                margin: EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isAvailable 
                    ? Colors.green.withOpacity(0.05)
                    : Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAvailable 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.lock,
                      color: isAvailable ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${slot['start']} - ${slot['end']}',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isAvailable)
                            Text(
                              'OCUPADO',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () => _deleteSlot(slot['id'] ?? ''),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _showAddSlotDialog(Map<String, dynamic> service) async {
    String selectedDay = 'LUNES';
    TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: 18, minute: 0);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.charcoal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add_circle_outline, color: AppColors.gold, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuevo Horario',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        service['nombre'] ?? 'Servicio',
                        style: TextStyle(color: AppColors.gray, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SELECTOR DE DÍA
                  Text(
                    'Selecciona el día de la semana',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black26,
                    ),
                    padding: EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dayNames.map((day) {
                        final isSelected = selectedDay == day;
                        return InkWell(
                          onTap: () {
                            setDialogState(() => selectedDay = day);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.gold.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.gold : Colors.grey.shade700,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              day.substring(0, 3),
                              style: TextStyle(
                                color: isSelected ? AppColors.gold : AppColors.gray,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // HORAS
                  Text(
                    'Rango horario',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      // Inicio
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Desde',
                              style: TextStyle(color: AppColors.gray, fontSize: 11),
                            ),
                            SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: startTime,
                                  builder: (ctx, child) => Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(primary: AppColors.gold),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (time != null) {
                                  setDialogState(() => startTime = time);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Text(
                                    '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      // Fin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasta',
                              style: TextStyle(color: AppColors.gray, fontSize: 11),
                            ),
                            SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: endTime,
                                  builder: (ctx, child) => Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(primary: AppColors.gold),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (time != null) {
                                  setDialogState(() => endTime = time);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Text(
                                    '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // RESUMEN
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$selectedDay ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: TextStyle(color: AppColors.gray)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _createSlot(
                    service,
                    selectedDay,
                    startTime,
                    endTime,
                  );
                },
                child: Text('Guardar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createSlot(
    Map<String, dynamic> service,
    String dayOfWeek,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    try {
      // El backend siempre requiere stylistId en el body
      final body = <String, dynamic>{
        'stylistId': widget.stylistId,
        'serviceId': service['_id'],
        'dayOfWeek': dayOfWeek,
        'dayStart': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        'dayEnd': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      };

      print('📤 Creating slot (Role: ${widget.userRole}): ${jsonEncode(body)}');

      final response = await _slotsApi.createSlots(body, token: widget.token);
      
      print('📥 Response: ${response.statusCode}');
      print('📋 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Horario creado para ${service['nombre']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Recargar slots
        setState(() {});
      } else if (response.statusCode == 409) {
        // Conflicto: Ya existe un horario que se cruza
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Ya existe un horario que se cruza con el seleccionado';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $errorMessage'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        // Recargar slots para mostrar el estado actual
        setState(() {});
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating slot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    try {
      final response = await _slotsApi.deleteSlot(slotId, token: widget.token);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Horario eliminado'), backgroundColor: Colors.green),
        );
        setState(() {});
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting slot: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showDayDetailsDialog(String day, List<Map<String, dynamic>> slots) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text(
          'Horarios de $day',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total de slots
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text(
                      '${slots.length} slot${slots.length > 1 ? 's' : ''} creado${slots.length > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // Lista de slots
              Text(
                'Detalles:',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 10),
              ...slots.asMap().entries.map((entry) {
                final slot = entry.value;
                final isAvailable = slot['available'] ?? true;
                
                return Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isAvailable 
                      ? Colors.green.withOpacity(0.05)
                      : Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAvailable 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isAvailable 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                isAvailable ? Icons.check : Icons.lock,
                                color: isAvailable ? Colors.green : Colors.red,
                                size: 14,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${slot['start']} - ${slot['end']}',
                                  style: TextStyle(
                                    color: AppColors.gray,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                if (!isAvailable)
                                  Text(
                                    'OCUPADO',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.edit, size: 14),
                              label: Text('Editar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.gold,
                                side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                              ),
                              onPressed: () {
                                // TODO: Implementar editar slot
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Editar slot no implementado aún'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.delete, size: 14),
                              label: Text('Eliminar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red.withOpacity(0.3)),
                              ),
                              onPressed: () {
                                _deleteSlot(slot['id'] ?? '');
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cerrar', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

}
