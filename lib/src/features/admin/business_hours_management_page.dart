import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import '../../api/business_hours_api.dart';
import '../../core/theme/app_theme.dart';

class BusinessHoursManagementPage extends StatefulWidget {
  final String token;
  final String userRole;

  const BusinessHoursManagementPage({
    super.key,
    required this.token,
    required this.userRole,
  });

  @override
  State<BusinessHoursManagementPage> createState() =>
      _BusinessHoursManagementPageState();
}

class _BusinessHoursManagementPageState
    extends State<BusinessHoursManagementPage> {
  late BusinessHoursApi _api;
  bool _isLoading = true;
  bool _isSaving = false;

  // Días de la semana
  final List<String> _daysOfWeek = [
    'Domingo',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  // Data para los horarios
  late Map<int, Map<String, String>> _dayHours;
  late List<Map<String, dynamic>> _exceptions;

  @override
  void initState() {
    super.initState();
    _api = BusinessHoursApi(ApiClient.instance);
    _initializeHours();
    _loadBusinessHours();
  }

  void _initializeHours() {
    _dayHours = {
      for (int i = 0; i < 7; i++) i: {'open': '09:00', 'close': '18:00'}
    };
    _exceptions = [];
  }

  Future<void> _loadBusinessHours() async {
    try {
      setState(() => _isLoading = true);
      final response = await _api.getBusinessHours();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Business hours loaded: ${response.body}');

        if (data != null && data is Map) {
          // Cargar días
          if (data['days'] is List) {
            for (var day in data['days']) {
              final dayOfWeek = day['dayOfWeek'];
              _dayHours[dayOfWeek] = {
                'open': day['open'] ?? '09:00',
                'close': day['close'] ?? '18:00',
              };
            }
          }

          // Cargar excepciones
          if (data['exceptions'] is List) {
            _exceptions = List<Map<String, dynamic>>.from(data['exceptions']);
          }
        }
      } else if (response.statusCode == 404) {
        print('⚠️ No hay horarios guardados aún, usando valores por defecto');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading business hours: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando horarios: $e')),
        );
      }
    }
  }

  Future<void> _saveBusinessHours() async {
    try {
      // Validar datos
      for (int i = 0; i < 7; i++) {
        final open = _dayHours[i]!['open']!;
        final close = _dayHours[i]!['close']!;

        if (open.isEmpty || close.isEmpty) {
          _showError('Por favor completa todos los horarios');
          return;
        }

        if (close.compareTo(open) <= 0) {
          _showError('La hora de cierre debe ser mayor a la de apertura');
          return;
        }
      }

      setState(() => _isSaving = true);

      // Preparar payload - ASEGURARSE de que days se envía como array
      List<Map<String, dynamic>> daysList = [];
      for (int i = 0; i < 7; i++) {
        daysList.add({
          'dayOfWeek': i,
          'open': _dayHours[i]!['open']!,
          'close': _dayHours[i]!['close']!,
        });
      }

      final payload = {
        'days': daysList,
        'exceptions': _exceptions,
      };

      print('📤 Enviando payload: ${jsonEncode(payload)}');
      print('📤 Days count: ${daysList.length}');
      for (var day in daysList) {
        print('  - ${day['dayOfWeek']}: ${day['open']} - ${day['close']}');
      }

      final response = await _api.upsertBusinessHours(
        payload,
        token: widget.token,
      );

      if (response.statusCode == 200) {
        print('✅ Horarios guardados exitosamente');
        _showSuccess('Horarios guardados exitosamente');
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        _showError('Error guardando horarios: ${response.statusCode}');
      }

      setState(() => _isSaving = false);
    } catch (e) {
      print('❌ Error saving business hours: $e');
      _showError('Error guardando horarios: $e');
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectTime(int dayOfWeek, bool isOpenTime) async {
    final currentTime =
        isOpenTime ? _dayHours[dayOfWeek]!['open']! : _dayHours[dayOfWeek]!['close']!;
    final parts = currentTime.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (selected != null) {
      final formatted =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';

      setState(() {
        if (isOpenTime) {
          _dayHours[dayOfWeek]!['open'] = formatted;
        } else {
          _dayHours[dayOfWeek]!['close'] = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Horario del Negocio',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de sección
                  Text(
                    'Horarios Semanales',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Cards por día
                  ...[
                    for (int i = 0; i < 7; i++)
                      _buildDayCard(i, _daysOfWeek[i]),
                  ],

                  SizedBox(height: 32),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isSaving ? null : _saveBusinessHours,
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Guardar Horarios',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDayCard(int dayOfWeek, String dayName) {
    final open = _dayHours[dayOfWeek]!['open']!;
    final close = _dayHours[dayOfWeek]!['close']!;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName,
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              // Hora de apertura
              Expanded(
                child: _buildTimeSelector(
                  label: 'Apertura',
                  time: open,
                  onTap: () => _selectTime(dayOfWeek, true),
                ),
              ),
              SizedBox(width: 16),
              // Hora de cierre
              Expanded(
                child: _buildTimeSelector(
                  label: 'Cierre',
                  time: close,
                  onTap: () => _selectTime(dayOfWeek, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.gray,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.access_time, color: AppColors.gold),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
