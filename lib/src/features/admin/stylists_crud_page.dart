import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'admin_constants.dart';
import 'widgets/gender_selector.dart';

class StylistsCrudPage extends StatefulWidget {
  final String token;
  const StylistsCrudPage({super.key, required this.token});

  @override
  State<StylistsCrudPage> createState() => _StylistsCrudPageState();
}

class _StylistsCrudPageState extends State<StylistsCrudPage> {
  List<dynamic> stylists = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStylists();
  }

  Future<void> _fetchStylists() async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/stylists',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          stylists = data is List ? data : (data['data'] ?? []);
          loading = false;
        });
      } else {
        setState(() { stylists = []; loading = false; });
      }
    } catch (e) {
      print('Error: $e');
      setState(() { stylists = []; loading = false; });
    }
  }

  Future<void> _createStylist(Map<String, dynamic> stylist) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.post(
        '/api/v1/stylists',
        body: jsonEncode(stylist),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estilista creada exitosamente'), backgroundColor: Colors.green));
        await _fetchStylists();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear estilista'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _editStylist(String id, Map<String, dynamic> stylist) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.put(
        '/api/v1/stylists/$id',
        body: jsonEncode(stylist),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estilista actualizada exitosamente'), backgroundColor: Colors.green));
        await _fetchStylists();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar estilista'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _deleteStylist(String id) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.delete(
        '/api/v1/stylists/$id',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estilista eliminada exitosamente'), backgroundColor: Colors.green));
        await _fetchStylists();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar estilista'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  void _showStylistForm({Map<String, dynamic>? stylist, required bool isEdit}) {
    final nombreCtrl = TextEditingController(text: stylist?['nombre'] ?? '');
    final apellidoCtrl = TextEditingController(text: stylist?['apellido'] ?? '');
    final cedulaCtrl = TextEditingController(text: stylist?['cedula'] ?? '');
    final telefonoCtrl = TextEditingController(text: stylist?['telefono'] ?? '');
    String selectedGender = stylist?['genero'] ?? 'M';
    final edadCtrl = TextEditingController(text: stylist?['edad']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: stylist?['email'] ?? '');
    final passwordCtrl = TextEditingController(text: stylist?['password'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? 'Editar Estilista' : 'Crear Estilista', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                _buildTextField(nombreCtrl, 'Nombre', Icons.person),
                SizedBox(height: 12),
                _buildTextField(apellidoCtrl, 'Apellido', Icons.person_outline),
                SizedBox(height: 12),
                _buildTextField(cedulaCtrl, 'Cédula', Icons.credit_card),
                SizedBox(height: 12),
                _buildTextField(telefonoCtrl, 'Teléfono', Icons.phone),
                SizedBox(height: 12),
                Text('Género', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setState) => GenderSelector(
                    initialValue: selectedGender,
                    onChanged: (value) {
                      selectedGender = value;
                    },
                  ),
                ),
                SizedBox(height: 12),
                _buildTextField(edadCtrl, 'Edad', Icons.cake),
                SizedBox(height: 12),
                _buildTextField(emailCtrl, 'Email', Icons.email),
                SizedBox(height: 12),
                _buildTextField(passwordCtrl, 'Contraseña', Icons.lock, isPassword: true),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gray,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('Cancelar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(isEdit ? 'Guardar' : 'Crear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final data = FormBuilder.buildStylistData(
                          nombre: nombreCtrl.text,
                          apellido: apellidoCtrl.text,
                          cedula: cedulaCtrl.text,
                          telefono: telefonoCtrl.text,
                          genero: selectedGender,
                          edad: int.tryParse(edadCtrl.text) ?? 0,
                          email: emailCtrl.text,
                          password: passwordCtrl.text,
                          catalogs: [AdminConstants.DEFAULT_CATALOG_ID],
                        );
                        Navigator.of(ctx).pop();
                        if (isEdit && stylist != null) {
                          await _editStylist(stylist['_id'], data);
                        } else {
                          await _createStylist(data);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.gold)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Estilistas', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : stylists.isEmpty
              ? Center(child: Text('No hay estilistas registradas', style: TextStyle(color: AppColors.gray, fontSize: 16)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: stylists.length,
                  itemBuilder: (context, i) {
                    final s = stylists[i];
                    return Card(
                      color: Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${s['nombre'] ?? ''} ${s['apellido'] ?? ''}', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 8),
                            Text('Email: ${s['email'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            Text('Especialización: ${s['especializacion'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                                  icon: Icon(Icons.edit, color: Colors.black),
                                  label: Text('Editar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showStylistForm(stylist: s, isEdit: true),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  label: Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => _deleteStylist(s['_id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        child: Icon(Icons.add, color: Colors.black),
        onPressed: () => _showStylistForm(isEdit: false),
      ),
    );
  }
}
