import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../api/stylists_api.dart';
import '../../api/api_client.dart';

/// Tab para mostrar los catálogos/servicios asignados al estilista
class StylistCatalogsTab extends StatefulWidget {
  final String stylistId;
  final String token;

  const StylistCatalogsTab({
    super.key,
    required this.stylistId,
    required this.token,
  });

  @override
  State<StylistCatalogsTab> createState() => _StylistCatalogsTabState();
}

class _StylistCatalogsTabState extends State<StylistCatalogsTab> {
  late StylistsApi _stylistsApi;
  List<dynamic> catalogs = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _stylistsApi = StylistsApi(ApiClient.instance);
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('📚 Cargando catálogos del estilista: ${widget.stylistId}');

      final response = await _stylistsApi.getStylistCatalogs(
        stylistId: widget.stylistId,
        token: widget.token,
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parsear respuesta - puede ser lista o mapa con propiedad 'data'
        List catalogsList = [];
        if (data is List) {
          catalogsList = data;
        } else if (data is Map && data['data'] != null) {
          catalogsList = data['data'] is List ? data['data'] : [data['data']];
        } else if (data is Map && data['catalogs'] != null) {
          catalogsList = data['catalogs'] is List ? data['catalogs'] : [data['catalogs']];
        } else if (data is Map) {
          catalogsList = [data];
        }

        print('✅ Catálogos recibidos: ${catalogsList.length}');

        setState(() {
          catalogs = catalogsList;
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        print('ℹ️ No se encontraron catálogos');
        setState(() {
          catalogs = [];
          isLoading = false;
          errorMessage = 'No tienes catálogos asignados aún';
        });
      } else {
        print('❌ Error: ${response.statusCode}');
        setState(() {
          isLoading = false;
          errorMessage = 'Error al cargar catálogos (${response.statusCode})';
        });
      }
    } catch (e) {
      print('❌ Excepción al cargar catálogos: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: RefreshIndicator(
        onRefresh: _loadCatalogs,
        color: AppColors.gold,
        backgroundColor: AppColors.charcoal,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.charcoal, Colors.grey.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, color: AppColors.gold, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mis Servicios',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Servicios asignados a ti',
                                style: TextStyle(
                                  color: AppColors.gray,
                                  fontSize: 14,
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
            ),

            // Content
            if (isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else if (errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.gold,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadCatalogs,
                          icon: Icon(Icons.refresh),
                          label: Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (catalogs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books,
                          color: AppColors.gold.withOpacity(0.5),
                          size: 80,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes servicios asignados',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Contacta con tu gerente o administrador',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final catalog = catalogs[index];
                      return _buildCatalogCard(catalog);
                    },
                    childCount: catalogs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogCard(Map<String, dynamic> catalog) {
    final nombre = catalog['nombre'] ?? catalog['name'] ?? 'Sin nombre';
    final descripcion = catalog['descripcion'] ?? catalog['description'] ?? '';
    final precio = catalog['precio'] ?? catalog['price'] ?? 0;
    final duracion = catalog['duracion'] ?? catalog['duration'] ?? 0;
    final categoria = catalog['categoria'] ?? catalog['category'] ?? '';
    final activo = catalog['activo'] ?? catalog['active'] ?? true;
    final imagenUrl = catalog['imagenUrl'] ?? catalog['imageUrl'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activo ? AppColors.gold.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen si existe
          if (imagenUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imagenUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey.shade700,
                    child: Icon(Icons.image_not_supported, color: AppColors.gray, size: 40),
                  );
                },
              ),
            ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!activo)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Inactivo',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                if (categoria.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: Text(
                      categoria,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                if (descripcion.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: AppColors.gray,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.attach_money,
                        '\$${precio.toStringAsFixed(2)}',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.access_time,
                        '$duracion min',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold, size: 16),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
