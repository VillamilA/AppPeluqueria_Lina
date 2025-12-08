import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import '../../api/catalogs_api.dart';
import '../../core/theme/app_theme.dart';

class CatalogManagementPage extends StatefulWidget {
  final String token;

  const CatalogManagementPage({super.key, required this.token});

  @override
  State<CatalogManagementPage> createState() => _CatalogManagementPageState();
}

class _CatalogManagementPageState extends State<CatalogManagementPage> {
  List<dynamic> _catalogs = [];
  bool _loading = true;
  late CatalogsApi _catalogsApi;

  @override
  void initState() {
    super.initState();
    _catalogsApi = CatalogsApi(ApiClient.instance);
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    setState(() => _loading = true);
    try {
      final res = await _catalogsApi.getCatalogs(token: widget.token);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _catalogs = data is List ? data : (data['data'] ?? []);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading catalogs: $e');
      setState(() => _loading = false);
    }
  }

  void _showCatalogForm({Map<String, dynamic>? catalog}) {
    showDialog(
      context: context,
      builder: (ctx) => _CatalogFormDialog(
        token: widget.token,
        catalog: catalog,
        onSave: (catalogData) async {
          if (catalog != null) {
            // Update
            final res = await _catalogsApi.updateCatalog(
              catalogId: catalog['_id'],
              nombre: catalogData['nombre'],
              descripcion: catalogData['descripcion'],
              imageUrl: catalogData['imageUrl'],
              token: widget.token,
            );
            if (res.statusCode == 200) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Catálogo actualizado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadCatalogs();
            }
          } else {
            // Create
            final res = await _catalogsApi.createCatalog(
              nombre: catalogData['nombre'],
              descripcion: catalogData['descripcion'],
              imageUrl: catalogData['imageUrl'],
              token: widget.token,
            );
            if (res.statusCode == 201 || res.statusCode == 200) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Catálogo creado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadCatalogs();
            }
          }
        },
      ),
    );
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
            SnackBar(
              content: Text('Catálogo eliminado'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCatalogs();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Catálogos', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _catalogs.isEmpty
              ? Center(child: Text('No hay catálogos registrados', style: TextStyle(color: AppColors.gray, fontSize: 16)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _catalogs.length,
                  itemBuilder: (context, index) {
                    final catalog = _catalogs[index];
                    return Card(
                      color: Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catalog['nombre'] ?? 'Sin nombre',
                              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              catalog['descripcion'] ?? 'Sin descripción',
                              style: TextStyle(color: AppColors.gray, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                                  icon: Icon(Icons.edit, color: Colors.black),
                                  label: Text('Editar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showCatalogForm(catalog: catalog),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  label: Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => _deleteCatalog(catalog['_id']),
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
        onPressed: () => _showCatalogForm(),
      ),
    );
  }
}

class _CatalogFormDialog extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? catalog;
  final Function(Map<String, dynamic>) onSave;

  const _CatalogFormDialog({
    required this.token,
    this.catalog,
    required this.onSave,
  });

  @override
  State<_CatalogFormDialog> createState() => _CatalogFormDialogState();
}

class _CatalogFormDialogState extends State<_CatalogFormDialog> {
  late TextEditingController nombreCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController imageUrlCtrl;
  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.catalog?['nombre'] ?? '');
    descripcionCtrl = TextEditingController(text: widget.catalog?['descripcion'] ?? '');
    imageUrlCtrl = TextEditingController(text: widget.catalog?['imageUrl'] ?? '');
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    imageUrlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (nombreCtrl.text.isEmpty || descripcionCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onSave({
      'nombre': nombreCtrl.text,
      'descripcion': descripcionCtrl.text,
      'imageUrl': imageUrlCtrl.text,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.charcoal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.catalog != null ? 'Editar Catálogo' : 'Crear Nuevo Catálogo',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(nombreCtrl, 'Nombre *', Icons.category),
              SizedBox(height: 12),
              _buildTextField(
                descripcionCtrl,
                'Descripción *',
                Icons.description,
                maxLines: 3,
              ),
              SizedBox(height: 12),
              _buildTextField(imageUrlCtrl, 'URL de Imagen', Icons.image),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gray,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: Text(
                      widget.catalog != null ? 'Guardar' : 'Crear',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.gold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.gray),
        prefixIcon: Icon(icon, color: AppColors.gold),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}
