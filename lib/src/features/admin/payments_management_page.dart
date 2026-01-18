import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../api/payments_api.dart';
import '../../api/api_client.dart';
import '../../widgets/search_bar_widget.dart';

class PaymentsManagementPage extends StatefulWidget {
  final String token;

  const PaymentsManagementPage({
    super.key,
    required this.token,
  });

  @override
  State<PaymentsManagementPage> createState() => _PaymentsManagementPageState();
}

class _PaymentsManagementPageState extends State<PaymentsManagementPage>
    with SingleTickerProviderStateMixin {
  final PaymentsApi _paymentsApi = PaymentsApi(ApiClient.instance);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Listas de datos
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> filteredPayments = [];
  List<Map<String, dynamic>> clients = [];

  // Filtros
  String filterStatus = 'ALL'; // ALL, PENDING, PAID
  String? selectedClientId;
  String searchQuery = '';

  // Estados
  bool loading = false;

  // Estadísticas
  int totalPayments = 0;
  int pendingCount = 0;
  int paidCount = 0;
  double totalAmount = 0.0;
  double pendingAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          filterStatus = ['ALL', 'PENDING', 'PAID'][_tabController.index];
          _applyFilter();
        });
      }
    });
    _fetchInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => loading = true);
    await Future.wait([
      _fetchPayments(),
      _fetchClients(),
    ]);
    setState(() => loading = false);
  }

  Future<void> _fetchPayments() async {
    try {
      setState(() => loading = true);
      
      final res = await _paymentsApi.getTransferProofs(
        token: widget.token,
        clientId: selectedClientId,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<Map<String, dynamic>> rawPayments = List<Map<String, dynamic>>.from(data['data'] ?? []);
        
        print('✅ ${rawPayments.length} comprobantes cargados');
        print('📦 Estructura de primer pago: ${rawPayments.isNotEmpty ? rawPayments[0].toString() : 'Sin datos'}');
        
        // ← ENRIQUECER PAGOS CON DATOS DE RESERVAS
        print('🔄 Iniciando enriquecimiento de pagos...');
        await _enrichPaymentsWithBookingData(rawPayments);
        print('✅ Enriquecimiento completado');
        
        // Log detallado de amounts después del enriquecimiento
        print('📊 Montos después de enriquecimiento:');
        for (int i = 0; i < rawPayments.length && i < 5; i++) {
          final payment = rawPayments[i];
          print('  [${i}] ${payment['bookingId']}: amount=${payment['amount']} (${payment['clientName']})');
        }
        
        if (mounted) {
          setState(() {
            payments = rawPayments;
            _calculateStats();
            _applyFilter();
            loading = false;
          });
        }
      } else {
        print('❌ Error al cargar pagos: ${res.statusCode}');
        print('📋 Response body: ${res.body}');
        if (mounted) setState(() => loading = false);
      }
    } catch (e) {
      print('❌ Excepción al cargar pagos: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  /// ← NUEVO MÉTODO: Enriquecer pagos con datos de reservas si falta amount
  Future<void> _enrichPaymentsWithBookingData(List<Map<String, dynamic>> payments) async {
    int enrichedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    
    for (var payment in payments) {
      try {
        // Si ya tiene amount y es mayor a 0, no hacer nada
        final currentAmount = payment['amount'];
        if (currentAmount != null && currentAmount is num && currentAmount > 0) {
          print('  ⏭️ [${payment['bookingId']}] Ya tiene amount: $currentAmount');
          skippedCount++;
          continue;
        }
        
        // Obtener datos de la reserva
        final bookingId = payment['bookingId'];
        if (bookingId == null || (bookingId is String && bookingId.isEmpty)) {
          print('  ⚠️ [${payment['bookingId']}] bookingId nulo o vacío');
          errorCount++;
          continue;
        }
        
        print('  🔍 [${bookingId}] Obteniendo datos de reserva...');
        
        try {
          // ← IMPORTANTE: Usar ApiClient con token para hacer la llamada directa
          final bookingRes = await ApiClient.instance.get(
            '/api/v1/bookings/$bookingId',
            token: widget.token,
          );
          
          print('  📊 [${bookingId}] Status: ${bookingRes.statusCode}');
          
          if (bookingRes.statusCode == 200) {
            try {
              final bookingData = jsonDecode(bookingRes.body);
              print('  📦 [${bookingId}] Booking data keys: ${bookingData.keys.join(", ")}');
              
              // Buscar el precio en varios campos posibles
              double? price;
              if (bookingData['precio'] != null) {
                price = (bookingData['precio'] as num).toDouble();
                print('  💰 [${bookingId}] Encontrado en "precio": $price');
              } else if (bookingData['price'] != null) {
                price = (bookingData['price'] as num).toDouble();
                print('  💰 [${bookingId}] Encontrado en "price": $price');
              } else if (bookingData['total'] != null) {
                price = (bookingData['total'] as num).toDouble();
                print('  💰 [${bookingId}] Encontrado en "total": $price');
              } else if (bookingData['monto'] != null) {
                price = (bookingData['monto'] as num).toDouble();
                print('  💰 [${bookingId}] Encontrado en "monto": $price');
              } else if (bookingData['data'] != null && bookingData['data'] is Map) {
                // A veces la respuesta viene en data
                final data = bookingData['data'];
                if (data['precio'] != null) {
                  price = (data['precio'] as num).toDouble();
                  print('  💰 [${bookingId}] Encontrado en "data.precio": $price');
                } else if (data['price'] != null) {
                  price = (data['price'] as num).toDouble();
                  print('  💰 [${bookingId}] Encontrado en "data.price": $price');
                }
              }
              
              if (price != null && price > 0) {
                payment['amount'] = price;
                print('  ✅ [${bookingId}] amount=$price (desde booking)');
                enrichedCount++;
              } else {
                print('  ⚠️ [${bookingId}] No encontró precio en booking. Estructura: ${bookingData.toString().length > 200 ? bookingData.toString().substring(0, 200) + '...' : bookingData.toString()}');
                payment['amount'] = 0.0;
                errorCount++;
              }
            } catch (parseE) {
              print('  ❌ [${bookingId}] Error parseando JSON: $parseE');
              print('  📋 Response body: ${bookingRes.body}');
              payment['amount'] = 0.0;
              errorCount++;
            }
          } else {
            print('  ❌ [${bookingId}] Error HTTP ${bookingRes.statusCode} al obtener booking');
            print('  📋 Response: ${bookingRes.body}');
            payment['amount'] = 0.0;
            errorCount++;
          }
        } catch (e) {
          print('  ❌ [${bookingId}] Excepción al obtener booking: $e');
          payment['amount'] = 0.0;
          errorCount++;
        }
      } catch (e) {
        print('  ❌ Error inesperado en pago: $e');
        errorCount++;
      }
    }
    
    print('📊 Resultados enriquecimiento: $enrichedCount enriquecidos, $skippedCount ya tenían, $errorCount errores');
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
        
        // El response puede ser un Map con 'data' o directamente una lista
        late List<Map<String, dynamic>> clientsList;
        
        if (data is Map<String, dynamic> && data['data'] != null) {
          clientsList = List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else if (data is List) {
          clientsList = List<Map<String, dynamic>>.from(data);
        } else {
          clientsList = [];
        }
        
        setState(() {
          clients = clientsList;
        });
        print('✅ ${clients.length} clientes cargados para filtro');
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

  void _calculateStats() {
    totalPayments = payments.length;
    pendingCount = payments.where((p) => p['paymentStatus'] == 'PENDING').length;
    paidCount = payments.where((p) => p['paymentStatus'] == 'PAID').length;
    
    totalAmount = 0.0;
    pendingAmount = 0.0;
    
    print('📊 Calculando estadísticas para ${payments.length} pagos...');
    
    for (int i = 0; i < payments.length; i++) {
      final payment = payments[i];
      
      // Intentar obtener el amount de varias formas
      double amount = 0.0;
      
      if (payment['amount'] != null) {
        amount = (payment['amount'] as num).toDouble();
        print('  [$i] amount=${amount} (desde payment[amount])');
      } else if (payment['price'] != null) {
        amount = (payment['price'] as num).toDouble();
        print('  [$i] amount=${amount} (desde payment[price])');
      } else if (payment['total'] != null) {
        amount = (payment['total'] as num).toDouble();
        print('  [$i] amount=${amount} (desde payment[total])');
      } else {
        print('  [$i] ⚠️ NO ENCONTRADO amount en: ${payment.keys.join(", ")}');
      }
      
      totalAmount += amount;
      if (payment['paymentStatus'] == 'PENDING') {
        pendingAmount += amount;
      }
    }
    
    print('💰 Total: \$${totalAmount.toStringAsFixed(2)}, Pendiente: \$${pendingAmount.toStringAsFixed(2)}');
  }

  void _applyFilter() {
    var temp = List<Map<String, dynamic>>.from(payments);

    // Filtro por estado (tab)
    if (filterStatus == 'PENDING') {
      temp = temp.where((p) => p['paymentStatus'] == 'PENDING').toList();
    } else if (filterStatus == 'PAID') {
      temp = temp.where((p) => p['paymentStatus'] == 'PAID').toList();
    }

    // Filtro por cliente
    if (selectedClientId != null && selectedClientId!.isNotEmpty) {
      temp = temp.where((p) => p['clientId'] == selectedClientId).toList();
    }

    // Búsqueda por ID de reserva o nombre de cliente
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      temp = temp.where((p) {
        final bookingId = (p['bookingId'] ?? '').toString().toLowerCase();
        final clientName = (p['clientName'] ?? '').toString().toLowerCase();
        return bookingId.contains(query) || clientName.contains(query);
      }).toList();
    }

    // Ordenar por fecha de subida (más reciente primero)
    temp.sort((a, b) {
      final dateA = a['transferProofUploadedAt'] ?? '';
      final dateB = b['transferProofUploadedAt'] ?? '';
      return dateB.compareTo(dateA);
    });

    setState(() {
      filteredPayments = temp;
    });

    print('🔍 Filtrados: ${filteredPayments.length} de ${payments.length}');
  }

  Future<void> _confirmPayment(String bookingId) async {
    // Encontrar el pago para obtener el monto y datos
    final payment = payments.firstWhere(
      (p) => p['bookingId'] == bookingId,
      orElse: () => {},
    );
    
    // Obtener amount de múltiples fuentes posibles
    double amount = 0.0;
    if (payment['amount'] != null) {
      amount = (payment['amount'] as num).toDouble();
    } else if (payment['price'] != null) {
      amount = (payment['price'] as num).toDouble();
    } else if (payment['total'] != null) {
      amount = (payment['total'] as num).toDouble();
    }
    
    final clientName = payment['clientName'] ?? 'N/A';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF5F5F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Confirmar Pago',
              style: TextStyle(color: const Color(0xFF3E3E3E), fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Confirmar este pago?',
              style: TextStyle(
                color: const Color(0xFF6B6B6B),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: const Color(0xFF6B6B6B)),
                      SizedBox(width: 8),
                      Text(
                        'Cliente:',
                        style: TextStyle(color: const Color(0xFF6B6B6B), fontSize: 12),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clientName,
                          style: TextStyle(
                            color: const Color(0xFF3E3E3E),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Monto:',
                        style: TextStyle(color: const Color(0xFF6B6B6B), fontSize: 12),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Esta acción marcará la reserva como PAGADA.',
              style: TextStyle(
                color: const Color(0xFF6B6B6B),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: const Color(0xFF6B6B6B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirmar Pago'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => loading = true);
        final res = await _paymentsApi.confirmTransferPayment(
          bookingId: bookingId,
          token: widget.token,
        );

        if (res.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Pago confirmado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchPayments();
        } else {
          final error = jsonDecode(res.body)['message'] ?? 'Error desconocido';
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => loading = false);
      }
    }
  }

  void _showProofImage(String? imageUrl, String clientName) {
    print('🖼️ [PROOF IMAGE] Iniciando _showProofImage');
    print('🖼️ [PROOF IMAGE] imageUrl: $imageUrl');
    print('🖼️ [PROOF IMAGE] clientName: $clientName');
    print('🖼️ [PROOF IMAGE] imageUrl is null: ${imageUrl == null}');
    print('🖼️ [PROOF IMAGE] imageUrl is empty: ${imageUrl?.isEmpty}');
    
    if (imageUrl == null || imageUrl.isEmpty) {
      print('❌ [PROOF IMAGE] URL es null o vacía - mostrando snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay comprobante disponible')),
      );
      return;
    }

    print('✅ [PROOF IMAGE] URL válida, abriendo diálogo');
    print('🖼️ [PROOF IMAGE] URL completa: $imageUrl');

    showDialog(
      context: context,
      builder: (ctx) {
        print('📱 [PROOF IMAGE] Construyendo diálogo de imagen');
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: AppColors.gold),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Comprobante de $clientName',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.gray),
                        onPressed: () {
                          print('❌ [PROOF IMAGE] Cerrando diálogo');
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
                // Imagen
                Flexible(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          print('✅ [PROOF IMAGE] Imagen cargada exitosamente');
                          return child;
                        }
                        print('⏳ [PROOF IMAGE] Cargando imagen... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? "?"}');
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ [PROOF IMAGE] Error al cargar imagen: $error');
                        print('❌ [PROOF IMAGE] StackTrace: $stackTrace');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 48),
                              SizedBox(height: 16),
                              Text(
                                'Error al cargar imagen',
                                style: TextStyle(color: Colors.red),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'URL: $imageUrl',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Usa dos dedos para hacer zoom',
                    style: TextStyle(color: AppColors.gray, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pendiente';
      case 'PAID':
        return 'Pagado';
      case 'FAILED':
        return 'Fallido';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PAID':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      default:
        return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text(
          'Gestión de Pagos',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.gold),
            onPressed: _fetchInitialData,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Column(
            children: [
              // Estadísticas
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip(
                        'Total',
                        totalPayments.toString(),
                        Icons.receipt_long,
                        AppColors.gold,
                      ),
                      SizedBox(width: 8),
                      _buildStatChip(
                        'Pendientes',
                        pendingCount.toString(),
                        Icons.pending,
                        Colors.orange,
                      ),
                      SizedBox(width: 8),
                      _buildStatChip(
                        'Confirmados',
                        paidCount.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      SizedBox(width: 8),
                      _buildStatChip(
                        'Por Cobrar',
                        '\$${pendingAmount.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.gold,
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.gray,
                tabs: [
                  Tab(text: 'Todos (${payments.length})'),
                  Tab(text: 'Pendientes ($pendingCount)'),
                  Tab(text: 'Pagados ($paidCount)'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border(
                bottom: BorderSide(color: AppColors.gray.withOpacity(0.3)),
              ),
            ),
            child: Column(
              children: [
                // Barra de búsqueda
                SearchBarWidget(
                  controller: _searchController,
                  placeholder: 'Buscar por ID de reserva o cliente...',
                  onSearch: (query) {
                    setState(() {
                      searchQuery = query;
                      _applyFilter();
                    });
                  },
                ),
                SizedBox(height: 12),
                // Filtro por cliente
                Row(
                  children: [
                    Icon(Icons.filter_list, color: AppColors.gold, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedClientId,
                        decoration: InputDecoration(
                          labelText: 'Filtrar por Cliente',
                          labelStyle: TextStyle(color: AppColors.gray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.gray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.gray),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.charcoal,
                        style: TextStyle(color: Colors.white),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todos los clientes', style: TextStyle(color: AppColors.gray)),
                          ),
                          ...clients.map((client) {
                            return DropdownMenuItem<String>(
                              value: client['_id'] as String?,
                              child: Text(
                                '${client['nombre']} ${client['apellido']}',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedClientId = value;
                            _applyFilter();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de pagos
          Expanded(
            child: loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                : filteredPayments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: AppColors.gray),
                            SizedBox(height: 16),
                            Text(
                              'No hay comprobantes',
                              style: TextStyle(color: AppColors.gray, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: _fetchInitialData,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = filteredPayments[index];
                            return _buildPaymentCard(payment, isTablet);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, bool isTablet) {
    final bookingId = payment['bookingId'] ?? '';
    var clientName = payment['clientName'] ?? 'N/A';
    
    // Si clientName es vacío o un ID, intentar obtener del listado de clientes
    if (clientName == 'N/A' || clientName.isEmpty || clientName.length == 24) {
      final clientId = payment['clientId'];
      if (clientId != null) {
        clientName = _getClientName(clientId);
      }
    }
    
    final paymentStatus = payment['paymentStatus'] ?? 'PENDING';
    final transferProofUrl = payment['transferProofUrl'];
    final uploadedAt = _formatDate(payment['transferProofUploadedAt']);
    
    print('💳 [PAYMENT CARD] Construyendo tarjeta de pago');
    print('💳 [PAYMENT CARD] bookingId: $bookingId');
    print('💳 [PAYMENT CARD] clientName: $clientName');
    print('💳 [PAYMENT CARD] paymentStatus: $paymentStatus');
    print('💳 [PAYMENT CARD] transferProofUrl: $transferProofUrl');
    print('💳 [PAYMENT CARD] uploadedAt: $uploadedAt');
    print('💳 [PAYMENT CARD] Datos completos del payment: $payment');
    
    // Obtener amount de múltiples fuentes posibles
    double amount = 0.0;
    if (payment['amount'] != null) {
      amount = (payment['amount'] as num).toDouble();
    } else if (payment['price'] != null) {
      amount = (payment['price'] as num).toDouble();
    } else if (payment['total'] != null) {
      amount = (payment['total'] as num).toDouble();
    }
    
    print('💳 [PAYMENT CARD] amount: $amount');

    final statusColor = _getStatusColor(paymentStatus);
    final statusLabel = _getStatusLabel(paymentStatus);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.05),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con badges
              Row(
                children: [
                  // Badge de ID
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tag, color: AppColors.gold, size: 14),
                        SizedBox(width: 4),
                        Text(
                          bookingId.substring(bookingId.length > 8 ? bookingId.length - 8 : 0),
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  // Badge de estado
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  // Monto
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: amount > 0 ? AppColors.gold : Colors.orange,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (amount == 0.0)
                        Text(
                          '(cargando monto...)',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Información del cliente
              _buildInfoRow(
                Icons.person,
                'Cliente',
                clientName,
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                Icons.calendar_today,
                'Fecha de subida',
                uploadedAt,
              ),
              SizedBox(height: 16),
              // Botones de acción
              Row(
                children: [
                  // Botón ver comprobante
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.image, size: 18),
                      label: Text('Ver Comprobante'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: BorderSide(color: AppColors.gold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: transferProofUrl != null
                          ? () => _showProofImage(transferProofUrl, clientName)
                          : null,
                    ),
                  ),
                  if (paymentStatus == 'PENDING') ...[
                    SizedBox(width: 12),
                    // Botón confirmar pago
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.check_circle, size: 18),
                        label: Text(amount > 0 ? 'Confirmar' : 'Monto Pendiente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: amount > 0 ? Colors.green : Colors.orange.withOpacity(0.7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: amount > 0 ? () => _confirmPayment(bookingId) : null,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gray, size: 18),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppColors.gray,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Métodos helpers para obtener nombres por ID
  String _getClientName(String? clientId) {
    if (clientId == null || clientId.isEmpty) return 'N/A';
    try {
      final client = clients.firstWhere(
        (c) => c['_id'] == clientId,
        orElse: () => {},
      );
      if (client.isEmpty) return clientId;
      return '${client['nombre'] ?? ''} ${client['apellido'] ?? ''}'.trim();
    } catch (e) {
      return clientId;
    }
  }
}