import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../api/api_client.dart';
import '../../api/bookings_api.dart';
import 'widgets/stylists_selection_card.dart';
import 'widgets/scrollable_week_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class BookingFlowPage extends StatefulWidget {
  final dynamic service;
  final String token;
  final String clienteId;
  final String userRole;
  final List<dynamic> stylists;
  final String? targetStylistId; // Para gerentes/admins que quieran reservar para un estilista específico

  const BookingFlowPage({
    super.key,
    required this.service,
    required this.token,
    required this.clienteId,
    required this.userRole,
    required this.stylists,
    this.targetStylistId,
  });

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> {
  // Estado
  dynamic _selectedStylist;
  DateTime? _selectedDate;
  String? _selectedSlotId;
  List<dynamic> _availableSlots = [];
  bool _loadingSlots = false;
  bool _creatingBooking = false;
  final _notasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🔵 [BOOKING_FLOW] initState - Servicio: ${widget.service['nombre']}');
    print('🔵 [BOOKING_FLOW] Total estilistas disponibles: ${widget.stylists.length}');
    
    // Solicitar permisos de notificación
    _requestNotificationPermissions();
    
    // Si viene con targetStylistId (gerente/admin), seleccionar automáticamente
    if (widget.targetStylistId != null) {
      print('🔵 [BOOKING_FLOW] targetStylistId recibido: ${widget.targetStylistId}');
      _selectedStylist = widget.stylists.firstWhere(
        (s) => s['_id'] == widget.targetStylistId,
        orElse: () {
          print('❌ [BOOKING_FLOW] No se encontró estilista con ID: ${widget.targetStylistId}');
          return null;
        },
      );
      print('🔵 [BOOKING_FLOW] _selectedStylist después de buscar: $_selectedStylist');
    } else {
      print('🔵 [BOOKING_FLOW] Sin targetStylistId (cliente eligiendo)');
    }
  }
  
  Future<void> _requestNotificationPermissions() async {
    try {
      final notificationService = NotificationService();
      final hasPermission = await notificationService.requestPermissions();
      if (hasPermission) {
        print('✅ [BOOKING_FLOW] Permisos de notificación otorgados');
      } else {
        print('⚠️ [BOOKING_FLOW] Permisos de notificación denegados');
      }
    } catch (e) {
      print('❌ [BOOKING_FLOW] Error al solicitar permisos: $e');
    }
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  List<dynamic> _getStylistsForService() {
    // Obtener estilistas que hacen este servicio
    final serviceId = widget.service['_id'];
    return widget.stylists
        .where((stylist) {
          final servicios = stylist['servicios'] as List? ?? [];
          return servicios.contains(serviceId);
        })
        .toList();
  }

  List<String> _getWorkDaysForStylist(dynamic stylist) {
    // Obtener días de trabajo del estilista desde su horario
    final horario = stylist['horario'] as Map? ?? {};
    final workDays = <String>[];

    const dayMap = {
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miercoles': 'Miércoles',
      'jueves': 'Jueves',
      'viernes': 'Viernes',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    dayMap.forEach((key, value) {
      if (horario[key] != null && horario[key] == true) {
        workDays.add(value);
      }
    });

    return workDays;
  }

  Future<void> _loadAvailableSlots(DateTime date) async {
    print('═══════════════════════════════════════');
    print('🟠 [_LOAD_SLOTS] INICIANDO CARGA DE SLOTS');
    print('═══════════════════════════════════════');
    print('📅 Fecha seleccionada: $date');
    print('📋 Servicio: ${widget.service['nombre']} (ID: ${widget.service['_id']})');
    print('👤 _selectedStylist al inicio: $_selectedStylist');
    print('👤 _selectedStylist.nombre: ${_selectedStylist?['nombre']}');
    print('👤 _selectedStylist._id: ${_selectedStylist?['_id']}');

    // ✅ VALIDACIÓN DEFENSIVA: No cargar slots si no hay estilista seleccionado
    if (_selectedStylist == null) {
      print('❌ [VALIDACIÓN FALLIDA] _selectedStylist es NULL');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Por favor selecciona un estilista primero'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      print('═══════════════════════════════════════');
      return; // ← DETENER AQUÍ, NO CONTINUAR
    }
    print('✅ [VALIDACIÓN 1] _selectedStylist existe');

    // ✅ GUARDIANES ADICIONALES
    if (!mounted) {
      print('❌ Widget NO está montado');
      return;
    }
    print('✅ [VALIDACIÓN 2] Widget está montado');
    
    final stylistId = _selectedStylist?['_id'];
    print('🔍 stylistId extraido: $stylistId (type: ${stylistId.runtimeType})');

    if (stylistId == null || stylistId.isEmpty) {
      print('❌ [VALIDACIÓN FALLIDA] stylistId es null o vacío. selectedStylist: $_selectedStylist');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: ID del estilista no válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('═══════════════════════════════════════');
      return;
    }
    print('✅ [VALIDACIÓN 3] stylistId válido: $stylistId');

    setState(() => _loadingSlots = true);
    try {
      final dateString =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final serviceId = widget.service['_id'];
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🚀 LLAMANDO A API CON:');
      print('   serviceId=$serviceId (type: ${serviceId.runtimeType})');
      print('   stylistId=$stylistId (type: ${stylistId.runtimeType})');
      print('   dateString=$dateString');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await BookingsApi(ApiClient.instance).getSlots(
        serviceId: serviceId,
        stylistId: stylistId,
        date: dateString,
      );

      print('✅ [API_RESPONSE] Status Code: ${response.statusCode}');
      print('✅ [API_RESPONSE] Body (primeros 200 chars): ${response.body.substring(0, math.min(200, response.body.length))}');

      if (!mounted) {
        print('❌ Widget no está montado después de API');
        return; // ← DETENER SI LA PANTALLA FUE CERRADA
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slots = data is List ? data : (data['data'] ?? []);
        
        print('✅ [SUCCESS] Slots cargados: ${slots.length}');
        if (slots.isNotEmpty) {
          print('   Primer slot: ${slots[0]}');
        }

        setState(() {
          _availableSlots = slots.cast<dynamic>();
          _selectedSlotId = null;
          print('✅ setState completado. _availableSlots.length: ${_availableSlots.length}');
        });
      } else {
        print('❌ [ERROR] Status ${response.statusCode}: ${response.body}');
        setState(() => _availableSlots = []);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error ${response.statusCode}: No hay horarios disponibles'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [EXCEPTION] Error al cargar slots: $e');
      print('   Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSlots = false);
        print('✅ _loadingSlots = false');
      }
    }
    print('═══════════════════════════════════════');
  }


  String _formatTime(dynamic timeData) {
    try {
      if (timeData is String) {
        if (timeData.contains(':')) {
          return timeData.substring(0, 5);
        }
        final dateTime = DateTime.parse(timeData);
        return DateFormat('HH:mm').format(dateTime);
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _creatingBooking = true);
    try {
      final dateString =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      final bookingRequest = {
        'slotId': _selectedSlotId,
        'date': dateString,
        if (_notasController.text.isNotEmpty) 'notas': _notasController.text,
      };

      final response = await BookingsApi(ApiClient.instance).createBooking(
        bookingRequest,
        token: widget.token,
      );

      if (response.statusCode == 201) {
        final bookingData = jsonDecode(response.body);
        
        print('📝 [BOOKING_FLOW] Respuesta de reserva: $bookingData');
        
        // Extraer información de la respuesta
        final inicio = bookingData['inicio'] ?? '';
        final serviceName = widget.service['nombre'] ?? 'Servicio';
        
        // Obtener nombre del estilista de forma confiable
        String stylistName = _selectedStylist?['nombre'] ?? '';
        if (stylistName.isEmpty && bookingData['estilista'] != null) {
          final estilista = bookingData['estilista'];
          if (estilista is Map) {
            stylistName = '${estilista['nombre'] ?? ''} ${estilista['apellido'] ?? ''}'.trim();
          }
        }
        if (stylistName.isEmpty) {
          stylistName = 'Estilista';
        }
        
        print('👤 [BOOKING_FLOW] Estilista: $stylistName');
        print('🕐 [BOOKING_FLOW] Inicio: $inicio');
        
        // Formatear hora
        String timeDisplay = 'Hora';
        if (inicio.isNotEmpty) {
          // Manejar formato ISO (2024-01-18T10:30:00Z) o HH:mm
          if (inicio.contains('T')) {
            try {
              final dateTime = DateTime.parse(inicio);
              timeDisplay = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
            } catch (e) {
              print('❌ [BOOKING_FLOW] Error parsing hora: $e');
              if (inicio.contains(':')) {
                timeDisplay = inicio.substring(0, 5);
              }
            }
          } else if (inicio.contains(':')) {
            timeDisplay = inicio.substring(0, 5);
          }
        }
        
        print('✅ [BOOKING_FLOW] Hora formateada: $timeDisplay');
        
        // Extraer la fecha de la reserva para la notificación
        DateTime bookingDate = DateTime.now();
        if (inicio.isNotEmpty) {
          try {
            if (inicio.contains('T')) {
              bookingDate = DateTime.parse(inicio);
            }
          } catch (e) {
            print('⚠️ [BOOKING_FLOW] Error parsing fecha: $e, usando hoy');
          }
        }
        
        // Enviar notificación con la fecha correcta
        _sendBookingNotification(serviceName, stylistName, timeDisplay, bookingDate);
        
        if (mounted) {
          // Mostrar diálogo de éxito
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('¡Cita Confirmada!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSummaryRowForDialog('Servicio:', serviceName),
                  const SizedBox(height: 12),
                  _buildSummaryRowForDialog('Estilista:', stylistName),
                  const SizedBox(height: 12),
                  _buildSummaryRowForDialog('Hora:', timeDisplay),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Te recordamos tu cita. Presenta puntualidad.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar diálogo
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        // Regresar al dashboard (2 pops: página de booking + página anterior)
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      }
                    });
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? 'Error al crear la cita';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _creatingBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final stylistsForService = _getStylistsForService();
    final workDays = _selectedStylist != null
        ? _getWorkDaysForStylist(_selectedStylist)
        : <String>[];

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        title: Text(
          'Reservar Cita',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.gold,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. INFORMACIÓN DEL SERVICIO
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 14),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                border: Border.all(color: AppColors.gold, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Servicio Seleccionado',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 8 : 10),
                  Text(
                    widget.service['nombre'] ?? 'N/A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: AppColors.gold,
                        size: isMobile ? 14 : 15,
                      ),
                      SizedBox(width: isMobile ? 6 : 8),
                      Text(
                        '\$${widget.service['precio']?.toString() ?? 'N/A'}',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Icon(
                        Icons.schedule,
                        color: AppColors.gold,
                        size: isMobile ? 14 : 15,
                      ),
                      SizedBox(width: isMobile ? 6 : 8),
                      Text(
                        '${widget.service['duracionMin']?.toString() ?? 'N/A'} min',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // 2. SELECCIONAR ESTILISTA
            Text(
              '1. Elige tu estilista',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 10 : 12),

            if (stylistsForService.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 20 : 24),
                  child: Text(
                    'No hay estilistas disponibles para este servicio',
                    style: TextStyle(
                      color: AppColors.gray,
                      fontSize: isMobile ? 13 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stylistsForService.length,
                itemBuilder: (context, index) {
                  final stylist = stylistsForService[index];
                  final isSelected = _selectedStylist != null &&
                      stylist['_id'] == _selectedStylist['_id'];
                  final workDaysForThisStylist =
                      _getWorkDaysForStylist(stylist);

                  return StylistsSelectionCard(
                    stylistName:
                        '${stylist['nombre']} ${stylist['apellido']}',
                    rating: (stylist['calificacion'] ?? 0).toDouble(),
                    specialization: stylist['especialidad'] ?? 'General',
                    isSelected: isSelected,
                    workDays: workDaysForThisStylist,
                    onTap: () {
                      print('✅ [STYLIST_SELECT] Usuario seleccionó: ${stylist['nombre']} ${stylist['apellido']}');
                      print('✅ [STYLIST_SELECT] Stylist ID: ${stylist['_id']}');
                      setState(() {
                        _selectedStylist = stylist;
                        _selectedDate = null;
                        _selectedSlotId = null;
                        _availableSlots = [];
                        print('✅ [STYLIST_SELECT] After setState - _selectedStylist: ${_selectedStylist?['nombre']} (ID: ${_selectedStylist?['_id']})');
                      });
                    },
                  );
                },
              ),

            SizedBox(height: isMobile ? 20 : 24),

            // 3. CALENDARIO DESLIZABLE (Solo si hay estilista seleccionado)
            if (_selectedStylist != null) ...[
              Text(
                '2. Elige la fecha',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 10 : 12),
              Text(
                'Desliza para ver más días',
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: isMobile ? 12 : 13,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 8 : 10),
              ScrollableWeekCalendar(
                initialDate: DateTime.now(),
                selectedDate: _selectedDate,
                workDays: workDays,
                onDateSelected: (date) {
                  print('📅 [CALENDAR] Usuario seleccionó fecha: $date');
                  print('📅 [CALENDAR] _selectedStylist ANTES de cargar: $_selectedStylist');
                  print('📅 [CALENDAR] _selectedStylist._id: ${_selectedStylist?['_id']}');
                  
                  if (_selectedStylist == null) {
                    print('❌ [CALENDAR] ERROR: No hay estilista seleccionado');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Debes seleccionar un estilista primero'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    return;
                  }
                  
                  setState(() {
                    _selectedDate = date;
                    _selectedSlotId = null;
                  });
                  _loadAvailableSlots(date);
                },
              ),
              SizedBox(height: isMobile ? 16 : 20),
            ],

            // 4. HORARIOS DISPONIBLES
            if (_selectedDate != null) ...[
              Text(
                '3. Elige tu hora',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 10 : 12),

              if (_loadingSlots)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20 : 24),
                    child: const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  ),
                )
              else if (_availableSlots.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20 : 24),
                    child: Text(
                      'No hay horarios disponibles para esta fecha',
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: isMobile ? 13 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 3,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: isMobile ? 10 : 12,
                    mainAxisSpacing: isMobile ? 10 : 12,
                  ),
                  itemCount: _availableSlots.length,
                  itemBuilder: (context, index) {
                    final slot = _availableSlots[index];
                    final isSelected = _selectedSlotId == slot['slotId'];
                    final isAvailable = slot['isAvailable'] != false;

                    return GestureDetector(
                      onTap: isAvailable
                          ? () {
                              setState(() => _selectedSlotId = isSelected ? null : slot['slotId']);
                            }
                          : null,
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.gold.withOpacity(0.15)
                              : (isAvailable ? Colors.grey.shade900 : Colors.red.withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold
                                : (isAvailable ? AppColors.gold.withOpacity(0.3) : Colors.red.withOpacity(0.4)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAvailable ? Icons.check_circle : Icons.cancel_schedule_send,
                              color: isAvailable ? AppColors.gold : Colors.red.shade400,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot['stylistName'] ?? 'Estilista',
                                    style: TextStyle(
                                      color: isAvailable ? Colors.white : Colors.red.shade300,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${_formatTime(slot['start'] ?? '??:??')} - ${_formatTime(slot['end'] ?? '??:??')}',
                                    style: TextStyle(
                                      color: isAvailable ? AppColors.gold : Colors.red.shade300,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                color: AppColors.gold,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(height: isMobile ? 16 : 20),
            ],

            // 5. NOTAS/PREFERENCIAS
            if (_selectedDate != null && _selectedSlotId != null) ...[
              Text(
                '4. Tus preferencias (opcional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 12),
              TextField(
                controller: _notasController,
                maxLines: 3,
                maxLength: 200,
                style: TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ej: No muy corto, rubio claro, etc.',
                  hintStyle: TextStyle(color: AppColors.gray),
                  filled: true,
                  fillColor: AppColors.charcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gold),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                      width: 2,
                    ),
                  ),
                  counterStyle: TextStyle(color: AppColors.gray),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // RESUMEN Y BOTÓN CONFIRMAR
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  border: Border.all(color: AppColors.gold, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de tu reserva',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isMobile ? 10 : 12),
                    _buildSummaryRow(
                      'Servicio:',
                      widget.service['nombre'] ?? 'N/A',
                      isMobile,
                    ),
                    _buildSummaryRow(
                      'Estilista:',
                      '${_selectedStylist['nombre']} ${_selectedStylist['apellido']}',
                      isMobile,
                    ),
                    _buildSummaryRow(
                      'Fecha:',
                      DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      isMobile,
                    ),
                    _buildSummaryRow(
                      'Duración:',
                      '${widget.service['duracionMin']} min',
                      isMobile,
                    ),
                    _buildSummaryRow(
                      'Precio:',
                      '\$${widget.service['precio']}',
                      isMobile,
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // BOTÓN AGENDAR
              SizedBox(
                width: double.infinity,
                height: isMobile ? 48 : 52,
                child: ElevatedButton(
                  onPressed: _creatingBooking ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    disabledBackgroundColor: AppColors.gray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _creatingBooking
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.charcoal),
                        )
                      : Text(
                          'Agendar Cita',
                          style: TextStyle(
                            color: AppColors.charcoal,
                            fontSize: isMobile ? 15 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isMobile,
      {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.gray,
              fontSize: isMobile ? 12 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlighted ? AppColors.gold : Colors.white,
              fontSize: isMobile ? 12 : 13,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRowForDialog(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _sendBookingNotification(
    String serviceName,
    String stylistName,
    String timeDisplay,
    DateTime bookingDate,
  ) async {
    try {
      print('📲 Enviando notificación de cita confirmada');
      final notificationService = NotificationService();
      
      // Usar la fecha de la reserva
      final dateFormat = DateFormat('EEEE, d MMMM', 'es_ES');
      final dateStr = dateFormat.format(bookingDate);
      
      await notificationService.notifyClientBookingCreated(
        stylistName: stylistName,
        date: dateStr,
        time: timeDisplay,
      );
      
      print('✅ Notificación enviada correctamente');
    } catch (e) {
      print('❌ Error al enviar notificación: $e');
    }
  }}