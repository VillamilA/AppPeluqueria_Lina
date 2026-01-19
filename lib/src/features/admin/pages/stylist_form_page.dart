import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../common/dialogs/app_dialogs.dart';
import '../admin_constants.dart';
import '../widgets/gender_selector.dart';
import 'stylist_catalogs_page.dart';

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

class _StylistFormPageState extends State<StylistFormPage> with SingleTickerProviderStateMixin {
  late TextEditingController nombreCtrl;
  late TextEditingController apellidoCtrl;
  late TextEditingController cedulaCtrl;
  late TextEditingController telefonoCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController passwordCtrl;
  late TextEditingController confirmPasswordCtrl;
  late String selectedGender;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Catalogs management is now in separate page

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
      confirmPasswordCtrl = TextEditingController(text: '');
      selectedGender = widget.stylist?['genero']?.toString() ?? 'F';
      
      // Catalogs are now managed in a separate page (stylist_catalogs_page.dart)
      
      _animController = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );
      _animController.forward();
      
      print('✅ Todos los controllers inicializados correctamente');
    } catch (e) {
      print('❌ Error al inicializar controllers: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    cedulaCtrl.dispose();
    telefonoCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validar nombre
    final nombreValidation = FormValidations.validateNameMessage(nombreCtrl.text);
    if (nombreValidation != null) {
      _showErrorSnack(nombreValidation);
      return;
    }

    // Validar apellido
    final apellidoValidation = FormValidations.validateNameMessage(apellidoCtrl.text);
    if (apellidoValidation != null) {
      _showErrorSnack(apellidoValidation);
      return;
    }

    // Validar cédula
    final cedulaValidation = FormValidations.validateCedulaMessage(cedulaCtrl.text);
    if (cedulaValidation != null) {
      _showErrorSnack(cedulaValidation);
      return;
    }

    // Validar teléfono
    final telefonoValidation = FormValidations.validatePhoneMessage(telefonoCtrl.text);
    if (telefonoValidation != null) {
      _showErrorSnack(telefonoValidation);
      return;
    }

    // Validar email (solo en creación)
    if (!widget.isEdit && emailCtrl.text.isEmpty) {
      _showErrorSnack('El email es requerido');
      return;
    }

    if (!widget.isEdit && !FormValidations.isValidEmail(emailCtrl.text)) {
      _showErrorSnack(FormValidations.validateEmailMessage(emailCtrl.text) ?? 'Email inválido');
      return;
    }

    // Validar contraseñas
    if (!widget.isEdit && passwordCtrl.text.isEmpty) {
      _showErrorSnack('La contraseña es requerida');
      return;
    }
    if (passwordCtrl.text.isNotEmpty && passwordCtrl.text != confirmPasswordCtrl.text) {
      _showErrorSnack('Las contraseñas no coinciden');
      return;
    }

    setState(() => _isSaving = true);

    print('🟦 === SAVING STYLIST ===');
    print('📝 isEdit: ${widget.isEdit}');
    print('📋 nombreCtrl: "${nombreCtrl.text}" (${nombreCtrl.text.runtimeType})');
    print('📋 apellidoCtrl: "${apellidoCtrl.text}" (${apellidoCtrl.text.runtimeType})');
    print('📋 emailCtrl: "${emailCtrl.text}" (${emailCtrl.text.runtimeType})');
    print('📋 selectedGender: "$selectedGender" (${selectedGender.runtimeType})');
    print('📋 passwordCtrl: "${passwordCtrl.text.isNotEmpty ? '***' : 'EMPTY'}" (${passwordCtrl.text.runtimeType})');
    print('📋 Note: Catalogs are managed separately in StylistCatalogsPage');

    final data = <String, dynamic>{
      'nombre': nombreCtrl.text,
      'apellido': apellidoCtrl.text,
      'cedula': cedulaCtrl.text,
      'telefono': telefonoCtrl.text,
      'genero': selectedGender,
      // Solo incluir password si no está vacío o si estamos creando
      if (!widget.isEdit || passwordCtrl.text.isNotEmpty)
        'password': passwordCtrl.text,
    };

    // Email y role solo en creación
    if (!widget.isEdit) {
      data['email'] = emailCtrl.text;
      data['role'] = AdminConstants.ROLE_ESTILISTA;
    }

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
      if (mounted) {
        AppDialogHelper.showSuccess(
          context,
          title: 'Estilista ${widget.isEdit ? 'actualizada' : 'creada'}',
          message: '${widget.isEdit ? 'Cambios guardados' : 'Estilista registrada'} exitosamente',
          onAccept: () {
            if (mounted) Navigator.pop(context);
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final maxWidth = isMobile ? screenWidth : 600.0;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEdit ? 'Editar Estilista' : 'Nuevo Estilista',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // INFORMACIÓN PERSONAL
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: AppColors.gold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Información Personal',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildTextField(nombreCtrl, 'Nombre', Icons.person,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                            LengthLimitingTextInputFormatter(50),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildTextField(apellidoCtrl, 'Apellido', Icons.person_outline,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                            LengthLimitingTextInputFormatter(50),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildTextField(cedulaCtrl, 'Cédula (máx 10 números)', Icons.credit_card,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildTextField(telefonoCtrl, 'Teléfono (comienza con 09)', Icons.phone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Género',
                          style: TextStyle(color: AppColors.gold.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8),
                        GenderSelector(
                          initialValue: selectedGender,
                          onChanged: (value) => setState(() => selectedGender = value),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // CREDENCIALES
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock, color: AppColors.gold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              widget.isEdit ? 'Cambiar Contraseña' : 'Credenciales',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (widget.isEdit) ...[
                          SizedBox(height: 8),
                          Text(
                            'Dejar en blanco para no cambiar',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                        SizedBox(height: 16),
                        if (!widget.isEdit) ...[
                          _buildTextField(emailCtrl, 'Email', Icons.email),
                          SizedBox(height: 12),
                        ],
                        _buildTextField(passwordCtrl, widget.isEdit ? 'Nueva contraseña (opcional)' : 'Contraseña', Icons.lock, isPassword: true),
                        SizedBox(height: 12),
                        _buildTextField(confirmPasswordCtrl, 'Confirmar contraseña', Icons.lock_outline, isPassword: true),
                      ],
                    ),
                  ),

                  if (widget.isEdit) ...[
                    SizedBox(height: 16),

                    // GESTIONAR CATÁLOGOS
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final stylistId = widget.stylist!['_id']?.toString() ?? 
                                             widget.stylist!['id']?.toString() ?? '';
                            
                            if (stylistId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ID del estilista no encontrado'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StylistCatalogsPage(
                                  token: widget.token,
                                  stylistId: stylistId,
                                  stylistName: '${nombreCtrl.text} ${apellidoCtrl.text}',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(Icons.style, color: AppColors.gold, size: 22),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gestionar Catálogos',
                                        style: TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Servicios y disponibilidad',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: AppColors.gold, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 24),

                  // BOTONES DE ACCIÓN
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: BorderSide(color: AppColors.gold, width: 1.5),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Cancelar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: _isSaving ? 0 : 4,
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black87),
                                )
                              : Text(
                                  widget.isEdit ? 'Guardar' : 'Crear',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.gold.withOpacity(0.7), size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.gold, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[850],
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
