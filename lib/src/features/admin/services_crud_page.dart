import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';

class ServicesCrudPage extends StatefulWidget {
  final String token;
  const ServicesCrudPage({super.key, required this.token});

  @override
  State<ServicesCrudPage> createState() => _ServicesCrudPageState();
}

class _ServicesCrudPageState extends State<ServicesCrudPage> {
  List<dynamic> services = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/services',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          services = data is List ? data : (data['data'] ?? []);
          loading = false;
        });
      } else {
        setState(() { services = []; loading = false; });
      }
    } catch (e) {
      print('Error al obtener servicios: $e');
      setState(() { services = []; loading = false; });
    }
  }

  Future<void> _createService(Map<String, dynamic> service) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/v1/services',
        body: jsonEncode(service),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Servicio creado exitosamente'), backgroundColor: Colors.green));
        await _fetchServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear servicio'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _editService(String id, Map<String, dynamic> service) async {
    try {
      final res = await ApiClient.instance.put(
        '/api/v1/services/$id',
        body: jsonEncode(service),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Servicio actualizado exitosamente'), backgroundColor: Colors.green));
        await _fetchServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar servicio'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteService(String id) async {
    try {
      final res = await ApiClient.instance.delete(
        '/api/v1/services/$id',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Servicio eliminado exitosamente'), backgroundColor: Colors.green));
        await _fetchServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar servicio'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showServiceForm({Map<String, dynamic>? service, required bool isEdit}) {
    final codigoCtrl = TextEditingController(text: service?['codigo'] ?? '');
    final nombreCtrl = TextEditingController(text: service?['nombre'] ?? '');
    final descripcionCtrl = TextEditingController(text: service?['descripcion'] ?? '');
    final duracionCtrl = TextEditingController(text: service?['duracionMin']?.toString() ?? '');
    final precioCtrl = TextEditingController(text: service?['precio']?.toString() ?? '');
    final categoriaCtrl = TextEditingController(text: service?['categoria'] ?? '');
    bool activo = service?['activo'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text(isEdit ? 'Editar Servicio' : 'Crear Servicio', style: TextStyle(color: AppColors.gold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(codigoCtrl, 'Código (ej: SV010)'),
              _buildTextField(nombreCtrl, 'Nombre'),
              _buildTextField(descripcionCtrl, 'Descripción'),
              _buildTextField(duracionCtrl, 'Duración (minutos)', TextInputType.number),
              _buildTextField(precioCtrl, 'Precio', TextInputType.number),
              _buildTextField(categoriaCtrl, 'Categoría'),
              CheckboxListTile(
                title: Text('Activo', style: TextStyle(color: AppColors.gold)),
                value: activo,
                activeColor: AppColors.gold,
                onChanged: (v) => activo = v ?? true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancelar', style: TextStyle(color: AppColors.gold)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text(isEdit ? 'Guardar' : 'Crear', style: TextStyle(color: Colors.black)),
            onPressed: () async {
              final data = {
                'codigo': codigoCtrl.text,
                'nombre': nombreCtrl.text,
                'descripcion': descripcionCtrl.text,
                'duracionMin': int.tryParse(duracionCtrl.text) ?? 0,
                'precio': double.tryParse(precioCtrl.text) ?? 0.0,
                'categoria': categoriaCtrl.text,
                'activo': activo,
              };
              Navigator.of(ctx).pop();
              if (isEdit && service != null) {
                await _editService(service['_id'], data);
              } else {
                await _createService(data);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: AppColors.gold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.gold),
          filled: true,
          fillColor: AppColors.charcoal.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.gold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Servicios', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        foregroundColor: AppColors.gold,
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : services.isEmpty
              ? Center(child: Text('No hay servicios registrados', style: TextStyle(color: AppColors.gray, fontSize: 16)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: services.length,
                  itemBuilder: (context, i) {
                    final s = services[i];
                    return Card(
                      color: AppColors.charcoal.withOpacity(0.8),
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(Icons.design_services, color: AppColors.gold),
                        title: Text(s['nombre'] ?? 'Servicio', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(s['descripcion'] ?? '', style: TextStyle(color: AppColors.gray, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('\$${s['precio']} - ${s['duracionMin']} min', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(icon: Icon(Icons.edit, color: AppColors.gold, size: 20), onPressed: () => _showServiceForm(service: s, isEdit: true)),
                              IconButton(icon: Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteService(s['_id'])),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        child: Icon(Icons.add, color: Colors.black, size: 28),
        onPressed: () => _showServiceForm(isEdit: false),
      ),
    );
  }
}
