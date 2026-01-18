import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../api/stylist_bookings_api.dart';
import '../../api/api_client.dart';
import 'dart:convert';
import '../../widgets/cancel_booking_dialog.dart';
import 'widgets/stylist_booking_card.dart';

class StylistBookingsTab extends StatefulWidget {
  final String token;

  const StylistBookingsTab({
    super.key,
    required this.token,
  });

  @override
  State<StylistBookingsTab> createState() => _StylistBookingsTabState();
}

class _StylistBookingsTabState extends State<StylistBookingsTab> {
  late StylistBookingsApi _api;
  List<dynamic> _bookings = [];
  bool _loading = true;
  String _filterStatus = 'SCHEDULED';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _api = StylistBookingsApi(ApiClient.instance);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    try {
      print('🔵 [STYLIST_BOOKINGS] Iniciando carga de citas...');
      print('   Token: ${widget.token.substring(0, 20)}...');
      
      final response = await _api.getMyBookings(widget.token);
      print('📥 [STYLIST_BOOKINGS] Response status: ${response.statusCode}');
      print('📥 [STYLIST_BOOKINGS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [STYLIST_BOOKINGS] Data type: ${data.runtimeType}');
        print('✅ [STYLIST_BOOKINGS] Data keys: ${data.keys}');
        
        final bookingsList = data['data'] ?? [];
        print('✅ [STYLIST_BOOKINGS] Bookings recibidas: ${bookingsList.length}');
        
        if (bookingsList.isNotEmpty) {
          for (int i = 0; i < bookingsList.length; i++) {
            print('   [$i] Status: ${bookingsList[i]['status']}, ID: ${bookingsList[i]['_id']}');
          }
        }
        
        setState(() {
          _bookings = bookingsList;
          _errorMessage = '';
          _loading = false;
        });
      } else if (response.statusCode == 401) {
        print('❌ [STYLIST_BOOKINGS] 401 - No autorizado');
        setState(() {
          _errorMessage = 'No autorizado. Por favor, vuelve a iniciar sesión.';
          _loading = false;
        });
      } else {
        print('❌ [STYLIST_BOOKINGS] Error ${response.statusCode}');
        setState(() {
          _errorMessage = 'Error al cargar las reservas (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e, st) {
      print('❌ [STYLIST_BOOKINGS] Excepción: $e');
      print('   Stack: $st');
      setState(() {
        _errorMessage = 'Error: $e';
        _loading = false;
      });
    }
  }

  List<dynamic> get _filteredBookings {
    return _bookings.where((b) {
      final status = b['estado'] ?? b['status'] ?? '';
      return status == _filterStatus;
    }).toList();
  }

  Future<void> _confirmBooking(String bookingId) async {
    try {
      final response = await _api.confirmBooking(bookingId, widget.token);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reserva confirmada'), backgroundColor: Colors.green),
        );
        await _loadBookings();
        // Cambiar automáticamente al tab de "Confirmadas"
        setState(() => _filterStatus = 'CONFIRMED');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _completeBooking(String bookingId) async {
    try {
      final response = await _api.completeBooking(bookingId, widget.token);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reserva completada'), backgroundColor: Colors.green),
        );
        await _loadBookings();
        // Cambiar automáticamente al tab de "Completadas"
        setState(() => _filterStatus = 'COMPLETED');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al completar'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    // Encontrar la info de la reserva para mostrar en el diálogo
    final booking = _bookings.firstWhere((b) => b['_id'] == bookingId, orElse: () => {});
    final clientName = booking['clientName'] ?? 'Cliente';
    
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => CancelBookingDialog(
        bookingInfo: clientName,
      ),
    );
    
    if (motivo != null && motivo.isNotEmpty) {
      try {
        final response = await _api.cancelBooking(bookingId, widget.token, motivo: motivo);
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Reserva cancelada'), backgroundColor: Colors.green),
            );
            await _loadBookings();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al cancelar'), backgroundColor: Colors.red),
            );
          }
        } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    final estado = status.toUpperCase();
    switch (estado) {
      case 'SCHEDULED':
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    final estado = status.toUpperCase();
    switch (estado) {
      case 'SCHEDULED':
      case 'PENDING':
        return 'Pendiente';
      case 'CONFIRMED':
        return 'Confirmada';
      case 'COMPLETED':
        return 'Completada';
      case 'CANCELLED':
        return 'Cancelada';
      default:
        return estado;
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
            'Mis Citas',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('SCHEDULED', 'Pendientes'),
                SizedBox(width: 8),
                _buildStatusChip('CONFIRMED', 'Confirmadas'),
                SizedBox(width: 8),
                _buildStatusChip('COMPLETED', 'Completadas'),
                SizedBox(width: 8),
                _buildStatusChip('CANCELLED', 'Canceladas'),
              ],
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
                    : _filteredBookings.isEmpty
                        ? Center(
                            child: Text(
                              'No hay reservas ${_getStatusLabel(_filterStatus).toLowerCase()}',
                              style: TextStyle(color: AppColors.gray),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredBookings.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final booking = _filteredBookings[index];
                              
                              // Obtener datos del cliente
                              final clienteNombre = booking['clienteNombre'] ?? 'Cliente';
                              final clienteApellido = booking['clienteApellido'] ?? '';
                              final fullClientName = '$clienteNombre $clienteApellido'.trim();
                              
                              // Obtener nombre del servicio
                              final servicioNombre = booking['servicioNombre'] ?? 'Servicio';
                              
                              // Parsear fechas
                              DateTime? fecha;
                              try {
                                final inicioStr = booking['inicio']?.toString();
                                if (inicioStr != null) {
                                  fecha = DateTime.parse(inicioStr);
                                }
                              } catch (e) {
                                // Fecha inválida
                              }
                              
                              // Obtener horas
                              String startTime = '--:--';
                              String endTime = '--:--';
                              try {
                                if (booking['inicio'] != null) {
                                  final inicio = DateTime.parse(booking['inicio']);
                                  startTime = '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
                                }
                                if (booking['fin'] != null) {
                                  final fin = DateTime.parse(booking['fin']);
                                  endTime = '${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}';
                                }
                              } catch (e) {
                                // Horas inválidas
                              }

                              final estado = booking['estado'] ?? booking['status'] ?? 'SCHEDULED';
                              final notas = booking['notas'];

                              return StylistBookingCard(
                                clientName: fullClientName,
                                serviceName: servicioNombre,
                                date: fecha,
                                startTime: startTime,
                                endTime: endTime,
                                status: estado.toUpperCase(),
                                statusColor: _getStatusColor(estado),
                                statusLabel: _getStatusLabel(estado),
                                notes: notas,
                                onConfirm: (estado == 'SCHEDULED' || estado == 'PENDING')
                                    ? () => _confirmBooking(booking['_id'])
                                    : null,
                                onComplete: (estado == 'CONFIRMED')
                                    ? () => _completeBooking(booking['_id'])
                                    : null,
                                onCancel: (estado != 'COMPLETED' && estado != 'CANCELLED')
                                    ? () => _cancelBooking(booking['_id'])
                                    : null,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
      backgroundColor: Colors.grey.shade800,
      selectedColor: _getStatusColor(status).withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? _getStatusColor(status) : AppColors.gray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? _getStatusColor(status) : Colors.transparent,
        width: 1.5,
      ),
    );
  }
}
