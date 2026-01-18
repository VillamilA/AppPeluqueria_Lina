import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../api/api_client.dart';

class SlotManagementDialog extends StatefulWidget {
  final String stylistId;
  final String token;

  const SlotManagementDialog({
    super.key,
    required this.stylistId,
    required this.token,
  });

  @override
  State<SlotManagementDialog> createState() => _SlotManagementDialogState();
}

class _SlotManagementDialogState extends State<SlotManagementDialog> {
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;
  String? errorMsg;

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
      
      final response = await ApiClient.instance.get(
        '/api/v1/schedules/stylist/${widget.stylistId}',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scheduleList = data is List ? data : (data['data'] ?? []);

        setState(() {
          schedules = List<Map<String, dynamic>>.from(scheduleList);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMsg = 'Error al cargar horarios (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = 'Error: $e';
      });
    }
  }

  Future<void> _deleteSchedule(String scheduleId, String dayOfWeek) async {
    try {
      final url = '/api/v1/schedules/stylist?stylistId=${widget.stylistId}&dayOfWeek=$dayOfWeek';
      
      final response = await ApiClient.instance.delete(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Horario eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSchedules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar horario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateDialog() {
    final daysOfWeek = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miércoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sábado',
      7: 'Domingo',
    };

    // Get days that don't have schedules yet
    final usedDays = schedules.map((s) => s['dayOfWeek'] as int?).whereType<int>().toSet();
    final availableDays = daysOfWeek.keys.where((day) => !usedDays.contains(day)).toList();

    if (availableDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya hay horarios para todos los días de la semana'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int? selectedDay = availableDays.first;
    final startTimeCtrl = TextEditingController(text: '09:00');
    final endTimeCtrl = TextEditingController(text: '17:00');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.charcoal,
          title: Text(
            'Crear Nuevo Horario',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedDay,
                dropdownColor: AppColors.charcoal,
                style: TextStyle(color: AppColors.gold),
                decoration: InputDecoration(
                  labelText: 'Día de la Semana',
                  labelStyle: TextStyle(color: AppColors.gold),
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
              SizedBox(height: 16),
              TextField(
                controller: startTimeCtrl,
                style: TextStyle(color: AppColors.gold),
                decoration: InputDecoration(
                  labelText: 'Hora Inicio (HH:MM)',
                  labelStyle: TextStyle(color: AppColors.gold),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: endTimeCtrl,
                style: TextStyle(color: AppColors.gold),
                decoration: InputDecoration(
                  labelText: 'Hora Fin (HH:MM)',
                  labelStyle: TextStyle(color: AppColors.gold),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: AppColors.gray)),
            ),
            TextButton(
              onPressed: () async {
                if (selectedDay == null) return;
                
                await _createSchedule(
                  selectedDay!,
                  startTimeCtrl.text,
                  endTimeCtrl.text,
                );
                if (mounted) Navigator.pop(ctx);
              },
              child: Text('Crear', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSchedule(int dayOfWeek, String startTime, String endTime) async {
    try {
      final payload = {
        'stylistId': widget.stylistId,
        'dayOfWeek': dayOfWeek,
        'dayStart': startTime,
        'dayEnd': endTime,
      };

      final response = await ApiClient.instance.put(
        '/api/v1/schedules/stylist',
        body: jsonEncode(payload),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Horario creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSchedules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear horario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditDialog(Map<String, dynamic> schedule) {
    final startTimeCtrl = TextEditingController(text: schedule['dayStart'] ?? '09:00');
    final endTimeCtrl = TextEditingController(text: schedule['dayEnd'] ?? '17:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text(
          'Editar Horario - ${schedule['dayOfWeek']?.toString() ?? "Desconocido"}',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startTimeCtrl,
              style: TextStyle(color: AppColors.gold),
              decoration: InputDecoration(
                labelText: 'Hora Inicio (HH:MM)',
                labelStyle: TextStyle(color: AppColors.gold),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold, width: 2),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: endTimeCtrl,
              style: TextStyle(color: AppColors.gold),
              decoration: InputDecoration(
                labelText: 'Hora Fin (HH:MM)',
                labelStyle: TextStyle(color: AppColors.gold),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () async {
              await _updateSchedule(
                schedule,
                startTimeCtrl.text,
                endTimeCtrl.text,
              );
              if (mounted) Navigator.pop(ctx);
            },
            child: Text('Actualizar', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSchedule(
    Map<String, dynamic> schedule,
    String startTime,
    String endTime,
  ) async {
    try {
      final payload = {
        'stylistId': widget.stylistId,
        'dayOfWeek': schedule['dayOfWeek'],
        'dayStart': startTime,
        'dayEnd': endTime,
      };

      final response = await ApiClient.instance.put(
        '/api/v1/schedules/stylist',
        body: jsonEncode(payload),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Horario actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSchedules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar horario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.charcoal,
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.gold)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gestionar Horarios',
                    style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold),
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
                  ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : errorMsg != null
                      ? Center(
                          child: Text(
                            errorMsg!,
                            style: TextStyle(color: Colors.red),
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
                                      'No hay horarios configurados',
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
                                      label: Text('Agregar Horario', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: _showCreateDialog,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                // Add button
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: AppColors.charcoal,
                                      minimumSize: Size.fromHeight(40),
                                    ),
                                    icon: Icon(Icons.add, size: 20),
                                    label: Text('Agregar Horario', style: TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: _showCreateDialog,
                                  ),
                                ),
                                // Schedule list
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: schedules.length,
                                    itemBuilder: (ctx, index) {
                                final schedule = schedules[index];
                                return Container(
                                  margin: EdgeInsets.all(8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900,
                                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            schedule['dayOfWeek']?.toString() ?? 'Día desconocido',
                                            style: TextStyle(
                                              color: AppColors.gold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '${schedule['dayStart'] ?? '00:00'} - ${schedule['dayEnd'] ?? '00:00'}',
                                            style: TextStyle(color: AppColors.gray, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: AppColors.gold),
                                            onPressed: () => _showEditDialog(schedule),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteSchedule(
                                              schedule['_id'] ?? '',
                                              schedule['dayOfWeek']?.toString() ?? '',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),                          ),
                        ],
                      ),            ),
          ],
        ),
      ),
    );
  }
}
