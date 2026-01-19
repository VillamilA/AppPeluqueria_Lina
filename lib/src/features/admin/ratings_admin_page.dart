import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/search_bar_widget.dart';
import '../../../services/ratings_service.dart';

/// Página para gestionar calificaciones de estilistas (ADMIN)
/// Vista principal: Lista de estilistas
/// Al hacer clic en un estilista: Ve todas sus calificaciones y reseñas
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
  Map<String, double> stylistAvgRatings = {};
  Map<String, int> stylistRatingCounts = {};
  
  bool loading = true;
  String searchQuery = '';
  
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
            _loadStylistStats(stylistId);
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

  Future<void> _loadStylistStats(String stylistId) async {
    try {
      final result = await _ratingsService.getEstilistaRatingsEnriquecidos(
        stylistId: stylistId,
        limit: 100,
      );

      if (result['success'] == true) {
        final ratingsList = result['data'] as List? ?? [];
        
        // Calcular promedio
        double avgRating = 0.0;
        if (ratingsList.isNotEmpty) {
          final sum = ratingsList.fold<double>(
            0.0,
            (sum, r) {
              final stars = (r is Map ? r['estrellas'] : 0) ?? 0;
              final starsDouble = stars is int ? stars.toDouble() : (stars as double);
              return sum + starsDouble;
            }
          );
          avgRating = sum / ratingsList.length;
        }
        
        setState(() {
          stylistAvgRatings[stylistId] = avgRating;
          stylistRatingCounts[stylistId] = ratingsList.length;
        });
        print('⭐ Estilista $stylistId: ${avgRating.toStringAsFixed(1)} ⭐ (${ratingsList.length} reseñas)');
      }
    } catch (e) {
      print('❌ Error cargando stats: $e');
      setState(() {
        stylistAvgRatings[stylistId] = 0.0;
        stylistRatingCounts[stylistId] = 0;
      });
    }
  }

  void _applyFilter() {
    final query = searchQuery.toLowerCase();
    setState(() {
      filteredStylists = stylists.where((stylist) {
        final nombre = (stylist['nombre'] ?? '').toString().toLowerCase();
        final apellido = (stylist['apellido'] ?? '').toString().toLowerCase();
        return nombre.contains(query) || apellido.contains(query);
      }).toList();
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
          // Recargar stats del estilista
          _loadStylistStats(stylistId);
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
        title: Text('Calificaciones de Estilistas', 
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Column(
              children: [
                // Barra de búsqueda
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.black26,
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
                Expanded(
                  child: filteredStylists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_outline, size: 64, color: AppColors.gray),
                              SizedBox(height: 16),
                              Text('No hay estilistas disponibles',
                                style: TextStyle(color: AppColors.gray, fontSize: 16)
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(16),
                          separatorBuilder: (_, __) => SizedBox(height: 12),
                          itemCount: filteredStylists.length,
                          itemBuilder: (context, index) {
                            final stylist = filteredStylists[index];
                            final stylistId = stylist['_id'] ?? stylist['id'] ?? '';
                            final nombre = stylist['nombre'] ?? 'Desconocido';
                            final apellido = stylist['apellido'] ?? '';
                            final avgRating = stylistAvgRatings[stylistId] ?? 0.0;
                            final ratingCount = stylistRatingCounts[stylistId] ?? 0;

                            return _buildStylistListItem(
                              stylist,
                              stylistId,
                              nombre,
                              apellido,
                              avgRating,
                              ratingCount,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStylistListItem(
    Map<String, dynamic> stylist,
    String stylistId,
    String nombre,
    String apellido,
    double avgRating,
    int ratingCount,
  ) {
    return Card(
      color: Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StylistRatingsDetailPage(
                token: widget.token,
                stylistId: stylistId,
                stylistName: '$nombre $apellido',
                ratingsService: _ratingsService,
                onDeleteRating: _deleteRating,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(Icons.person, color: AppColors.gold, size: 28),
              ),
              SizedBox(width: 16),
              
              // Información
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
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            return Icon(
                              i < avgRating.toInt() ? Icons.star : Icons.star_outline,
                              size: 14,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        SizedBox(width: 8),
                        Text(
                          avgRating > 0 ? avgRating.toStringAsFixed(1) : 'Sin calificaciones',
                          style: TextStyle(
                            color: avgRating > 0 ? AppColors.gold : AppColors.gray,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '($ratingCount)',
                          style: TextStyle(color: AppColors.gray, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Icono flecha
              Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla de detalles: Historial completo de calificaciones del estilista
class StylistRatingsDetailPage extends StatefulWidget {
  final String token;
  final String stylistId;
  final String stylistName;
  final RatingsService ratingsService;
  final Function(String, String) onDeleteRating;

  const StylistRatingsDetailPage({
    super.key,
    required this.token,
    required this.stylistId,
    required this.stylistName,
    required this.ratingsService,
    required this.onDeleteRating,
  });

  @override
  State<StylistRatingsDetailPage> createState() => _StylistRatingsDetailPageState();
}

class _StylistRatingsDetailPageState extends State<StylistRatingsDetailPage> {
  List<dynamic> ratings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      setState(() => loading = true);
      
      final result = await widget.ratingsService.getEstilistaRatingsEnriquecidos(
        stylistId: widget.stylistId,
        limit: 100,
      );

      if (result['success'] == true) {
        setState(() {
          ratings = result['data'] as List? ?? [];
        });
        print('✅ Calificaciones cargadas: ${ratings.length}');
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar calificaciones: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _deleteRating(String ratingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text('¿Eliminar Calificación?', 
          style: TextStyle(color: AppColors.gold)
        ),
        content: Text('Esta acción no se puede deshacer', 
          style: TextStyle(color: AppColors.gray)
        ),
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
          await _loadRatings();
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
    // Calcular estadísticas
    double avgRating = 0.0;
    if (ratings.isNotEmpty) {
      final sum = ratings.fold<double>(
        0.0,
        (sum, r) {
          final stars = (r is Map ? r['estrellas'] : 0) ?? 0;
          final starsDouble = stars is int ? stars.toDouble() : (stars as double);
          return sum + starsDouble;
        }
      );
      avgRating = sum / ratings.length;
    }

    // Extraer servicios únicos
    final servicios = <String>{};
    for (var rating in ratings) {
      final servicio = rating['serviceData'] as Map<String, dynamic>? ?? {};
      final nombre = servicio['nombre'] ?? servicio['serviceName'] ?? '';
      if (nombre.isNotEmpty) {
        servicios.add(nombre);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text(widget.stylistName,
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // RESUMEN SUPERIOR
                  if (ratings.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Card(
                        color: Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Promedio
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text('Promedio',
                                        style: TextStyle(color: AppColors.gray, fontSize: 12)
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.amber, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            avgRating.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: AppColors.gold,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text('Total',
                                        style: TextStyle(color: AppColors.gray, fontSize: 12)
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '${ratings.length}',
                                        style: TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              if (servicios.isNotEmpty) ...[
                                SizedBox(height: 16),
                                Divider(color: AppColors.gold.withOpacity(0.2), height: 1),
                                SizedBox(height: 12),
                                Text('Servicios:',
                                  style: TextStyle(color: AppColors.gray, fontSize: 12)
                                ),
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: servicios.map((s) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.gold.withOpacity(0.4)),
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
                      ),
                    ),
                  ],

                  // LISTA DE CALIFICACIONES
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Historial de Calificaciones',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        if (ratings.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No hay calificaciones aún',
                                style: TextStyle(color: AppColors.gray)
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            separatorBuilder: (_, __) => SizedBox(height: 12),
                            itemCount: ratings.length,
                            itemBuilder: (context, index) {
                              return _buildRatingCard(ratings[index]);
                            },
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final estrellas = rating['estrellas'] ?? 0;
    final comentario = rating['comentario'] ?? '';
    final ratingId = rating['_id'] ?? '';
    
    final booking = rating['bookingData'] as Map<String, dynamic>? ?? {};
    final servicio = rating['serviceData'] as Map<String, dynamic>? ?? {};
    final cliente = rating['clientData'] as Map<String, dynamic>? ?? {};
    
    final serviceName = servicio['nombre'] ?? 'Servicio desconocido';
    final clienteName = '${cliente['nombre'] ?? ''} ${cliente['apellido'] ?? ''}'.trim();
    
    // Fecha
    final inicio = booking['inicio'];
    late final String fecha;
    if (inicio != null) {
      try {
        final dt = DateTime.parse(inicio.toString());
        fecha = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (e) {
        fecha = 'N/A';
      }
    } else {
      fecha = 'N/A';
    }

    return Card(
      color: Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: estrellas >= 4 ? Colors.green.withOpacity(0.3) : (estrellas >= 3 ? Colors.orange.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Estrellas y Fecha
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
                Text(fecha,
                  style: TextStyle(color: AppColors.gray, fontSize: 11)
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Servicio y Cliente
            Text(serviceName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text('Por: $clienteName',
              style: TextStyle(
                color: AppColors.gray,
                fontSize: 11,
              ),
            ),
            
            // Comentario
            if (comentario.isNotEmpty) ...[
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(comentario,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            // Botón eliminar
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _deleteRating(ratingId),
                icon: Icon(Icons.delete, size: 14),
                label: Text('Eliminar'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
