import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api/api_client.dart';
import '../../api/catalogs_api.dart';
import '../../widgets/search_bar_widget.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'pages/catalog_form_page.dart';
import 'dialogs/manage_catalog_services_dialog.dart';

class CatalogManagementPage extends StatefulWidget {
  final String token;

  const CatalogManagementPage({super.key, required this.token});

  @override
  State<CatalogManagementPage> createState() => _CatalogManagementPageState();
}

class _CatalogManagementPageState extends State<CatalogManagementPage> {
  List<dynamic> catalogs = [];
  List<dynamic> filteredCatalogs = [];
  bool loading = true;
  String filterStatus = 'all'; // 'all', 'active', 'inactive'
  String searchQuery = '';
  late TextEditingController searchController;
  late CatalogsApi _catalogsApi;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _catalogsApi = CatalogsApi(ApiClient.instance);
    _fetchCatalogs();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCatalogs() async {
    setState(() { loading = true; });
    try {
      final res = await _catalogsApi.getCatalogs(token: widget.token);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          catalogs = data is List ? data : (data['data'] ?? []);
          _applyFilter();
          loading = false;
        });
      } else {
        setState(() { catalogs = []; loading = false; });
      }
    } catch (e) {
      print('Error loading catalogs: $e');
      setState(() { catalogs = []; loading = false; });
    }
  }

  void _applyFilter() {
    List<dynamic> temp = catalogs;
    
    // Filtrar por estado
    if (filterStatus == 'all') {
      temp = catalogs;
    } else if (filterStatus == 'active') {
      temp = catalogs.where((c) => (c['activo'] ?? true) == true).toList();
    } else if (filterStatus == 'inactive') {
      temp = catalogs.where((c) => (c['activo'] ?? true) == false).toList();
    }
    
    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      temp = temp.where((c) {
        final nombre = (c['nombre'] ?? '').toString().toLowerCase();
        final descripcion = (c['descripcion'] ?? '').toString().toLowerCase();
        
        return nombre.contains(query) || 
               descripcion.contains(query);
      }).toList();
    }
    
    setState(() {
      filteredCatalogs = temp;
    });
  }

  Future<void> _createCatalog(Map<String, dynamic> catalog) async {
    setState(() { loading = true; });
    try {
      final res = await _catalogsApi.createCatalog(
        nombre: catalog['nombre'],
        descripcion: catalog['descripcion'],
        imageUrl: catalog['imageUrl'],
        token: widget.token,
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Catálogo creado exitosamente'), backgroundColor: Colors.green));
        await _fetchCatalogs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear catálogo'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _editCatalog(String id, Map<String, dynamic> catalog) async {
    setState(() { loading = true; });
    try {
      final res = await _catalogsApi.updateCatalog(
        catalogId: id,
        nombre: catalog['nombre'],
        descripcion: catalog['descripcion'],
        imageUrl: catalog['imageUrl'],
        token: widget.token,
      );
      if (res.statusCode == 200) {
        final index = catalogs.indexWhere((c) => c['_id'] == id);
        if (index != -1) {
          setState(() {
            catalogs[index] = {...catalogs[index], ...catalog};
            _applyFilter();
            loading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catálogo actualizado exitosamente'), backgroundColor: Colors.green)
        );
        _fetchCatalogs().then((_) => print('Datos sincronizados'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar catálogo'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _toggleCatalogStatus(String id, bool currentStatus) async {
    try {
      late http.Response res;
      if (currentStatus) {
        res = await _catalogsApi.deactivateCatalog(catalogId: id, token: widget.token);
      } else {
        res = await _catalogsApi.activateCatalog(catalogId: id, token: widget.token);
      }
      
      if (res.statusCode == 200) {
        final index = catalogs.indexWhere((c) => c['_id'] == id);
        if (index != -1) {
          setState(() {
            catalogs[index]['activo'] = !currentStatus;
            _applyFilter();
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? '✅ Catálogo activado' : '❌ Catálogo desactivado'),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Error: ${res.statusCode}');
      }
    } catch (e) {
      print('Error toggling catalog status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteCatalog(String catalogId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text('¿Eliminar Catálogo?', style: TextStyle(color: AppColors.gold)),
        content: Text('Esta acción no se puede deshacer', style: TextStyle(color: AppColors.gray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.gold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await _catalogsApi.deleteCatalog(
          catalogId: catalogId,
          token: widget.token,
        );
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Catálogo eliminado'), backgroundColor: Colors.green)
          );
          _fetchCatalogs();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCatalogForm({Map<String, dynamic>? catalog, required bool isEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatalogFormPage(
          token: widget.token,
          catalog: catalog,
          isEdit: isEdit,
          onSave: (data) async {
            if (isEdit && catalog != null) {
              await _editCatalog(catalog['_id'], data);
            } else {
              await _createCatalog(data);
            }
          },
        ),
      ),
    );
  }

  void _showManageServicesDialog(Map<String, dynamic> catalog) {
    print('📌 [CATALOG_PAGE] Abriendo diálogo para catálogo: ${catalog['_id']}');
    print('📌 [CATALOG_PAGE] Servicios actuales: ${catalog['services']}');
    
    showDialog(
      context: context,
      builder: (context) => ManageCatalogServicesDialog(
        token: widget.token,
        catalogId: catalog['_id'] ?? '',
        currentServices: (catalog['services'] ?? []) as List<dynamic>,
        onServicesSaved: (serviceIds) {
          print('📌 [CATALOG_PAGE] Servicios guardados: $serviceIds');
          // Actualizar el catálogo en la lista local
          final index = catalogs.indexWhere((c) => c['_id'] == catalog['_id']);
          if (index != -1) {
            setState(() {
              catalogs[index]['services'] = serviceIds;
              _applyFilter();
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int activeCount = catalogs.where((c) => c['activo'] == true).length;
    final int inactiveCount = catalogs.where((c) => c['activo'] == false).length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Catálogos', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
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
              placeholder: 'Buscar por nombre o descripción...',
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
                _buildFilterChip('Todos', 'all', catalogs.length),
                _buildFilterChip('Activos', 'active', activeCount),
                _buildFilterChip('Inactivos', 'inactive', inactiveCount),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : filteredCatalogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: AppColors.gray),
                            SizedBox(height: 16),
                            Text(
                              'No hay catálogos en esta categoría',
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
                            itemCount: filteredCatalogs.length,
                            itemBuilder: (context, i) => _buildCatalogCard(filteredCatalogs[i]),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredCatalogs.length,
                            itemBuilder: (context, i) => _buildCatalogCard(filteredCatalogs[i]),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        icon: Icon(Icons.add, color: Colors.black),
        label: Text('Nuevo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () => _showCatalogForm(isEdit: false),
      ),
    );
  }

  Widget _buildCatalogCard(Map<String, dynamic> c) {
    final isActive = c['activo'] ?? true;
    final servicesCount = (c['services'] as List?)?.length ?? 0;
    
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
                  child: Icon(Icons.category, color: AppColors.gold, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['nombre'] ?? 'Sin nombre',
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
            _buildInfoRow(Icons.description, c['descripcion'] ?? 'Sin descripción'),
            SizedBox(height: 8),
            _buildInfoRow(Icons.content_cut, '$servicesCount servicio${servicesCount != 1 ? 's' : ''}'),
            
            SizedBox(height: 16),
            
            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.miscellaneous_services,
                  label: 'Servicios',
                  color: Colors.blue,
                  onPressed: () => _showManageServicesDialog(c),
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Editar',
                  color: AppColors.gold,
                  onPressed: () => _showCatalogForm(catalog: c, isEdit: true),
                ),
                _buildActionButton(
                  icon: isActive ? Icons.block : Icons.check_circle,
                  label: isActive ? 'Desactivar' : 'Activar',
                  color: isActive ? Colors.red : Colors.green,
                  onPressed: () => _toggleCatalogStatus(c['_id'], isActive),
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Eliminar',
                  color: Colors.red,
                  onPressed: () => _deleteCatalog(c['_id']),
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
