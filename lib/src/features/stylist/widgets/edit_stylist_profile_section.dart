import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../api/users_api.dart';
import '../../../api/api_client.dart';
import '../../common/dialogs/app_dialogs.dart';

class EditStylistProfileSection extends StatefulWidget {
  final String token;
  final Map<String, dynamic> stylist;
  final VoidCallback? onSuccess;

  const EditStylistProfileSection({
    super.key,
    required this.token,
    required this.stylist,
    this.onSuccess,
  });

  @override
  State<EditStylistProfileSection> createState() => _EditStylistProfileSectionState();
}

class _EditStylistProfileSectionState extends State<EditStylistProfileSection> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _cedulaCtrl;
  late TextEditingController _emailCtrl;

  String _selectedGender = 'O';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.stylist['nombre'] ?? '');
    _apellidoCtrl = TextEditingController(text: widget.stylist['apellido'] ?? '');
    _telefonoCtrl = TextEditingController(text: widget.stylist['telefono'] ?? '');
    _cedulaCtrl = TextEditingController(text: widget.stylist['cedula'] ?? '');
    _emailCtrl = TextEditingController(text: widget.stylist['email'] ?? '');
    _selectedGender = widget.stylist['genero'] ?? 'O';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _cedulaCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // El backend permite null/vacío en todos estos campos
      // Solo validamos formato si están presentes

      // Preparar datos para actualizar
      final data = <String, dynamic>{
        'nombre': _nombreCtrl.text.trim().isEmpty ? null : _nombreCtrl.text.trim(),
        'apellido': _apellidoCtrl.text.trim().isEmpty ? null : _apellidoCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
        'genero': _selectedGender,
      };

      // Eliminar null values para no enviar campos vacíos
      data.removeWhere((key, value) => value == null);

      if (data.isEmpty) {
        throw Exception('No hay cambios para guardar');
      }

      print('🔵 [STYLIST PROFILE] Actualizando perfil...');
      
      print('  - Endpoint: PUT /api/v1/users/me');
      print('  - Data: ${data.keys.join(", ")}');

      final response = await UsersApi(ApiClient.instance).updateMyProfile(
        data,
        widget.token,
      );

      print('  - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Perfil actualizado exitosamente');

        if (mounted) {
          // Usar AppDialogHelper como en el cliente
          AppDialogHelper.showSuccess(
            context,
            title: 'Perfil actualizado',
            message: 'Tus datos han sido guardados correctamente',
            onAccept: () {
              if (mounted) {
                widget.onSuccess?.call();
                // Esperar 2 segundos antes de cerrar para que la API procese
                Future.delayed(Duration(seconds: 2), () {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                });
              }
            },
          );
        }
      } else if (response.statusCode == 400) {
        throw Exception('La solicitud es inválida');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Sesión expirada');
      } else if (response.statusCode == 404) {
        throw Exception('Perfil no encontrado');
      } else if (response.statusCode == 500) {
        throw Exception('Error del servidor');
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        AppDialogHelper.showError(
          context,
          title: 'Error',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Editar Perfil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),

            // Sección: Datos permitidos para editar
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Solo puedes editar: nombre, apellido, teléfono y género',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ===== NOMBRE =====
            _buildTextField(
              controller: _nombreCtrl,
              label: 'Nombre',
              hint: 'Ingresa tu nombre (opcional)',
              enabled: true,
              maxLength: 60,
              validator: (value) {
                // Campo opcional, pero si tiene datos, validar formato
                if (value != null && value.isNotEmpty) {
                  if (value.length < 2) return 'Mínimo 2 caracteres';
                  if (value.length > 60) return 'Máximo 60 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ===== APELLIDO =====
            _buildTextField(
              controller: _apellidoCtrl,
              label: 'Apellido',
              hint: 'Ingresa tu apellido (opcional)',
              enabled: true,
              maxLength: 60,
              validator: (value) {
                // Campo opcional, pero si tiene datos, validar formato
                if (value != null && value.isNotEmpty) {
                  if (value.length < 2) return 'Mínimo 2 caracteres';
                  if (value.length > 60) return 'Máximo 60 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ===== CÉDULA (bloqueada) =====
            _buildTextField(
              controller: _cedulaCtrl,
              label: 'Cédula (No editable)',
              hint: 'Tu cédula no se puede cambiar',
              enabled: false,
              validator: null,
            ),
            const SizedBox(height: 12),

            // ===== EMAIL (bloqueada) =====
            _buildTextField(
              controller: _emailCtrl,
              label: 'Email (No editable)',
              hint: 'Tu email no se puede cambiar',
              enabled: false,
              keyboardType: TextInputType.emailAddress,
              validator: null,
            ),
            const SizedBox(height: 12),

            // ===== TELÉFONO =====
            _buildTelefonoField(),
            const SizedBox(height: 12),

            // ===== GÉNERO =====
            _buildGenderDropdown(),
            const SizedBox(height: 20),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.charcoal),
                        ),
                      )
                    : const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          color: AppColors.charcoal,
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

  /// Campo de teléfono con validación inteligente
  Widget _buildTelefonoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teléfono',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _telefonoCtrl,
          enabled: true,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
            _TelefonoInputFormatter(),
          ],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ingresa tu número (opcional)',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: AppColors.charcoal,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            helperText: 'Formato: 09XXXXXXXX (opcional)',
            helperStyle: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          validator: (value) {
            // Campo opcional, permite null o vacío
            if (value == null || value.isEmpty) return null;
            // Si tiene datos, validar formato
            if (!value.startsWith('09')) return 'Debe empezar con 09';
            if (value.length != 10) return 'Debe tener exactamente 10 dígitos';
            return null;
          },
        ),
      ],
    );
  }

  /// Campo de texto genérico
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines ?? 1,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: AppColors.charcoal,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade800),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: validator,
        ),
      ],
    );
  }

  /// Dropdown de género
  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Género',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          items: const [
            DropdownMenuItem(value: 'M', child: Text('Masculino')),
            DropdownMenuItem(value: 'F', child: Text('Femenino')),
            DropdownMenuItem(value: 'O', child: Text('Otro')),
          ],
          onChanged: (value) => setState(() => _selectedGender = value ?? 'O'),
          style: const TextStyle(color: Colors.white),
          dropdownColor: AppColors.charcoal,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.charcoal,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

/// Input formatter para teléfono
class _TelefonoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    if (text.length < 2) {
      return newValue;
    }

    if (!text.startsWith('09')) {
      return oldValue;
    }

    if (text.length > 10) {
      text = text.substring(0, 10);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.fromPosition(
        TextPosition(offset: text.length),
      ),
    );
  }
}
