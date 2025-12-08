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

      print('📋 Cargando horarios del estilista: ${widget.stylistId}');
      
      final response = await ApiClient.instance.get(
        '/api/v1/schedules/stylist/${widget.stylistId}',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scheduleList = data is List ? data : (data['data'] ?? []);

        print('✅ Horarios recibidos: ${scheduleList.length}');

        setState(() {
          schedules = List<Map<String, dynamic>>.from(scheduleList);
          isLoading = false;
        });
      } else {
        print('❌ Error al cargar horarios: ${response.statusCode}');
        setState(() {
          isLoading = false;
          errorMsg = 'Error al cargar horarios (${response.statusCode})';
        });
      }
    } catch (e) {
      print('❌ Excepción al cargar horarios: $e');
      setState(() {
        isLoading = false;
        errorMsg = 'Error: $e';
      });
    }
  }

  Future<void> _deleteSchedule(String scheduleId, String dayOfWeek) async {
    try {
      print('🗑️ Eliminando horario: $scheduleId ($dayOfWeek)');
      
      // Construir URL con query parameters
      final url = '/api/v1/schedules/stylist?stylistId=${widget.stylistId}&dayOfWeek=$dayOfWeek';
      print('📤 DELETE $url');
      
      final response = await ApiClient.instance.delete(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Horario eliminado exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Horario eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSchedules();
      } else {
        print('❌ Error al eliminar: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar horario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Excepción al eliminar: $e');
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
          'Editar Horario - ${schedule['dayOfWeek']}',
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
      print('✏️ Actualizando horario: ${schedule['dayOfWeek']}');

      final payload = {
        'stylistId': widget.stylistId,
        'dayOfWeek': schedule['dayOfWeek'],
        'dayStart': startTime,
        'dayEnd': endTime,
      };

      print('📤 Payload: ${jsonEncode(payload)}');

      final response = await ApiClient.instance.put(
        '/api/v1/schedules/stylist',
        body: jsonEncode(payload),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Horario actualizado exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Horario actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSchedules();
      } else {
        print('❌ Error al actualizar: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar horario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Excepción al actualizar: $e');
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
                              child: Text(
                                'No hay horarios configurados',
                                style: TextStyle(color: AppColors.gray),
                              ),
                            )
                          : ListView.builder(
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
                                            schedule['dayOfWeek'] ?? 'Día desconocido',
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
                                              schedule['dayOfWeek'] ?? '',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
