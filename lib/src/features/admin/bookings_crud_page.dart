import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';

class BookingsCrudPage extends StatefulWidget {
  final String token;
  const BookingsCrudPage({super.key, required this.token});

  @override
  State<BookingsCrudPage> createState() => _BookingsCrudPageState();
}

class _BookingsCrudPageState extends State<BookingsCrudPage> {
  List<dynamic> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/bookings',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          bookings = (data is List) ? data : (data['data'] ?? []);
          loading = false;
        });
      } else {
        setState(() { bookings = []; loading = false; });
      }
    } catch (e) {
      print('Error: $e');
      setState(() { bookings = []; loading = false; });
    }
  }

  Future<void> _createBooking(Map<String, dynamic> booking) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.post(
        '/api/v1/bookings',
        body: jsonEncode(booking),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reserva creada exitosamente'), backgroundColor: Colors.green));
        await _fetchBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear reserva'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _editBooking(String id, Map<String, dynamic> booking) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.put(
        '/api/v1/bookings/$id',
        body: jsonEncode(booking),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reserva actualizada exitosamente'), backgroundColor: Colors.green));
        await _fetchBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar reserva'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  Future<void> _deleteBooking(String id) async {
    setState(() { loading = true; });
    try {
      final res = await ApiClient.instance.delete(
        '/api/v1/bookings/$id',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reserva eliminada exitosamente'), backgroundColor: Colors.green));
        await _fetchBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar reserva'), backgroundColor: Colors.red));
        setState(() { loading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { loading = false; });
    }
  }

  void _showBookingForm({Map<String, dynamic>? booking, required bool isEdit}) {
    final clienteCtrl = TextEditingController(text: booking?['clienteNombre'] ?? '');
    final stylistCtrl = TextEditingController(text: booking?['stylistNombre'] ?? '');
    final fechaCtrl = TextEditingController(text: booking?['fecha'] ?? '');
    final horaCtrl = TextEditingController(text: booking?['hora'] ?? '');
    final servicioCtrl = TextEditingController(text: booking?['servicio'] ?? '');

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
                Text(isEdit ? 'Editar Reserva' : 'Crear Reserva', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextField(
                  controller: clienteCtrl,
                  style: TextStyle(color: AppColors.gold),
                  decoration: InputDecoration(
                    labelText: 'Cliente',
                    labelStyle: TextStyle(color: AppColors.gray),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.gold)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: stylistCtrl,
                  style: TextStyle(color: AppColors.gold),
                  decoration: InputDecoration(
                    labelText: 'Estilista',
                    labelStyle: TextStyle(color: AppColors.gray),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.gold)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: servicioCtrl,
                  style: TextStyle(color: AppColors.gold),
                  decoration: InputDecoration(
                    labelText: 'Servicio',
                    labelStyle: TextStyle(color: AppColors.gray),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.gold)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: fechaCtrl,
                  style: TextStyle(color: AppColors.gold),
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    labelStyle: TextStyle(color: AppColors.gray),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.gold)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: horaCtrl,
                  style: TextStyle(color: AppColors.gold),
                  decoration: InputDecoration(
                    labelText: 'Hora',
                    labelStyle: TextStyle(color: AppColors.gray),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.gold)),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gray),
                      child: Text('Cancelar', style: TextStyle(color: Colors.black)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                      child: Text(isEdit ? 'Guardar' : 'Crear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final data = {
                          'clienteNombre': clienteCtrl.text,
                          'stylistNombre': stylistCtrl.text,
                          'servicio': servicioCtrl.text,
                          'fecha': fechaCtrl.text,
                          'hora': horaCtrl.text,
                        };
                        Navigator.of(ctx).pop();
                        if (isEdit && booking != null) {
                          await _editBooking(booking['_id'], data);
                        } else {
                          await _createBooking(data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text('Gestión de Reservas', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : bookings.isEmpty
              ? Center(child: Text('No hay reservas registradas', style: TextStyle(color: AppColors.gray, fontSize: 16)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, i) {
                    final b = bookings[i];
                    return Card(
                      color: Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reserva #${b['_id']?.substring(0, 8) ?? ''}', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 8),
                            Text('Cliente: ${b['clienteNombre'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            Text('Estilista: ${b['stylistNombre'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            Text('Servicio: ${b['servicio'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            Text('Fecha: ${b['fecha'] ?? 'N/A'} - Hora: ${b['hora'] ?? 'N/A'}', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                                  icon: Icon(Icons.edit, color: Colors.black),
                                  label: Text('Editar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showBookingForm(booking: b, isEdit: true),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  label: Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => _deleteBooking(b['_id']),
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
        onPressed: () => _showBookingForm(isEdit: false),
      ),
    );
  }
}
