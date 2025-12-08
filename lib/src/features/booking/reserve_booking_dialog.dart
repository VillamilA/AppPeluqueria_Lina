import '../../api/bookings_api.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ReserveBookingDialog extends StatefulWidget {
  final String clienteId;
  final String serviceId;
  final String catalogId;
  final double precio;
  final List<dynamic> stylists;
  final String token;
  final List<dynamic>? categories;
  const ReserveBookingDialog({
    super.key,
    required this.clienteId,
    required this.serviceId,
    required this.catalogId,
    required this.precio,
    required this.stylists,
    required this.token,
    this.categories,
  });

  @override
  State<ReserveBookingDialog> createState() => _ReserveBookingDialogState();
}

class _ReserveBookingDialogState extends State<ReserveBookingDialog> {
  // Datos de reserva
  String? stylistId;
  DateTime? selectedDate;
  String? selectedSlotId;
  List<dynamic> availableSlots = [];
  String? selectedCategoryId;
  
  // Control
  bool _loading = false;
  final _notasCtrl = TextEditingController();
  final ScrollController _calendarScrollController = ScrollController();

  List<dynamic> get filteredStylists {
    final categoryId = selectedCategoryId ?? widget.catalogId;
    final serviceId = widget.serviceId;
    return widget.stylists.where((stylist) {
      final catalogs = stylist['catalogs'] as List<dynamic>? ?? [];
      final services = stylist['servicesOffered'] as List<dynamic>? ?? [];
      final hasCatalog = catalogs.any((cat) => (cat is Map && cat['_id'] == categoryId));
      final hasService = services.any((srv) => (srv is Map && srv['_id'] == serviceId));
      return hasCatalog && hasService;
    }).toList();
  }

  Future<void> fetchSlots() async {
    if (stylistId == null || widget.serviceId.isEmpty || selectedDate == null) return;
    final days = ['DOMINGO','LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO'];
    final dayOfWeek = days[selectedDate!.weekday % 7];
    print('[RESERVE_DIALOG] Fetching slots for stylist=$stylistId, service=${widget.serviceId}, day=$dayOfWeek');
    final res = await BookingsApi(ApiClient.instance).getSlots(
      stylistId: stylistId!,
      serviceId: widget.serviceId,
      dayOfWeek: dayOfWeek,
      token: widget.token,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        availableSlots = data['data'] ?? [];
        selectedSlotId = null;
      });
    } else {
      setState(() {
        availableSlots = [];
      });
    }
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 550,
        ),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.gold.withOpacity(0.2), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reservar tu cita',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Completa todos los campos',
                        style: TextStyle(
                          color: AppColors.gray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.gold),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // CONTENIDO
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. SELECTOR DE ESTILISTA (DROPDOWN)
                      Text(
                        '👤 Selecciona tu estilista',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      if (filteredStylists.isEmpty)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            'No hay estilistas disponibles para este servicio',
                            style: TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            underline: SizedBox(),
                            dropdownColor: AppColors.charcoal,
                            value: stylistId,
                            hint: Text(
                              'Selecciona un estilista',
                              style: TextStyle(color: AppColors.gray),
                            ),
                            items: filteredStylists.map<DropdownMenuItem<String>>((stylist) {
                              return DropdownMenuItem<String>(
                                value: stylist['_id'],
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.gold,
                                      child: Icon(Icons.person, color: Colors.black, size: 18),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '${stylist['nombre']} ${stylist['apellido']}',
                                      style: TextStyle(color: AppColors.gold),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                stylistId = value;
                                selectedDate = null;
                                selectedSlotId = null;
                                availableSlots = [];
                              });
                            },
                            style: TextStyle(color: AppColors.gold, fontSize: 14),
                            iconEnabledColor: AppColors.gold,
                          ),
                        ),

                      if (stylistId != null) ...[
                        SizedBox(height: 24),

                        // 2. SELECTOR DE FECHA (CALENDARIO HORIZONTAL)
                        Text(
                          '📅 Escoge tu día',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            controller: _calendarScrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: 60, // 60 días disponibles
                            itemBuilder: (context, index) {
                              final date = DateTime.now().add(Duration(days: index));
                              final isSelected = selectedDate?.year == date.year &&
                                  selectedDate?.month == date.month &&
                                  selectedDate?.day == date.day;
                              final isToday = index == 0;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedDate = date;
                                    selectedSlotId = null;
                                  });
                                  fetchSlots();
                                },
                                child: Container(
                                  width: 70,
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.gold
                                        : isToday
                                            ? Colors.blue.shade700
                                            : Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.gold : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('EEE', 'es_ES').format(date).toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.black
                                              : isToday
                                                  ? AppColors.gold
                                                  : AppColors.gray,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.black
                                              : isToday
                                                  ? AppColors.gold
                                                  : AppColors.gold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (isToday)
                                        Text(
                                          'Hoy',
                                          style: TextStyle(
                                            color: isSelected ? Colors.black : AppColors.gray,
                                            fontSize: 9,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 24),

                        // 3. SELECTOR DE HORARIO
                        if (selectedDate != null) ...[
                          Text(
                            '🕐 Escoge tu horario',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(selectedDate!),
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 12),
                          if (availableSlots.isEmpty)
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Cargando horarios disponibles...',
                                style: TextStyle(color: Colors.orangeAccent),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.3,
                              ),
                              itemCount: availableSlots.length,
                              itemBuilder: (context, i) {
                                final slot = availableSlots[i];
                                final isOccupied = slot['isActive'] == false;
                                final isSelected = selectedSlotId == slot['id'];

                                return GestureDetector(
                                  onTap: isOccupied
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedSlotId = slot['id'];
                                          });
                                        },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isOccupied
                                          ? Colors.grey.shade700
                                          : isSelected
                                              ? AppColors.gold
                                              : Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.gold
                                            : isOccupied
                                                ? Colors.red.withOpacity(0.3)
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isOccupied) ...[
                                          Icon(Icons.lock, color: Colors.red, size: 24),
                                          SizedBox(height: 4),
                                          Text(
                                            'OCUPADO',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ] else ...[
                                          Icon(
                                            Icons.schedule,
                                            color: isSelected ? Colors.black : AppColors.gold,
                                            size: 20,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '${slot['startTime']}',
                                            style: TextStyle(
                                              color: isSelected ? Colors.black : AppColors.gold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'a',
                                            style: TextStyle(
                                              color: isSelected ? Colors.black : AppColors.gray,
                                              fontSize: 9,
                                            ),
                                          ),
                                          Text(
                                            '${slot['endTime']}',
                                            style: TextStyle(
                                              color: isSelected ? Colors.black : AppColors.gray,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],

                        SizedBox(height: 20),

                        // NOTAS OPCIONALES
                        Text(
                          '📝 Notas (opcional)',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _notasCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Cuéntanos algo especial...',
                            hintStyle: TextStyle(color: AppColors.gray),
                            filled: true,
                            fillColor: Colors.grey.shade800,
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
                              borderSide: BorderSide(color: AppColors.gold),
                            ),
                          ),
                          style: TextStyle(color: AppColors.gold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // BOTONES INFERIORES
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.gold.withOpacity(0.2), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: BorderSide(color: AppColors.gold, width: 2),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: Icon(Icons.close),
                    label: Text('Cancelar'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.black),
                              ),
                            )
                          : Icon(Icons.check_circle),
                      label: Text(
                        _loading ? 'Reservando...' : 'Reservar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: (_loading ||
                              stylistId == null ||
                              selectedDate == null ||
                              selectedSlotId == null ||
                              filteredStylists.isEmpty)
                          ? null
                          : () async {
                              await _submitBooking();
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _loading = true);

    try {
      print('[RESERVE] selectedSlotId: $selectedSlotId');
      print('[RESERVE] availableSlots count: ${availableSlots.length}');
      
      final slot = availableSlots.firstWhere(
        (s) {
          print('[RESERVE] Comparing slot id: ${s['id']} with selectedSlotId: $selectedSlotId');
          return s['id'] == selectedSlotId;
        },
        orElse: () {
          print('[RESERVE] No slot found with id: $selectedSlotId');
          throw Exception('Slot no encontrado');
        },
      );

      print('[RESERVE] Slot encontrado: $slot');
      
      // Formato correcto del endpoint
      final bookingData = {
        "slotId": slot['_id'] ?? slot['id'], // ID del slot
        "date": DateFormat('yyyy-MM-dd').format(selectedDate!), // Formato YYYY-MM-DD
        "notas": _notasCtrl.text.isNotEmpty ? _notasCtrl.text : null,
      };

      print('[RESERVE] Enviando reserva: $bookingData');
      print('[RESERVE] Token: ${widget.token.substring(0, 20)}...');

      final result = await BookingsApi(ApiClient.instance).createBooking(bookingData, token: widget.token);

      print('[RESERVE] Response status: ${result.statusCode}');
      print('[RESERVE] Response body: ${result.body}');

      setState(() => _loading = false);

      if (result.statusCode == 201 || result.statusCode == 200) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear la reserva: ${result.statusCode} - ${result.body}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('[RESERVE] ERROR: $e');
      print('[RESERVE] Stack trace: $stackTrace');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 48,
                ),
              ),
              SizedBox(height: 24),
              Text(
                '¡Cita reservada!',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Tu cita ha sido confirmada exitosamente',
                style: TextStyle(color: AppColors.gray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Recibirás una confirmación por correo',
                style: TextStyle(color: AppColors.gray, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra success dialog
                  Navigator.of(context).pop(true); // Cierra reserve dialog
                },
                child: Text(
                  'Volver a servicios',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
