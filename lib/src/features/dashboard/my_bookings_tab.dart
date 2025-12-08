import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../api/bookings_api.dart';
import '../../core/theme/app_theme.dart';
import '../booking/rating_dialog.dart';
import '../common/dialogs/app_dialogs.dart';

class MyBookingsTab extends StatefulWidget {
  final String token;
  const MyBookingsTab({super.key, required this.token});

  @override
  State<MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<MyBookingsTab> {
  List<dynamic> bookings = [];
  bool isLoading = true;
  String errorMessage = '';

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
        setState(() {
          bookings = data is List ? data : data['data'] ?? [];
          isLoading = false;
          errorMessage = '';
        });
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

  String _getStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'SCHEDULED':
        return 'Programada';
      case 'CONFIRMED':
        return 'Confirmada';
      case 'COMPLETED':
        return 'Completada';
      case 'CANCELLED':
        return 'Cancelada';
      case 'PENDING':
        return 'Pendiente';
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
      case 'CANCELLED':
        return Colors.red;
      default:
        return AppColors.gray;
    }
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
                      child: ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: bookings.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final status = booking['estado'] ?? 'SCHEDULED';
                          final servicioNombre = booking['servicioNombre'] ?? 'Servicio';
                          final estilistaNombre = '${booking['estilistaNombre'] ?? ''} ${booking['estilistaApellido'] ?? ''}';
                          final inicio = booking['inicio'];
                          final fin = booking['fin'];
                          
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
                                          horizontal: 12,
                                          vertical: 6,
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
                                            fontSize: 12,
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
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: Icon(Icons.edit_calendar),
                                            label: Text('Reprogramar'),
                                            onPressed: () {
                                              _showRescheduleDialog(booking);
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade700,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: Icon(Icons.cancel),
                                            label: Text('Cancelar'),
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

  Future<void> _cancelBooking(String bookingId) async {
    try {
      AppDialogHelper.showLoading(context);

      final api = BookingsApi(ApiClient.instance);
      final response = await api.cancelBooking(
        bookingId,
        data: {"motivo": "Cancelado por cliente"},
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
    final inicio = booking['inicio'];
    
    // Calcular horas restantes
    int horasRestantes = 0;
    try {
      if (inicio != null) {
        final fechaCita = DateTime.parse(inicio.toString());
        final ahora = DateTime.now();
        horasRestantes = fechaCita.difference(ahora).inHours;
      }
    } catch (e) {
      print('Error calculando horas restantes: $e');
    }

    final bool puedesCancelar = horasRestantes >= 12;
    
    AppDialogHelper.showConfirm(
      context,
      title: '¿Cancelar esta cita?',
      message: servicioNombre,
      subtitle: puedesCancelar 
        ? null 
        : 'Tu cuenta será congelada por 24 horas si cancelas ahora.',
      confirmText: 'Confirmar cancelación',
      cancelText: 'Volver',
      isDestructive: true,
      onConfirm: () => _cancelBooking(bookingId),
    );
  }

  void _showRescheduleDialog(dynamic booking) {
    final servicioNombre = booking['servicioNombre'] ?? 'Servicio';
    final inicio = booking['inicio'];
    
    // Calcular horas restantes
    int horasRestantes = 0;
    try {
      if (inicio != null) {
        final fechaCita = DateTime.parse(inicio.toString());
        final ahora = DateTime.now();
        horasRestantes = fechaCita.difference(ahora).inHours;
      }
    } catch (e) {
      print('Error calculando horas restantes: $e');
    }

    final bool puedesReprogramar = horasRestantes >= 12;
    final String message = '$servicioNombre\n\n${puedesReprogramar ? 'Puedes reprogramar sin restricciones. Faltan $horasRestantes horas.' : 'Tu cuenta será congelada por 24 horas si reprogramas ahora.'}\n\nPor favor, contacta con nosotros:\n+1-234-567-8900\npeluqueria@lina.com';

    AppDialogHelper.showInfo(
      context,
      title: '¿Reprogramar esta cita?',
      message: message,
      buttonText: 'Cerrar',
    );
  }
}


