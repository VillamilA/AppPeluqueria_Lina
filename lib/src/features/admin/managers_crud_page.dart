import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/users_api.dart';
import '../../data/services/verification_service.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import 'admin_constants.dart';
import 'pages/manager_form_page.dart';

class ManagersCrudPage extends StatefulWidget {
  final String token;
  const ManagersCrudPage({super.key, required this.token});

  @override
  State<ManagersCrudPage> createState() => _ManagersCrudPageState();
}

class _ManagersCrudPageState extends State<ManagersCrudPage> {
  List<dynamic> managers = [];
  bool loading = true;
  late UsersApi _usersApi;

  @override
  void initState() {
    super.initState();
    _usersApi = UsersApi(ApiClient.instance);
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
        
        final managersList = (data is List)
          ? data
          : (data['data'] is List ? data['data'] : []);
        
        print('👥 Managers count: ${managersList.length}');
        print('📝 Managers: $managersList');
        
        // Verificar roles en la lista
        if (managersList.isNotEmpty) {
          for (int i = 0; i < managersList.length; i++) {
            final manager = managersList[i];
            print('  Manager $i - Role: ${manager['role']}, Nombre: ${manager['nombre']}');
          }
        }
        
        setState(() {
          managers = managersList;
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
        // Enviar email de verificación al gerente
        try {
          await VerificationService.instance.sendVerificationEmail(manager['email']);
          print('✅ Email de verificación enviado a ${manager['email']}');
        } catch (e) {
          print('⚠️ No se pudo enviar email de verificación: $e');
          // Continuar aunque falle el email
        }
        
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

  Future<void> _toggleManagerStatus(String id, bool currentStatus) async {
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
            content: Text(!currentStatus ? 'Gerente activado' : 'Gerente desactivado'),
            backgroundColor: AppColors.gold,
          ),
        );
        _fetchManagers();
      }
    } catch (e) {
      print('Error toggling manager status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { loading = false; });
    }
  }

  void _showManagerForm({Map<String, dynamic>? manager, required bool isEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagerFormPage(
          token: widget.token,
          manager: manager,
          isEdit: isEdit,
          onSave: (data) async {
            if (isEdit && manager != null) {
              await _editManager(manager['_id'], data);
            } else {
              await _createManager(data);
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                                  icon: Icon(Icons.edit, color: Colors.black),
                                  label: Text('Editar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showManagerForm(manager: m, isEdit: true),
                                ),
                                Switch(
                                  value: m['isActive'] ?? true,
                                  onChanged: (newValue) => _toggleManagerStatus(m['_id'], m['isActive'] ?? true),
                                  activeThumbColor: Colors.green,
                                  inactiveThumbColor: Colors.grey,
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
