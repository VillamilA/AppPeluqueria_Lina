import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../api/stylist_bookings_api.dart';
import '../../api/api_client.dart';
import 'dart:convert';

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
    // Mostrar diálogo para pedir motivo
    String? motivo;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Cancelar Cita', style: TextStyle(color: AppColors.gold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Por qué deseas cancelar esta cita?',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 12),
              TextField(
                maxLines: 3,
                onChanged: (value) => motivo = value,
                decoration: InputDecoration(
                  hintText: 'Motivo de la cancelación...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmar Cancelación', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
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
    });
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
                              print('📋 [BOOKING] Index: $index, Booking: $booking');
                              
                              // Obtener datos del cliente (solo ID en la respuesta)
                              final clienteNombre = booking['clienteNombre'] ?? 'Cliente';
                              final clienteApellido = booking['clienteApellido'] ?? '';
                              
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
                                print('Error al parsear fecha: $e');
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
                                print('Error al parsear horas: $e');
                              }

                              final estado = booking['estado'] ?? booking['status'] ?? 'SCHEDULED';

                              return Card(
                                color: AppColors.charcoal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _getStatusColor(estado).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
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
                                                  '$clienteNombre $clienteApellido',
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
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(estado).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _getStatusColor(estado),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              _getStatusLabel(estado),
                                              style: TextStyle(
                                                color: _getStatusColor(estado),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, color: AppColors.gray, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            fecha != null 
                                              ? DateFormat('d MMMM, yyyy', 'es_ES').format(fecha)
                                              : 'Sin fecha',
                                            style: TextStyle(color: AppColors.gray, fontSize: 12),
                                          ),
                                          SizedBox(width: 16),
                                          Icon(Icons.access_time, color: AppColors.gray, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            '$startTime - $endTime',
                                            style: TextStyle(color: AppColors.gray, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      if (booking['notas'] != null && booking['notas'].toString().isNotEmpty) ...[
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade800,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            booking['notas'],
                                            style: TextStyle(
                                              color: AppColors.gray,
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                      ],
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (estado == 'SCHEDULED')
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                onPressed: () => _confirmBooking(booking['_id']),
                                                child: Text('Confirmar'),
                                              ),
                                            ),
                                          if (estado == 'CONFIRMED')
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.gold,
                                                  foregroundColor: Colors.black,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                onPressed: () => _completeBooking(booking['_id']),
                                                child: Text('Completar'),
                                              ),
                                            ),
                                          if (estado != 'COMPLETED' && estado != 'CANCELLED')
                                            SizedBox(width: 8),
                                          if (estado != 'COMPLETED' && estado != 'CANCELLED')
                                            Expanded(
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: BorderSide(color: Colors.red),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                onPressed: () => _cancelBooking(booking['_id']),
                                                child: Text('Cancelar'),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
