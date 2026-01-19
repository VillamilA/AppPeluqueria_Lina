import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../api/api_client.dart';
import '../../../api/catalogs_api.dart';
import '../../../core/theme/app_theme.dart';

class ManageCatalogServicesDialog extends StatefulWidget {
  final String token;
  final String catalogId;
  final List<dynamic> currentServices;
  final Function(List<String>) onServicesSaved;

  const ManageCatalogServicesDialog({
    super.key,
    required this.token,
    required this.catalogId,
    required this.currentServices,
    required this.onServicesSaved,
  });

  @override
  State<ManageCatalogServicesDialog> createState() =>
      _ManageCatalogServicesDialogState();
}

class _ManageCatalogServicesDialogState
    extends State<ManageCatalogServicesDialog> {
  List<dynamic> allServices = [];
  List<String> selectedServiceIds = [];
  bool loading = true;
  bool saving = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Manejar que currentServices puede ser una lista de IDs (strings)
    // o una lista de objetos con '_id'
    print('📌 [DIALOG] currentServices: ${widget.currentServices}');
    
    if (widget.currentServices.isNotEmpty) {
      selectedServiceIds = widget.currentServices.map((s) {
        if (s is String && s.isNotEmpty) {
          return s;
        } else if (s is Map && s.containsKey('_id')) {
          final id = s['_id'];
          return (id is String) ? id : id.toString();
        }
        return '';
      }).where((id) => id.isNotEmpty).toList();
    } else {
      selectedServiceIds = [];
    }
    
    print('📌 [DIALOG] selectedServiceIds iniciales: $selectedServiceIds');
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/services',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('📌 [DIALOG] Servicios response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          allServices = data is List ? data : (data['data'] ?? []);
          allServices =
              allServices.where((s) => s['activo'] == true).toList();
          
          // Validar que los servicios seleccionados existan
          // Si alguno no existe, removarlo
          selectedServiceIds = selectedServiceIds.where((id) {
            final exists = allServices.any((service) => service['_id'] == id);
            if (!exists) {
              print('⚠️ [DIALOG] Servicio no válido removido: $id');
            }
            return exists;
          }).toList();
          
          print('📌 [DIALOG] Servicios cargados: ${allServices.length}');
          print('📌 [DIALOG] Servicios seleccionados después validación: $selectedServiceIds');
          loading = false;
        });
      } else {
        setState(() => loading = false);
        _showError('Error al cargar servicios (${res.statusCode})');
      }
    } catch (e) {
      print('❌ [DIALOG] Error loading services: $e');
      setState(() => loading = false);
      _showError('Error: $e');
    }
  }

  void _toggleService(String serviceId) {
    setState(() {
      if (selectedServiceIds.contains(serviceId)) {
        selectedServiceIds.remove(serviceId);
      } else {
        selectedServiceIds.add(serviceId);
      }
    });
  }

  Future<void> _saveServices() async {
    if (selectedServiceIds.isEmpty) {
      _showError('Debes seleccionar al menos un servicio');
      return;
    }

    // Validar que todos los servicios seleccionados existan en la lista
    final validServiceIds = selectedServiceIds.where((id) {
      return allServices.any((service) => service['_id'] == id);
    }).toList();

    if (validServiceIds.isEmpty) {
      _showError('Los servicios seleccionados no son válidos');
      return;
    }

    print('📌 [SAVE] Guardando servicios: $validServiceIds');

    setState(() => saving = true);

    try {
      final catalogApi = CatalogsApi(ApiClient.instance);
      final res = await catalogApi.replaceServicesInCatalog(
        catalogId: widget.catalogId,
        serviceIds: validServiceIds,
        token: widget.token,
      );

      print('📌 [SAVE] Response status: ${res.statusCode}');
      print('📌 [SAVE] Response body: ${res.body}');

      if (res.statusCode == 200) {
        widget.onServicesSaved(validServiceIds);
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Servicios actualizados correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (res.statusCode == 400) {
        final errorBody = jsonDecode(res.body);
        _showError('Error: ${errorBody['message'] ?? 'Datos inválidos'}');
      } else {
        _showError('Error al guardar servicios: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ [SAVE] Error: $e');
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  List<dynamic> get filteredServices {
    if (searchQuery.isEmpty) return allServices;
    final query = searchQuery.toLowerCase();
    return allServices
        .where((s) =>
            (s['nombre'] ?? '').toString().toLowerCase().contains(query) ||
            (s['codigo'] ?? '').toString().toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.charcoal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(
                  bottom: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                ),
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.miscellaneous_services, color: AppColors.gold),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gestionar Servicios',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
              child: loading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : Column(
                      children: [
                        // Search
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Buscar servicio...',
                              hintStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Icons.search, color: AppColors.gold),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: AppColors.gold.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.gold),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() => searchQuery = value);
                            },
                          ),
                        ),

                        // Service List
                        Expanded(
                          child: filteredServices.isEmpty
                              ? Center(
                                  child: Text(
                                    'No hay servicios disponibles',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredServices.length,
                                  itemBuilder: (context, index) {
                                    final service = filteredServices[index];
                                    final serviceId = service['_id'];
                                    final isSelected =
                                        selectedServiceIds.contains(serviceId);

                                    return Container(
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.gold.withOpacity(0.1)
                                            : Colors.grey[900],
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.gold
                                              : Colors.grey[700]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: CheckboxListTile(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _toggleService(serviceId),
                                        checkColor: Colors.black87,
                                        activeColor: AppColors.gold,
                                        title: Text(
                                          service['nombre'] ?? 'Sin nombre',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (service['codigo'] != null)
                                              Text(
                                                'Código: ${service['codigo']}',
                                                style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 12),
                                              ),
                                            if (service['precio'] != null)
                                              Text(
                                                'Precio: \$${service['precio']}',
                                                style: TextStyle(
                                                    color: AppColors.gold,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),

            // Footer
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                ),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${selectedServiceIds.length} servicio(s) seleccionado(s)',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: BorderSide(color: AppColors.gold),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Cancelar'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saving ? null : _saveServices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: saving
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black87,
                                  ),
                                )
                              : Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
