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
      final status = (b['estado'] ?? b['status'] ?? '').toString().toUpperCase();
      return status == _filterStatus.toUpperCase();
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
      // Mostrar diálogo para preguntar si el cliente asistió
      final clienteAsistio = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            '¿El cliente asistió?',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.charcoal,
          content: Text(
            'Selecciona si el cliente asistió a la cita',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: Text('❌ No asistió'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('✅ Sí asistió'),
            ),
          ],
        ),
      );

      if (clienteAsistio == null) return; // Usuario canceló

      final response = await _api.completeBooking(
        bookingId,
        widget.token,
        clienteAsistio: clienteAsistio,
        precio: null,
      );
      if (response.statusCode == 200) {
        final statusText = clienteAsistio ? 'Reserva completada' : 'Marcado como no asistió';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusText),
            backgroundColor: clienteAsistio ? Colors.green : Colors.purple,
          ),
        );
        await _loadBookings();
        // Cambiar automáticamente al tab de estado correspondiente
        setState(() => _filterStatus = clienteAsistio ? 'COMPLETED' : 'NO_SHOW');
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
        isStylista: true,
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
      case 'PENDING_STYLIST_CONFIRMATION':
        return Colors.orange;
      case 'SCHEDULED':
      case 'PENDING':
        return Colors.amber;
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
      case 'PENDING_STYLIST_CONFIRMATION':
        return 'Pendiente de confirmar';
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
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════
                // ENCABEZADO CON GRADIENTE
                // ═══════════════════════════════════════════
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.gold.withOpacity(0.2),
                        AppColors.gold.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Citas',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.gold.withOpacity(0.7), size: 16),
                          SizedBox(width: 8),
                          Text(
                            '${_bookings.length} reservas en total',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // ═══════════════════════════════════════════
                // FILTROS CON ESTILO MEJORADO
                // ═══════════════════════════════════════════
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('PENDING_STYLIST_CONFIRMATION', '🔔 Por confirmar', Colors.orange),
                      SizedBox(width: 10),
                      _buildStatusChip('SCHEDULED', '⏳ Pendientes', Colors.amber),
                      SizedBox(width: 10),
                      _buildStatusChip('CONFIRMED', '✓ Confirmadas', Colors.blue),
                      SizedBox(width: 10),
                      _buildStatusChip('COMPLETED', '✓✓ Completadas', Colors.green),
                      SizedBox(width: 10),
                      _buildStatusChip('CANCELLED', '✕ Canceladas', Colors.red),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // ═══════════════════════════════════════════
                // CONTENIDO: Citas o Mensaje Vacío
                // ═══════════════════════════════════════════
                _loading
                    ? Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : _errorMessage.isNotEmpty
                        ? Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _filteredBookings.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.event_note,
                                        color: AppColors.gray.withOpacity(0.5),
                                        size: 48,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No hay citas ${_getStatusLabel(_filterStatus).toLowerCase()}',
                                        style: TextStyle(
                                          color: AppColors.gray,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _filteredBookings.length,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
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
                                    onConfirm: (estado == 'SCHEDULED' || estado == 'PENDING' || estado == 'PENDING_STYLIST_CONFIRMATION')
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String label, Color color) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.25)
              : Colors.grey.shade800.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.gray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
