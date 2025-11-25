import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/widgets/custom_input_field.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/email_service.dart';
import '../../../core/utils/validators.dart';
import 'email_verification_dialog.dart';

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
                    validator: Validators.nombre,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomInputField(
                    controller: _apellidoCtrl,
                    label: 'Apellido',
                    textInputAction: TextInputAction.next,
                    validator: Validators.apellido,
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
              validator: Validators.cedula,
            ),
            const SizedBox(height: 12),
            CustomInputField(
              controller: _telefonoCtrl,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.telefono,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _genero,
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Género: Masculino')),
                DropdownMenuItem(value: 'F', child: Text('Género: Femenino')),
              ],
              onChanged: (v) => setState(() => _genero = v ?? 'M'),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.charcoal,
                labelText: 'Género',
                labelStyle: const TextStyle(color: AppColors.gray),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            CustomInputField(
              controller: _correoCtrl,
              label: 'Correo',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            CustomInputField(
              controller: _passCtrl,
              label: 'Contraseña',
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
            ),
            const SizedBox(height: 12),
            CustomInputField(
              controller: _pass2Ctrl,
              label: 'Confirmar contraseña',
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (v) => v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (!(_formKey.currentState?.validate() ?? false)) return;
                        setState(() => _loading = true);
                        try {
                          await AuthService.instance.register({
                            'nombre': _nombreCtrl.text.trim(),
                            'apellido': _apellidoCtrl.text.trim(),
                            'cedula': _cedulaCtrl.text.trim(),
                            'telefono': _telefonoCtrl.text.trim(),
                            'genero': _genero,
                            'email': _correoCtrl.text.trim(),
                            'password': _passCtrl.text,
                          });
                          try {
                            await EmailService.instance.sendVerificationEmail(_correoCtrl.text.trim());
                          } catch (e) {
                            print('Warning: No se pudo enviar correo de verificación: $e');
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
                                  ],
                                ),
                              ),
                            ),
                          );
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => EmailVerificationDialog(
                                  email: _correoCtrl.text.trim(),
                                  isAfterRegistration: true,
                                ),
                              );
                            }
                          });
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
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
