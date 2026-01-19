import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/dialogs/app_dialogs.dart';

class CatalogFormPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? catalog;
  final bool isEdit;
  final Function(Map<String, dynamic>) onSave;

  const CatalogFormPage({
    super.key,
    required this.token,
    this.catalog,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<CatalogFormPage> createState() => _CatalogFormPageState();
}

class _CatalogFormPageState extends State<CatalogFormPage> with SingleTickerProviderStateMixin {
  late TextEditingController nombreCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController imageUrlCtrl;
  bool activo = true;
  bool isSaving = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.catalog?['nombre'] ?? '');
    descripcionCtrl = TextEditingController(text: widget.catalog?['descripcion'] ?? '');
    imageUrlCtrl = TextEditingController(text: widget.catalog?['imageUrl'] ?? '');
    activo = widget.catalog?['activo'] ?? true;

    _animController = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    imageUrlCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validar nombre (solo letras y espacios)
    if (nombreCtrl.text.isEmpty) {
      _showErrorSnack('El nombre es requerido');
      return;
    }
    
    final nombreRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$');
    if (!nombreRegex.hasMatch(nombreCtrl.text)) {
      _showErrorSnack('El nombre solo puede contener letras y espacios');
      return;
    }

    // Validar descripción (máximo 150 caracteres)
    if (descripcionCtrl.text.length > 150) {
      _showErrorSnack('La descripción no puede exceder 150 caracteres');
      return;
    }

    // Validar URL de imagen (si se proporciona)
    if (imageUrlCtrl.text.isNotEmpty) {
      final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
        caseSensitive: false,
      );
      if (!urlRegex.hasMatch(imageUrlCtrl.text)) {
        _showErrorSnack('La URL de imagen no es válida');
        return;
      }
    }

    setState(() => isSaving = true);

    final data = <String, dynamic>{
      'nombre': nombreCtrl.text.trim(),
    };

    if (descripcionCtrl.text.isNotEmpty) {
      data['descripcion'] = descripcionCtrl.text.trim();
    }

    if (imageUrlCtrl.text.isNotEmpty) {
      data['imageUrl'] = imageUrlCtrl.text.trim();
    }

    if (!widget.isEdit) {
      data['activo'] = activo;
    }

    try {
      await widget.onSave(data);
      if (mounted) {
        AppDialogHelper.showSuccess(
          context,
          title: 'Catálogo ${widget.isEdit ? 'actualizado' : 'creado'}',
          message: '${widget.isEdit ? 'Cambios guardados' : 'Catálogo registrado'} exitosamente',
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
          widget.isEdit ? 'Editar Catálogo' : 'Nuevo Catálogo',
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
                  // INFORMACIÓN DEL CATÁLOGO
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
                            Icon(Icons.category, color: AppColors.gold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Información del Catálogo',
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
                          'Nombre del Catálogo *', 
                          Icons.label,
                          helperText: 'Solo letras y espacios',
                        ),
                        SizedBox(height: 12),
                        _buildTextField(
                          descripcionCtrl, 
                          'Descripción (opcional)', 
                          Icons.description, 
                          maxLines: 3,
                          maxLength: 150,
                          helperText: '${descripcionCtrl.text.length}/150 caracteres',
                        ),
                        SizedBox(height: 12),
                        _buildTextField(
                          imageUrlCtrl, 
                          'URL de Imagen (opcional)', 
                          Icons.image,
                          helperText: 'Ejemplo: https://ejemplo.com/imagen.jpg',
                        ),
                        if (!widget.isEdit) ...[
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
                                    'Estado Activo',
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
    int? maxLength,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: (value) {
        // Actualizar el estado para refrescar el contador de caracteres
        setState(() {});
      },
      style: TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        helperText: helperText,
        helperStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
        counterStyle: TextStyle(color: AppColors.gold.withOpacity(0.7), fontSize: 12),
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
