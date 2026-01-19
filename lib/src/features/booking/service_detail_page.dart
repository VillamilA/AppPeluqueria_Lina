import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../api/api_client.dart';
import '../../api/bookings_api.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class ServiceDetailPage extends StatefulWidget {
  final dynamic service;
  final String token;
  final String clienteId;
  final List<dynamic> stylists;

  const ServiceDetailPage({
    super.key,
    required this.service,
    required this.token,
    required this.clienteId,
    required this.stylists,
  });

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage>
    with TickerProviderStateMixin {
  DateTime? _selectedDate;
  String? _selectedSlotId;
  List<dynamic> _availableSlots = [];
  bool _loadingSlots = false;
  bool _showScrollIndicator = false;
  final _notasController = TextEditingController();
  late ScrollController _calendarScrollController;
  final _mainScrollController = ScrollController();
  late AnimationController _scrollAnimationController;

  @override
  void initState() {
    super.initState();
    _calendarScrollController = ScrollController();
    _mainScrollController.addListener(_onMainScroll);
    
    // Animación para la flecha
    _scrollAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Solicitar permisos de notificación
    _requestNotificationPermissions();
    
    // Detectar después del primer frame si hay scroll disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsScroll();
    });
  }
  
  Future<void> _requestNotificationPermissions() async {
    try {
      final notificationService = NotificationService();
      final hasPermission = await notificationService.requestPermissions();
      if (hasPermission) {
        print('✅ [SERVICE_DETAIL] Permisos de notificación otorgados');
      } else {
        print('⚠️ [SERVICE_DETAIL] Permisos de notificación denegados');
      }
    } catch (e) {
      print('❌ [SERVICE_DETAIL] Error al solicitar permisos: $e');
    }
  }
  
  void _checkIfNeedsScroll() {
    if (_mainScrollController.position.maxScrollExtent > 50) {
      // Hay contenido para scrollear
      if (!_showScrollIndicator) {
        setState(() => _showScrollIndicator = true);
      }
    } else {
      // No hay contenido suficiente para scrollear
      if (_showScrollIndicator) {
        setState(() => _showScrollIndicator = false);
      }
    }
  }

  void _onMainScroll() {
    // Ocultar indicador cuando el usuario empieza a scrollear
    if (_mainScrollController.offset > 50) {
      if (_showScrollIndicator) {
        setState(() => _showScrollIndicator = false);
      }
    }
  }

  @override
  void dispose() {
    _notasController.dispose();
    _calendarScrollController.dispose();
    _mainScrollController.dispose();
    _scrollAnimationController.dispose();
    super.dispose();
  }

  /// Obtener estilistas que atienden este servicio
  /// Generar próximos 30 días comenzando hoy
  List<DateTime> _getNext30Days() {
    final today = DateTime.now();
    return List.generate(30, (i) => today.add(Duration(days: i)));
  }

  /// Cargar slots para fecha y servicio
  Future<void> _loadAvailableSlots(DateTime date) async {
    if (_loadingSlots) return;

    setState(() => _loadingSlots = true);
    try {
      final dateString =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final serviceId = widget.service['_id'];
      
      print('🔍 DEBUG: Cargando slots...');
      print('   - Fecha: $dateString');
      print('   - Service ID: $serviceId');
      print('   - Mostrando todos los estilistas');

      // Para obtener slots de todos los estilistas, NO incluimos stylistId en la query
      // Llamamos al endpoint sin el parámetro stylistId
      final response = await ApiClient.instance.get(
        '/api/v1/bookings/availability?date=$dateString&serviceId=$serviceId',
      );

      print('✅ Response status: ${response.statusCode}');
      print('📋 Response body (primeros 300 chars): ${response.body.substring(0, math.min(300, response.body.length))}');

      if (response.statusCode == 200) {
        try {
          // La respuesta es un array directo: [{ slotId, stylistId, stylistName, start, end }, ...]
          final slots = jsonDecode(response.body) as List;
          
          print('📊 Slots recibidos: ${slots.length}');
          for (var slot in slots) {
            print('   - ${slot['stylistName']}: ${slot['start']} - ${slot['end']}');
          }

          setState(() {
            _availableSlots = slots;
            _selectedSlotId = null; // Reset selection
          });
        } catch (parseError) {
          print('❌ Error parseando respuesta: $parseError');
          setState(() => _availableSlots = []);
        }
      } else {
        print('❌ Error: Status code ${response.statusCode}');
        setState(() => _availableSlots = []);
      }
    } catch (e) {
      print('❌ Error loading slots: $e');
      setState(() => _availableSlots = []);
    } finally {
      setState(() => _loadingSlots = false);
    }
  }

  /// Enviar reserva
  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona fecha y horario'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final bookingData = {
        "slotId": _selectedSlotId,
        "date": dateString,
        "notas": _notasController.text.isNotEmpty ? _notasController.text : null,
      };

      setState(() => _loadingSlots = true);

      final response = await BookingsApi(ApiClient.instance).createBooking(
        bookingData,
        token: widget.token,
      );

      if (response.statusCode == 201) {
        final bookingData = jsonDecode(response.body);
        
        print('📝 [SERVICE_DETAIL] Respuesta de reserva: $bookingData');
        
        // Extraer información del slot seleccionado
        final selectedSlot = _availableSlots.firstWhere(
          (s) => s['slotId'] == _selectedSlotId,
          orElse: () => {},
        );
        
        print('📍 [SERVICE_DETAIL] Slot seleccionado: $selectedSlot');
        
        final inicio = bookingData['inicio'] ?? selectedSlot['start'] ?? '';
        final serviceName = widget.service['nombre'] ?? 'Servicio';
        
        // Obtener nombre del estilista del slot (más confiable que buscar en widget.stylists)
        String stylistName = selectedSlot['stylistName'] ?? 'Estilista';
        
        // Si aún no tenemos el nombre, intentar obtenerlo del bookingData
        if (stylistName == 'Estilista' && bookingData['estilista'] != null) {
          final estilista = bookingData['estilista'];
          if (estilista is Map) {
            stylistName = '${estilista['nombre'] ?? ''} ${estilista['apellido'] ?? ''}'.trim();
          }
        }
        
        print('👤 [SERVICE_DETAIL] Estilista: $stylistName');
        print('🕐 [SERVICE_DETAIL] Inicio: $inicio');
        
        // Formatear hora
        String timeDisplay = 'Hora';
        if (inicio.isNotEmpty) {
          // Manejar formato ISO (2024-01-18T10:30:00Z) o HH:mm
          if (inicio.contains('T')) {
            try {
              final dateTime = DateTime.parse(inicio);
              timeDisplay = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
            } catch (e) {
              print('❌ [SERVICE_DETAIL] Error parsing hora: $e');
              if (inicio.contains(':')) {
                timeDisplay = inicio.substring(0, 5);
              }
            }
          } else if (inicio.contains(':')) {
            timeDisplay = inicio.substring(0, 5);
          }
        }
        
        print('✅ [SERVICE_DETAIL] Hora formateada: $timeDisplay');
        
        // Extraer la fecha de la reserva para la notificación
        DateTime bookingDate = DateTime.now();
        if (inicio.isNotEmpty) {
          try {
            if (inicio.contains('T')) {
              bookingDate = DateTime.parse(inicio);
            }
          } catch (e) {
            print('⚠️ [SERVICE_DETAIL] Error parsing fecha: $e, usando hoy');
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
                        // Regresar al dashboard (2 pops: página de servicio + página anterior)
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
        final errorMsg = errorData['message'] ?? 'Error al agendar';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loadingSlots = false);
    }
  }

  /// Obtener nombre del estilista del slot seleccionado
  String _getSelectedStylistName() {
    if (_selectedSlotId == null || _availableSlots.isEmpty) return 'Por seleccionar';
    try {
      final slot = _availableSlots.firstWhere(
        (s) => s['slotId'] == _selectedSlotId,
        orElse: () => null,
      );
      if (slot == null) return 'Por seleccionar';
      return slot['stylistName'] ?? 'Desconocido';
    } catch (e) {
      return 'Por seleccionar';
    }
  }

  /// Obtener horario del slot seleccionado
  String _getSelectedSlotTime() {
    if (_availableSlots.isEmpty || _selectedSlotId == null) {
      return 'Por seleccionar';
    }
    try {
      final slot = _availableSlots.firstWhere(
        (s) => s['slotId'] == _selectedSlotId,
        orElse: () => null,
      );
      if (slot == null) return 'Por seleccionar';
      final startTime = _formatTime(slot['start'] ?? '??:??');
      return startTime; // Solo muestra la hora de inicio (HH:mm)
    } catch (e) {
      return 'Por seleccionar';
    }
  }
  
  String _getSelectedSlotDate() {
    if (_selectedDate == null) return 'Por seleccionar';
    try {
      return DateFormat('yyyy-MM-dd').format(_selectedDate!);
    } catch (e) {
      return 'Por seleccionar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceName = widget.service['nombre'] ?? 'Sin nombre';

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        title: Text(
          serviceName,
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBookingFlow(),
    );
  }

  /// Pantalla: Flujo principal de booking (calendario + horarios)
  Widget _buildBookingFlow() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final serviceName = widget.service['nombre'] ?? 'Sin nombre';
    final price = widget.service['precio'] ?? 0;
    final duration = widget.service['duracionMin'] ?? 0;
    final availableDays = _getNext30Days();
    
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _mainScrollController,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // TÍTULO PRINCIPAL - Centrado
                Text(
                  'Agenda tu cita',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 24 : 28),

                // SECCIÓN: CALENDARIO + HORARIOS
                SizedBox(
                  width: double.infinity,
                  child: _buildCalendarAndSlotsSection(isMobile, availableDays),
                ),

                SizedBox(height: isMobile ? 24 : 32),

                // RESUMEN Y NOTAS (si fecha y slot seleccionados)
                if (_selectedDate != null && _selectedSlotId != null)
                  SizedBox(
                    width: double.infinity,
                    child: _buildSummaryAndConfirm(isMobile, serviceName, price, duration),
                  )
                else if (_selectedDate != null)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        'Selecciona un horario para continuar',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
        
        // INDICADOR DE SCROLL (Flecha animada)
        if (_showScrollIndicator)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                  CurvedAnimation(
                    parent: _scrollAnimationController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.gold.withOpacity(0.7),
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Sección: Calendario (izq) + Horarios (der) - similar a imagen referencia
  Widget _buildCalendarAndSlotsSection(bool isMobile, List<DateTime> availableDays) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isMobile)
          // MOBILE: Apilado verticalmente
          _buildMobileCalendarAndSlots(availableDays)
        else
          // DESKTOP: Lado a lado
          _buildDesktopCalendarAndSlots(availableDays),
      ],
    );
  }

  /// Layout MOBILE: Calendario arriba, horarios abajo
  Widget _buildMobileCalendarAndSlots(List<DateTime> availableDays) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // CALENDARIO
        Text(
          'Selecciona la fecha',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        if (availableDays.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Este estilista no tiene días disponibles',
              style: TextStyle(
                color: Colors.orange.shade300,
                fontSize: 13,
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              controller: _calendarScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: availableDays.length,
              itemBuilder: (context, index) {
                final date = availableDays[index];
                final isSelected = _selectedDate?.year == date.year &&
                    _selectedDate?.month == date.month &&
                    _selectedDate?.day == date.day;
                final dayOfWeek =
                    ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'][date.weekday % 7];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedSlotId = null;
                    });
                    _loadAvailableSlots(date);
                  },
                  child: Container(
                    width: 75,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.gold : Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayOfWeek,
                          style: TextStyle(
                            color: isSelected ? Colors.black : AppColors.gray,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        SizedBox(height: 20),

        // HORARIOS
        if (_selectedDate != null) ...[
          Text(
            'Selecciona tu hora',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          _buildSlotsGrid(),
          SizedBox(height: 20),
        ],
      ],
    );
  }

  /// Layout DESKTOP: Calendario (izq) + Horarios (der)
  Widget _buildDesktopCalendarAndSlots(List<DateTime> availableDays) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CALENDARIO (Izquierda)
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona la fecha',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              if (availableDays.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'No disponible',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    controller: _calendarScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: availableDays.length,
                    itemBuilder: (context, index) {
                      final date = availableDays[index];
                      final isSelected = _selectedDate?.year == date.year &&
                          _selectedDate?.month == date.month &&
                          _selectedDate?.day == date.day;
                      final dayOfWeek =
                          ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'][date.weekday % 7];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _selectedSlotId = null;
                          });
                          _loadAvailableSlots(date);
                        },
                        child: Container(
                          width: 90,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.gold : Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayOfWeek,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : AppColors.gray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                DateFormat('MMM').format(date),
                                style: TextStyle(
                                  color: isSelected ? Colors.black : AppColors.gray,
                                  fontSize: 11,
                                ),
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
        ),
        SizedBox(width: 20),

        // HORARIOS (Derecha)
        if (_selectedDate != null)
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona tu hora',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                _buildSlotsGridDesktop(),
              ],
            ),
          )
        else
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Elige una fecha',
                style: TextStyle(
                  color: AppColors.gray.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Grid de slots compacto (MOBILE)
  Widget _buildSlotsGrid() {
    if (_loadingSlots) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 40,
              color: AppColors.gold.withOpacity(0.3),
            ),
            SizedBox(height: 10),
            Text(
              'No hay horarios disponibles',
              style: TextStyle(
                color: AppColors.gray.withOpacity(0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) => _buildSlotCard(index, true),
    );
  }

  /// Grid de slots DESKTOP (lado a lado con calendario)
  Widget _buildSlotsGridDesktop() {
    if (_loadingSlots) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'No hay horarios para este día',
          style: TextStyle(
            color: Colors.orange.shade300,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableSlots.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (context, index) => _buildSlotCard(index, false),
    );
  }

  /// Formatea tiempo de HH:mm:ss o ISO a HH:mm
  String _formatTime(dynamic time) {
    try {
      if (time == null) return '??:??';
      String timeStr = time.toString().trim();
      
      // Si contiene 'T' (formato ISO: "2026-01-16T14:00")
      if (timeStr.contains('T')) {
        timeStr = timeStr.split('T')[1]; // Extrae "14:00" o "14:00:00"
      }
      
      // Ahora extrae HH:mm
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
      }
      
      return timeStr;
    } catch (e) {
      return '??:??';
    }
  }

  /// Card individual para un slot
  /// Card individual para un slot
  Widget _buildSlotCard(int index, bool isGrid) {
    final slot = _availableSlots[index];
    final slotId = slot['slotId'];
    final startTime = _formatTime(slot['start']);
    final stylistName = slot['stylistName'] ?? 'Sin estilista';
    final isAvailable = slot['isAvailable'] != false;
    final isSelected = _selectedSlotId == slotId;

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() => _selectedSlotId = isSelected ? null : slotId);
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isGrid ? 8 : 10,
          vertical: isGrid ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withOpacity(0.15)
              : (isAvailable ? Colors.grey.shade900 : Colors.red.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : (isAvailable ? AppColors.gold.withOpacity(0.3) : Colors.red.withOpacity(0.4)),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de selección (radio-button style)
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.gold : AppColors.gray,
              size: 16,
            ),
            SizedBox(height: 3),
            
            // NOMBRE DEL ESTILISTA
            Text(
              stylistName,
              style: TextStyle(
                color: isAvailable ? Colors.white : Colors.red.shade300,
                fontSize: isGrid ? 10 : 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            
            // HORA (SOLO HH:MM)
            Text(
              startTime,
              style: TextStyle(
                color: isAvailable ? AppColors.gold : Colors.red.shade300,
                fontSize: isGrid ? 11 : 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Resumen y botón de confirmación
  Widget _buildSummaryAndConfirm(
    bool isMobile,
    String serviceName,
    dynamic price,
    int duration,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // NOTAS
        Text(
          'Tus preferencias (opcional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        TextField(
          controller: _notasController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Ej: No muy corto, cambio de color, etc...',
            hintStyle: TextStyle(color: AppColors.gray.withOpacity(0.5), fontSize: 12),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gold, width: 2),
            ),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
        SizedBox(height: 20),

        // RESUMEN
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Resumen de tu cita',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              _buildSummaryRow('Servicio:', serviceName, isMobile),
              SizedBox(height: 8),
              _buildSummaryRow('Estilista:', _getSelectedStylistName(), isMobile),
              SizedBox(height: 8),
              _buildSummaryRow('Fecha:', _getSelectedSlotDate(), isMobile),
              SizedBox(height: 8),
              _buildSummaryRow('Hora:', _getSelectedSlotTime(), isMobile),
              SizedBox(height: 8),
              _buildSummaryRow('Duración:', '$duration min', isMobile),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Container(height: 1, color: AppColors.gold.withOpacity(0.15)),
              ),
              _buildSummaryRow('Precio:', '\$$price', isMobile, isPrice: true),
            ],
          ),
        ),
        SizedBox(height: 16),

        // ALERTA: 10 minutos para llegar
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '⏱️ Tienes 10 minutos para llegar. Si no confirmas tu asistencia en la app, la cita se cancelará automáticamente.',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // BOTÓN CONFIRMAR
        SizedBox(
          width: double.infinity,
          height: isMobile ? 48 : 52,
          child: ElevatedButton(
            onPressed: _loadingSlots ? null : _submitBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
            ),
            child: _loadingSlots
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.black.withOpacity(0.6),
                      ),
                    ),
                  )
                : Text(
                    'Finaliza tu cita',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isMobile, {
    bool isPrice = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isMobile ? 12 : 13,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isPrice ? AppColors.gold : Colors.white,
              fontSize: isMobile ? 12 : 13,
              fontWeight: isPrice ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
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
      
      print('📅 [NOTIFICATION] Fecha de reserva: $dateStr');
      
      await notificationService.notifyClientBookingCreated(
        stylistName: stylistName,
        date: dateStr,
        time: timeDisplay,
      );
      
      print('✅ Notificación enviada correctamente');
    } catch (e) {
      print('❌ Error al enviar notificación: $e');
    }
  }
}
