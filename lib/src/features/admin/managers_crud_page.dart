import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/users_api.dart';
import '../../widgets/search_bar_widget.dart';
import '../../data/services/verification_service.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'admin_constants.dart';
import 'pages/manager_form_page.dart';

class ManagersCrudPage extends StatefulWidget {
  final String token;
  const ManagersCrudPage({super.key, required this.token});

  @override
  State<ManagersCrudPage> createState() => _ManagersCrudPageState();
}

class _ManagersCrudPageState extends State<ManagersCrudPage> {
  List<dynamic> managers = [];
  List<dynamic> filteredManagers = [];
  bool loading = true;
  String filterStatus = 'all'; // 'all', 'active', 'inactive'
  String searchQuery = '';
  late UsersApi _usersApi;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _usersApi = UsersApi(ApiClient.instance);
    _fetchManagers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchManagers() async {
    setState(() { loading = true; });
    try {
      final url = '/api/v1/users?role=${AdminConstants.ROLE_GERENTE}&includeInactive=true';
      print('🔍 Fetching managers from: $url');
      
      final res = await ApiClient.instance.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      print('📊 Response Status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final allUsers = (data is List)
          ? data
          : (data['data'] is List ? data['data'] : []);
        
        // ⚠️ FILTRADO ADICIONAL: Asegurar que SOLO sean gerentes
        final managersList = allUsers.where((user) {
          final role = (user['role'] ?? '').toString().toUpperCase();
          return role == AdminConstants.ROLE_GERENTE;
        }).toList();
        
        print('👥 Total usuarios recibidos: ${allUsers.length}');
        print('👥 Gerentes filtrados: ${managersList.length}');
        
        // Debug: Contar activos e inactivos
        int activos = 0;
        int inactivos = 0;
        if (managersList.isNotEmpty) {
          for (int i = 0; i < managersList.length; i++) {
            final manager = managersList[i];
            final isActive = manager['isActive'] ?? true;
            if (isActive) {
              activos++;
            } else {
              inactivos++;
            }
            print('  [$i] ${manager['nombre']} ${manager['apellido']} - Role: ${manager['role']}, isActive: $isActive');
          }
          print('📈 RESUMEN: $activos activos, $inactivos inactivos');
        }
        
        setState(() {
          managers = managersList;
          _applyFilter();
          loading = false;
        });
      } else {
        print('❌ Error: Status code ${res.statusCode}');
        setState(() { managers = []; loading = false; });
      }
    } catch (e) {
      print('⚠️ Exception: $e');
      setState(() { managers = []; loading = false; });
    }
  }

  void _applyFilter() {
    print('🔍 Aplicando filtro: $filterStatus, búsqueda: $searchQuery');
    print('📊 Total gerentes antes de filtrar: ${managers.length}');
    
    // Primero filtrar por estado
    List<dynamic> result = managers;
    if (filterStatus == 'active') {
      result = managers.where((m) => (m['isActive'] ?? true) == true).toList();
    } else if (filterStatus == 'inactive') {
      result = managers.where((m) => (m['isActive'] ?? true) == false).toList();
    }
    
    // Luego filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((m) {
        final nombre = (m['nombre'] ?? '').toString().toLowerCase();
        final apellido = (m['apellido'] ?? '').toString().toLowerCase();
        final email = (m['email'] ?? '').toString().toLowerCase();
        final telefono = (m['telefono'] ?? '').toString().toLowerCase();
        return nombre.contains(query) || apellido.contains(query) || email.contains(query) || telefono.contains(query);
      }).toList();
    }
    
    setState(() {
      filteredManagers = result;
    });
    
    print('✅ Gerentes después de filtrar: ${filteredManagers.length}');
  }

  Future<void> _createManager(Map<String, dynamic> manager) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.post(
        '/api/v1/users',
        body: jsonEncode(manager),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        // Enviar email de verificación al gerente
        try {
          await VerificationService.instance.sendVerificationEmail(manager['email']);
          print('✅ Email de verificación enviado a ${manager['email']}');
        } catch (e) {
          print('⚠️ No se pudo enviar email de verificación: $e');
          // Continuar aunque falle el email
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gerente creado exitosamente'), backgroundColor: Colors.green));
        await _fetchManagers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear gerente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _editManager(String id, Map<String, dynamic> manager) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.put(
        '/api/v1/users/$id/profile',
        body: jsonEncode(manager),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        print('✅ Gerente actualizado en servidor: 200');
        
        // HOT RELOAD: Actualizar lista local inmediatamente
        final index = managers.indexWhere((m) => m['_id'] == id);
        if (index != -1) {
          setState(() {
            // Actualizar campos en lista local
            managers[index] = {...managers[index], ...manager};
            print('🔄 Lista local actualizada para gerente $id');
            _applyFilter();
            loading = false;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gerente actualizado exitosamente'), backgroundColor: Colors.green)
        );
        
        // Recargar desde servidor en background para sincronizar
        _fetchManagers().then((_) => print('🔃 Datos sincronizados con servidor'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar gerente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _toggleManagerStatus(String id, bool currentStatus) async {
    try {
      print('🔄 Cambiando estado de gerente $id');
      print('   Estado actual: $currentStatus');
      print('   Nuevo estado: ${!currentStatus}');
      
      final res = await _usersApi.updateUserStatus(
        id,
        !currentStatus,
        token: widget.token,
      );
      
      print('📡 Respuesta del servidor: ${res.statusCode}');
      print('📋 Body: ${res.body}');
      
      if (res.statusCode == 200) {
        // Hot reload - actualizar lista sin spinner
        final index = managers.indexWhere((m) => m['_id'] == id);
        if (index != -1) {
          setState(() {
            managers[index]['isActive'] = !currentStatus;
            print('✅ Estado actualizado localmente: ${managers[index]['isActive']}');
            _applyFilter();
          });
        } else {
          print('⚠️ No se encontró el gerente en la lista local');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? '✅ Gerente activado' : '❌ Gerente desactivado'),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Error: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error toggling manager status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showManagerForm({Map<String, dynamic>? manager, required bool isEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagerFormPage(
          token: widget.token,
          manager: manager,
          isEdit: isEdit,
          onSave: (data) async {
            if (isEdit && manager != null) {
              await _editManager(manager['_id'], data);
            } else {
              await _createManager(data);
            }
          },
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final int activeCount = managers.where((m) => (m['isActive'] ?? true) == true).length;
    final int inactiveCount = managers.where((m) => (m['isActive'] ?? true) == false).length;
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Gerentes', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: EdgeInsets.all(16),
            child: SearchBarWidget(
              controller: searchController,
              placeholder: 'Buscar por nombre, correo o teléfono...',
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
                _buildFilterChip('Todos', 'all', managers.length),
                _buildFilterChip('Activos', 'active', activeCount),
                _buildFilterChip('Inactivos', 'inactive', inactiveCount),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : filteredManagers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_center_outlined, size: 64, color: AppColors.gray),
                            SizedBox(height: 16),
                            Text(
                              'No hay gerentes en esta categoría',
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
                              childAspectRatio: 2.0,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredManagers.length,
                            itemBuilder: (context, i) => _buildManagerCard(filteredManagers[i]),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredManagers.length,
                            itemBuilder: (context, i) => _buildManagerCard(filteredManagers[i]),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        icon: Icon(Icons.add, color: Colors.black),
        label: Text('Nuevo Gerente', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () => _showManagerForm(isEdit: false),
      ),
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

  Widget _buildManagerCard(Map<String, dynamic> m) {
    final isActive = m['isActive'] ?? true;
    
    return Card(
      elevation: 4,
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar con icono
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gold, AppColors.gold.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.business_center, color: Colors.black, size: 28),
                ),
                SizedBox(width: 16),
                // Nombre y status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${m['nombre'] ?? ''} ${m['apellido'] ?? ''}',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? Colors.green : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: isActive ? Colors.green : Colors.orange,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isActive ? 'Activo' : 'Inactivo',
                                  style: TextStyle(
                                    color: isActive ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'GERENTE',
                              style: TextStyle(
                                color: Colors.purple.shade300,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Información de contacto
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email, m['email'] ?? 'N/A'),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.phone, m['telefono'] ?? 'N/A'),
                  if (m['cedula'] != null && m['cedula'].toString().isNotEmpty) ...[
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.badge, m['cedula']),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16),
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.edit, color: Colors.black, size: 20),
                    label: Text(
                      'Editar',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _showManagerForm(manager: m, isEdit: true),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.orange,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: isActive ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                    onPressed: () => _toggleManagerStatus(m['_id'], isActive),
                    tooltip: isActive ? 'Desactivar' : 'Activar',
                  ),
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
        Icon(icon, color: AppColors.gold, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.gray, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
