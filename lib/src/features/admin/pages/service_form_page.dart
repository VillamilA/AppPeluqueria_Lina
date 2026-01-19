import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/dialogs/app_dialogs.dart';
import '../../../utils/validators.dart';

class ServiceFormPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? service;
  final bool isEdit;
  final Function(Map<String, dynamic>) onSave;

  const ServiceFormPage({
    super.key,
    required this.token,
    this.service,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> with SingleTickerProviderStateMixin {
  late TextEditingController nombreCtrl;
  late TextEditingController codigoCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController precioCtrl;
  late TextEditingController duracionCtrl;
  bool activo = true;
  bool isSaving = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.service?['nombre'] ?? '');
    codigoCtrl = TextEditingController(text: widget.service?['codigo'] ?? '');
    descripcionCtrl = TextEditingController(text: widget.service?['descripcion'] ?? '');
    precioCtrl = TextEditingController(text: widget.service?['precio']?.toString() ?? '');
    duracionCtrl = TextEditingController(text: widget.service?['duracionMin']?.toString() ?? '');
    activo = widget.service?['activo'] ?? true;

    _animController = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    codigoCtrl.dispose();
    descripcionCtrl.dispose();
    precioCtrl.dispose();
    duracionCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validar nombre del servicio
    final nameError = FormValidators.validateServiceName(nombreCtrl.text);
    if (nameError != null) {
      _showErrorSnack(nameError);
      return;
    }

    // Validar código (solo en creación)
    if (!widget.isEdit) {
      final codeError = FormValidators.validateServiceCode(codigoCtrl.text);
      if (codeError != null) {
        _showErrorSnack(codeError);
        return;
      }
    }

    // Validar precio
    final priceError = FormValidators.validatePrice(precioCtrl.text);
    if (priceError != null) {
      _showErrorSnack(priceError);
      return;
    }

    // Validar duración
    final durationError = FormValidators.validateDuration(duracionCtrl.text);
    if (durationError != null) {
      _showErrorSnack(durationError);
      return;
    }

    // Validar descripción (opcional)
    final descError = FormValidators.validateDescription(descripcionCtrl.text);
    if (descError != null) {
      _showErrorSnack(descError);
      return;
    }

    setState(() => isSaving = true);

    final precio = double.parse(precioCtrl.text);
    final duracion = int.parse(duracionCtrl.text);

    final data = <String, dynamic>{
      'nombre': nombreCtrl.text.trim(),
      'precio': precio,
      'duracionMin': duracion,
    };

    if (!widget.isEdit) {
      data['codigo'] = codigoCtrl.text.trim().toUpperCase();
    }

    if (descripcionCtrl.text.isNotEmpty) {
      data['descripcion'] = descripcionCtrl.text.trim();
    }

    if (widget.isEdit || activo != true) {
      data['activo'] = activo;
    }

    try {
      await widget.onSave(data);
      if (mounted) {
        AppDialogHelper.showSuccess(
          context,
          title: 'Servicio ${widget.isEdit ? 'actualizado' : 'creado'}',
          message: '${widget.isEdit ? 'Cambios guardados' : 'Servicio registrado'} exitosamente',
          onAccept: () {
            if (mounted) Navigator.pop(context);
          },
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
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
          widget.isEdit ? 'Editar Servicio' : 'Nuevo Servicio',
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
                  // INFORMACIÓN BÁSICA
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
                            Icon(Icons.design_services, color: AppColors.gold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Información del Servicio',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          nombreCtrl,
                          'Nombre del Servicio *',
                          Icons.label,
                          maxLength: 30,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-záéíóúñA-ZÁÉÍÓÚÑ\s&\-\.]'),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildTextField(
                          codigoCtrl,
                          'Código * (máx 7 caracteres)',
                          Icons.qr_code,
                          enabled: !widget.isEdit,
                          maxLength: 7,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]'),
                            ),
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              return newValue.copyWith(text: newValue.text.toUpperCase());
                            }),
                          ],
                        ),
                        if (widget.isEdit) ...[
                          SizedBox(height: 8),
                          Text(
                            'El código no puede modificarse',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                        SizedBox(height: 12),
                        _buildTextField(
                          descripcionCtrl,
                          'Descripción (opcional)',
                          Icons.description,
                          maxLines: 3,
                          maxLength: 500,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // PRECIO Y DURACIÓN
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
                            Icon(Icons.attach_money, color: AppColors.gold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Detalles del Servicio',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          precioCtrl,
                          'Precio * (solo números)',
                          Icons.monetization_on,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildTextField(
                          duracionCtrl,
                          'Duración en minutos * (solo números)',
                          Icons.schedule,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Duración: entre 5 y 480 minutos',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[700]!, width: 1),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.toggle_on, color: AppColors.gold.withOpacity(0.7), size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Servicio Activo',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                ),
                              ),
                              Switch(
                                value: activo,
                                onChanged: (value) => setState(() => activo = value),
                                activeThumbColor: AppColors.gold,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

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
                          onPressed: isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: isSaving ? 0 : 4,
                          ),
                          child: isSaving
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
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      enabled: enabled,
      inputFormatters: inputFormatters,
      style: TextStyle(color: enabled ? Colors.white : Colors.grey[600], fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.gold.withOpacity(enabled ? 0.7 : 0.3), size: 20),
        counterText: '', // Oculta el contador si hay maxLength
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.gold, width: 1.5),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[850] : Colors.grey[900],
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
