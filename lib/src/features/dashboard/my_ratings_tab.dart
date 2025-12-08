import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/ratings_api.dart';
import '../../api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MyRatingsTab extends StatefulWidget {
  final String token;

  const MyRatingsTab({
    super.key,
    required this.token,
  });

  @override
  State<MyRatingsTab> createState() => _MyRatingsTabState();
}

class _MyRatingsTabState extends State<MyRatingsTab> {
  late RatingsApi _ratingsApi;
  List<dynamic> _ratings = [];
  bool _loading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _ratingsApi = RatingsApi(ApiClient.instance);
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      print('🔵 [MY_RATINGS] Iniciando carga de calificaciones...');
      setState(() {
        _loading = true;
        _errorMessage = '';
      });

      final response = await _ratingsApi.getMyRatings(widget.token);
      print('📥 [MY_RATINGS] Response status: ${response.statusCode}');
      print('📥 [MY_RATINGS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [MY_RATINGS] Data type: ${data.runtimeType}');

        final ratingsList = data is List ? data : (data['data'] ?? []);
        print('✅ [MY_RATINGS] Calificaciones recibidas: ${ratingsList.length}');

        setState(() {
          _ratings = ratingsList;
          _loading = false;
        });
      } else if (response.statusCode == 401) {
        print('❌ [MY_RATINGS] 401 - No autorizado');
        setState(() {
          _errorMessage = 'No autorizado. Por favor, vuelve a iniciar sesión.';
          _loading = false;
        });
      } else {
        print('❌ [MY_RATINGS] Error ${response.statusCode}');
        setState(() {
          _errorMessage = 'Error al cargar las calificaciones (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e, st) {
      print('❌ [MY_RATINGS] Excepción: $e');
      print('   Stack: $st');
      setState(() {
        _errorMessage = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis Calificaciones',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _ratings.isEmpty
                        ? Center(
                            child: Text(
                              'No has realizado calificaciones aún',
                              style: TextStyle(color: AppColors.gray),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _ratings.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final rating = _ratings[index];
                              return _buildRatingCard(rating);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(dynamic rating) {
    // Obtener nombre del estilista - puede estar en diferentes formatos
    String estilistaNombre = 'Estilista';
    if (rating['stylistId'] != null) {
      if (rating['stylistId'] is Map) {
        final nombre = rating['stylistId']['nombre'] ?? '';
        final apellido = rating['stylistId']['apellido'] ?? '';
        estilistaNombre = '$nombre $apellido'.trim();
      } else {
        estilistaNombre = rating['stylistId'].toString();
      }
    }

    // Obtener nombre del servicio - puede estar en diferentes formatos
    String servicioNombre = 'Servicio';
    if (rating['bookingId'] != null) {
      if (rating['bookingId'] is Map) {
        servicioNombre = rating['bookingId']['servicioNombre'] ?? 'Servicio';
      }
    }

    final estrellas = rating['estrellas'] ?? 0;
    final comentario = rating['comentario'] ?? '';
    
    DateTime? fecha;
    try {
      if (rating['createdAt'] != null) {
        fecha = DateTime.parse(rating['createdAt'].toString());
      }
    } catch (e) {
      // Ignorar error de parsing
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estilistaNombre,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      servicioNombre,
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '$estrellas.0',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  Icons.star,
                  color: i < estrellas ? Colors.amber : Colors.grey.shade700,
                  size: 14,
                );
              }),
            ],
          ),
          if (comentario.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comentario,
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          SizedBox(height: 8),
          Text(
            fecha != null ? DateFormat('d MMM, yyyy', 'es_ES').format(fecha) : 'Fecha desconocida',
            style: TextStyle(color: AppColors.gray, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
