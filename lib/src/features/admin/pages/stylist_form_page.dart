import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_constants.dart';
import '../widgets/gender_selector.dart';
import '../dialogs/catalog_form_dialog.dart';

class StylistFormPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? stylist;
  final bool isEdit;
  final Function(Map<String, dynamic>) onSave;

  const StylistFormPage({super.key, 
    required this.token,
    this.stylist,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<StylistFormPage> createState() => _StylistFormPageState();
}

class _StylistFormPageState extends State<StylistFormPage> {
  late TextEditingController nombreCtrl;
  late TextEditingController apellidoCtrl;
  late TextEditingController cedulaCtrl;
  late TextEditingController telefonoCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController passwordCtrl;
  late TextEditingController edadCtrl;
  late String selectedGender;

  // Catalogs
  List<dynamic> _catalogs = [];
  List<String> _selectedCatalogs = [];
  bool _loadingCatalogs = true;

  // Schedule (work hours)
  final Map<String, List<String>> _workSchedule = {
    'lunes': [],
    'martes': [],
    'miercoles': [],
    'jueves': [],
    'viernes': [],
    'sabado': [],
    'domingo': [],
  };

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    print('🟦 === STYLIST FORM INIT ===');
    print('📝 isEdit: ${widget.isEdit}');
    print('👤 stylist data keys: ${widget.stylist?.keys.toList()}');
    
    // Verificar cada campo antes de asignarlo
    if (widget.stylist != null) {
      print('🔍 Verificando tipos de datos:');
      widget.stylist!.forEach((key, value) {
        print('  - $key: ${value.runtimeType} = $value');
      });
    }
    
    try {
      nombreCtrl = TextEditingController(text: widget.stylist?['nombre']?.toString() ?? '');
      apellidoCtrl = TextEditingController(text: widget.stylist?['apellido']?.toString() ?? '');
      cedulaCtrl = TextEditingController(text: widget.stylist?['cedula']?.toString() ?? '');
      telefonoCtrl = TextEditingController(text: widget.stylist?['telefono']?.toString() ?? '');
      emailCtrl = TextEditingController(text: widget.stylist?['email']?.toString() ?? '');
      // En edición NO precargar password
      passwordCtrl = TextEditingController(text: widget.isEdit ? '' : (widget.stylist?['password']?.toString() ?? ''));
      edadCtrl = TextEditingController(text: widget.stylist?['edad']?.toString() ?? '');
      selectedGender = widget.stylist?['genero']?.toString() ?? 'F';
      
      // Solo cargar catalogs si estamos creando, no editando
      // catalogs puede ser List<String> (IDs) o List<Map> (objetos completos)
      if (widget.stylist?['catalogs'] != null && widget.stylist!['catalogs'] is List) {
        final catalogsList = widget.stylist!['catalogs'] as List;
        _selectedCatalogs = catalogsList
            .map((catalog) {
              // Si es un Map con _id, extraer el ID
              if (catalog is Map && catalog.containsKey('_id')) {
                return catalog['_id'].toString();
              }
              // Si es un String, usarlo directamente
              return catalog.toString();
            })
            .toList()
            .cast<String>();
      }
      
      print('✅ Todos los controllers inicializados correctamente');
      print('📋 _selectedCatalogs: $_selectedCatalogs');
    } catch (e) {
      print('❌ Error al inicializar controllers: $e');
      rethrow;
    }
    
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/catalog',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _catalogs = data is List ? data : (data['data'] ?? []);
          _loadingCatalogs = false;
        });
        print('✅ Catálogos cargados: ${_catalogs.length}');
      } else {
        print('❌ Error: ${res.statusCode}');
        setState(() => _loadingCatalogs = false);
      }
    } catch (e) {
      print('⚠️ Error loading catalogs: $e');
      setState(() => _loadingCatalogs = false);
    }
  }

  void _showCatalogForm() {
    showDialog(
      context: context,
      builder: (ctx) => CatalogFormDialog(
        token: widget.token,
        onCatalogCreated: (catalogId) {
          print('✅ Catálogo creado: $catalogId');
          _loadCatalogs();
        },
      ),
    );
  }

  void _showWorkDayDialog(String dayName) {
    TextEditingController timeCtrl = TextEditingController(
      text: _workSchedule[dayName]?.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text(
          'Horario de ${dayName[0].toUpperCase()}${dayName.substring(1)}',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa los horarios separados por coma',
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
            SizedBox(height: 8),
            Text(
              'Ej: 08:00-12:00, 14:00-18:00',
              style: TextStyle(color: AppColors.gold.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            TextField(
              controller: timeCtrl,
              style: TextStyle(color: AppColors.gold),
              decoration: InputDecoration(
                hintText: '08:00-12:00, 14:00-18:00',
                hintStyle: TextStyle(color: AppColors.gray.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.gold),
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 12),
            Text(
              'Deja vacío para no trabajar este día',
              style: TextStyle(color: AppColors.gray, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (timeCtrl.text.isEmpty) {
                  _workSchedule[dayName] = [];
                } else {
                  _workSchedule[dayName] = timeCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                }
              });
              print('📅 Horario actualizado para $dayName: ${_workSchedule[dayName]}');
              Navigator.pop(ctx);
            },
            child: Text('Guardar', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    cedulaCtrl.dispose();
    telefonoCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    edadCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (nombreCtrl.text.isEmpty || emailCtrl.text.isEmpty || _selectedCatalogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa los campos requeridos y selecciona al menos un catálogo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    print('🟦 === SAVING STYLIST ===');
    print('📝 isEdit: ${widget.isEdit}');
    print('📋 nombreCtrl: "${nombreCtrl.text}" (${nombreCtrl.text.runtimeType})');
    print('📋 apellidoCtrl: "${apellidoCtrl.text}" (${apellidoCtrl.text.runtimeType})');
    print('📋 emailCtrl: "${emailCtrl.text}" (${emailCtrl.text.runtimeType})');
    print('📋 edadCtrl: "${edadCtrl.text}" (${edadCtrl.text.runtimeType})');
    print('📋 selectedGender: "$selectedGender" (${selectedGender.runtimeType})');
    print('📋 passwordCtrl: "${passwordCtrl.text.isNotEmpty ? '***' : 'EMPTY'}" (${passwordCtrl.text.runtimeType})');
    print('📋 _selectedCatalogs: $_selectedCatalogs (${_selectedCatalogs.runtimeType})');

    final data = {
      'nombre': nombreCtrl.text,
      'apellido': apellidoCtrl.text,
      'cedula': cedulaCtrl.text,
      'telefono': telefonoCtrl.text,
      'edad': int.tryParse(edadCtrl.text) ?? 0,
      'genero': selectedGender,
      'email': emailCtrl.text,
      // Solo incluir password si no está vacío o si estamos creando
      if (!widget.isEdit || passwordCtrl.text.isNotEmpty)
        'password': passwordCtrl.text,
      // Incluir catalogs (tanto en creación como en edición)
      'catalogs': _selectedCatalogs,
      // En creación, incluir role
      if (!widget.isEdit)
        'role': AdminConstants.ROLE_ESTILISTA,
    };

    // En creación, puede incluir workSchedule si lo desea
    if (!widget.isEdit) {
      final Map<String, dynamic> workScheduleData = {};
      _workSchedule.forEach((day, hours) {
        if (hours.isNotEmpty) {
          workScheduleData[day] = hours;
        }
      });
      
      if (workScheduleData.isNotEmpty) {
        data['workSchedule'] = workScheduleData;
      }
    }
    
    print('📤 Datos finales a enviar: ${data.keys.toList()}');
    print('📤 Payload: ${jsonEncode(data)}');

    try {
      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEdit ? 'Editar Estilista' : 'Crear Estilista',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información personal
            Text('Información Personal', style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildTextField(nombreCtrl, 'Nombre *', Icons.person),
            SizedBox(height: 16),
            _buildTextField(apellidoCtrl, 'Apellido *', Icons.person_outline),
            SizedBox(height: 16),
            _buildTextField(cedulaCtrl, 'Cédula *', Icons.credit_card),
            SizedBox(height: 16),
            _buildTextField(telefonoCtrl, 'Teléfono *', Icons.phone),
            SizedBox(height: 16),
            _buildTextField(edadCtrl, 'Edad', Icons.cake, keyboardType: TextInputType.number),
            SizedBox(height: 16),
            Text('Género', style: TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            GenderSelector(
              initialValue: selectedGender,
              onChanged: (value) => setState(() => selectedGender = value),
            ),

            // Datos de acceso
            SizedBox(height: 24),
            Text('Datos de Acceso', style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildTextField(emailCtrl, 'Email *', Icons.email),
            SizedBox(height: 16),
            _buildTextField(passwordCtrl, 'Contraseña ${widget.isEdit ? '(dejar vacío para no cambiar)' : '*'}', Icons.lock, isPassword: true),

            // Catálogos - SIEMPRE (creación y edición)
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Text('Catálogos *', style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: Icon(Icons.add, color: Colors.black, size: 18),
                    label: Text('Crear', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _showCatalogForm,
                  ),
                ],
              ),
              SizedBox(height: 12),
              _loadingCatalogs
                  ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : _catalogs.isEmpty
                      ? Text('No hay catálogos disponibles. ¡Crea uno!', style: TextStyle(color: AppColors.gray))
                      : Column(
                          children: _catalogs.map<Widget>((catalog) {
                            return CheckboxListTile(
                            title: Text(catalog['nombre'] ?? 'Sin nombre', style: TextStyle(color: AppColors.gold)),
                            subtitle: Text(catalog['descripcion'] ?? '', style: TextStyle(color: AppColors.gray, fontSize: 12)),
                            value: _selectedCatalogs.contains(catalog['_id']),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedCatalogs.add(catalog['_id']);
                                } else {
                                  _selectedCatalogs.remove(catalog['_id']);
                                }
                              });
                            },
                          );
                        }).toList(),
                        ),

            // Horario de trabajo - SOLO AL CREAR
            if (!widget.isEdit) ...[
              SizedBox(height: 24),
              Text('Horario de Trabajo (Opcional)', style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              ..._workSchedule.entries.map((entry) {
                final hasHours = entry.value.isNotEmpty;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasHours ? AppColors.gold.withOpacity(0.15) : Colors.grey.shade700,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: hasHours ? AppColors.gold : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onPressed: () => _showWorkDayDialog(entry.key),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.key[0].toUpperCase() + entry.key.substring(1),
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (hasHours) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '✓ Definido',
                                style: TextStyle(color: AppColors.gold, fontSize: 11),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        hasHours ? entry.value.join(', ') : 'Tap para agregar',
                        style: TextStyle(
                          color: hasHours ? AppColors.gray : AppColors.gray.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            ],

            // Botones
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gray,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(widget.isEdit ? 'Guardar' : 'Crear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.gold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.gray),
        prefixIcon: Icon(icon, color: AppColors.gold),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
