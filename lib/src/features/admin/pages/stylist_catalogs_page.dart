import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class StylistCatalogsPage extends StatefulWidget {
  final String stylistId;
  final String stylistName;
  final String token;

  const StylistCatalogsPage({
    super.key,
    required this.stylistId,
    required this.stylistName,
    required this.token,
  });

  @override
  State<StylistCatalogsPage> createState() => _StylistCatalogsPageState();
}

class _StylistCatalogsPageState extends State<StylistCatalogsPage> {
  List<dynamic> allCatalogs = []; // Todos los catálogos disponibles
  List<String> selectedCatalogIds = []; // IDs de catálogos seleccionados
  bool loadingAllCatalogs = true;
  bool loadingAssignedCatalogs = true;
  bool isSaving = false;
  String? expandedCatalogId;

  @override
  void initState() {
    super.initState();
    _loadAllCatalogs();
    _loadAssignedCatalogs();
  }

  /// Cargar TODOS los catálogos disponibles
  Future<void> _loadAllCatalogs() async {
    try {
      print('📦 Cargando todos los catálogos disponibles...');
      final res = await ApiClient.instance.get(
        '/api/v1/catalog?includeServices=true',
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // El endpoint retorna { "data": [...] } o directo un array
        final catalogsList = data is Map 
            ? (data['data'] ?? []) 
            : (data is List ? data : []);
        
        setState(() {
          allCatalogs = catalogsList;
          loadingAllCatalogs = false;
        });
        print('✅ Catálogos disponibles cargados: ${allCatalogs.length}');
      } else {
        print('❌ Error cargando catálogos: ${res.statusCode}');
        setState(() { loadingAllCatalogs = false; });
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() { loadingAllCatalogs = false; });
    }
  }

  /// Cargar catálogos asignados al estilista actual
  Future<void> _loadAssignedCatalogs() async {
    try {
      print('👗 Cargando catálogos asignados al estilista...');
      final res = await ApiClient.instance.get(
        '/api/v1/stylists/${widget.stylistId}/catalogs',
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        // El endpoint retorna { "catalogs": [...] } o { "stylist": {...}, "catalogs": [...] }
        List<dynamic> assignedList = [];
        if (data is Map) {
          assignedList = data['catalogs'] ?? [];
        } else if (data is List) {
          assignedList = data;
        }
        
        // Extraer los IDs de los catálogos asignados
        final ids = assignedList
            .map((c) => c is Map ? (c['_id'] ?? c['id'] ?? '') : c.toString())
            .where((id) => id.isNotEmpty)
            .cast<String>()
            .toList();
        
        setState(() {
          selectedCatalogIds = ids;
          loadingAssignedCatalogs = false;
        });
        print('✅ Catálogos asignados cargados: $selectedCatalogIds');
      } else if (res.statusCode == 404) {
        print('ℹ️ No hay catálogos asignados');
        setState(() { loadingAssignedCatalogs = false; });
      } else {
        print('❌ Error: ${res.statusCode}');
        setState(() { loadingAssignedCatalogs = false; });
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() { loadingAssignedCatalogs = false; });
    }
  }

  /// Guardar cambios: PUT /api/v1/stylists/:id/services
  Future<void> _saveCatalogs() async {
    try {
      setState(() { isSaving = true; });
      
      print('💾 Guardando catálogos: $selectedCatalogIds');
      
      final res = await ApiClient.instance.put(
        '/api/v1/stylists/${widget.stylistId}/services',
        body: {'catalogs': selectedCatalogIds},
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print('✅ Catálogos guardados exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Catálogos actualizados exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        print('❌ Error: ${res.statusCode}');
        try {
          final errorBody = jsonDecode(res.body);
          final errorMsg = errorBody['message'] ?? 'Error al actualizar';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${res.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      setState(() { isSaving = false; });
    } catch (e) {
      print('❌ Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() { isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catálogos de ${widget.stylistName}',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${selectedCatalogIds.length} catálogo(s) asignado(s)',
              style: TextStyle(
                color: AppColors.gray,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (!isSaving)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: TextButton.icon(
                  onPressed: _saveCatalogs,
                  icon: Icon(Icons.save, color: AppColors.gold),
                  label: Text(
                    'Guardar',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: loadingAllCatalogs || loadingAssignedCatalogs
          ? Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona los catálogos que deseas asignar a este estilista:',
                    style: TextStyle(
                      color: AppColors.gray,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  if (allCatalogs.isEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.charcoal.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No hay catálogos disponibles',
                          style: TextStyle(color: AppColors.gray),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: allCatalogs.map<Widget>((catalog) {
                        final catalogId = catalog['_id'] ?? catalog['id'] ?? '';
                        final catalogName = catalog['nombre'] ?? 'Sin nombre';
                        final catalogDesc = catalog['descripcion'] ?? '';
                        final services = catalog['services'] ?? [];
                        final isSelected = selectedCatalogIds.contains(catalogId);
                        final isExpanded = expandedCatalogId == catalogId;

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold.withOpacity(0.1)
                                : AppColors.charcoal.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.gold.withOpacity(0.5)
                                  : AppColors.gold.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Header del catálogo con checkbox
                              CheckboxListTile(
                                title: Text(
                                  catalogName,
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (catalogDesc.isNotEmpty)
                                      Text(
                                        catalogDesc,
                                        style: TextStyle(
                                          color: AppColors.gray,
                                          fontSize: 12,
                                        ),
                                      ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${services.length} servicio(s)',
                                      style: TextStyle(
                                        color: AppColors.gold.withOpacity(0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (!selectedCatalogIds.contains(catalogId)) {
                                        selectedCatalogIds.add(catalogId);
                                      }
                                    } else {
                                      selectedCatalogIds.remove(catalogId);
                                      expandedCatalogId = null;
                                    }
                                  });
                                },
                                activeColor: AppColors.gold,
                                checkColor: Colors.black,
                                tileColor: Colors.transparent,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),

                              // Botón Ver Servicios y lista de servicios expandida
                              if (isSelected && services.isNotEmpty) ...[
                                Divider(
                                  color: AppColors.gold.withOpacity(0.2),
                                  height: 1,
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.gold.withOpacity(0.2),
                                        foregroundColor: AppColors.gold,
                                        side: BorderSide(
                                          color: AppColors.gold.withOpacity(0.4),
                                          width: 1,
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          expandedCatalogId = isExpanded ? null : catalogId;
                                        });
                                      },
                                      icon: isExpanded
                                          ? Icon(Icons.expand_less)
                                          : Icon(Icons.expand_more),
                                      label: Text(
                                        isExpanded
                                            ? 'Ocultar Servicios'
                                            : 'Ver Servicios (${services.length})',
                                      ),
                                    ),
                                  ),
                                ),

                                // Lista de servicios expandida
                                if (isExpanded) ...[
                                  Container(
                                    color: Colors.black.withOpacity(0.2),
                                    padding: EdgeInsets.all(12),
                                    child: services.isEmpty
                                        ? Text(
                                            'No hay servicios en este catálogo',
                                            style: TextStyle(
                                              color: AppColors.gray,
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: services
                                                .map<Widget>((service) {
                                              final serviceName =
                                                  service['nombre'] ??
                                                      'Servicio';
                                              final servicePrecio =
                                                  service['precio'] ?? 0;
                                              final serviceDuracion =
                                                  service['duracionMin'] ??
                                                      0;

                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Container(
                                                  padding:
                                                      EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .charcoal
                                                        .withOpacity(0.5),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(8),
                                                    border: Border.all(
                                                      color: AppColors.gold
                                                          .withOpacity(0.2),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              serviceName,
                                                              style:
                                                                  TextStyle(
                                                                color:
                                                                    AppColors
                                                                        .gold,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .access_time,
                                                                  color: AppColors
                                                                      .gray,
                                                                  size: 12,
                                                                ),
                                                                SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  '$serviceDuracion min',
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        AppColors
                                                                            .gray,
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .gold
                                                              .withOpacity(
                                                                  0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4),
                                                        ),
                                                        child: Text(
                                                          '\$$servicePrecio',
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .gold,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }
}
