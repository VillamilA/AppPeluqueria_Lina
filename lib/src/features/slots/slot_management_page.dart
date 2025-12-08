import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api_client.dart';
import '../../api/slots_api.dart';
import '../../api/users_api.dart';
import '../../core/theme/app_theme.dart';
import '../slots/create_slot_dialog.dart';

class SlotManagementPage extends StatefulWidget {
  final String token;
  final String userRole;

  const SlotManagementPage({super.key, 
    required this.token,
    required this.userRole,
  });

  @override
  State<SlotManagementPage> createState() => _SlotManagementPageState();
}

class _SlotManagementPageState extends State<SlotManagementPage> {
  late SlotsApi _slotsApi;
  late UsersApi _usersApi;
  List<dynamic> _stylists = [];
  String? _selectedStylistId;
  bool _isLoadingStylists = true;

  @override
  void initState() {
    super.initState();
    _slotsApi = SlotsApi(ApiClient.instance);
    _usersApi = UsersApi(ApiClient.instance);
    _loadStylists();
  }

  void _loadStylists() async {
    try {
      print('📋 SlotManagementPage: Cargando estilistas...');
      final response = await _usersApi.getUsersByRole('ESTILISTA', token: widget.token);
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ Data type: ${data.runtimeType}');
          
          List<dynamic> stylistsList = [];
          if (data is List) {
            stylistsList = data;
          } else if (data is Map && data['data'] is List) {
            stylistsList = data['data'];
          }
          
          print('✅ Estilistas cargados: ${stylistsList.length}');
          for (int i = 0; i < stylistsList.length; i++) {
            final s = stylistsList[i];
            print('   [$i] ${s['nombre']} ${s['apellido']} - ID: ${s['_id'] ?? s['id']}');
          }
          
          setState(() {
            _stylists = stylistsList;
            _isLoadingStylists = false;
            if (_stylists.isNotEmpty) {
              _selectedStylistId = _stylists.first['_id'] ?? _stylists.first['id'];
              print('✅ Stylist seleccionado: $_selectedStylistId');
            }
          });
        } catch (e, st) {
          print('❌ Error al parsear: $e');
          print('Stack: $st');
          setState(() => _isLoadingStylists = false);
        }
      } else {
        print('❌ Error al cargar estilistas: ${response.statusCode}');
        setState(() => _isLoadingStylists = false);
      }
    } catch (e, st) {
      print('❌ Error loading stylists: $e');
      print('Stack: $st');
      setState(() => _isLoadingStylists = false);
    }
  }

  void _showCreateSlotDialog() {
    if (_selectedStylistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona un estilista primero')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CreateSlotDialog(
        slotsApi: _slotsApi,
        token: widget.token,
        initialStylistId: _selectedStylistId,
        userRole: widget.userRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        title: Text(
          'Gestionar Horarios',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingStylists
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona un Estilista',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedStylistId,
                      onChanged: (value) {
                        setState(() => _selectedStylistId = value);
                      },
                      items: _stylists.map<DropdownMenuItem<String?>>((stylist) {
                        final stylistId = stylist['_id'] ?? stylist['id'];
                        return DropdownMenuItem(
                          value: stylistId as String?,
                          child: Text(
                            '${stylist['nombre']} ${stylist['apellido']}',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gold),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      dropdownColor: Colors.grey.shade800,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showCreateSlotDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.charcoal,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text(
                            'Crear Nuevo Horario',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Información',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear horarios para los estilistas:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Selecciona el estilista\n2. Haz clic en "Crear Nuevo Horario"\n3. Elige el día de la semana\n4. Establece los horarios de inicio y fin\n5. Confirma la creación',
                          style: TextStyle(color: AppColors.gray, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
