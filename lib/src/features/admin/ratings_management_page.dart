import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/search_bar_widget.dart';

/// Página para ver calificaciones de estilistas (GERENTE)
/// GERENTE solo puede ver: promedio de estrellas
class RatingsManagementPage extends StatefulWidget {
  final String token;

  const RatingsManagementPage({super.key, required this.token});

  @override
  State<RatingsManagementPage> createState() => _RatingsManagementPageState();
}

class _RatingsManagementPageState extends State<RatingsManagementPage> {
  List<dynamic> stylists = [];
  List<dynamic> filteredStylists = [];
  Map<String, double> stylistAvgRatings = {};
  Map<String, int> stylistTotalRatings = {};
  
  bool loading = true;
  String searchQuery = '';
  
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _fetchStylists();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStylists() async {
    try {
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
            _loadStylistRatings(stylistId);
          }
        }
        
        setState(() {
          stylists = stylistsList;
          filteredStylists = stylistsList;
          loading = false;
        });
        print('✅ Estilistas cargados: ${stylists.length}');
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _loadStylistRatings(String stylistId) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/ratings/stylist/$stylistId?limit=100',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final ratingsList = data is Map 
          ? (data['data'] as List? ?? [])
          : (data is List ? data : []);
        
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
            stylistTotalRatings[stylistId] = ratingsList.length;
          });
          print('⭐ ${stylistId}: ${avgRating.toStringAsFixed(1)} (${ratingsList.length} ratings)');
        } else {
          setState(() {
            stylistAvgRatings[stylistId] = 0.0;
            stylistTotalRatings[stylistId] = 0;
          });
        }
      }
    } catch (e) {
      print('❌ Error cargando ratings: $e');
      setState(() {
        stylistAvgRatings[stylistId] = 0.0;
        stylistTotalRatings[stylistId] = 0;
      });
    }
  }

  void _applyFilter() {
    final query = searchQuery.toLowerCase();
    List<dynamic> temp = stylists;

    if (searchQuery.isNotEmpty) {
      temp = temp.where((s) {
        final nombre = (s['nombre'] ?? '').toString().toLowerCase();
        final apellido = (s['apellido'] ?? '').toString().toLowerCase();
        
        return nombre.contains(query) || apellido.contains(query);
      }).toList();
    }

    setState(() {
      filteredStylists = temp;
    });
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
                        
                        return _buildStylistCard(stylist, stylistId, nombre, apellido);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStylistCard(Map<String, dynamic> stylist, String stylistId, 
    String nombre, String apellido) {
    
    final avgRating = stylistAvgRatings[stylistId] ?? 0.0;
    final totalRatings = stylistTotalRatings[stylistId] ?? 0;

    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.gold.withOpacity(0.2)),
      ),
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      Icon(Icons.star, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: TextStyle(
                          color: avgRating > 0 ? Colors.orange : AppColors.gray,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '($totalRatings)',
                        style: TextStyle(color: AppColors.gray, fontSize: 12),
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
