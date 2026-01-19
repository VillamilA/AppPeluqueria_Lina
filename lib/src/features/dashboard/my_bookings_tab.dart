import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../api/api_client.dart';
import '../../api/bookings_api.dart';
import '../../widgets/cancel_booking_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../booking/rating_dialog.dart';
import '../booking/reschedule_booking_dialog.dart';
import '../common/dialogs/app_dialogs.dart';
import '../../services/bookings_enrichment_service.dart';

class MyBookingsTab extends StatefulWidget {
  final String token;
  const MyBookingsTab({super.key, required this.token});

  @override
  State<MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<MyBookingsTab> {
  List<dynamic> bookings = [];
  List<dynamic> filteredBookings = [];
  bool isLoading = true;
  String errorMessage = '';
  
  // Filtros
  String filterStatus = 'ALL'; // ALL, SCHEDULED, CONFIRMED, COMPLETED, NO_SHOW, CANCELLED
  String filterPayment = 'ALL'; // ALL, PAID, UNPAID
  String filterSortBy = 'RECENT'; // RECENT, OLDEST

  @override
  void initState() {
    super.initState();
    _fetchMyBookings();
  }

  Future<void> _fetchMyBookings() async {
    try {
      setState(() => isLoading = true);
      
      final api = BookingsApi(ApiClient.instance);
      final response = await api.getClientBookings(widget.token);
      
      print('[MY_BOOKINGS] Response status: ${response.statusCode}');
      print('[MY_BOOKINGS] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawBookings = data is List ? data : data['data'] ?? [];
        
        // Enriquecer datos con información de estilista y servicio
        print('[MY_BOOKINGS] Enriqueciendo ${rawBookings.length} citas...');
        final enrichmentService = BookingsEnrichmentService(token: widget.token);
        final enrichedBookings = await enrichmentService.enrichBookings(rawBookings);
        
        setState(() {
          bookings = enrichedBookings;
          _applyFilters();
          isLoading = false;
          errorMessage = '';
        });
        
        print('[MY_BOOKINGS] ✅ Cache: ${enrichmentService.getCacheStats()}');
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar citas';
          isLoading = false;
        });
      }
    } catch (e) {
      print('[MY_BOOKINGS] Error: $e');
      setState(() {
        errorMessage = 'Error al conectar';
        isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, d MMM yyyy', 'es_ES').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getTimeRange(String? inicio, String? fin) {
    try {
      String formatTime(String? timeStr) {
        if (timeStr == null) return '-';
        final date = DateTime.parse(timeStr);
        return DateFormat('HH:mm').format(date);
      }
      return '${formatTime(inicio)} - ${formatTime(fin)}';
    } catch (e) {
      return '-';
    }
  }

  void _applyFilters() {
    List<dynamic> filtered = bookings;

    // Filtro por estado
    if (filterStatus != 'ALL') {
      filtered = filtered.where((booking) {
        return (booking['estado'] ?? 'SCHEDULED').toUpperCase() == filterStatus;
      }).toList();
    }

    // Filtro por estado de pago
    if (filterPayment != 'ALL') {
      filtered = filtered.where((booking) {
        final paymentStatus = (booking['paymentStatus'] ?? 'UNPAID').toUpperCase();
        return paymentStatus == filterPayment;
      }).toList();
    }

    // Ordenamiento por antigüedad
    if (filterSortBy == 'RECENT') {
      filtered.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['inicio'] ?? '');
          final dateB = DateTime.parse(b['inicio'] ?? '');
          return dateB.compareTo(dateA); // Más recientes primero
        } catch (e) {
          return 0;
        }
      });
    } else if (filterSortBy == 'OLDEST') {
      filtered.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['inicio'] ?? '');
          final dateB = DateTime.parse(b['inicio'] ?? '');
          return dateA.compareTo(dateB); // Más antiguos primero
        } catch (e) {
          return 0;
        }
      });
    }

    setState(() {
      filteredBookings = filtered;
    });
  }

  String _getStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'SCHEDULED':
        return 'Programada';
      case 'CONFIRMED':
        return 'Reservada';
      case 'COMPLETED':
        return 'Completada';
      case 'NO_SHOW':
        return '❌ No Asististe';
      case 'CANCELLED':
        return 'Cancelada';
      case 'PENDING_STYLIST_CONFIRMATION':
        return 'Pendiente aprobación';
      default:
        return status ?? 'Desconocido';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'SCHEDULED':
        return Colors.orange;
      case 'CONFIRMED':
        return AppColors.gold;
      case 'COMPLETED':
        return Colors.green;
      case 'NO_SHOW':
        return Colors.purple;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING_STYLIST_CONFIRMATION':
        return Colors.amber;
      default:
        return AppColors.gray;
    }
  }

  String _getPaymentStatusLabel(String? paymentStatus) {
    switch (paymentStatus?.toUpperCase()) {
      case 'PAID':
        return 'Pagado';
      case 'UNPAID':
        return 'No Pagado';
      case 'PENDING':
        return 'Pendiente';
      case 'REFUNDED':
        return 'Reembolsado';
      default:
        return paymentStatus ?? 'Desconocido';
    }
  }

  Color _getPaymentStatusColor(String? paymentStatus) {
    switch (paymentStatus?.toUpperCase()) {
      case 'PAID':
        return Colors.green.shade400;
      case 'UNPAID':
        return Colors.red.shade400;
      case 'PENDING':
        return Colors.orange.shade400;
      case 'REFUNDED':
        return Colors.blue.shade400;
      default:
        return AppColors.gray;
    }
  }

  /// Construye un filtro compacto y responsive
  Widget _buildCompactFilter(
    String label,
    String currentValue,
    List<String> values,
    List<String> labels,
    List<Color> colors,
    Function(String) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gold.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(6),
        color: AppColors.charcoal.withOpacity(0.6),
      ),
      child: DropdownButton<String>(
        value: currentValue,
        underline: SizedBox(),
        isDense: true,
        dropdownColor: AppColors.charcoal,
        style: TextStyle(color: Colors.white, fontSize: 10),
        items: List.generate(values.length, (i) {
          return DropdownMenuItem(
            value: values[i],
            child: Text(
              labels[i],
              style: TextStyle(
                color: colors[i],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        title: Text(
          'Mis Citas',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: AppColors.gold.withOpacity(0.4),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Aún no tienes reservada ninguna cita',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'con nosotros',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          Text(
                            '¡Échale un ojo a nuestros servicios!',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchMyBookings,
                      color: AppColors.gold,
                      child: Column(
                        children: [
                          // FILTROS - UNA SOLA LÍNEA
                          Container(
                            color: Colors.black26,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                // Estado
                                Expanded(
                                  child: _buildCompactFilter(
                                    'Estado',
                                    filterStatus,
                                    ['ALL', 'SCHEDULED', 'CONFIRMED', 'COMPLETED', 'NO_SHOW', 'CANCELLED'],
                                    ['Todas', 'Programadas', 'Reservadas', 'Completadas', '❌ No Asistí', 'Canceladas'],
                                    [Colors.white, Colors.orange, AppColors.gold, Colors.green, Colors.purple, Colors.red],
                                    (value) {
                                      setState(() {
                                        filterStatus = value;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                
                                // Pago
                                Expanded(
                                  child: _buildCompactFilter(
                                    'Pago',
                                    filterPayment,
                                    ['ALL', 'PAID', 'UNPAID'],
                                    ['Todos', 'Pagadas', 'No pagadas'],
                                    [Colors.white, Colors.green, Colors.red],
                                    (value) {
                                      setState(() {
                                        filterPayment = value;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                
                                // Antigüedad
                                Expanded(
                                  child: _buildCompactFilter(
                                    'Orden',
                                    filterSortBy,
                                    ['RECENT', 'OLDEST'],
                                    ['Recientes', 'Antiguos'],
                                    [Colors.white, Colors.white],
                                    (value) {
                                      setState(() {
                                        filterSortBy = value;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // LISTA
                          Expanded(
                            child: filteredBookings.isEmpty
                                ? Center(
                                    child: Text(
                                      'No hay citas con estos filtros',
                                      style: TextStyle(
                                        color: AppColors.gray,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(16),
                                    itemCount: filteredBookings.length,
                                    separatorBuilder: (_, __) =>
                                        SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final booking = filteredBookings[index];
                                      final status =
                                          booking['estado'] ?? 'SCHEDULED';

                                      // Obtener datos enriquecidos (con fallback a datos crudos)
                                      final servicioNombre =
                                          booking['service']?['nombre'] ??
                                              booking['servicioNombre'] ??
                                              'Servicio';
                                      final estilistaNombre =
                                          booking['stylist']
                                                      ?['nombre'] !=
                                                  null
                                              ? '${booking['stylist']['nombre']} ${booking['stylist']['apellido'] ?? ''}'
                                                  .trim()
                                              : '${booking['estilistaNombre'] ?? ''} ${booking['estilistaApellido'] ?? ''}'
                                                  .trim();

                                      final inicio = booking['inicio'];
                                      final fin = booking['fin'];
                                      final paymentStatus =
                                          booking['paymentStatus'] ??
                                              'UNPAID';
                          final precio = booking['precio'];
                          final invoiceNumber = booking['invoiceNumber'];
                          
                          return Card(
                            color: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _getStatusColor(status).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header con estado
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              servicioNombre,
                                              style: TextStyle(
                                                color: AppColors.gold,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Con: $estilistaNombre',
                                              style: TextStyle(
                                                color: AppColors.gray,
                                                fontSize: 12,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _formatDate(inicio),
                                              style: TextStyle(
                                                color: AppColors.gray,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusLabel(status),
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Detalles
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.charcoal,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow(
                                          'Estilista',
                                          estilistaNombre.trim(),
                                        ),
                                        SizedBox(height: 8),
                                        _buildDetailRow(
                                          'Horario',
                                          _getTimeRange(inicio, fin),
                                        ),
                                        if (precio != null) ...[
                                          SizedBox(height: 8),
                                          _buildDetailRow(
                                            'Precio',
                                            '\$${precio.toStringAsFixed(2)}',
                                          ),
                                        ],
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              'Estado de Pago:',
                                              style: TextStyle(
                                                color: AppColors.gray,
                                                fontSize: 12,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getPaymentStatusColor(paymentStatus).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _getPaymentStatusColor(paymentStatus),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                _getPaymentStatusLabel(paymentStatus),
                                                style: TextStyle(
                                                  color: _getPaymentStatusColor(paymentStatus),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (invoiceNumber != null) ...[
                                          SizedBox(height: 8),
                                          _buildDetailRow(
                                            'Factura',
                                            invoiceNumber,
                                          ),
                                        ],
                                        if (booking['notas'] != null && booking['notas'].isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Text(
                                            'Notas:',
                                            style: TextStyle(
                                              color: AppColors.gray,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            booking['notas'],
                                            style: TextStyle(
                                              color: AppColors.gold.withOpacity(0.7),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Botones de acción según estado
                                  if (status.toUpperCase() == 'COMPLETED') ...[
                                    SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.gold,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: Icon(Icons.star_outline),
                                        label: Text(
                                          'Calificar servicio',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => RatingDialog(
                                              bookingId: booking['_id'] ?? '',
                                              stylistName: estilistaNombre.trim(),
                                              serviceName: servicioNombre,
                                              token: widget.token,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ] else if (status.toUpperCase() != 'CANCELLED') ...[
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey.shade700,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: Icon(Icons.edit_calendar, size: 18),
                                            label: Text('Reprogramar', style: TextStyle(fontSize: 12)),
                                            onPressed: () {
                                              _showRescheduleDialog(booking);
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: paymentStatus == 'PAID' 
                                                  ? Colors.grey.shade600 
                                                  : Colors.green.shade700,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: Icon(Icons.payment, size: 18),
                                            label: Text('Pagar', style: TextStyle(fontSize: 12)),
                                            onPressed: paymentStatus == 'PAID' 
                                                ? null 
                                                : () {
                                                    _showPaymentDialog(booking);
                                                  },
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade700,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: Icon(Icons.cancel, size: 18),
                                            label: Text('Cancelar', style: TextStyle(fontSize: 12)),
                                            onPressed: () {
                                              _showCancelDialog(booking);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.gray,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isPrice ? AppColors.gold : AppColors.gold.withOpacity(0.8),
            fontSize: 12,
            fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _cancelBooking(String bookingId, String bookingInfo) async {
    // Mostrar diálogo para obtener el motivo
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => CancelBookingDialog(
        bookingInfo: bookingInfo,
        isStylista: false,
      ),
    );

    if (motivo == null || motivo.isEmpty) return; // Usuario canceló

    try {
      AppDialogHelper.showLoading(context);

      final api = BookingsApi(ApiClient.instance);
      final response = await api.cancelBooking(
        bookingId,
        data: {"motivo": motivo},
        token: widget.token,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      print('[CANCEL_BOOKING] Response status: ${response.statusCode}');
      print('[CANCEL_BOOKING] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppDialogHelper.showSuccess(
          context,
          title: 'Cita cancelada',
          message: 'Tu cita ha sido cancelada exitosamente',
          onAccept: () {
            Navigator.pop(context);
            _fetchMyBookings();
          },
        );
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'No puedes cancelar esta cita en este momento.';

        AppDialogHelper.showError(
          context,
          title: 'No se puede cancelar',
          message: message,
          subtitle: 'Tu cuenta ha sido congelada por 24 horas.',
        );
      } else if (response.statusCode == 403) {
        AppDialogHelper.showError(
          context,
          title: 'Acceso denegado',
          message: 'No tienes permiso para cancelar esta cita.',
        );
      } else {
        AppDialogHelper.showError(
          context,
          title: 'Error',
          message: 'Error al cancelar la cita. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading si hay excepción
      print('[CANCEL_BOOKING] Error: $e');
      AppDialogHelper.showError(
        context,
        title: 'Error',
        message: 'Error al procesar la cancelación: $e',
      );
    }
  }

  void _showCancelDialog(dynamic booking) {
    final bookingId = booking['_id'] ?? '';
    final servicioNombre = booking['servicioNombre'] ?? 'Servicio';
    final estilistaName = booking['estilistaName'] ?? 'Estilista';
    
    // Crear info para el diálogo
    final bookingInfo = '$servicioNombre con $estilistaName';

    // Llamar directamente a _cancelBooking que mostrará el diálogo de motivo
    _cancelBooking(bookingId, bookingInfo);
  }

  void _showRescheduleDialog(dynamic booking) {
    showDialog(
      context: context,
      builder: (context) => RescheduleBookingDialog(
        booking: booking,
        token: widget.token,
        onSuccess: (updatedBooking) {
          // Actualizar la lista de citas
          _fetchMyBookings();
        },
      ),
    );
  }

  Future<void> _showPaymentDialog(dynamic booking) async {
    final bookingId = booking['_id'];
    if (bookingId == null) {
      AppDialogHelper.showError(
        context,
        title: 'Error',
        message: 'No se pudo obtener el ID de la reserva',
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Solicitar información de transferencia
      final response = await http.post(
        Uri.parse('${ApiClient.instance.baseUrl}/api/v1/payments/booking/$bookingId/transfer-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final bankInfo = data['bankInfo'];
        final amount = data['amount'];

        if (bankInfo != null && mounted) {
          _showBankInfoDialog(bookingId, bankInfo, amount);
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          AppDialogHelper.showError(
            context,
            title: 'Error',
            message: errorData['message'] ?? 'No se pudo generar la solicitud de pago',
          );
        }
      }
    } catch (e) {
      // Cerrar loading si está abierto
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        AppDialogHelper.showError(
          context,
          title: 'Error de conexión',
          message: 'No se pudo conectar con el servidor: $e',
        );
      }
    }
  }

  void _showBankInfoDialog(String bookingId, Map<String, dynamic> bankInfo, dynamic amount) {
    final bank = bankInfo['bank'] ?? '';
    final accountType = bankInfo['accountType'] ?? '';
    final accountNumber = bankInfo['accountNumber'] ?? '';
    final accountHolder = bankInfo['accountHolder'] ?? '';
    final reference = bankInfo['reference'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Transferencia'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monto a pagar: \$${amount?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildInfoRow('Banco:', bank),
              _buildInfoRow('Tipo de cuenta:', accountType),
              _buildCopyableRow('Número de cuenta:', accountNumber),
              _buildInfoRow('Titular:', accountHolder),
              _buildCopyableRow('Referencia:', reference),
              const SizedBox(height: 24),
              const Text(
                'Por favor, realiza la transferencia y luego sube el comprobante.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickAndUploadProof(bookingId);
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Subir Comprobante'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copiado'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadProof(String bookingId) async {
    final ImagePicker picker = ImagePicker();
    
    // Mostrar opciones de cámara o galería
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Comprobante'),
        content: const Text('¿Cómo deseas obtener el comprobante?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      // Validar tamaño (max 2MB)
      final file = File(image.path);
      final fileSize = await file.length();
      if (fileSize > 2 * 1024 * 1024) {
        if (mounted) {
          AppDialogHelper.showError(
            context,
            title: 'Archivo muy grande',
            message: 'El comprobante no debe exceder 2 MB',
          );
        }
        return;
      }

      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Crear request multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.instance.baseUrl}/api/v1/payments/booking/$bookingId/transfer-proof'),
      );

      request.headers['Authorization'] = 'Bearer ${widget.token}';
      
      // Determinar el tipo MIME basado en la extensión del archivo
      String? mimeType;
      final extension = image.path.toLowerCase().split('.').last;
      
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Por defecto
      }
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          AppDialogHelper.showSuccess(
            context,
            title: 'Comprobante subido',
            message: 'Tu comprobante ha sido enviado correctamente. El pago será verificado pronto.',
            onAccept: () {
              _fetchMyBookings(); // Recargar las reservas
            },
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          AppDialogHelper.showError(
            context,
            title: 'Error al subir comprobante',
            message: errorData['message'] ?? 'No se pudo subir el comprobante',
          );
        }
      }
    } catch (e) {
      // Cerrar loading si está abierto
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst || !route.willHandlePopInternally);
      }
      
      if (mounted) {
        AppDialogHelper.showError(
          context,
          title: 'Error',
          message: 'No se pudo subir el comprobante: $e',
        );
      }
    }
  }
}


