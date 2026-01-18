import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../api/slots_api.dart';

/// Diálogo para que el estilista modifique su propio horario
/// Solo puede editar su horario, no el de otros estilistas
class StylistScheduleDialog extends StatefulWidget {
  final String token;
  final String stylistId;
  final SlotsApi slotsApi;

  const StylistScheduleDialog({
    super.key,
    required this.token,
    required this.stylistId,
    required this.slotsApi,
  });

  @override
  State<StylistScheduleDialog> createState() => _StylistScheduleDialogState();
}

class _StylistScheduleDialogState extends State<StylistScheduleDialog> {
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;
  String? errorMsg;

  // Días de la semana numerados (1-7, donde 1 = Monday)
  final Map<int, String> daysOfWeek = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      setState(() {
        isLoading = true;
        errorMsg = null;
      });

      final response = await widget.slotsApi.getStylistSchedule(
        token: widget.token,
        stylistId: widget.stylistId,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parsear respuesta - puede ser lista o mapa con propiedad 'data'
        List schedulesList = [];
        if (data is List) {
          schedulesList = data;
        } else if (data is Map && data['data'] != null) {
          schedulesList = data['data'] is List ? data['data'] : [data['data']];
        } else if (data is Map) {
          schedulesList = [data];
        }

        setState(() {
          schedules = List<Map<String, dynamic>>.from(
            schedulesList.whereType<Map>().cast<Map<String, dynamic>>(),
          );
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          if (response.statusCode == 404) {
            errorMsg = 'No tienes horarios registrados aún';
          } else {
            errorMsg = 'Error al cargar horarios (${response.statusCode})';
          }
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = 'Error: $e';
      });
    }
  }

  void _showEditDialog(Map<String, dynamic> schedule) {
    final dayOfWeek = schedule['dayOfWeek'] as int?;
    final slots = List<Map<String, dynamic>>.from(
      (schedule['slots'] ?? []).map((s) => Map<String, dynamic>.from(s)),
    );

    showDialog(
      context: context,
      builder: (ctx) => _EditScheduleDialog(
        dayOfWeek: dayOfWeek ?? 1,
        dayName: daysOfWeek[dayOfWeek] ?? 'Día',
        slots: slots,
        token: widget.token,
        stylistId: widget.stylistId,
        slotsApi: widget.slotsApi,
        onSuccess: () {
          _loadSchedules();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddDayDialog() {
    // Get days that don't have schedules yet
    final usedDays = schedules.map((s) => s['dayOfWeek'] as int).toSet();
    final availableDays = daysOfWeek.keys.where((day) => !usedDays.contains(day)).toList();

    if (availableDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya tienes horarios para todos los días de la semana'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int? selectedDay = availableDays.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text(
          'Agregar Nuevo Día',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selecciona el día de la semana:',
                  style: TextStyle(color: AppColors.gray),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: selectedDay,
                  dropdownColor: AppColors.charcoal,
                  style: TextStyle(color: AppColors.gold),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.gold),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.gold, width: 2),
                    ),
                  ),
                  items: availableDays.map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(daysOfWeek[day] ?? 'Día $day'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDay = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (selectedDay != null) {
                // Open edit dialog with empty slots for the new day
                _showEditDialog({
                  'dayOfWeek': selectedDay,
                  'slots': [],
                });
              }
            },
            child: Text('Continuar', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.charcoal,
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mi Horario',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.gold),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : errorMsg != null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.schedule, color: AppColors.gold, size: 64),
                                SizedBox(height: 16),
                                Text(
                                  errorMsg!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.gray, fontSize: 16),
                                ),
                                SizedBox(height: 24),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: AppColors.charcoal,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  icon: Icon(Icons.add),
                                  label: Text('Agregar Primer Horario', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    setState(() => errorMsg = null);
                                    _showAddDayDialog();
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : schedules.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.schedule, color: AppColors.gold, size: 64),
                                    SizedBox(height: 16),
                                    Text(
                                      'No tienes horarios configurados',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.gray, fontSize: 16),
                                    ),
                                    SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.gold,
                                        foregroundColor: AppColors.charcoal,
                                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                      icon: Icon(Icons.add),
                                      label: Text('Agregar Día', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: _showAddDayDialog,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                // Add day button
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: AppColors.charcoal,
                                      minimumSize: Size.fromHeight(40),
                                    ),
                                    icon: Icon(Icons.add, size: 20),
                                    label: Text('Agregar Día', style: TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: _showAddDayDialog,
                                  ),
                                ),
                                // Schedule list
                                Expanded(
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(12),
                                    itemCount: schedules.length,
                                    itemBuilder: (ctx, idx) {
                                      final schedule = schedules[idx];
                                      final dayOfWeek = schedule['dayOfWeek'] as int?;
                                      final dayName = daysOfWeek[dayOfWeek] ?? 'Desconocido';
                                      final slots = List<Map<String, dynamic>>.from(
                                        (schedule['slots'] ?? [])
                                            .map((s) => Map<String, dynamic>.from(s)),
                                      );

                                      return Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade800,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.gold.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  dayName,
                                                  style: TextStyle(
                                                    color: AppColors.gold,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.edit,
                                                      color: AppColors.gold, size: 18),
                                                  onPressed: () =>
                                                      _showEditDialog(schedule),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            ...slots.map((slot) => Padding(
                                              padding: EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                '  ${slot['start']} - ${slot['end']}',
                                                style: TextStyle(
                                                  color: AppColors.gray,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
            ),

            // Footer
            Padding(
              padding: EdgeInsets.all(12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.charcoal,
                  minimumSize: Size.fromHeight(40),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para editar un día específico del horario
class _EditScheduleDialog extends StatefulWidget {
  final int dayOfWeek;
  final String dayName;
  final List<Map<String, dynamic>> slots;
  final String token;
  final String stylistId;
  final SlotsApi slotsApi;
  final VoidCallback onSuccess;

  const _EditScheduleDialog({
    required this.dayOfWeek,
    required this.dayName,
    required this.slots,
    required this.token,
    required this.stylistId,
    required this.slotsApi,
    required this.onSuccess,
  });

  @override
  State<_EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<_EditScheduleDialog> {
  late List<Map<String, dynamic>> editableSlots;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Crear copia de slots para editar
    editableSlots = widget.slots.map((slot) {
      return {
        'start': slot['start'],
        'end': slot['end'],
      };
    }).toList();
  }

  Future<void> _saveChanges() async {
    try {
      if (editableSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes agregar al menos un horario'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => isSaving = true);

      // Validar que las horas sean válidas
      for (var slot in editableSlots) {
        if ((slot['start'] as String).isEmpty || (slot['end'] as String).isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Por favor completa todas las horas'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isSaving = false);
          return;
        }
      }

      final scheduleData = {
        'stylistId': widget.stylistId,
        'dayOfWeek': widget.dayOfWeek,
        'slots': editableSlots,
        'exceptions': [],
      };

      final response = await widget.slotsApi.updateStylistSchedule(
        scheduleData: scheduleData,
        token: widget.token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Horario actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSuccess();
        }
      } else {
        if (mounted) {
          try {
            final errorData = jsonDecode(response.body);
            final errorMsg = errorData['message'] ?? 'Error desconocido';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $errorMsg'),
                backgroundColor: Colors.red,
              ),
            );
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al actualizar (${response.statusCode})'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _selectTime(int slotIndex, bool isStart) async {
    final currentValue = isStart
        ? editableSlots[slotIndex]['start']
        : editableSlots[slotIndex]['end'];

    final timeParts = currentValue.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        final timeString =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          editableSlots[slotIndex]['start'] = timeString;
        } else {
          editableSlots[slotIndex]['end'] = timeString;
        }
      });
    }
  }

  void _addSlot() {
    setState(() {
      editableSlots.add({
        'start': '09:00',
        'end': '17:00',
      });
    });
  }

  void _removeSlot(int index) {
    setState(() {
      editableSlots.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.charcoal,
      title: Text(
        'Editar Horario - ${widget.dayName}',
        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...editableSlots.asMap().entries.map((entry) {
              final idx = entry.key;
              final slot = entry.value;

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Franja ${idx + 1}',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (editableSlots.length > 1)
                          GestureDetector(
                            onTap: () => _removeSlot(idx),
                            child: Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(idx, true),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: AppColors.gold.withOpacity(0.3)),
                              ),
                              child: Text(
                                slot['start'],
                                style: TextStyle(color: AppColors.gold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('-', style: TextStyle(color: AppColors.gold)),
                        SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(idx, false),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: AppColors.gold.withOpacity(0.3)),
                              ),
                              child: Text(
                                slot['end'],
                                style: TextStyle(color: AppColors.gold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.gold),
                ),
                onPressed: _addSlot,
                child: Text(
                  '+ Agregar Franja',
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
            ),
          ],
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
          onPressed: isSaving ? null : _saveChanges,
          child: isSaving
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.charcoal,
                  ),
                )
              : Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
