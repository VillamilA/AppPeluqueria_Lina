import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../widgets/search_bar_widget.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'pages/service_form_page.dart';

class ServicesCrudPage extends StatefulWidget {
  final String token;
  const ServicesCrudPage({super.key, required this.token});

  @override
  State<ServicesCrudPage> createState() => _ServicesCrudPageState();
}

class _ServicesCrudPageState extends State<ServicesCrudPage> {
  List<dynamic> services = [];
  List<dynamic> filteredServices = [];
  bool loading = true;
  String filterStatus = 'all'; // 'all', 'active', 'inactive'
  String searchQuery = '';
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _fetchServices();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/services',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          services = data is List ? data : (data['data'] ?? []);
          _applyFilter();
          loading = false;
        });
      } else {
        setState(() { services = []; loading = false; });
      }
    } catch (e) {
      print('Error loading services: $e');
      setState(() { services = []; loading = false; });
    }
  }

  void _applyFilter() {
    List<dynamic> temp = services;
    
    // Filtrar por estado
    if (filterStatus == 'all') {
      temp = services;
    } else if (filterStatus == 'active') {
      temp = services.where((s) => (s['activo'] ?? true) == true).toList();
    } else if (filterStatus == 'inactive') {
      temp = services.where((s) => (s['activo'] ?? true) == false).toList();
    }
    
    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      temp = temp.where((s) {
        final nombre = (s['nombre'] ?? '').toString().toLowerCase();
        final codigo = (s['codigo'] ?? '').toString().toLowerCase();
        final descripcion = (s['descripcion'] ?? '').toString().toLowerCase();
        
        return nombre.contains(query) || 
               codigo.contains(query) || 
               descripcion.contains(query);
      }).toList();
    }
    
    setState(() {
      filteredServices = temp;
    });
  }

  Future<void> _createService(Map<String, dynamic> service) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.post(
        '/api/v1/services',
        body: jsonEncode(service),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Servicio creado exitosamente'), backgroundColor: Colors.green));
        await _fetchServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear servicio'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _editService(String id, Map<String, dynamic> service) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.put(
        '/api/v1/services/$id',
        body: jsonEncode(service),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final index = services.indexWhere((s) => s['_id'] == id);
        if (index != -1) {
          setState(() {
            services[index] = {...services[index], ...service};
            _applyFilter();
            loading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Servicio actualizado exitosamente'), backgroundColor: Colors.green)
        );
        _fetchServices().then((_) => print('Datos sincronizados'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar servicio'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _toggleServiceStatus(String id, bool currentStatus) async {
    try {
      final res = await ApiClient.instance.put(
        '/api/v1/services/$id',
        body: jsonEncode({'activo': !currentStatus}),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      
      if (res.statusCode == 200) {
        final index = services.indexWhere((s) => s['_id'] == id);
        if (index != -1) {
          setState(() {
            services[index]['activo'] = !currentStatus;
            _applyFilter();
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? '✅ Servicio activado' : '❌ Servicio desactivado'),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Error: ${res.statusCode}');
      }
    } catch (e) {
      print('Error toggling service status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showServiceForm({Map<String, dynamic>? service, required bool isEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceFormPage(
          token: widget.token,
          service: service,
          isEdit: isEdit,
          onSave: (data) async {
            if (isEdit && service != null) {
              await _editService(service['_id'], data);
            } else {
              await _createService(data);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int activeCount = services.where((s) => s['activo'] == true).length;
    final int inactiveCount = services.where((s) => s['activo'] == false).length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Servicios', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: EdgeInsets.all(16),
            child: SearchBarWidget(
              controller: searchController,
              placeholder: 'Buscar por nombre, código o descripción...',
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
                _buildFilterChip('Todos', 'all', services.length),
                _buildFilterChip('Activos', 'active', activeCount),
                _buildFilterChip('Inactivos', 'inactive', inactiveCount),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.content_cut, size: 64, color: AppColors.gray),
                            SizedBox(height: 16),
                            Text(
                              'No hay servicios en esta categoría',
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
                            itemCount: filteredServices.length,
                            itemBuilder: (context, i) => _buildServiceCard(filteredServices[i]),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredServices.length,
                            itemBuilder: (context, i) => _buildServiceCard(filteredServices[i]),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        icon: Icon(Icons.add, color: Colors.black),
        label: Text('Nuevo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () => _showServiceForm(isEdit: false),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> s) {
    final isActive = s['activo'] ?? true;
    final precio = s['precio'] ?? 0;
    final duracion = s['duracionMin'] ?? 0;
    
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
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.content_cut, color: AppColors.gold, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['nombre'] ?? 'Sin nombre',
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
            _buildInfoRow(Icons.code, s['codigo'] ?? 'N/A'),
            SizedBox(height: 8),
            _buildInfoRow(Icons.attach_money, '\$${precio.toString()}'),
            SizedBox(height: 8),
            _buildInfoRow(Icons.schedule, '$duracion min'),
            
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
                  onPressed: () => _showServiceForm(service: s, isEdit: true),
                ),
                _buildActionButton(
                  icon: isActive ? Icons.block : Icons.check_circle,
                  label: isActive ? 'Desactivar' : 'Activar',
                  color: isActive ? Colors.red : Colors.green,
                  onPressed: () => _toggleServiceStatus(s['_id'], isActive),
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

