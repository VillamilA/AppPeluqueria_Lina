import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/business_hours_service.dart';

/// Gestión de horarios por estilista (ADMIN/GERENTE)
class StylistScheduleManagementPage extends StatefulWidget {
  final String token;
  final String stylistId;
  final String stylistName;
  final String userRole; // ADMIN o GERENTE

  const StylistScheduleManagementPage({
    super.key,
    required this.token,
    required this.stylistId,
    required this.stylistName,
    required this.userRole,
  });

  @override
  State<StylistScheduleManagementPage> createState() => _StylistScheduleManagementPageState();
}

class _StylistScheduleManagementPageState extends State<StylistScheduleManagementPage> {
  late Map<int, List<Map<String, dynamic>>> _schedules; // dayOfWeek: [slots]
  bool _loading = true;
  bool _saving = false;
  int? _selectedDay;

  // ✅ BUSINESS HOURS SUPPORT
  late BusinessHoursService _businessHoursService;
  Map<int, BusinessHours>? _businessHours;

  final List<String> _dayNames = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  @override
  void initState() {
    super.initState();
    _schedules = {};
    _businessHoursService = BusinessHoursService();
    _businessHoursService.initialize();
    _fetchStylistSchedules();
    _loadBusinessHours();
  }

  Future<void> _fetchStylistSchedules() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/schedules/stylist/${widget.stylistId}',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('📥 Response Status: ${res.statusCode}');
      print('📋 Response Body (primeros 500 chars): ${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('✅ Data decodificado, tipo: ${data.runtimeType}');
        
        // El backend retorna directamente un array, NO un objeto con "schedules"
        List<dynamic> schedules = [];
        if (data is List) {
          schedules = data;
          print('📊 Data es Array, schedules encontrados: ${schedules.length}');
        } else if (data is Map && data['schedules'] is List) {
          schedules = data['schedules'] as List;
          print('📊 Data es Map con "schedules", schedules encontrados: ${schedules.length}');
        } else {
          print('⚠️ Formato inesperado de data: ${data.runtimeType}');
        }

        setState(() {
          _schedules.clear();
          for (var schedule in schedules) {
            try {
              print('🔍 Procesando schedule: $schedule');
              
              // Convertir dayOfWeek a int - MUY importante
              final dayOfWeekRaw = schedule['dayOfWeek'];
              print('   dayOfWeekRaw: $dayOfWeekRaw (tipo: ${dayOfWeekRaw.runtimeType})');
              
              late int dayOfWeek;
              if (dayOfWeekRaw is int) {
                dayOfWeek = dayOfWeekRaw;
              } else if (dayOfWeekRaw is String) {
                dayOfWeek = int.parse(dayOfWeekRaw);
              } else if (dayOfWeekRaw is double) {
                dayOfWeek = dayOfWeekRaw.toInt();
              } else {
                print('⚠️ dayOfWeek tipo inesperado: ${dayOfWeekRaw.runtimeType}');
                continue;
              }
              
              print('   dayOfWeek convertido: $dayOfWeek (tipo: ${dayOfWeek.runtimeType})');
              
              final slots = (schedule['slots'] as List?)?.map((s) {
                final start = s['start']?.toString() ?? '09:00';
                final end = s['end']?.toString() ?? '10:00';
                return {'start': start, 'end': end};
              }).toList() ?? [];
              
              print('   Slots: ${slots.length}');
              
              _schedules[dayOfWeek] = slots;
              print('✅ Schedule guardado para dayOfWeek=$dayOfWeek');
            } catch (e) {
              print('❌ Error procesando schedule: $e');
              print('   Stack trace: ${StackTrace.current}');
            }
          }
          print('📈 Total schedules guardados: ${_schedules.length}');
          print('   Claves (dayOfWeek): ${_schedules.keys.toList()}');
        });
      } else {
        print('❌ Response status no es 200: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Exception en _fetchStylistSchedules: $e');
      print('   Stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ✅ CARGAR HORARIOS DEL NEGOCIO (Business Hours)
  Future<void> _loadBusinessHours() async {
    try {
      final hours = await _businessHoursService.getBusinessHours();
      if (mounted) {
        setState(() {
          _businessHours = hours;
        });
      }
    } catch (e) {
      print('❌ Error cargando horarios del negocio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron cargar los horarios del negocio'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// ✅ VALIDAR QUE EL HORARIO ESTÉ DENTRO DEL RANGO DEL NEGOCIO
  Future<String?> _validateTimeRangeWithBusinessHours(
    int dayOfWeek,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    if (_businessHours == null) {
      return '❌ Error: Horarios del negocio no cargados';
    }

    final businessHour = _businessHours![dayOfWeek];
    if (businessHour == null) {
      return '❌ No hay horario definido para este día';
    }

    // Convertir TimeOfDay a minutos para comparación
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Obtener horarios del negocio
    final openMinutes = int.parse(businessHour.openTime.split(':')[0]) * 60 +
        int.parse(businessHour.openTime.split(':')[1]);
    final closeMinutes = int.parse(businessHour.closeTime.split(':')[0]) * 60 +
        int.parse(businessHour.closeTime.split(':')[1]);

    // Validaciones
    if (startMinutes < openMinutes) {
      return '❌ Antes de apertura (${businessHour.openTime})';
    }
    if (endMinutes > closeMinutes) {
      return '❌ Después de cierre (${businessHour.closeTime})';
    }
    if (startMinutes >= endMinutes) {
      return '❌ Hora final debe ser posterior a la inicial';
    }

    return null; // ✅ Todo válido
  }

  Future<void> _saveScheduleForDay(int dayOfWeek) async {
    final slots = _schedules[dayOfWeek] ?? [];
    
    // ✅ VALIDAR QUE HAYA AL MENOS 1 SLOT
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Debes agregar al menos un horario de trabajo'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // ✅ VALIDAR CADA SLOT CONTRA HORARIOS DEL NEGOCIO
      for (final slot in slots) {
        try {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validationError),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            setState(() => _saving = false);
            return;
          }
        } catch (e) {
          print('❌ Error validando slot: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error validando horario: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _saving = false);
          return;
        }
      }

      // ✅ CONSTRUIR DATOS PARA ENVIAR
      final slotsData = slots.map((s) {
        return {'start': s['start'], 'end': s['end']};
      }).toList();

      final body = {
        'stylistId': widget.stylistId,
        'dayOfWeek': dayOfWeek,
        'slots': slotsData,
        'exceptions': [],
      };

      print('📤 Guardando horario:');
      print('   stylistId: ${widget.stylistId}');
      print('   dayOfWeek: $dayOfWeek (${_dayNames[dayOfWeek]})');
      print('   slots count: ${slotsData.length}');
      print('   slots data: $slotsData');

      final res = await ApiClient.instance.put(
        '/api/v1/schedules/stylist',
        body: jsonEncode(body),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response: ${res.statusCode}');
      if (res.statusCode != 200) {
        print('📋 Response Body: ${res.body}');
      }

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Horario guardado para ${_dayNames[dayOfWeek]}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (res.statusCode == 400) {
        // Error 400 - Datos inválidos
        String errorMsg = 'Datos inválidos. Verifica los horarios.';
        try {
          final errData = jsonDecode(res.body);
          if (errData['message'] != null) {
            errorMsg = errData['message'].toString();
          }
          if (errData['details'] is List && errData['details'].isNotEmpty) {
            final detail = errData['details'][0];
            if (detail['message'] != null) {
              errorMsg = detail['message'].toString();
            }
          }
        } catch (e) {
          print('Error parsing 400 response: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $errorMsg'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error ${res.statusCode}. Intenta de nuevo.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  void _addSlot(int dayOfWeek) {
    setState(() {
      if (!_schedules.containsKey(dayOfWeek)) {
        _schedules[dayOfWeek] = [];
      }
      _schedules[dayOfWeek]!.add({'start': '09:00', 'end': '10:00'});
    });
  }

  void _removeSlot(int dayOfWeek, int slotIndex) {
    setState(() {
      _schedules[dayOfWeek]!.removeAt(slotIndex);
      if (_schedules[dayOfWeek]!.isEmpty) {
        _schedules.remove(dayOfWeek);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(
          backgroundColor: AppColors.charcoal,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.gold, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Horarios - ${widget.stylistName}', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        ),
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horarios',
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(7, (index) {
            final dayOfWeek = index;
            final dayName = _dayNames[dayOfWeek];
            final hasSchedule = _schedules.containsKey(dayOfWeek);
            final slots = _schedules[dayOfWeek] ?? [];

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasSchedule ? AppColors.gold : Colors.grey[800]!,
                  width: hasSchedule ? 2 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedDay = _selectedDay == dayOfWeek ? null : dayOfWeek;
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                color: hasSchedule ? AppColors.gold : AppColors.gray,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                if (hasSchedule)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${slots.length} slots',
                                      style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                Icon(
                                  _selectedDay == dayOfWeek ? Icons.expand_less : Icons.expand_more,
                                  color: AppColors.gold,
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_selectedDay == dayOfWeek) ...[
                          SizedBox(height: 16),
                          ...List.generate(slots.length, (slotIndex) {
                            final slot = slots[slotIndex];
                            return _buildSlotEditor(dayOfWeek, slotIndex, slot);
                          }),
                          SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold.withOpacity(0.2),
                              foregroundColor: AppColors.gold,
                              minimumSize: Size(double.infinity, 40),
                            ),
                            icon: Icon(Icons.add),
                            label: Text('Agregar slot'),
                            onPressed: () => _addSlot(dayOfWeek),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              minimumSize: Size(double.infinity, 40),
                            ),
                            onPressed: _saving ? null : () => _saveScheduleForDay(dayOfWeek),
                            child: Text(
                              'Guardar',
                              style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSlotEditor(int dayOfWeek, int slotIndex, Map<String, dynamic> slot) {
    // Asegurar que start y end son strings
    final startTime = slot['start']?.toString() ?? '09:00';
    final endTime = slot['end']?.toString() ?? '10:00';
    
    // 🕐 Obtener horarios del negocio para este día
    String businessHourInfo = '';
    if (_businessHours != null && _businessHours![dayOfWeek] != null) {
      final bh = _businessHours![dayOfWeek]!;
      businessHourInfo = 'Negocio: ${bh.openTime} - ${bh.closeTime}';
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🕐 Show business hours info
          if (businessHourInfo.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                businessHourInfo,
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    try {
                      final parts = startTime.split(':');
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        ),
                      );
                      if (time != null) {
                        // ✅ Validar inmediatamente contra horarios del negocio
                        final endParts = endTime.split(':');
                        final endTimeOfDay = TimeOfDay(
                          hour: int.parse(endParts[0]),
                          minute: int.parse(endParts[1]),
                        );
                        
                        final validationError = await _validateTimeRangeWithBusinessHours(
                          dayOfWeek,
                          time,
                          endTimeOfDay,
                        );

                        if (validationError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(validationError),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          slot['start'] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    } catch (e) {
                      print('⚠️ Error parsing start time: $e');
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      startTime,
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text('-', style: TextStyle(color: AppColors.gray)),
              SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    try {
                      final parts = endTime.split(':');
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        ),
                      );
                      if (time != null) {
                        // ✅ Validar inmediatamente contra horarios del negocio
                        final startParts = startTime.split(':');
                        final startTimeOfDay = TimeOfDay(
                          hour: int.parse(startParts[0]),
                          minute: int.parse(startParts[1]),
                        );
                        
                        final validationError = await _validateTimeRangeWithBusinessHours(
                          dayOfWeek,
                          startTimeOfDay,
                          time,
                        );

                        if (validationError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(validationError),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          slot['end'] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    } catch (e) {
                      print('⚠️ Error parsing end time: $e');
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      endTime,
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red, size: 18),
                onPressed: () => _removeSlot(dayOfWeek, slotIndex),
                constraints: BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
