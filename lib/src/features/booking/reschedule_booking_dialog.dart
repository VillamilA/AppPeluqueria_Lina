import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../core/theme/app_theme.dart';
import '../../api/bookings_api.dart';
import '../../api/api_client.dart';
import '../../services/bookings_enrichment_service.dart';
import '../../services/notification_service.dart';

class RescheduleBookingDialog extends StatefulWidget {
  final dynamic booking;
  final String token;
  final Function(dynamic) onSuccess;

  const RescheduleBookingDialog({
    super.key,
    required this.booking,
    required this.token,
    required this.onSuccess,
  });

  @override
  State<RescheduleBookingDialog> createState() => _RescheduleBookingDialogState();
}

class _RescheduleBookingDialogState extends State<RescheduleBookingDialog> {
  late BookingsApi _bookingsApi;
  late dynamic _enrichedBooking;
  
  DateTime? _selectedDate;
  String? _selectedSlotId;
  List<dynamic> _availableSlots = [];
  bool _loadingSlots = false;
  bool _sendingReschedule = false;
  bool _enrichingData = true;
  String? _errorMessage;

  late int _horasRestantes;
  late bool _puedesReprogramar;

  @override
  void initState() {
    super.initState();
    _bookingsApi = BookingsApi(ApiClient.instance);
    _enrichedBooking = widget.booking;
    _enrichBookingData();
  }

  /// Enriquecer datos del booking con información de estilista y servicio
  Future<void> _enrichBookingData() async {
    try {
      print('🔄 Enriqueciendo datos del booking...');
      final enrichmentService = BookingsEnrichmentService(token: widget.token);
      final enrichedList = await enrichmentService.enrichBookings([widget.booking]);
      
      if (enrichedList.isNotEmpty) {
        setState(() {
          _enrichedBooking = enrichedList[0];
          _enrichingData = false;
        });
        print('✅ Datos enriquecidos exitosamente');
      } else {
        setState(() {
          _enrichedBooking = widget.booking;
          _enrichingData = false;
        });
      }
    } catch (e) {
      print('⚠️ Error enriqueciendo datos: $e');
      setState(() {
        _enrichedBooking = widget.booking;
        _enrichingData = false;
      });
    }
    
    _validateReschedule();
  }

  void _validateReschedule() {
    try {
      final inicio = _enrichedBooking['inicio'];
      if (inicio != null) {
        final fechaCita = DateTime.parse(inicio.toString());
        final ahora = DateTime.now();
        _horasRestantes = fechaCita.difference(ahora).inHours;
        _puedesReprogramar = _horasRestantes >= 12;
      } else {
        _horasRestantes = 0;
        _puedesReprogramar = false;
      }
    } catch (e) {
      print('Error validando plazo: $e');
      _horasRestantes = 0;
      _puedesReprogramar = false;
    }
  }

  /// Obtener slots disponibles para la fecha seleccionada
  Future<void> _loadAvailableSlots(DateTime date) async {
    setState(() {
      _loadingSlots = true;
      _errorMessage = null;
      _selectedSlotId = null;
      _availableSlots = [];
    });

    try {
      final servicioId = _enrichedBooking['servicioId'];
      final estilistaId = _enrichedBooking['estilistaId'];

      if (servicioId == null || estilistaId == null) {
        setState(() {
          _errorMessage = 'No se pudo obtener información del servicio o estilista';
          _loadingSlots = false;
        });
        return;
      }

      print('📅 Cargando slots para:');
      print('   Servicio: $servicioId');
      print('   Estilista: $estilistaId');
      print('   Fecha: ${_formatDateForApi(date)}');

      // Obtener slots disponibles
      final response = await _bookingsApi.getSlots(
        serviceId: servicioId,
        stylistId: estilistaId,
        date: _formatDateForApi(date),
      );

      print('📅 Response status: ${response.statusCode}');
      print('📅 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle both array and object with data property
        List<dynamic> slots = [];
        if (data is List) {
          slots = data;
        } else if (data is Map && data['data'] is List) {
          slots = data['data'];
        } else if (data is Map && data['slots'] is List) {
          slots = data['slots'];
        }

        print('📅 Slots encontrados: ${slots.length}');

        // Los slots ya deben ser del estilista correcto del backend
        setState(() {
          _availableSlots = slots;
          _loadingSlots = false;
          if (slots.isEmpty) {
            _errorMessage = 'No hay horarios disponibles para esta fecha con ${widget.booking['estilistaNombre']}';
          }
        });
      } else {
        print('❌ Error status: ${response.statusCode}');
        setState(() {
          _errorMessage = 'Error al cargar disponibilidad: ${response.statusCode}';
          _loadingSlots = false;
        });
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _loadingSlots = false;
      });
    }
  }

  /// Enviar solicitud de reprogramación
  Future<void> _submitReschedule() async {
    if (_selectedDate == null || _selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona fecha y horario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _sendingReschedule = true;
      _errorMessage = null;
    });

    try {
      final bookingId = _enrichedBooking['_id'];
      
      print('📤 Reprogramando:');
      print('   Booking ID: $bookingId');
      print('   Slot ID: $_selectedSlotId');
      print('   Fecha: ${_formatDateForApi(_selectedDate!)}');

      final response = await _bookingsApi.rescheduleBooking(
        bookingId,
        data: {
          'slotId': _selectedSlotId,
          'date': _formatDateForApi(_selectedDate!),
        },
        token: widget.token,
      );

      print('📤 Response status: ${response.statusCode}');
      print('📤 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final updatedBooking = jsonDecode(response.body);
        
        // Extraer información para la notificación (misma lógica que en el dialog)
        final servicioNombre = _enrichedBooking['servicioNombre'] ?? 
                               _enrichedBooking['service']?['nombre'] ?? 
                               'Servicio';
        final estilistaNombre = _enrichedBooking['estilistaNombre'] ?? 
                                (_enrichedBooking['stylist'] != null
                                    ? '${_enrichedBooking['stylist']['nombre']} ${_enrichedBooking['stylist']['apellido'] ?? ''}'.trim()
                                    : 'Estilista');
        final fechaCitaAnterior = _formatDateDisplay(DateTime.parse(_enrichedBooking['inicio']));
        final horaCitaAnterior = _formatTimeDisplay(_enrichedBooking['inicio']);
        final fechaCitaNueva = _formatDateDisplay(_selectedDate!);
        final horaCitaNueva = _formatTimeDisplay(
          _availableSlots
              .firstWhere((s) => s['slotId'] == _selectedSlotId || s['_id'] == _selectedSlotId)['start'] ?? ''
        );

        // Enviar notificación
        final notificationService = NotificationService();
        await notificationService.notifyBookingRescheduled(
          serviceName: servicioNombre,
          stylistName: estilistaNombre,
          oldDate: fechaCitaAnterior,
          oldTime: horaCitaAnterior,
          newDate: fechaCitaNueva,
          newTime: horaCitaNueva,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cita reprogramada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          widget.onSuccess(updatedBooking);
        }
      } else if (response.statusCode == 403) {
        setState(() {
          _errorMessage = 'Reprogramación fuera de plazo. La cita debe estar a más de 12 horas de distancia. Contacta a administración.';
          _sendingReschedule = false;
        });
      } else if (response.statusCode == 409) {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = 'Horario no disponible: ${errorData['message'] ?? 'Intenta con otro horario'}';
          _sendingReschedule = false;
        });
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = 'Error en la solicitud: ${errorData['message'] ?? 'Verifica los datos'}';
          _sendingReschedule = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode}';
          _sendingReschedule = false;
        });
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _sendingReschedule = false;
      });
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateDisplay(DateTime date) {
    return DateFormat('d MMM yyyy', 'es_ES').format(date);
  }

  /// Extraer solo la hora en formato HH:MM (24 horas)
  /// Maneja: "HH:MM", "HH:MM:SS", "09:30:00" → "09:30"
  String _formatTimeDisplay(String timeStr) {
    try {
      if (timeStr.isEmpty) return '';
      
      // Si contiene "T" es un ISO string, tomar la parte de la hora
      if (timeStr.contains('T')) {
        final parts = timeStr.split('T');
        timeStr = parts.length > 1 ? parts[1] : timeStr;
      }
      
      // Dividir por ":" y tomar solo horas y minutos
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        final horas = parts[0].padLeft(2, '0');
        final minutos = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
        return '$horas:$minutos';
      }
      
      return timeStr;
    } catch (e) {
      print('Error formateando hora: $e');
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading si aún se están enriqueciendo los datos
    if (_enrichingData) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.charcoal,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.gold),
              const SizedBox(height: 16),
              const Text(
                'Cargando información de la cita...',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final servicioNombre = _enrichedBooking['servicioNombre'] ?? 
                           _enrichedBooking['service']?['nombre'] ?? 
                           'Servicio';
    final estilistaNombre = _enrichedBooking['estilistaNombre'] ?? 
                            _enrichedBooking['stylist'] != null
                                ? '${_enrichedBooking['stylist']['nombre']} ${_enrichedBooking['stylist']['apellido'] ?? ''}'.trim()
                                : 'Estilista';
    final fechaCita = _enrichedBooking['inicio'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.charcoal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =============== ENCABEZADO ===============
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reprogramar Cita',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.gold),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.gold, height: 20),
              const SizedBox(height: 8),

              // =============== DETALLES ACTUALES ===============
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.charcoal.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: AppColors.gold, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Información Actual',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Servicio:', servicioNombre),
                    const SizedBox(height: 8),
                    _buildInfoRow('Estilista:', estilistaNombre),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Fecha Actual:',
                      _formatDateDisplay(DateTime.parse(fechaCita)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // =============== VALIDACIÓN DE PLAZO 12 HORAS ===============
              if (!_puedesReprogramar)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '❌ No puedes reprogramar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Faltan $_horasRestantes horas. Necesitas 12 horas de anticipación.',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Contacta a administración para opciones alternativas.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '✅ Puedes reprogramar (faltan $_horasRestantes horas)',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_puedesReprogramar) ...[
                const SizedBox(height: 24),

                // =============== SELECCIONAR NUEVA FECHA ===============
                const Text(
                  'Selecciona Nueva Fecha',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.gold,
                              surface: AppColors.charcoal,
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      await _loadAvailableSlots(picked);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gold, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      _selectedDate == null
                          ? '📅 Elegir Fecha'
                          : '📅 ${_formatDateDisplay(_selectedDate!)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =============== SELECCIONAR HORARIO ===============
                const Text(
                  'Selecciona Horario',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${estilistaNombre} - Mismo estilista',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),

                // =============== MOSTRAR SLOTS O LOADING ===============
                if (_loadingSlots)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  )
                else if (_availableSlots.isEmpty && _selectedDate != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No hay horarios disponibles para esta fecha',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_selectedDate == null)
                  Text(
                    'Selecciona una fecha para ver horarios disponibles',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.3),
                      ),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      padding: const EdgeInsets.all(8),
                      itemCount: _availableSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _availableSlots[index];
                        final slotId = slot['slotId'] ?? slot['_id'] ?? '';
                        final hora = slot['start'] ?? slot['hora'] ?? '';
                        final isSelected = _selectedSlotId == slotId;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedSlotId = slotId),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.charcoal.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.gold
                                    : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: isSelected ? Colors.black : AppColors.gold,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimeDisplay(hora),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.black : AppColors.gold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                // =============== MOSTRAR ERROR SI EXISTE ===============
                if (_errorMessage != null && _errorMessage!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),

                const SizedBox(height: 20),

                // =============== BOTONES ===============
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _sendingReschedule ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _sendingReschedule ||
                                _selectedDate == null ||
                                _selectedSlotId == null
                            ? null
                            : _submitReschedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _sendingReschedule
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Text(
                                'Reprogramar',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Widget helper para mostrar información
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

