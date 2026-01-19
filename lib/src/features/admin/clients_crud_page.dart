import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/users_api.dart';
import '../../data/services/verification_service.dart';
import '../../widgets/search_bar_widget.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'admin_constants.dart';
import 'pages/client_form_page.dart';

class ClientsCrudPage extends StatefulWidget {
  final String token;
  const ClientsCrudPage({super.key, required this.token});

  @override
  State<ClientsCrudPage> createState() => _ClientsCrudPageState();
}

class _ClientsCrudPageState extends State<ClientsCrudPage> {
  List<dynamic> clients = [];
  List<dynamic> filteredClients = [];
  bool loading = true;
  String filterStatus = 'all'; // 'all', 'active', 'inactive'
  String searchQuery = '';
  late TextEditingController searchController;
  late UsersApi _usersApi;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _usersApi = UsersApi(ApiClient.instance);
    _fetchClients();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    setState(() { loading = true; });
    try {
      // Incluir parámetro para obtener TODOS los clientes (activos e inactivos)
      final url = '/api/v1/users?role=${AdminConstants.ROLE_CLIENTE}&includeInactive=true';
      print('🔍 Fetching clients from: $url');
      print('🔑 Token: ${widget.token}');
      print('📌 ROLE_CLIENTE constant: ${AdminConstants.ROLE_CLIENTE}');
      
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
        
        final allUsers = (data is List)
          ? data
          : (data['data'] is List ? data['data'] : []);
        
        // ⚠️ FILTRADO ADICIONAL: Asegurar que SOLO sean clientes
        final clientsList = allUsers.where((user) {
          final role = (user['role'] ?? '').toString().toUpperCase();
          return role == AdminConstants.ROLE_CLIENTE;
        }).toList();
        
        print('👥 Total usuarios recibidos: ${allUsers.length}');
        print('👥 Clientes filtrados: ${clientsList.length}');
        
        // Debug: Mostrar rol de cada usuario
        if (clientsList.isNotEmpty) {
          for (int i = 0; i < clientsList.length; i++) {
            final client = clientsList[i];
            print('  Cliente $i - Nombre: ${client['nombre']} ${client['apellido']}, Role: ${client['role']}, isActive: ${client['isActive']}');
          }
        }
        
        setState(() {
          clients = clientsList;
          _applyFilter();
          loading = false;
        });
      } else {
        print('❌ Error: Status code ${res.statusCode}');
        setState(() { clients = []; loading = false; });
      }
    } catch (e) {
      print('⚠️ Exception: $e');
      setState(() { clients = []; loading = false; });
    }
  }

  void _applyFilter() {
    print('🔍 Aplicando filtro: $filterStatus, búsqueda: "$searchQuery"');
    print('📊 Total clientes antes de filtrar: ${clients.length}');
    
    List<dynamic> temp = clients;
    
    // Filtrar por estado
    if (filterStatus == 'all') {
      temp = clients;
    } else if (filterStatus == 'active') {
      temp = clients.where((c) => (c['isActive'] ?? true) == true).toList();
    } else if (filterStatus == 'inactive') {
      temp = clients.where((c) => (c['isActive'] ?? true) == false).toList();
    }
    
    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      temp = temp.where((c) {
        final nombre = (c['nombre'] ?? '').toString().toLowerCase();
        final apellido = (c['apellido'] ?? '').toString().toLowerCase();
        final email = (c['email'] ?? '').toString().toLowerCase();
        final telefono = (c['telefono'] ?? '').toString().toLowerCase();
        
        return nombre.contains(query) || 
               apellido.contains(query) || 
               email.contains(query) || 
               telefono.contains(query);
      }).toList();
    }
    
    setState(() {
      filteredClients = temp;
    });
    
    print('✅ Clientes después de filtrar: ${filteredClients.length}');
    
    // Debug: Mostrar estado de clientes filtrados
    for (var c in filteredClients) {
      print('  - ${c['nombre']} ${c['apellido']}: isActive = ${c['isActive']}');
    }
  }

  Future<void> _createClient(Map<String, dynamic> client) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.post(
        '/api/v1/users',
        body: jsonEncode(client),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        // Enviar email de verificación al cliente
        try {
          await VerificationService.instance.sendVerificationEmail(client['email']);
          print('✅ Email de verificación enviado a ${client['email']}');
        } catch (e) {
          print('⚠️ No se pudo enviar email de verificación: $e');
          // Continuar aunque falle el email
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cliente creado exitosamente'), backgroundColor: Colors.green));
        await _fetchClients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear cliente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _editClient(String id, Map<String, dynamic> client) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.put(
        '/api/v1/users/$id/profile',
        body: jsonEncode(client),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        print('✅ Cliente actualizado en servidor: 200');
        
        // HOT RELOAD: Actualizar lista local inmediatamente
        final index = clients.indexWhere((c) => c['_id'] == id);
        if (index != -1) {
          setState(() {
            // Actualizar campos en lista local
            clients[index] = {...clients[index], ...client};
            print('🔄 Lista local actualizada para cliente $id');
            _applyFilter();
            loading = false;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente actualizado exitosamente'), backgroundColor: Colors.green)
        );
        
        // Recargar desde servidor en background para sincronizar
        _fetchClients().then((_) => print('🔃 Datos sincronizados con servidor'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar cliente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _toggleClientStatus(String id, bool currentStatus) async {
    try {
      print('🔄 Cambiando estado de cliente $id');
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
        final index = clients.indexWhere((c) => c['_id'] == id);
        if (index != -1) {
          setState(() {
            clients[index]['isActive'] = !currentStatus;
            print('✅ Estado actualizado localmente: ${clients[index]['isActive']}');
            _applyFilter();
          });
        } else {
          print('⚠️ No se encontró el cliente en la lista local');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? '✅ Cliente activado' : '❌ Cliente desactivado'),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Error: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error toggling client status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showClientForm({Map<String, dynamic>? client, required bool isEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormPage(
          token: widget.token,
          client: client,
          isEdit: isEdit,
          onSave: (data) async {
            if (isEdit && client != null) {
              await _editClient(client['_id'], data);
            } else {
              await _createClient(data);
            }
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final int activeCount = clients.where((c) => c['isActive'] == true).length;
    final int inactiveCount = clients.where((c) => c['isActive'] == false).length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Clientes', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
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
                _buildFilterChip('Todos', 'all', clients.length),
                _buildFilterChip('Activos', 'active', activeCount),
                _buildFilterChip('Inactivos', 'inactive', inactiveCount),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : filteredClients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 64, color: AppColors.gray),
                            SizedBox(height: 16),
                            Text(
                              'No hay clientes en esta categoría',
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
                              childAspectRatio: 1.6,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredClients.length,
                            itemBuilder: (context, i) => _buildClientCard(filteredClients[i]),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredClients.length,
                            itemBuilder: (context, i) => _buildClientCard(filteredClients[i]),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        icon: Icon(Icons.add, color: Colors.black),
        label: Text('Nuevo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () => _showClientForm(isEdit: false),
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> c) {
    final isActive = c['isActive'] ?? true;
    
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
                        '${c['nombre'] ?? ''} ${c['apellido'] ?? ''}',
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
                                  isActive ? 'Activo' : 'Inactivo',
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
            _buildInfoRow(Icons.email, c['email'] ?? 'N/A'),
            SizedBox(height: 8),
            _buildInfoRow(Icons.phone, c['telefono'] ?? 'N/A'),
            
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
                  onPressed: () => _showClientForm(client: c, isEdit: true),
                ),
                _buildActionButton(
                  icon: isActive ? Icons.block : Icons.check_circle,
                  label: isActive ? 'Desactivar' : 'Activar',
                  color: isActive ? Colors.red : Colors.green,
                  onPressed: () => _toggleClientStatus(c['_id'], isActive),
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
