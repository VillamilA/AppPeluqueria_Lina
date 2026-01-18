import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/user_provider.dart';
import '../../common/dialogs/app_dialogs.dart';

class EditProfileSection extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final String userRole;
  final VoidCallback? onSuccess;

  const EditProfileSection({
    super.key,
    required this.token,
    required this.user,
    required this.userRole,
    this.onSuccess,
  });

  @override
  State<EditProfileSection> createState() => _EditProfileSectionState();
}

class _EditProfileSectionState extends State<EditProfileSection> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _cedulaCtrl;
  late TextEditingController _emailCtrl;

  String _selectedGender = 'O';

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.user['nombre'] ?? '');
    _apellidoCtrl = TextEditingController(text: widget.user['apellido'] ?? '');
    _telefonoCtrl = TextEditingController(text: widget.user['telefono'] ?? '');
    _cedulaCtrl = TextEditingController(text: widget.user['cedula'] ?? '');
    _emailCtrl = TextEditingController(text: widget.user['email'] ?? '');
    _selectedGender = widget.user['genero'] ?? 'O';
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

    final userProvider = context.read<UserProvider>();

    final success = await userProvider.updateMyProfile(
      token: widget.token,
      nombre: _nombreCtrl.text.isNotEmpty ? _nombreCtrl.text : null,
      apellido: _apellidoCtrl.text.isNotEmpty ? _apellidoCtrl.text : null,
      telefono: _telefonoCtrl.text.isNotEmpty ? _telefonoCtrl.text : null,
      genero: _selectedGender,
    );

    if (mounted) {
      if (success) {
        print('✅ Actualizando UI después de guardar...');
        AppDialogHelper.showSuccess(
          context,
          title: 'Perfil actualizado',
          message: 'Tus datos han sido guardados correctamente',
          onAccept: () {
            if (mounted) widget.onSuccess?.call();
          },
        );
      } else {
        AppDialogHelper.showError(
          context,
          title: 'Error',
          message: context.read<UserProvider>().error,
        );
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
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return Form(
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

                // ===== NOMBRE =====
                _buildTextField(
                  controller: _nombreCtrl,
                  label: 'Nombre',
                  hint: 'Ingresa tu nombre',
                  enabled: true,
                  maxLength: 60,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo requerido';
                    if (value.length < 2) return 'Mínimo 2 caracteres';
                    if (value.length > 60) return 'Máximo 60 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ===== APELLIDO =====
                _buildTextField(
                  controller: _apellidoCtrl,
                  label: 'Apellido',
                  hint: 'Ingresa tu apellido',
                  enabled: true,
                  maxLength: 60,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo requerido';
                    if (value.length < 2) return 'Mínimo 2 caracteres';
                    if (value.length > 60) return 'Máximo 60 caracteres';
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
                    onPressed: userProvider.isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: userProvider.isLoading
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
          );
        },
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
            hintText: 'Ingresa tu número',
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
            helperText: 'Formato: 09XXXXXXXX (10 dígitos)',
            helperStyle: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Campo requerido';
            if (!value.startsWith('09')) return 'Debe empezar con 09';
            if (value.length != 10) return 'Debe tener exactamente 10 dígitos';
            return null;
          },
        ),
      ],
    );
  }

  /// Campo de edad con validación
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

