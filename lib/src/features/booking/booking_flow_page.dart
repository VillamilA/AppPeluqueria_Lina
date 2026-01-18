import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../api/api_client.dart';
import '../../api/bookings_api.dart';
import 'widgets/stylists_selection_card.dart';
import 'widgets/scrollable_week_calendar.dart';
import 'package:intl/intl.dart';

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
    // Si viene con targetStylistId (gerente/admin), seleccionar automáticamente
    if (widget.targetStylistId != null) {
      _selectedStylist = widget.stylists.firstWhere(
        (s) => s['_id'] == widget.targetStylistId,
        orElse: () => null,
      );
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
    if (_selectedStylist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un estilista'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loadingSlots = true);
    try {
      final dateString =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final serviceId = widget.service['_id'];

      final response = await BookingsApi(ApiClient.instance).getSlots(
        serviceId: serviceId,
        date: dateString,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slots = data is List ? data : (data['data'] ?? []);

        setState(() {
          _availableSlots = slots.cast<dynamic>();
          _selectedSlotId = null;
        });
      } else {
        setState(() => _availableSlots = []);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay horarios disponibles para esta fecha'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading slots: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar horarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loadingSlots = false);
    }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cita creada exitosamente!'),
              backgroundColor: Colors.green,
            ),
          );
          // Volver a la página anterior
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.of(context).pop();
          });
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
                      setState(() {
                        _selectedStylist = stylist;
                        _selectedDate = null;
                        _selectedSlotId = null;
                        _availableSlots = [];
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
}
