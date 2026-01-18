import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/search_bar_widget.dart';
import '../../../services/ratings_service.dart';

/// Página para gestionar calificaciones de estilistas (ADMIN)
/// Admin tiene permiso completo: ver, editar y eliminar calificaciones
class RatingsAdminPage extends StatefulWidget {
  final String token;

  const RatingsAdminPage({super.key, required this.token});

  @override
  State<RatingsAdminPage> createState() => _RatingsAdminPageState();
}

class _RatingsAdminPageState extends State<RatingsAdminPage> {
  final _ratingsService = RatingsService();
  
  List<dynamic> stylists = [];
  List<dynamic> filteredStylists = [];
  Map<String, List<dynamic>> stylistRatings = {};
  Map<String, double> stylistAvgRatings = {};
  
  bool loading = true;
  bool loadingRatings = false;
  String searchQuery = '';
  String? selectedStylistId;
  
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _ratingsService.setToken(widget.token);
    _fetchStylists();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStylists() async {
    try {
      print('📊 Cargando estilistas...');
      final res = await ApiClient.instance.get(
        '/api/v1/stylists',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final stylistsList = data is Map ? (data['data'] ?? []) : (data is List ? data : []);
        
        // Cargar calificaciones promedio para cada estilista
        for (var stylistDyn in stylistsList) {
          final stylist = stylistDyn is Map<String, dynamic> 
            ? stylistDyn 
            : Map<String, dynamic>.from(stylistDyn as Map);
          final stylistId = stylist['_id'] ?? stylist['id'] ?? '';
          
          if (stylistId.isNotEmpty) {
            _loadStylistAvgRating(stylistId);
          }
        }
        
        setState(() {
          stylists = stylistsList;
          filteredStylists = stylistsList;
          loading = false;
        });
        print('✅ Estilistas cargados: ${stylists.length}');
      } else {
        print('❌ Error: ${res.statusCode}');
        setState(() => loading = false);
      }
    } catch (e) {
      print('❌ Error cargando estilistas: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _loadStylistAvgRating(String stylistId) async {
    try {
      final result = await _ratingsService.getEstilistaRatingsEnriquecidos(
        stylistId: stylistId,
        limit: 100,
      );

      if (result['success'] == true) {
        final ratingsList = result['data'] as List? ?? [];
        
        if (ratingsList.isNotEmpty) {
          final avgRating = ratingsList.fold<double>(
            0.0,
            (sum, r) {
              final stars = (r is Map ? r['estrellas'] : 0) ?? 0;
              final starsDouble = stars is int ? stars.toDouble() : (stars as double);
              return sum + starsDouble;
            }
          ) / ratingsList.length;
          
          setState(() {
            stylistAvgRatings[stylistId] = avgRating;
          });
          print('⭐ Promedio del estilista $stylistId: ${avgRating.toStringAsFixed(1)}');
        } else {
          setState(() {
            stylistAvgRatings[stylistId] = 0.0;
          });
        }
      }
    } catch (e) {
      print('❌ Error cargando promedio: $e');
      setState(() {
        stylistAvgRatings[stylistId] = 0.0;
      });
    }
  }

  Future<void> _fetchStylistRatings(String stylistId) async {
    setState(() => loadingRatings = true);
    try {
      print('⭐ Cargando calificaciones enriquecidas del estilista: $stylistId');
      
      final result = await _ratingsService.getEstilistaRatingsEnriquecidos(
        stylistId: stylistId,
        limit: 100,
      );

      if (result['success'] == true) {
        final enrichedRatings = result['data'] as List? ?? [];
        
        setState(() {
          stylistRatings[stylistId] = enrichedRatings;
          loadingRatings = false;
        });
        
        print('✅ Calificaciones cargadas y enriquecidas: ${enrichedRatings.length}');
      } else {
        print('❌ Error: ${result['error']}');
        setState(() => loadingRatings = false);
      }
    } catch (e) {
      print('❌ Error cargando calificaciones: $e');
      setState(() => loadingRatings = false);
    }
  }

  void _applyFilter() {
    final query = searchQuery.toLowerCase();
    List<dynamic> temp = stylists;

    if (searchQuery.isNotEmpty) {
      temp = temp.where((s) {
        final nombre = (s['nombre'] ?? '').toString().toLowerCase();
        final apellido = (s['apellido'] ?? '').toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        
        return nombre.contains(query) || 
               apellido.contains(query) || 
               email.contains(query);
      }).toList();
    }

    setState(() {
      filteredStylists = temp;
    });
  }

  Future<void> _deleteRating(String ratingId, String stylistId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text('¿Eliminar Calificación?', style: TextStyle(color: AppColors.gold)),
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
        final res = await ApiClient.instance.delete(
          '/api/v1/ratings/$ratingId',
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calificación eliminada'), backgroundColor: Colors.green),
          );
          _fetchStylistRatings(stylistId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Calificaciones (ADMIN)', 
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Barra de búsqueda
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: SearchBarWidget(
                      controller: searchController,
                      placeholder: 'Buscar estilista...',
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

                  // Lista de estilistas
                  if (filteredStylists.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No hay estilistas disponibles',
                        style: TextStyle(color: AppColors.gray)
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredStylists.length,
                      itemBuilder: (context, index) {
                        final stylist = filteredStylists[index];
                        final stylistId = stylist['_id'] ?? stylist['id'] ?? '';
                        final nombre = stylist['nombre'] ?? 'Desconocido';
                        final apellido = stylist['apellido'] ?? '';
                        final ratings = stylistRatings[stylistId] ?? [];
                        
                        return _buildStylistCard(stylist, stylistId, nombre, apellido, ratings);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStylistCard(Map<String, dynamic> stylist, String stylistId, 
    String nombre, String apellido, List<dynamic> ratings) {
    
    final isExpanded = selectedStylistId == stylistId;
    final avgRating = stylistAvgRatings[stylistId] ?? 0.0;

    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.gold.withOpacity(0.2)),
      ),
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (isExpanded) {
                setState(() => selectedStylistId = null);
              } else {
                setState(() => selectedStylistId = stylistId);
                _fetchStylistRatings(stylistId);
              }
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person, color: AppColors.gold),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nombre $apellido',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: TextStyle(
                                color: avgRating > 0 ? Colors.orange : AppColors.gray,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${ratings.length} calificaciones',
                              style: TextStyle(color: AppColors.gray, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.gold,
                  ),
                ],
              ),
            ),
          ),
          
          // Detalles expandidos
          if (isExpanded)
            _buildRatingsDetail(stylistId, ratings),
        ],
      ),
    );
  }

  Widget _buildRatingsDetail(String stylistId, List<dynamic> ratings) {
    final avgRating = ratings.isNotEmpty
        ? ratings.fold<double>(0, (sum, r) => sum + ((r['estrellas'] ?? 0) as num).toDouble()) / ratings.length
        : 0;
    
    // Extraer servicios únicos
    final servicios = <String>{};
    for (var rating in ratings) {
      final servicio = rating['servicio'] ?? rating['serviceName'];
      if (servicio != null) {
        servicios.add(servicio);
      }
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppColors.gold.withOpacity(0.2), height: 1),
          SizedBox(height: 16),
          
          if (loadingRatings)
            Center(child: CircularProgressIndicator(color: AppColors.gold))
          else if (ratings.isEmpty)
            Padding(
              padding: EdgeInsets.all(20),
              child: Text('No hay calificaciones aún',
                style: TextStyle(color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RESUMEN
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 RESUMEN DE CALIFICACIONES',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Total y Promedio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('Total',
                                style: TextStyle(color: AppColors.gray, fontSize: 11),
                              ),
                              SizedBox(height: 4),
                              Text('${ratings.length}',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text('Promedio',
                                style: TextStyle(color: AppColors.gray, fontSize: 11),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text(avgRating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Servicios
                      if (servicios.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Divider(color: AppColors.gold.withOpacity(0.2), height: 1),
                        SizedBox(height: 8),
                        Text('Servicios brindados:',
                          style: TextStyle(color: AppColors.gray, fontSize: 11),
                        ),
                        SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: servicios.map((s) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 0.5),
                            ),
                            child: Text(s,
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // HISTÓRICO DE CALIFICACIONES
                Text('📝 HISTÓRICO',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 12),
                
                // Lista de ratings
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    return _buildRatingItem(rating, stylistId);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(Map<String, dynamic> rating, String stylistId) {
    // Extraer datos del formato enriquecido
    final estrellas = rating['estrellas'] ?? 0;
    final comentario = rating['comentario'] ?? '';
    final ratingId = rating['_id'] ?? '';
    
    // Datos enriquecidos
    final booking = rating['bookingData'] as Map<String, dynamic>? ?? {};
    final servicio = rating['serviceData'] as Map<String, dynamic>? ?? {};
    final estilista = rating['stylistData'] as Map<String, dynamic>? ?? {};
    
    // Extraer información
    final String serviceName = servicio['nombre'] ?? 'Servicio desconocido';
    final double precio = (servicio['precio'] ?? 0).toDouble();
    final int duracion = servicio['duracionMin'] ?? 0;
    
    final String estilistaName = '${estilista['nombre'] ?? ''} ${estilista['apellido'] ?? ''}'.trim();
    
    // Fecha y hora de la cita
    final inicio = booking['inicio'];
    late final String fecha;
    late final String hora;
    
    if (inicio != null) {
      try {
        final dt = DateTime.parse(inicio.toString());
        fecha = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        hora = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        fecha = 'Desconocida';
        hora = '--:--';
      }
    } else {
      fecha = 'Desconocida';
      hora = '--:--';
    }

    print('🎬 Rating Item - Servicio: $serviceName, Estilista: $estilistaName, Precio: \$$precio');

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: estrellas >= 4 ? Colors.green : (estrellas >= 3 ? Colors.orange : Colors.red),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO: Estrellas y Fecha/Hora
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < estrellas ? Icons.star : Icons.star_outline,
                    size: 14,
                    color: Colors.amber,
                  );
                }),
              ),
              Text(
                '$fecha $hora',
                style: TextStyle(color: AppColors.gray, fontSize: 11),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // INFORMACIÓN: Servicio, Estilista, Precio, Duración
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Servicio
                Row(
                  children: [
                    Icon(Icons.cut, size: 13, color: AppColors.gold),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        serviceName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                
                // Estilista
                Row(
                  children: [
                    Icon(Icons.person, size: 13, color: AppColors.gold),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        estilistaName.isNotEmpty ? estilistaName : 'Estilista',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                
                // Precio y Duración
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 13, color: AppColors.gold),
                    SizedBox(width: 6),
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.timer, size: 13, color: AppColors.gold),
                    SizedBox(width: 6),
                    Text(
                      '${duracion}m',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 8),
          
          // Comentario (si existe)
          if (comentario.isNotEmpty)
            Text(
              comentario,
              style: TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _deleteRating(ratingId, stylistId),
              icon: Icon(Icons.delete, size: 16),
              label: Text('Eliminar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
