import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'admin_constants.dart';
import 'widgets/gender_selector.dart';

class ManagersCrudPage extends StatefulWidget {
  final String token;
  const ManagersCrudPage({super.key, required this.token});

  @override
  State<ManagersCrudPage> createState() => _ManagersCrudPageState();
}

class _ManagersCrudPageState extends State<ManagersCrudPage> {
  List<dynamic> managers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchManagers();
  }

  Future<void> _fetchManagers() async {
    setState(() { loading = true; });
    try {
      final url = '/api/v1/users?role=${AdminConstants.ROLE_GERENTE}';
      print('🔍 Fetching managers from: $url');
      print('🔑 Token: ${widget.token}');
      print('📌 ROLE_GERENTE constant: ${AdminConstants.ROLE_GERENTE}');
      
      final res = await ApiClient.instance.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      print('📊 Response Status: ${res.statusCode}');
      print('📋 Response Body: ${res.body}');
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('✅ Data decoded: $data');
        print('📦 Data type: ${data.runtimeType}');
        print('🔎 Has "data" key: ${data is Map && data.containsKey('data')}');
        
        final managers_list = (data is List)
          ? data
          : (data['data'] is List ? data['data'] : []);
        
        print('👥 Managers count: ${managers_list.length}');
        print('📝 Managers: $managers_list');
        
        // Verificar roles en la lista
        if (managers_list.isNotEmpty) {
          for (int i = 0; i < managers_list.length; i++) {
            final manager = managers_list[i];
            print('  Manager $i - Role: ${manager['role']}, Nombre: ${manager['nombre']}');
          }
        }
        
        setState(() {
          managers = managers_list;
          loading = false;
        });
      } else {
        print('❌ Error: Status code ${res.statusCode}');
        setState(() { managers = []; loading = false; });
      }
    } catch (e) {
      print('⚠️ Exception: $e');
      print('🔗 Stack trace: ${e.toString()}');
      setState(() { managers = []; loading = false; });
    }
  }

  Future<void> _createManager(Map<String, dynamic> manager) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.post(
        '/api/v1/users',
        body: jsonEncode(manager),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gerente creado exitosamente'), backgroundColor: Colors.green));
        await _fetchManagers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear gerente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _editManager(String id, Map<String, dynamic> manager) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.put(
        '/api/v1/users/$id',
        body: jsonEncode(manager),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gerente actualizado exitosamente'), backgroundColor: Colors.green));
        await _fetchManagers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar gerente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _deleteManager(String id) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.delete(
        '/api/v1/users/$id',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gerente eliminado exitosamente'), backgroundColor: Colors.green));
        await _fetchManagers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar gerente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  void _showManagerForm({Map<String, dynamic>? manager, required bool isEdit}) {
    final nombreCtrl = TextEditingController(text: manager?['nombre'] ?? '');
    final apellidoCtrl = TextEditingController(text: manager?['apellido'] ?? '');
    final cedulaCtrl = TextEditingController(text: manager?['cedula'] ?? '');
    final telefonoCtrl = TextEditingController(text: manager?['telefono'] ?? '');
    String selectedGender = manager?['genero'] ?? 'M';
    final emailCtrl = TextEditingController(text: manager?['email'] ?? '');
    final passwordCtrl = TextEditingController(text: manager?['password'] ?? '');

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
                Text(isEdit ? 'Editar Gerente' : 'Crear Gerente', 
                    style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
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
                      child: Text(isEdit ? 'Guardar' : 'Crear', 
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final data = FormBuilder.buildUserData(
                          nombre: nombreCtrl.text,
                          apellido: apellidoCtrl.text,
                          cedula: cedulaCtrl.text,
                          telefono: telefonoCtrl.text,
                          genero: selectedGender,
                          email: emailCtrl.text,
                          password: passwordCtrl.text,
                          role: AdminConstants.ROLE_GERENTE,
                        );
                        Navigator.of(ctx).pop();
                        if (isEdit && manager != null) {
                          await _editManager(manager['_id'], data);
                        } else {
                          await _createManager(data);
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
        title: Text('Gestión de Gerentes', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : managers.isEmpty
              ? Center(child: Text('No hay gerentes registrados', style: TextStyle(color: AppColors.gray, fontSize: 16)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: managers.length,
                  itemBuilder: (context, i) {
                    final m = managers[i];
                    return Card(
                      color: Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${m['nombre'] ?? ''} ${m['apellido'] ?? ''}', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 8),
                            Text('Email: ${m['email'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            Text('Teléfono: ${m['telefono'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                                  icon: Icon(Icons.edit, color: Colors.black),
                                  label: Text('Editar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showManagerForm(manager: m, isEdit: true),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  label: Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => _deleteManager(m['_id']),
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
        onPressed: () => _showManagerForm(isEdit: false),
      ),
    );
  }
}
