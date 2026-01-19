import '../../api/bookings_api.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

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
  bool _slotsLoaded = false;
  
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
    
    print('📍 Fetching slots: service=${widget.serviceId}, stylist=$stylistId, date=$selectedDate');
    
    final dateString = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
    
    final res = await BookingsApi(ApiClient.instance).getSlots(
      serviceId: widget.serviceId,
      stylistId: stylistId!,
      date: dateString,
    );
    
    print('📌 Response status: ${res.statusCode}');
    print('📋 Response body: ${res.body}');
    
    if (res.statusCode == 200) {
      // La respuesta es un array directo: [{ slotId, stylistId, stylistName, start, end }, ...]
      List<dynamic> slots = jsonDecode(res.body) as List;
      
      print('✅ Slots encontrados: ${slots.length}');
      for (var slot in slots) {
        print('   - ${slot['start']} a ${slot['end']}, estilista: ${slot['stylistName']}');
      }
      
      setState(() {
        availableSlots = slots;
        selectedSlotId = null;
        _slotsLoaded = true;
      });
    } else if (res.statusCode == 404) {
      print('⚠️ Sin slots disponibles (404)');
      setState(() {
        availableSlots = [];
        selectedSlotId = null;
        _slotsLoaded = true;
      });
    } else {
      print('❌ Error: ${res.statusCode}');
      setState(() {
        _slotsLoaded = true;
      });
      setState(() {
        availableSlots = [];
        selectedSlotId = null;
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
                          if (availableSlots.isEmpty && !_slotsLoaded)
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
                          else if (availableSlots.isEmpty && _slotsLoaded)
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Text(
                                'No hay horarios disponibles para esta fecha',
                                style: TextStyle(color: Colors.red),
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
                                final isAvailable = slot['isAvailable'] ?? true;
                                final slotId = slot['_id'] ?? '';
                                final isSelected = selectedSlotId == slotId;
                                final startTime = slot['startTime'] ?? '??:??';
                                final endTime = slot['endTime'] ?? '??:??';

                                return GestureDetector(
                                  onTap: !isAvailable
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedSlotId = slotId;
                                          });
                                        },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !isAvailable
                                          ? Colors.grey.shade700
                                          : isSelected
                                              ? AppColors.gold
                                              : Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.gold
                                            : !isAvailable
                                                ? Colors.red.withOpacity(0.3)
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (!isAvailable) ...[
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
                                            startTime,
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
                                            endTime,
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
      print('📌 [RESERVE] selectedSlotId: $selectedSlotId');
      print('📌 [RESERVE] availableSlots count: ${availableSlots.length}');
      
      // Buscar el slot por su _id
      final slot = availableSlots.firstWhere(
        (s) {
          final slotId = s['_id'] ?? '';
          print('📌 [RESERVE] Comparing slot _id: $slotId with selectedSlotId: $selectedSlotId');
          return slotId == selectedSlotId;
        },
        orElse: () {
          print('❌ [RESERVE] No slot found with id: $selectedSlotId');
          throw Exception('Slot no encontrado');
        },
      );

      print('✅ [RESERVE] Slot encontrado: ${slot['_id']} - ${slot['startTime']}-${slot['endTime']}');
      
      final bookingData = {
        "slotId": slot['_id'],
        "date": DateFormat('yyyy-MM-dd').format(selectedDate!),
        "notas": _notasCtrl.text.isNotEmpty ? _notasCtrl.text : null,
      };

      print('📤 [RESERVE] Enviando reserva: $bookingData');

      final result = await BookingsApi(ApiClient.instance).createBooking(bookingData, token: widget.token);

      print('📥 [RESERVE] Response status: ${result.statusCode}');
      print('📋 [RESERVE] Response body: ${result.body}');

      setState(() => _loading = false);

      if (result.statusCode == 201 || result.statusCode == 200) {
        if (mounted) {
          await _sendBookingNotifications();
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear la reserva: ${result.statusCode}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ [RESERVE] ERROR: $e');
      print('❌ [RESERVE] Stack trace: $stackTrace');
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

  /// Enviar notificaciones al cliente y al estilista
  Future<void> _sendBookingNotifications() async {
    try {
      final notificationService = NotificationService();
      
      // Solicitar permisos si no están otorgados
      final hasPermission = await notificationService.requestPermissions();
      if (!hasPermission) {
        print('[NOTIFICATIONS] Permisos de notificación denegados');
        return;
      }

      // Obtener información del slot y estilista seleccionados
      final slot = availableSlots.firstWhere(
        (s) => (s['_id'] ?? s['id']) == selectedSlotId,
        orElse: () => {},
      );
      
      final stylist = widget.stylists.firstWhere(
        (s) => s['_id'] == stylistId,
        orElse: () => {},
      );

      final stylistName = stylist['nombre'] ?? 'Estilista';
      final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate!);
      final startTime = slot['horaInicio'] ?? 'N/A';

      // Notificación para el cliente (usuario actual)
      await notificationService.notifyClientBookingCreated(
        stylistName: stylistName,
        date: formattedDate,
        time: startTime,
        notificationId: DateTime.now().millisecondsSinceEpoch % 1000000,
      );

      print('[NOTIFICATIONS] Notificación enviada al cliente');

      // Nota: En una implementación real, el backend debería enviar 
      // una notificación push al estilista. Por ahora, solo simulamos 
      // que se enviará cuando el estilista abra la app.
      
    } catch (e) {
      print('[NOTIFICATIONS] Error al enviar notificaciones: $e');
      // No interrumpimos el flujo aunque falle la notificación
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
