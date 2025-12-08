import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/users_api.dart';
import '../../api/slots_api.dart';
import '../../data/services/verification_service.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'pages/stylist_form_page.dart';
import '../slots/slot_management_dialog.dart';

class StylistsCrudPage extends StatefulWidget {
  final String token;
  const StylistsCrudPage({super.key, required this.token});

  @override
  State<StylistsCrudPage> createState() => _StylistsCrudPageState();
}

class _StylistsCrudPageState extends State<StylistsCrudPage> {
  List<dynamic> stylists = [];
  bool loading = true;
  late UsersApi _usersApi;
  late SlotsApi _slotsApi;

  @override
  void initState() {
    super.initState();
    _usersApi = UsersApi(ApiClient.instance);
    _slotsApi = SlotsApi(ApiClient.instance);
    _fetchStylists();
  }

  Future<void> _fetchStylists() async {
    setState(() { loading = true; });
    try {
      final url = '/api/v1/stylists';
      print('🔍 Fetching stylists from: $url');
      print('🔑 Token: ${widget.token}');
      
      final res = await ApiClient.instance.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      print('📊 Response Status: ${res.statusCode}');
      print('📋 Response Body: ${res.body}');
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('✅ Data decoded: $data');
        print('📦 Data type: ${data.runtimeType}');
        
        final stylistsList = (data is List)
          ? data
          : (data['data'] is List ? data['data'] : []);
        
        print('👥 Stylists count: ${stylistsList.length}');
        
        setState(() {
          stylists = stylistsList;
          loading = false;
        });
      } else {
        print('❌ Error: Status code ${res.statusCode}');
        setState(() { stylists = []; loading = false; });
      }
    } catch (e) {
      print('⚠️ Exception: $e');
      setState(() { stylists = []; loading = false; });
    }
  }

  Future<void> _createStylist(Map<String, dynamic> stylist) async {
    setState(() { loading = true; });
    try {
      // Extraer workSchedule antes de enviar
      final Map<String, dynamic> workSchedule = Map<String, dynamic>.from(stylist['workSchedule'] ?? {});
      
      // Crear una copia sin workSchedule para enviar al backend
      final Map<String, dynamic> stylistData = Map<String, dynamic>.from(stylist);
      stylistData.remove('workSchedule');
      
      final res = await ApiClient.instance.post(
        '/api/v1/stylists',
        body: jsonEncode(stylistData),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        // Obtener el ID del estilista creado
        final responseData = jsonDecode(res.body);
        final stylistId = responseData['_id'] ?? responseData['id'] ?? null;
        
        print('✅ Estilista creado con ID: $stylistId');

        // Crear slots si hay workSchedule
        if (workSchedule.isNotEmpty && stylistId != null) {
          await _createWorkSlots(stylistId, workSchedule);
        }

        // Enviar email de verificación al estilista
        try {
          await VerificationService.instance.sendVerificationEmail(stylistData['email']);
          print('✅ Email de verificación enviado a ${stylistData['email']}');
        } catch (e) {
          print('⚠️ No se pudo enviar email de verificación: $e');
          // Continuar aunque falle el email
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estilista creada exitosamente'), backgroundColor: Colors.green));
        await _fetchStylists();
      } else {
        final errorBody = jsonDecode(res.body);
        final errorMsg = errorBody['message'] ?? 'Error al crear estilista';
        print('❌ Error: $errorMsg (Status: ${res.statusCode})');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  /// Crear work slots para cada día del schedule
  Future<void> _createWorkSlots(String stylistId, Map<String, dynamic> workSchedule) async {
    final daysMap = {
      'lunes': 'LUNES',
      'martes': 'MARTES',
      'miercoles': 'MIERCOLES',
      'jueves': 'JUEVES',
      'viernes': 'VIERNES',
      'sabado': 'SABADO',
      'domingo': 'DOMINGO',
    };

    for (final entry in workSchedule.entries) {
      final dayNameLower = entry.key;
      final dayNameUpper = daysMap[dayNameLower] ?? dayNameLower.toUpperCase();
      final timeSlots = entry.value as List<dynamic>;

      for (final timeSlot in timeSlots) {
        final parts = timeSlot.toString().split('-');
        if (parts.length != 2) {
          print('⚠️ Formato inválido: $timeSlot. Esperado: HH:MM-HH:MM');
          continue;
        }

        final dayStart = parts[0].trim();
        final dayEnd = parts[1].trim();

        // Validar formato de hora
        if (!_isValidTimeFormat(dayStart) || !_isValidTimeFormat(dayEnd)) {
          print('⚠️ Formato de hora inválido: $dayStart-$dayEnd. Esperado: HH:MM');
          continue;
        }

        final slotData = {
          'stylistId': stylistId,
          'dayOfWeek': dayNameUpper,
          'dayStart': dayStart,
          'dayEnd': dayEnd,
        };

        try {
          print('📤 Creando slot: ${jsonEncode(slotData)}');
          final slotRes = await _slotsApi.createSlots(
            slotData,
            token: widget.token,
          );

          if (slotRes.statusCode == 201 || slotRes.statusCode == 200) {
            print('✅ Slot creado: $dayNameUpper $dayStart-$dayEnd');
          } else {
            print('❌ Error al crear slot: ${slotRes.statusCode} - ${slotRes.body}');
          }
        } catch (e) {
          print('❌ Error creando slot: $e');
        }
      }
    }
  }

  /// Validar que la hora esté en formato HH:MM
  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^\d{2}:\d{2}$');
    return regex.hasMatch(time);
  }

  Future<void> _editStylist(String id, Map<String, dynamic> data) async {
    setState(() { loading = true; });
    try {
      print('📝 Editando estilista: $id');
      print('🟦 Datos a actualizar: ${data.keys.toList()}');
      
      // Crear payload con SOLO los campos que pueden editarse
      final Map<String, dynamic> payload = {};
      
      // Campos editables
      final editableFields = ['nombre', 'apellido', 'cedula', 'telefono', 'edad', 'genero', 'email'];
      for (final field in editableFields) {
        if (data.containsKey(field)) {
          payload[field] = data[field];
        }
      }
      
      // Password solo si no está vacío
      if (data.containsKey('password') && (data['password'] as String).isNotEmpty) {
        payload['password'] = data['password'];
      }
      
      // Catalogs si están presentes
      if (data.containsKey('catalogs') && data['catalogs'] is List && (data['catalogs'] as List).isNotEmpty) {
        payload['catalogs'] = data['catalogs'];
        print('📋 Actualizando catálogos: ${data['catalogs']}');
      }
      
      print('📤 Payload final: ${payload.keys.toList()}');
      
      final res = await ApiClient.instance.put(
        '/api/v1/stylists/$id',
        body: jsonEncode(payload),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      
      print('📊 Response status: ${res.statusCode}');
      print('📋 Response body: ${res.body}');
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        print('✅ Estilista actualizada exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estilista actualizada exitosamente'), backgroundColor: Colors.green));
        await _fetchStylists();
      } else {
        print('❌ Error al actualizar: ${res.statusCode}');
        try {
          final errorBody = jsonDecode(res.body);
          final errorMsg = errorBody['message'] ?? 'Error al actualizar estilista';
          print('❌ Error message: $errorMsg');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.statusCode}'), backgroundColor: Colors.red));
        }
        setState(() { loading = false; });
      }
    } catch (e) {
      print('❌ Excepción: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _toggleStylistStatus(String id, bool currentStatus) async {
    setState(() { loading = true; });
    try {
      final res = await _usersApi.updateUserStatus(
        id,
        !currentStatus,
        token: widget.token,
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? 'Estilista activada' : 'Estilista desactivada'),
            backgroundColor: AppColors.gold,
          ),
        );
        _fetchStylists();
      }
    } catch (e) {
      print('Error toggling stylist status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { loading = false; });
    }
  }

  void _showStylistForm({Map<String, dynamic>? stylist, required bool isEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StylistFormPage(
          token: widget.token,
          stylist: stylist,
          isEdit: isEdit,
          onSave: (data) async {
            if (isEdit && stylist != null) {
              print('📝 Editando estilista ${stylist['_id']} con datos: ${data.keys.toList()}');
              await _editStylist(stylist['_id'], data);
              
              // Después de editar, preguntar si desea gestionar horarios
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.charcoal,
                    title: Text('Gestionar Horarios', style: TextStyle(color: AppColors.gold)),
                    content: Text('¿Deseas gestionar los horarios de este estilista?', style: TextStyle(color: AppColors.gold)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('No', style: TextStyle(color: AppColors.gray)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showSlotManagement(stylist['_id']);
                        },
                        child: Text('Sí', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }
            } else {
              print('➕ Creando nuevo estilista con datos: ${data.keys.toList()}');
              await _createStylist(data);
            }
          },
        ),
      ),
    );
  }

  void _showSlotManagement(String stylistId) {
    showDialog(
      context: context,
      builder: (ctx) => SlotManagementDialog(
        stylistId: stylistId,
        token: widget.token,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Estilistas', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : stylists.isEmpty
              ? Center(child: Text('No hay estilistas registradas', style: TextStyle(color: AppColors.gray, fontSize: 16)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: stylists.length,
                  itemBuilder: (context, i) {
                    final s = stylists[i];
                    return Card(
                      color: Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${s['nombre'] ?? ''} ${s['apellido'] ?? ''}', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 8),
                            Text('Email: ${s['email'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            Text('Especialización: ${s['especializacion'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Estado', style: TextStyle(color: AppColors.gold, fontSize: 12)),
                                    Switch(
                                      value: s['isActive'] ?? true,
                                      onChanged: (value) => _toggleStylistStatus(s['_id'], s['isActive'] ?? true),
                                      activeThumbColor: Colors.green,
                                      inactiveThumbColor: Colors.grey,
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                                  icon: Icon(Icons.edit, color: Colors.black),
                                  label: Text('Editar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showStylistForm(stylist: s, isEdit: true),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        child: Icon(Icons.add, color: Colors.black),
        onPressed: () => _showStylistForm(isEdit: false),
      ),
    );
  }
}
