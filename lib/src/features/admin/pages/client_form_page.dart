import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_constants.dart';
import '../widgets/gender_selector.dart';

class ClientFormPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? client;
  final bool isEdit;
  final Function(Map<String, dynamic>) onSave;

  const ClientFormPage({super.key, 
    required this.token,
    this.client,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  late TextEditingController nombreCtrl;
  late TextEditingController apellidoCtrl;
  late TextEditingController cedulaCtrl;
  late TextEditingController telefonoCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController passwordCtrl;
  late String selectedGender;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.client?['nombre'] ?? '');
    apellidoCtrl = TextEditingController(text: widget.client?['apellido'] ?? '');
    cedulaCtrl = TextEditingController(text: widget.client?['cedula'] ?? '');
    telefonoCtrl = TextEditingController(text: widget.client?['telefono'] ?? '');
    emailCtrl = TextEditingController(text: widget.client?['email'] ?? '');
    passwordCtrl = TextEditingController(text: widget.client?['password'] ?? '');
    selectedGender = widget.client?['genero'] ?? 'M';
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    cedulaCtrl.dispose();
    telefonoCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (nombreCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completa los campos requeridos'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isSaving = true);

    final data = FormBuilder.buildClientData(
      nombre: nombreCtrl.text,
      apellido: apellidoCtrl.text,
      cedula: cedulaCtrl.text,
      telefono: telefonoCtrl.text,
      genero: selectedGender,
      email: emailCtrl.text,
      password: passwordCtrl.text,
    );

    try {
      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => isSaving = false);
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
          widget.isEdit ? 'Editar Cliente' : 'Crear Cliente',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(nombreCtrl, 'Nombre', Icons.person),
            SizedBox(height: 16),
            _buildTextField(apellidoCtrl, 'Apellido', Icons.person_outline),
            SizedBox(height: 16),
            _buildTextField(cedulaCtrl, 'Cédula', Icons.credit_card),
            SizedBox(height: 16),
            _buildTextField(telefonoCtrl, 'Teléfono', Icons.phone),
            SizedBox(height: 16),
            Text('Género', style: TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            GenderSelector(
              initialValue: selectedGender,
              onChanged: (value) => setState(() => selectedGender = value),
            ),
            SizedBox(height: 16),
            _buildTextField(emailCtrl, 'Email', Icons.email),
            SizedBox(height: 16),
            _buildTextField(passwordCtrl, 'Contraseña', Icons.lock, isPassword: true),
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
                    onPressed: isSaving ? null : _save,
                    child: isSaving
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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
