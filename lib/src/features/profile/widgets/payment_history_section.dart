import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../api/payments_api.dart';
import '../../../api/services_api.dart';
import '../../../api/stylists_api.dart';
import '../../../api/api_client.dart';
import 'dart:convert';

class PaymentHistorySection extends StatefulWidget {
  final String token;

  const PaymentHistorySection({
    super.key,
    required this.token,
  });

  @override
  State<PaymentHistorySection> createState() => _PaymentHistorySectionState();
}

class _PaymentHistorySectionState extends State<PaymentHistorySection> {
  List<dynamic> _bookings = [];
  List<dynamic> _allBookings = []; // Todos sin filtrar
  bool _loading = true;
  String _errorMessage = '';
  double _totalPaid = 0.0;
  int _currentPage = 1;
  int _totalPages = 1;
  String _filterStatus = 'ALL'; // ALL, PAID, UNPAID

  // Catálogos
  final Map<String, String> _servicesMap = {}; // serviceId -> nombre
  final Map<String, String> _stylistsMap = {}; // stylistId -> nombre

  late PaymentsApi _paymentsApi;
  late ServicesApi _servicesApi;
  late StylistsApi _stylistsApi;

  @override
  void initState() {
    super.initState();
    _paymentsApi = PaymentsApi(ApiClient.instance);
    _servicesApi = ServicesApi(ApiClient.instance);
    _stylistsApi = StylistsApi(ApiClient.instance);
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      // Cargar servicios
      final servicesResponse = await _servicesApi.listServices(token: widget.token);
      if (servicesResponse.statusCode == 200) {
        final servicesData = jsonDecode(servicesResponse.body);
        final services = servicesData is List ? servicesData : (servicesData['data'] ?? []);
        for (var service in services) {
          _servicesMap[service['_id']] = service['nombre'] ?? service['name'] ?? 'Sin nombre';
        }
      }

      // Cargar estilistas
      final stylistsResponse = await _stylistsApi.listStylists(token: widget.token);
      if (stylistsResponse.statusCode == 200) {
        final stylistsData = jsonDecode(stylistsResponse.body);
        final stylists = stylistsData is List ? stylistsData : (stylistsData['data'] ?? []);
        for (var stylist in stylists) {
          final firstName = stylist['firstName'] ?? '';
          final lastName = stylist['lastName'] ?? '';
          _stylistsMap[stylist['_id']] = '$firstName $lastName'.trim();
        }
      }

      _fetchBookings();
    } catch (e) {
      print('Error loading catalogs: $e');
      _fetchBookings();
    }
  }

  Future<void> _fetchBookings() async {
    try {
      setState(() => _loading = true);
      final response = await _paymentsApi.getMyBookings(widget.token, page: _currentPage, limit: 20);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final bookings = responseData['data'] ?? [];
        final meta = responseData['meta'] ?? {};
        
        setState(() {
          _allBookings = bookings;
        });
        
        // Aplicar filtro y calcular total
        _applyFilter();
        
        // Calcular páginas totales
        final totalItems = meta['total'] ?? bookings.length;
        final limit = meta['limit'] ?? 20;
        final totalPages = (totalItems / limit).ceil();
        
        setState(() {
          _totalPages = totalPages > 0 ? totalPages : 1;
          _errorMessage = '';
        });
      } else {
        setState(() => _errorMessage = 'No se pudo cargar el historial');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    List<dynamic> filtered = _allBookings;
    
    if (_filterStatus == 'PAID') {
      filtered = _allBookings.where((b) => b['paymentStatus'] == 'PAID').toList();
    } else if (_filterStatus == 'UNPAID') {
      filtered = _allBookings.where((b) => b['paymentStatus'] != 'PAID').toList();
    }
    
    // Calcular total solo de PAGADOS (independiente del filtro)
    double total = 0;
    for (var booking in _allBookings) {
      if (booking['paymentStatus'] == 'PAID') {
        final precio = booking['precio'];
        if (precio != null) {
          total += precio is int ? precio.toDouble() : (precio as double);
        }
      }
    }
    
    setState(() {
      _bookings = filtered;
      _totalPaid = total;
    });
  }

  void _changeFilter(String newFilter) {
    setState(() {
      _filterStatus = newFilter;
    });
    _applyFilter();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? startStr, String? endStr) {
    if (startStr == null || startStr.isEmpty) return '-';
    try {
      final start = DateTime.parse(startStr);
      final startTime = DateFormat('HH:mm').format(start);
      
      if (endStr != null && endStr.isNotEmpty) {
        final end = DateTime.parse(endStr);
        final endTime = DateFormat('HH:mm').format(end);
        return '$startTime - $endTime';
      }
      
      return startTime;
    } catch (e) {
      return startStr;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'UNPAID':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      case 'REFUNDED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return '✅ PAGADO';
      case 'UNPAID':
        return 'NO PAGADO';
      case 'PENDING':
        return 'PENDIENTE';
      case 'REFUNDED':
        return 'REEMBOLSADO';
      default:
        return status ?? 'DESCONOCIDO';
    }
  }

  String _getPaymentMethodLabel(String? method) {
    if (method == null) return 'No especificado';
    
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'Efectivo';
      case 'CARD':
        return 'Tarjeta';
      case 'TRANSFER':
        return 'Transferencia Bancaria';
      case 'TRANSFER_PICHINCHA':
        return 'Transferencia Pichincha';
      case 'TRANSFER_GUAYAQUIL':
        return 'Transferencia Banco Guayaquil';
      case 'TRANSFER_PACIFICO':
        return 'Transferencia Banco Pacífico';
      case 'PAYPAL':
        return 'PayPal';
      default:
        // Reemplazar guiones bajos por espacios y capitalizar
        return method.replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '\$0';
    final value = amount is int ? amount.toDouble() : (amount as double);
    return '\$${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay reservas registradas',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen total
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withOpacity(0.2),
                AppColors.gold.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pagado',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(_totalPaid),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.gold,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Filtros
        Row(
          children: [
            _buildFilterChip('Todos', 'ALL'),
            const SizedBox(width: 8),
            _buildFilterChip('Pagados', 'PAID'),
            const SizedBox(width: 8),
            _buildFilterChip('No Pagados', 'UNPAID'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Lista de reservas con pagos
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final booking = _bookings[index];
            
            // IDs
            final servicioId = booking['servicioId'] ?? '';
            final estilistaId = booking['estilistaId'] ?? '';
            
            // Obtener nombres de los catálogos cargados
            final servicioNombre = _servicesMap[servicioId] ?? 
                                   (booking['servicio'] is Map ? booking['servicio']['nombre'] : null) ??
                                   'Servicio desconocido';
            
            final estilistaName = _stylistsMap[estilistaId] ??
                                  (booking['estilista'] is Map 
                                    ? '${booking['estilista']['firstName'] ?? ''} ${booking['estilista']['lastName'] ?? ''}'.trim()
                                    : null) ??
                                  'Estilista desconocido';
            
            // Información de pago y fechas
            final amount = booking['precio'];
            final status = booking['paymentStatus'];
            final method = booking['paymentMethod'];
            final paidAt = booking['paidAt'];
            final invoiceNumber = booking['invoiceNumber'];
            final date = _formatDate(booking['inicio']);
            final time = _formatTime(booking['inicio'], booking['fin']);

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status == 'PAID' 
                    ? AppColors.gold.withOpacity(0.3) 
                    : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado: servicio y estado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            servicioNombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(status).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            _getStatusLabel(status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Estilista
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          estilistaName,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Fecha
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Hora
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          size: 16,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey[800]),
                    const SizedBox(height: 12),
                    
                    // Información de pago
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (method != null) ...[
                              Text(
                                'Método',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getPaymentMethodLabel(method),
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (invoiceNumber != null) ...[
                              Text(
                                'Factura',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                invoiceNumber,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Monto',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrency(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                fontSize: 20,
                              ),
                            ),
                            if (paidAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Pagado: ${_formatDate(paidAt)}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Paginación
        if (_totalPages > 1) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _currentPage > 1 
                  ? () {
                      setState(() => _currentPage--);
                      _fetchBookings();
                    }
                  : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _currentPage > 1 
                      ? AppColors.gold 
                      : Colors.grey[700]!,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_back,
                  color: _currentPage > 1 
                    ? AppColors.gold 
                    : Colors.grey[700],
                  size: 16,
                ),
                label: Text(
                  'Anterior',
                  style: TextStyle(
                    color: _currentPage > 1 
                      ? AppColors.gold 
                      : Colors.grey[700],
                  ),
                ),
              ),
              Text(
                'Página $_currentPage de $_totalPages',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _currentPage < _totalPages 
                  ? () {
                      setState(() => _currentPage++);
                      _fetchBookings();
                    }
                  : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _currentPage < _totalPages 
                      ? AppColors.gold 
                      : Colors.grey[700]!,
                  ),
                ),
                label: Text(
                  'Siguiente',
                  style: TextStyle(
                    color: _currentPage < _totalPages 
                      ? AppColors.gold 
                      : Colors.grey[700],
                  ),
                ),
                icon: Icon(
                  Icons.arrow_forward,
                  color: _currentPage < _totalPages 
                    ? AppColors.gold 
                    : Colors.grey[700],
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.grey[700]!,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey[300],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
