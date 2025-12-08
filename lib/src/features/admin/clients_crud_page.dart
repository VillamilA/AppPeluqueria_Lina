import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/users_api.dart';
import '../../data/services/verification_service.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'admin_constants.dart';
import 'pages/client_form_page.dart';

class ClientsCrudPage extends StatefulWidget {
  final String token;
  const ClientsCrudPage({super.key, required this.token});

  @override
  State<ClientsCrudPage> createState() => _ClientsCrudPageState();
}

class _ClientsCrudPageState extends State<ClientsCrudPage> {
  List<dynamic> clients = [];
  bool loading = true;
  late UsersApi _usersApi;

  @override
  void initState() {
    super.initState();
    _usersApi = UsersApi(ApiClient.instance);
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
        
        final clientsList = (data is List)
          ? data
          : (data['data'] is List ? data['data'] : []);
        
        print('👥 Clients count: ${clientsList.length}');
        print('📝 Clients: $clientsList');
        
        // Verificar roles en la lista
        if (clientsList.isNotEmpty) {
          for (int i = 0; i < clientsList.length; i++) {
            final client = clientsList[i];
            print('  Cliente $i - Role: ${client['role']}, Nombre: ${client['nombre']}');
          }
        }
        
        setState(() {
          clients = clientsList;
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
        // Enviar email de verificación al cliente
        try {
          await VerificationService.instance.sendVerificationEmail(client['email']);
          print('✅ Email de verificación enviado a ${client['email']}');
        } catch (e) {
          print('⚠️ No se pudo enviar email de verificación: $e');
          // Continuar aunque falle el email
        }
        
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

  Future<void> _toggleClientStatus(String id, bool currentStatus) async {
    setState(() { loading = true; });
    try {
      final res = await _usersApi.updateUserStatus(
        id,
        !currentStatus,
        token: widget.token,
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? 'Cliente activado' : 'Cliente desactivado'),
            backgroundColor: AppColors.gold,
          ),
        );
        _fetchClients();
      }
    } catch (e) {
      print('Error toggling client status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { loading = false; });
    }
  }

  void _showClientForm({Map<String, dynamic>? client, required bool isEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormPage(
          token: widget.token,
          client: client,
          isEdit: isEdit,
          onSave: (data) async {
            if (isEdit && client != null) {
              await _editClient(client['_id'], data);
            } else {
              await _createClient(data);
            }
          },
        ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Estado', style: TextStyle(color: AppColors.gold, fontSize: 12)),
                                    Switch(
                                      value: c['isActive'] ?? true,
                                      onChanged: (value) => _toggleClientStatus(c['_id'], c['isActive'] ?? true),
                                      activeThumbColor: Colors.green,
                                      inactiveThumbColor: Colors.grey,
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                                  icon: Icon(Icons.edit, color: Colors.black),
                                  label: Text('Editar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showClientForm(client: c, isEdit: true),
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
