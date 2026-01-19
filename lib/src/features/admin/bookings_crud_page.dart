import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../api/bookings_api.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../widgets/cancel_booking_dialog.dart';
import 'package:http/http.dart' as http;

class BookingsCrudPage extends StatefulWidget {
  final String token;
  const BookingsCrudPage({super.key, required this.token});

  @override
  State<BookingsCrudPage> createState() => _BookingsCrudPageState();
}

class _BookingsCrudPageState extends State<BookingsCrudPage> with SingleTickerProviderStateMixin {
  List<dynamic> bookings = [];
  List<dynamic> filteredBookings = [];
  List<dynamic> stylists = [];
  List<dynamic> clients = [];
  List<dynamic> categories = [];
  
  bool loading = true;
  String filterStatus = 'all'; // 'all', 'SCHEDULED', 'CONFIRMED', 'COMPLETED', 'NO_SHOW', 'CANCELLED'
  String filterCategory = 'all'; // 'all' o id de categoría
  String selectedStylistId = 'all';
  String selectedClientId = 'all';
  String searchQuery = '';
  
  late TextEditingController searchController;
  late BookingsApi _bookingsApi;

  // Estadísticas
  int totalBookings = 0;
  int scheduledCount = 0;
  int confirmedCount = 0;
  int completedCount = 0;
  int noShowCount = 0;
  int cancelledCount = 0;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _bookingsApi = BookingsApi(ApiClient.instance);
    _fetchInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() { loading = true; });
    await Future.wait([
      _fetchBookings(),
      _fetchStylists(),
      _fetchClients(),
      _fetchCategories(),
    ]);
    setState(() { loading = false; });
  }

  Future<void> _fetchBookings() async {
    try {
      print('🔍 Obteniendo reservas...');
      final res = await ApiClient.instance.get(
        '/api/v1/bookings?limit=100',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      print('📊 Response Status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bookingsList = (data is List) ? data : (data['data'] is List ? data['data'] : []);
        
        print('📦 Total reservas recibidas: ${bookingsList.length}');
        
        setState(() {
          bookings = bookingsList;
          _calculateStats();
          _applyFilter();
        });
      } else {
        print('❌ Error: Status code ${res.statusCode}');
        setState(() { bookings = []; });
      }
    } catch (e) {
      print('⚠️ Exception: $e');
      setState(() { bookings = []; });
    }
  }

  Future<void> _fetchStylists() async {
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/stylists',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          stylists = (data is List) ? data : (data['data'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching stylists: $e');
    }
  }

  Future<void> _fetchClients() async {
    try {
      // Use http.get directly to avoid global error handler for 403
      final baseUrl = ApiClient.instance.baseUrl;
      final url = Uri.parse('$baseUrl/api/v1/users?role=CLIENTE');
      
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clients = (data is List) ? data : (data['data'] ?? []);
        });
        print('✅ Clientes cargados: ${clients.length}');
      } else if (response.statusCode == 403) {
        // GERENTE role doesn't have permission to fetch clients
        // This is expected - we'll use fallback names in UI
        print('⚠️ Sin permisos para cargar lista de clientes (esperado para GERENTE)');
      } else {
        print('❌ Error al cargar clientes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Excepción al cargar clientes: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/categories',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          categories = (data is List) ? data : (data['data'] ?? []);
        });
        print('✅ Categorías cargadas: ${categories.length}');
      }
    } catch (e) {
      print('⚠️ Error al cargar categorías: $e');
    }
  }

  void _calculateStats() {
    totalBookings = bookings.length;
    scheduledCount = bookings.where((b) => b['estado'] == 'SCHEDULED').length;
    confirmedCount = bookings.where((b) => b['estado'] == 'CONFIRMED').length;
    completedCount = bookings.where((b) => b['estado'] == 'COMPLETED').length;
    noShowCount = bookings.where((b) => b['estado'] == 'NO_SHOW').length;
    cancelledCount = bookings.where((b) => b['estado'] == 'CANCELLED').length;
    
    print('📊 Estadísticas: Total=$totalBookings, Scheduled=$scheduledCount, Confirmed=$confirmedCount, Completed=$completedCount, NoShow=$noShowCount, Cancelled=$cancelledCount');
  }

  void _applyFilter() {
    print('🔍 Aplicando filtro: estado=$filterStatus, categoría=$filterCategory, estilista=$selectedStylistId');
    
    List<dynamic> temp = bookings;
    
    // Filtrar por estado
    if (filterStatus != 'all') {
      temp = temp.where((b) => b['estado'] == filterStatus).toList();
    }
    
    // Filtrar por categoría (mediante servicioId)
    if (filterCategory != 'all') {
      // Obtener los IDs de servicios de la categoría seleccionada
      final category = categories.firstWhere(
        (c) => c['_id'] == filterCategory,
        orElse: () => null,
      );
      if (category != null) {
        final serviceIds = (category['services'] as List? ?? []);
        temp = temp.where((b) {
          final servicioId = b['servicioId'];
          return serviceIds.contains(servicioId);
        }).toList();
      }
    }
    
    // Filtrar por estilista
    if (selectedStylistId != 'all') {
      temp = temp.where((b) => b['estilistaId'] == selectedStylistId).toList();
    }
    
    // Filtrar por cliente
    if (selectedClientId != 'all') {
      temp = temp.where((b) => b['clienteId'] == selectedClientId).toList();
    }
    
    // Búsqueda por texto
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      temp = temp.where((b) {
        final id = (b['_id'] ?? '').toString().toLowerCase();
        final notes = (b['notas'] ?? '').toString().toLowerCase();
        return id.contains(query) || notes.contains(query);
      }).toList();
    }
    
    setState(() {
      filteredBookings = temp;
    });
    
    print('✅ Reservas filtradas: ${filteredBookings.length}');
  }

  Future<void> _cancelBooking(String id, String clienteName) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => CancelBookingDialog(
        bookingInfo: clienteName,
        isStylista: false,
      ),
    );

    if (motivo != null && motivo.isNotEmpty) {
      try {
        setState(() { loading = true; });
        final res = await _bookingsApi.cancelBooking(
          id,
          data: {'razon': motivo},
          token: widget.token,
        );
        
        if (res.statusCode == 200) {
          print('✅ Reserva cancelada en servidor: 200');
          
          // HOT RELOAD: Actualizar lista local inmediatamente
          final index = bookings.indexWhere((b) => b['_id'] == id);
          if (index != -1) {
            setState(() {
              bookings[index]['estado'] = 'CANCELLED';
              print('🔄 Lista local actualizada para reserva $id');
              _applyFilter();
              _calculateStats();
              loading = false;
            });
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Reserva cancelada'), backgroundColor: Colors.orange),
          );
          
          // Recargar desde servidor en background para sincronizar
          _fetchBookings().then((_) => print('🔃 Datos sincronizados con servidor'));
        } else {
          throw Exception('Error: ${res.statusCode}');
        }
      } catch (e) {
        print('❌ Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar: $e'), backgroundColor: Colors.red),
        );
        setState(() { loading = false; });
      }
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'SCHEDULED':
        return 'Programada';
      case 'CONFIRMED':
        return 'Confirmada';
      case 'COMPLETED':
        return 'Completada';
      case 'NO_SHOW':
        return '❌ No Asistió';
      case 'CANCELLED':
        return 'Cancelada';
      case 'PENDING_STYLIST_CONFIRMATION':
        return 'Pendiente aprobación';
      default:
        return status ?? 'Desconocido';
    }
  }

  // Métodos helpers para obtener nombres por ID
  String _getClientName(String? clientId) {
    if (clientId == null || clientId.isEmpty) return 'N/A';
    try {
      final client = clients.firstWhere((c) => c['_id'] == clientId);
      return '${client['nombre'] ?? ''} ${client['apellido'] ?? ''}'.trim();
    } catch (e) {
      return clientId;
    }
  }

  String _getStylistName(String? stylistId) {
    if (stylistId == null || stylistId.isEmpty) return 'N/A';
    try {
      final stylist = stylists.firstWhere((s) => s['_id'] == stylistId);
      return '${stylist['nombre'] ?? ''} ${stylist['apellido'] ?? ''}'.trim();
    } catch (e) {
      return stylistId;
    }
  }

  String _getServiceName(String? serviceId) {
    if (serviceId == null || serviceId.isEmpty) return 'N/A';
    try {
      for (var category in categories) {
        if (category['servicios'] != null) {
          for (var service in category['servicios']) {
            if (service['_id'] == serviceId) {
              return service['nombre'] ?? 'N/A';
            }
          }
        }
      }
      return serviceId;
    } catch (e) {
      return serviceId;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'SCHEDULED':
        return Colors.blue;
      case 'CONFIRMED':
        return Colors.lightBlue;
      case 'COMPLETED':
        return Colors.green;
      case 'NO_SHOW':
        return Colors.purple;
      case 'CANCELLED':
        return Colors.red;
      default:
        return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gestión de Reservas',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Column(
            children: [
              // Estadísticas
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip('Total', totalBookings, AppColors.gold),
                      SizedBox(width: 8),
                      _buildStatChip('Programadas', scheduledCount, Colors.blue),
                      SizedBox(width: 8),
                      _buildStatChip('Confirmadas', confirmedCount, Colors.lightBlue),
                      SizedBox(width: 8),
                      _buildStatChip('Completadas', completedCount, Colors.green),
                      SizedBox(width: 8),
                      _buildStatChip('❌ No Asistió', noShowCount, Colors.purple),
                      SizedBox(width: 8),
                      _buildStatChip('Canceladas', cancelledCount, Colors.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtros avanzados
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.charcoal, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtros avanzados en una fila
                Row(
                  children: [
                    // Filtro de estado
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filterStatus,
                            dropdownColor: AppColors.charcoal,
                            style: TextStyle(color: AppColors.gold, fontSize: 13),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'all', child: Text('📋 Todas ($totalBookings)')),
                              DropdownMenuItem(value: 'SCHEDULED', child: Text('📅 Programadas ($scheduledCount)')),
                              DropdownMenuItem(value: 'CONFIRMED', child: Text('✅ Confirmadas ($confirmedCount)')),
                              DropdownMenuItem(value: 'COMPLETED', child: Text('✔️ Completadas ($completedCount)')),
                              DropdownMenuItem(value: 'NO_SHOW', child: Text('❌ No Asistió ($noShowCount)')),
                              DropdownMenuItem(value: 'CANCELLED', child: Text('🚫 Canceladas ($cancelledCount)')),
                            ],
                            onChanged: (value) {
                              setState(() { filterStatus = value ?? 'all'; });
                              _applyFilter();
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Filtro de estilista
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStylistId,
                            dropdownColor: AppColors.charcoal,
                            style: TextStyle(color: AppColors.gold, fontSize: 13),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'all', child: Text('👤 Todos los estilistas')),
                              ...stylists.map((s) => DropdownMenuItem(
                                value: s['_id'],
                                child: Text('${s['nombre']} ${s['apellido']}', overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() { selectedStylistId = value ?? 'all'; });
                              _applyFilter();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de reservas
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                : filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: AppColors.gray),
                            SizedBox(height: 16),
                            Text(
                              'No hay reservas en esta categoría',
                              style: TextStyle(color: AppColors.gray, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchBookings,
                        color: AppColors.gold,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, i) => _buildBookingCard(filteredBookings[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['estado'] ?? '';
    final statusColor = _getStatusColor(status);
    final inicio = _formatDate(booking['inicio']);
    final fin = _formatDate(booking['fin']);
    final precio = (booking['precio'] ?? 0.0).toDouble();
    final notas = booking['notas'] ?? '';
    final bookingId = (booking['_id'] ?? '').toString();
    final shortId = bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId;

    // Obtener nombres de cliente y estilista
    String clienteName = 'Cliente desconocido';
    String stylistName = 'Estilista desconocido';
    
    final clienteId = booking['clienteId'];
    final estilistaId = booking['estilistaId'];
    
    if (clienteId != null) {
      final client = clients.firstWhere(
        (c) => c['_id'] == clienteId,
        orElse: () => {'nombre': 'Cliente', 'apellido': ''},
      );
      clienteName = '${client['nombre']} ${client['apellido']}'.trim();
    }
    
    if (estilistaId != null) {
      final stylist = stylists.firstWhere(
        (s) => s['_id'] == estilistaId,
        orElse: () => {'nombre': 'Estilista', 'apellido': ''},
      );
      stylistName = '${stylist['nombre']} ${stylist['apellido']}'.trim();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black26, Colors.black12],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con ID y estado
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.3), statusColor.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '📋 #$shortId',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Contenido
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cliente y Estilista
                  Row(
                    children: [
                      Expanded(child: _buildInfoRow(Icons.person, 'Cliente', clienteName, AppColors.gold)),
                      SizedBox(width: 12),
                      Expanded(child: _buildInfoRow(Icons.content_cut, 'Estilista', stylistName, Color(0xFFD4AF37))),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Fechas
                  _buildInfoRow(Icons.calendar_today, 'Inicio', inicio, Colors.blue),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.event_available, 'Fin', fin, Colors.blue),
                  SizedBox(height: 12),
                  // Precio
                  _buildInfoRow(Icons.attach_money, 'Precio', '\$${precio.toStringAsFixed(2)}', Colors.green),
                  // Notas (si existen)
                  if (notas.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gray.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note, color: AppColors.gray, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text(notas, style: TextStyle(color: AppColors.gray, fontSize: 13, fontStyle: FontStyle.italic))),
                        ],
                      ),
                    ),
                  ],
                  // Botones de acción
                  if (status != 'CANCELLED') ...[
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.2),
                              side: BorderSide(color: Colors.red, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: Icon(Icons.cancel, color: Colors.red, size: 18),
                            label: Text('Cancelar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _cancelBooking(bookingId, clienteName),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold.withOpacity(0.2),
                              side: BorderSide(color: AppColors.gold, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                            label: Text('Ver Detalles', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _showBookingDetails(booking),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              center: Alignment.center,
              radius: 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.gray, fontSize: 11, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text(value, style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppColors.gold, size: 28),
                    SizedBox(width: 12),
                    Text('Detalles de Reserva', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 20),
                _buildDetailRow('ID Reserva', booking['_id'] ?? 'N/A'),
                Divider(color: AppColors.gray.withOpacity(0.3)),
                _buildDetailRow('Cliente', _getClientName(booking['clienteId'])),
                Divider(color: AppColors.gray.withOpacity(0.3)),
                _buildDetailRow('Estilista', _getStylistName(booking['estilistaId'])),
                Divider(color: AppColors.gray.withOpacity(0.3)),
                _buildDetailRow('Servicio', _getServiceName(booking['servicioId'])),
                Divider(color: AppColors.gray.withOpacity(0.3)),
                _buildDetailRow('Inicio', _formatDate(booking['inicio'])),
                Divider(color: AppColors.gray.withOpacity(0.3)),
                _buildDetailRow('Fin', _formatDate(booking['fin'])),
                Divider(color: AppColors.gray.withOpacity(0.3)),
                _buildDetailRow('Estado', _getStatusLabel(booking['estado'])),
                Divider(color: AppColors.gray.withOpacity(0.3)),
                _buildDetailRow('Precio', '\$${(booking['precio'] ?? 0.0).toStringAsFixed(2)}'),
                Divider(color: AppColors.gray.withOpacity(0.3)),
                _buildDetailRow('Estado Pago', booking['paymentStatus'] == 'PAID' ? 'Pagado' : 'Pendiente'),
                if (booking['paymentMethod'] != null) ...[
                  Divider(color: AppColors.gray.withOpacity(0.3)),
                  _buildDetailRow('Método Pago', booking['paymentMethod']),
                ],
                if (booking['paidAt'] != null) ...[
                  Divider(color: AppColors.gray.withOpacity(0.3)),
                  _buildDetailRow('Fecha Pago', _formatDate(booking['paidAt'])),
                ],
                if (booking['invoiceNumber'] != null) ...[
                  Divider(color: AppColors.gray.withOpacity(0.3)),
                  _buildDetailRow('N° Factura', booking['invoiceNumber']),
                ],
                if (booking['notas'] != null && booking['notas'].toString().isNotEmpty) ...[
                  Divider(color: AppColors.gray.withOpacity(0.3)),
                  _buildDetailRow('Notas', booking['notas']),
                ],
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cerrar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: AppColors.gray, fontSize: 14, fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text(value, style: TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
