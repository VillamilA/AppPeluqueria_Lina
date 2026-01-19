import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../api/users_api.dart';
import '../../../api/api_client.dart';
import '../../common/dialogs/app_dialogs.dart';
import 'dart:convert';

class ChangePasswordSection extends StatefulWidget {
  final String token;

  const ChangePasswordSection({
    super.key,
    required this.token,
  });

  @override
  State<ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<ChangePasswordSection> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  late UsersApi _usersApi;

  @override
  void initState() {
    super.initState();
    _usersApi = UsersApi(ApiClient.instance);
  }

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      AppDialogHelper.showError(
        context,
        title: 'Error',
        message: 'Las contraseñas no coinciden',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Según documentación: PUT /api/v1/users/me solo requiere el token
      // El endpoint actualiza solo los campos enviados
      final body = {
        'password': _newPasswordCtrl.text,
      };

      final response = await _usersApi.updateMyProfile(body, widget.token);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          AppDialogHelper.showSuccess(
            context,
            title: 'Contraseña actualizada',
            message: 'Tu contraseña ha sido cambiada correctamente',
            onAccept: () {
              _newPasswordCtrl.clear();
              _confirmPasswordCtrl.clear();
              Navigator.pop(context);
            },
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          AppDialogHelper.showError(
            context,
            title: 'Error',
            message: errorData['message'] ?? 'No se pudo cambiar la contraseña',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogHelper.showError(
          context,
          title: 'Error',
          message: 'Error: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
              'Cambiar Contraseña',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _newPasswordCtrl,
              label: 'Nueva Contraseña',
              hint: 'Ingresa tu nueva contraseña',
              obscure: _obscureNewPassword,
              onToggleObscure: () => setState(
                () => _obscureNewPassword = !_obscureNewPassword,
              ),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _confirmPasswordCtrl,
              label: 'Confirmar Contraseña',
              hint: 'Confirma tu nueva contraseña',
              obscure: _obscureConfirmPassword,
              onToggleObscure: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.charcoal),
                        ),
                      )
                    : const Text(
                        'Cambiar Contraseña',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
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
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onToggleObscure,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
