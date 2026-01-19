import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peluqueria_lina_app/src/widgets/custom_input_field.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../utils/validators.dart' as form_validators;
import 'auth_message_dialog.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  String _genero = 'M';
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  
  // Para mostrar requisitos de contraseña
  Map<String, bool> _passwordRequirements = {
    '8 caracteres mínimo': false,
    'Una MAYÚSCULA': false,
    'Una minúscula': false,
    'Un número (0-9)': false,
    'Carácter especial (.#\$%&@!*)': false,
  };

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _HintText(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomInputField(
                    controller: _nombreCtrl,
                    label: 'Nombre',
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-záéíóúñA-ZÁÉÍÓÚÑ\s]'),
                      ),
                      LengthLimitingTextInputFormatter(30),
                    ],
                    validator: (v) => form_validators.FormValidators.validateName(v, 'Nombre'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomInputField(
                    controller: _apellidoCtrl,
                    label: 'Apellido',
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-záéíóúñA-ZÁÉÍÓÚÑ\s]'),
                      ),
                      LengthLimitingTextInputFormatter(30),
                    ],
                    validator: (v) => form_validators.FormValidators.validateName(v, 'Apellido'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomInputField(
              controller: _cedulaCtrl,
              label: 'Cédula',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: Validators.cedula,
            ),
            const SizedBox(height: 12),
            CustomInputField(
              controller: _telefonoCtrl,
              label: 'Teléfono (ej: 0987654321)',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: form_validators.FormValidators.validatePhone,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _genero,
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Género: Masculino')),
                DropdownMenuItem(value: 'F', child: Text('Género: Femenino')),
                DropdownMenuItem(value: 'O', child: Text('Género: Otro')),
              ],
              onChanged: (v) => setState(() => _genero = v ?? 'M'),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.charcoal,
                labelText: 'Género',
                labelStyle: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w500),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              dropdownColor: AppColors.charcoal,
              style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            CustomInputField(
              controller: _correoCtrl,
              label: 'Correo',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: form_validators.FormValidators.validateEmail,
            ),
            const SizedBox(height: 16),
            // Campo de contraseña con visualización de requisitos
            CustomInputField(
              controller: _passCtrl,
              label: 'Contraseña',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              onChanged: (_) => setState(() {
                _passwordRequirements = form_validators.PasswordStrengthChecker.getAllRequirements(_passCtrl.text);
              }),
              validator: form_validators.FormValidators.validatePassword,
            ),
            if (_passCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Mostrar requisitos de contraseña
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _passwordRequirements.entries.map((entry) {
                    final isMet = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isMet ? Icons.check_circle : Icons.cancel,
                            color: isMet ? Colors.green : AppColors.gold.withOpacity(0.6),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: isMet ? Colors.green : AppColors.gold.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            CustomInputField(
              controller: _pass2Ctrl,
              label: 'Confirmar contraseña',
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) => v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold, // Fondo dorado
                  foregroundColor: Colors.black,   // Letras negras
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _loading
                    ? null
                    : () async {
                        if (!(_formKey.currentState?.validate() ?? false)) return;
                        setState(() => _loading = true);
                        try {
                          final res = await AuthService.instance.register({
                            'nombre': _nombreCtrl.text.trim(),
                            'apellido': _apellidoCtrl.text.trim(),
                            'cedula': _cedulaCtrl.text.trim(),
                            'telefono': _telefonoCtrl.text.trim(),
                            'genero': _genero,
                            'email': _correoCtrl.text.trim(),
                            'password': _passCtrl.text,
                          });

                          // Extraer token de la respuesta
                          String token = '';
                          if (res is Map && res.containsKey('token')) {
                            token = res['token'] ?? '';
                          } else if (res is String) {
                            token = res;
                          }

                          if (!mounted) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: AppColors.charcoal,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        color: AppColors.gold,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.black, size: 32),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('¡Registro exitoso!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Por favor verifica tu correo electrónico para poder iniciar sesión',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          Future.delayed(const Duration(seconds: 4), () {
                            if (mounted) {
                              Navigator.of(context).pop(); // Cierra el diálogo de éxito
                              // Redirigir al login
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false, // Elimina todas las rutas previas
                              );
                            }
                          });
                        } catch (e) {
                          if (!mounted) return;
                          
                          String errorMsg = e.toString();
                          if (errorMsg.startsWith('Exception: ')) {
                            errorMsg = errorMsg.substring(11);
                          }
                          
                          await AuthMessageDialog.show(
                            context,
                            title: 'Error en el Registro',
                            message: errorMsg,
                            type: MessageType.error,
                            confirmText: 'Intentar Nuevamente',
                          );
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Crear cuenta'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold, // Letras doradas
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText();
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Completa los datos para crear tu cuenta',
      style: TextStyle(color: AppColors.gray, fontSize: 13),
      textAlign: TextAlign.left,
    );
  }
}
