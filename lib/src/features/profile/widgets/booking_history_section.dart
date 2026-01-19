import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../api/bookings_api.dart';
import '../../../api/api_client.dart';
import '../../../services/bookings_enrichment_service.dart';
import 'dart:convert';

class BookingHistorySection extends StatefulWidget {
  final String token;
  final String userRole;

  const BookingHistorySection({
    super.key,
    required this.token,
    required this.userRole,
  });

  @override
  State<BookingHistorySection> createState() => _BookingHistorySectionState();
}

class _BookingHistorySectionState extends State<BookingHistorySection> {
  List<dynamic> _bookings = [];
  bool _loading = true;
  String _errorMessage = '';

  late BookingsApi _bookingsApi;

  @override
  void initState() {
    super.initState();
    _bookingsApi = BookingsApi(ApiClient.instance);
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      setState(() => _loading = true);
      final response = await _bookingsApi.getClientBookings(widget.token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawBookings = data is List ? data : (data['data'] ?? []);
        
        // Enriquecer datos con información de estilista y servicio
        final enrichmentService = BookingsEnrichmentService(token: widget.token);
        final enrichedBookings = await enrichmentService.enrichBookings(rawBookings);
        
        setState(() {
          _bookings = enrichedBookings;
          _errorMessage = '';
        });
      } else {
        setState(() => _errorMessage = 'No se pudo cargar el historial');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy', 'es_ES').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '-';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'RESERVADA':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'SCHEDULED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING_STYLIST_CONFIRMATION':
        return 'Pendiente aprobación';
      case 'CONFIRMED':
        return 'Reservada';
      case 'COMPLETED':
        return 'Completada';
      case 'CANCELLED':
        return 'Cancelada';
      case 'SCHEDULED':
        return 'Programada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No hay citas registradas',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Citas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _bookings.length,
            separatorBuilder: (_, __) => Divider(color: Colors.grey.shade700),
            itemBuilder: (context, index) {
              final booking = _bookings[index];
              
              // Obtener datos enriquecidos con fallback
              final servicioNombre = booking['service']?['nombre'] ?? 
                                     booking['servicioNombre'] ?? 
                                     'Servicio';
              final estilistaNombre = booking['stylist'] != null
                  ? '${booking['stylist']['nombre']} ${booking['stylist']['apellido'] ?? ''}'.trim()
                  : '${booking['estilistaNombre'] ?? ''} ${booking['estilistaApellido'] ?? ''}'.trim();
              
              final inicio = booking['inicio'];
              final fecha = _formatDate(inicio);
              final hora = _formatTime(inicio);
              final estado = _getStatusLabel(booking['estado'] ?? 'UNKNOWN');
              final precio = booking['precio'] ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Servicio y Estilista
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.content_cut,
                            color: AppColors.gold,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                servicioNombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Con: $estilistaNombre',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Fecha, Hora y Precio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$fecha, $hora',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(booking['estado'] ?? '').withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                estado,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(booking['estado'] ?? ''),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${precio.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _fetchBookings,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gold),
              ),
              child: const Text(
                'Actualizar',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
