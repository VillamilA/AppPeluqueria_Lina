import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'admin_constants.dart';
import 'widgets/gender_selector.dart';

class ClientsCrudPage extends StatefulWidget {
  final String token;
  const ClientsCrudPage({super.key, required this.token});

  @override
  State<ClientsCrudPage> createState() => _ClientsCrudPageState();
}

class _ClientsCrudPageState extends State<ClientsCrudPage> {
  List<dynamic> clients = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() { loading = true; });
    try {
      final url = '/api/v1/users?role=${AdminConstants.ROLE_CLIENTE}';
      print('🔍 Fetching clients from: $url');
      print('🔑 Token: ${widget.token}');
      print('📌 ROLE_CLIENTE constant: ${AdminConstants.ROLE_CLIENTE}');
      print('📌 ROLE_CLIENTE constant value: ${AdminConstants.ROLE_CLIENTE}');
      
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
        
        final clients_list = (data is List)
          ? data
          : (data['data'] is List ? data['data'] : []);
        
        print('👥 Clients count: ${clients_list.length}');
        print('📝 Clients: $clients_list');
        
        // Verificar roles en la lista
        if (clients_list.isNotEmpty) {
          for (int i = 0; i < clients_list.length; i++) {
            final client = clients_list[i];
            print('  Cliente $i - Role: ${client['role']}, Nombre: ${client['nombre']}');
          }
        }
        
        setState(() {
          clients = clients_list;
          loading = false;
        });
      } else {
        print('❌ Error: Status code ${res.statusCode}');
        setState(() { clients = []; loading = false; });
      }
    } catch (e) {
      print('⚠️ Exception: $e');
      print('🔗 Stack trace: ${e.toString()}');
      setState(() { clients = []; loading = false; });
    }
  }

  Future<void> _createClient(Map<String, dynamic> client) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.post(
        '/api/v1/users',
        body: jsonEncode(client),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cliente creado exitosamente'), backgroundColor: Colors.green));
        await _fetchClients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear cliente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _editClient(String id, Map<String, dynamic> client) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.put(
        '/api/v1/users/$id',
        body: jsonEncode(client),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cliente actualizado exitosamente'), backgroundColor: Colors.green));
        await _fetchClients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar cliente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _deleteClient(String id) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.delete(
        '/api/v1/users/$id',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cliente eliminado exitosamente'), backgroundColor: Colors.green));
        await _fetchClients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar cliente'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  void _showClientForm({Map<String, dynamic>? client, required bool isEdit}) {
    final nombreCtrl = TextEditingController(text: client?['nombre'] ?? '');
    final apellidoCtrl = TextEditingController(text: client?['apellido'] ?? '');
    final cedulaCtrl = TextEditingController(text: client?['cedula'] ?? '');
    final telefonoCtrl = TextEditingController(text: client?['telefono'] ?? '');
    String selectedGender = client?['genero'] ?? 'M';
    final emailCtrl = TextEditingController(text: client?['email'] ?? '');
    final passwordCtrl = TextEditingController(text: client?['password'] ?? '');

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
                Text(isEdit ? 'Editar Cliente' : 'Crear Cliente', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
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
                      child: Text(isEdit ? 'Guardar' : 'Crear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final data = FormBuilder.buildClientData(
                          nombre: nombreCtrl.text,
                          apellido: apellidoCtrl.text,
                          cedula: cedulaCtrl.text,
                          telefono: telefonoCtrl.text,
                          genero: selectedGender,
                          email: emailCtrl.text,
                          password: passwordCtrl.text,
                        );
                        Navigator.of(ctx).pop();
                        if (isEdit && client != null) {
                          await _editClient(client['_id'], data);
                        } else {
                          await _createClient(data);
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
        title: Text('Gestión de Clientes', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : clients.isEmpty
              ? Center(child: Text('No hay clientes registrados', style: TextStyle(color: AppColors.gray, fontSize: 16)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: clients.length,
                  itemBuilder: (context, i) {
                    final c = clients[i];
                    return Card(
                      color: Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c['nombre'] ?? ''} ${c['apellido'] ?? ''}', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 8),
                            Text('Email: ${c['email'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            Text('Teléfono: ${c['telefono'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                                  icon: Icon(Icons.edit, color: Colors.black),
                                  label: Text('Editar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showClientForm(client: c, isEdit: true),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  label: Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => _deleteClient(c['_id']),
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
        onPressed: () => _showClientForm(isEdit: false),
      ),
    );
  }
}
