import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/users_api.dart';
import '../../api/slots_api.dart';
import '../../data/services/verification_service.dart';
import '../../widgets/search_bar_widget.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'pages/stylist_form_page.dart';
import '../slots/schedule_hub_page.dart';

class StylistsCrudPage extends StatefulWidget {
  final String token;
  const StylistsCrudPage({super.key, required this.token});

  @override
  State<StylistsCrudPage> createState() => _StylistsCrudPageState();
}

class _StylistsCrudPageState extends State<StylistsCrudPage> {
  List<dynamic> stylists = [];
  List<dynamic> filteredStylists = [];
  bool loading = true;
  String filterStatus = 'all'; // 'all', 'active', 'inactive'
  String searchQuery = '';
  late TextEditingController searchController;
  late UsersApi _usersApi;
  late SlotsApi _slotsApi;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _usersApi = UsersApi(ApiClient.instance);
    _slotsApi = SlotsApi(ApiClient.instance);
    _fetchStylists();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStylists() async {
    setState(() { loading = true; });
    try {
      // Incluir parámetro para obtener TODOS los estilistas (activos e inactivos)
      final url = '/api/v1/stylists?includeInactive=true';
      print('🔍 Fetching stylists from: $url');
      print('🔑 Token: ${widget.token}');
      
      final res = await ApiClient.instance.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      print('📊 Response Status: ${res.statusCode}');
      print('📋 Response Body (primeros 500 chars): ${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}');
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('✅ Data decoded successfully');
        print('📦 Data type: ${data.runtimeType}');
        
        final allUsers = (data is List)
          ? data
          : (data['data'] is List ? data['data'] : []);
        
        // ⚠️ FILTRADO ADICIONAL: Asegurar que SOLO sean estilistas
        final stylistsList = allUsers.where((user) {
          final role = (user['role'] ?? '').toString().toUpperCase();
          return role == 'ESTILISTA';
        }).toList();
        
        print('👥 Total usuarios recibidos: ${allUsers.length}');
        print('👥 Estilistas filtrados: ${stylistsList.length}');
        
        // Debug: Contar activos e inactivos
        int activos = 0;
        int inactivos = 0;
        if (stylistsList.isNotEmpty) {
          for (int i = 0; i < stylistsList.length; i++) {
            final stylist = stylistsList[i];
            final isActive = stylist['isActive'] ?? true;
            
            // Contar según el estado real
            if (isActive == false) {
              inactivos++;
            } else {
              activos++;
            }
            
            print('  [$i] ${stylist['nombre']} ${stylist['apellido']} - Role: ${stylist['role']}, isActive: $isActive (${isActive.runtimeType})');
          }
          print('📈 RESUMEN: $activos activos, $inactivos inactivos');
        } else {
          print('⚠️ La lista de estilistas está vacía!');
        }
        
        setState(() {
          stylists = stylistsList;
          _applyFilter();
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

  void _applyFilter() {
    print('🔍 Aplicando filtro: $filterStatus, búsqueda: "$searchQuery"');
    print('📊 Total estilistas antes de filtrar: ${stylists.length}');
    
    List<dynamic> temp = stylists;
    
    // Filtrar por estado
    if (filterStatus == 'all') {
      temp = stylists;
    } else if (filterStatus == 'active') {
      temp = stylists.where((s) {
        final isActive = s['isActive'];
        return isActive == true || isActive == null; // Considera null como activo
      }).toList();
    } else if (filterStatus == 'inactive') {
      temp = stylists.where((s) {
        final isActive = s['isActive'];
        return isActive == false; // Solo los explícitamente inactivos
      }).toList();
    }
    
    // Debug: Mostrar cuántos hay en cada categoría
    final activosCount = stylists.where((s) => s['isActive'] != false).length;
    final inactivosCount = stylists.where((s) => s['isActive'] == false).length;
    print('📊 Conteo: $activosCount activos, $inactivosCount inactivos');
    
    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      temp = temp.where((s) {
        final nombre = (s['nombre'] ?? '').toString().toLowerCase();
        final apellido = (s['apellido'] ?? '').toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        final cedula = (s['cedula'] ?? '').toString().toLowerCase();
        
        return nombre.contains(query) || 
               apellido.contains(query) || 
               email.contains(query) || 
               cedula.contains(query);
      }).toList();
    }
    
    setState(() {
      filteredStylists = temp;
    });
    
    print('✅ Estilistas después de filtrar: ${filteredStylists.length}');
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
        final stylistId = responseData['_id'] ?? responseData['id'];
        
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
      
      // Usar endpoint de users para actualizar
      final res = await _usersApi.updateUserComplete(
        id,
        payload,
        token: widget.token,
      );
      
      print('📊 Response status: ${res.statusCode}');
      print('📋 Response body: ${res.body}');
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        print('✅ Estilista actualizada exitosamente');
        
        // HOT RELOAD: Actualizar lista local inmediatamente
        final index = stylists.indexWhere((s) => s['_id'] == id);
        if (index != -1) {
          setState(() {
            // Actualizar campos en lista local
            stylists[index] = {...stylists[index], ...payload};
            print('🔄 Lista local actualizada para estilista $id');
            _applyFilter();
            loading = false;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estilista actualizada exitosamente'), backgroundColor: Colors.green)
        );
        
        // Recargar desde servidor en background para sincronizar
        _fetchStylists().then((_) => print('🔃 Datos sincronizados con servidor'));
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
    try {
      print('🔄 Cambiando estado de estilista $id');
      print('   Estado actual: $currentStatus');
      print('   Nuevo estado: ${!currentStatus}');
      
      final res = currentStatus
          ? await _usersApi.deactivateUser(id, token: widget.token)
          : await _usersApi.activateUser(id, token: widget.token);
      
      print('📡 Respuesta del servidor: ${res.statusCode}');
      print('📋 Body completo: ${res.body}');
      
      if (res.statusCode == 200) {
        // Parsear respuesta para ver qué devuelve el backend
        try {
          final responseData = jsonDecode(res.body);
          print('📦 Response data: $responseData');
          
          // Verificar si el backend devuelve el nuevo estado
          if (responseData is Map && responseData.containsKey('isActive')) {
            print('✅ Backend devolvió isActive: ${responseData['isActive']}');
          }
        } catch (e) {
          print('⚠️ No se pudo parsear la respuesta: $e');
        }
        
        // RECARGAR desde el servidor para asegurar sincronización
        print('🔄 Recargando lista desde el servidor...');
        await _fetchStylists();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? '✅ Estilista activada' : '❌ Estilista desactivada'),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Error: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('❌ Error toggling stylist status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
                          _showSlotManagement(stylist['_id'], stylist['nombre'] ?? 'Estilista');
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

  void _showSlotManagement(String stylistId, String stylistName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleHubPage(
          token: widget.token,
          stylistId: stylistId,
          stylistName: stylistName,
          userRole: 'ADMIN',
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final int activeCount = stylists.where((s) => s['isActive'] == true).length;
    final int inactiveCount = stylists.where((s) => s['isActive'] == false).length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Estilistas', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: EdgeInsets.all(16),
            child: SearchBarWidget(
              controller: searchController,
              placeholder: 'Buscar por nombre, correo o cédula...',
              onSearch: (value) {
                setState(() {
                  searchQuery = value;
                  _applyFilter();
                });
              },
              onClear: () {
                setState(() {
                  searchQuery = '';
                  _applyFilter();
                });
              },
            ),
          ),
          // Filtros
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border(bottom: BorderSide(color: AppColors.gold.withOpacity(0.2))),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildFilterChip('Todos', 'all', stylists.length),
                _buildFilterChip('Activos', 'active', activeCount),
                _buildFilterChip('Inactivos', 'inactive', inactiveCount),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : filteredStylists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 64, color: AppColors.gray),
                            SizedBox(height: 16),
                            Text(
                              'No hay estilistas en esta categoría',
                              style: TextStyle(color: AppColors.gray, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : isTablet
                        ? GridView.builder(
                            padding: EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredStylists.length,
                            itemBuilder: (context, i) => _buildStylistCard(filteredStylists[i]),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredStylists.length,
                            itemBuilder: (context, i) => _buildStylistCard(filteredStylists[i]),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        icon: Icon(Icons.add, color: Colors.black),
        label: Text('Nuevo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () => _showStylistForm(isEdit: false),
      ),
    );
  }

  Widget _buildStylistCard(Map<String, dynamic> s) {
    final isActive = s['isActive'] ?? true;
    
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.gold.withOpacity(0.2)),
      ),
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  child: Icon(Icons.person, color: AppColors.gold),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s['nombre'] ?? ''} ${s['apellido'] ?? ''}',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? Colors.green : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.block,
                                  size: 12,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isActive ? 'Activa' : 'Inactiva',
                                  style: TextStyle(
                                    color: isActive ? Colors.green : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            Divider(color: AppColors.gold.withOpacity(0.2), height: 24),
            
            // Info
            _buildInfoRow(Icons.email, s['email'] ?? 'N/A'),
            
            SizedBox(height: 16),
            
            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Editar',
                  color: AppColors.gold,
                  onPressed: () => _showStylistForm(stylist: s, isEdit: true),
                ),
                _buildActionButton(
                  icon: Icons.schedule,
                  label: 'Horarios',
                  color: AppColors.gold,
                  onPressed: () => _showSlotManagement(s['_id'], s['nombre'] ?? 'Estilista'),
                ),
                _buildActionButton(
                  icon: isActive ? Icons.block : Icons.check_circle,
                  label: isActive ? 'Desactivar' : 'Activar',
                  color: isActive ? Colors.red : Colors.green,
                  onPressed: () => _toggleStylistStatus(s['_id'], isActive),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.gray, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = filterStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          filterStatus = value;
          _applyFilter();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.gray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? AppColors.gold : AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
