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
        
        // ✅ DIAGNÓSTICO: Verificar qué campos tienen los pagos ANTES de enriquecer
        print('🔍 DIAGNÓSTICO PRE-ENRIQUECIMIENTO:');
        for (int i = 0; i < (rawPayments.length > 3 ? 3 : rawPayments.length); i++) {
          final payment = rawPayments[i];
          print('  Pago[$i]:');
          print('    - Tiene "amount": ${payment.containsKey("amount")} = ${payment["amount"]}');
          print('    - Tiene "price": ${payment.containsKey("price")} = ${payment["price"]}');
          print('    - Tiene "total": ${payment.containsKey("total")} = ${payment["total"]}');
          print('    - Tiene "bookingId": ${payment.containsKey("bookingId")} = ${payment["bookingId"]}');
          print('    - Tiene "serviceName": ${payment.containsKey("serviceName")} = ${payment["serviceName"]}');
          print('    - Tiene "servicePrice": ${payment.containsKey("servicePrice")} = ${payment["servicePrice"]}');
          print('    - Todas las claves: ${payment.keys.toList()}');
        }
        
        // ← ENRIQUECER PAGOS CON DATOS DE RESERVAS
        print('🔄 Iniciando enriquecimiento de pagos...');
        await _enrichPaymentsWithBookingData(rawPayments);
        print('✅ Enriquecimiento completado');
        
        // ✅ DIAGNÓSTICO POST-ENRIQUECIMIENTO
        print('🔍 DIAGNÓSTICO POST-ENRIQUECIMIENTO:');
        int amountGreaterThanZero = 0;
        int amountIsZero = 0;
        for (int i = 0; i < rawPayments.length; i++) {
          final amount = rawPayments[i]['amount'] ?? 0.0;
          if ((amount as num) > 0) {
            amountGreaterThanZero++;
            print('  ✅ Pago[$i] ${rawPayments[i]["bookingId"]} tiene monto: $amount');
          } else {
            amountIsZero++;
            print('  ⚠️ Pago[$i] ${rawPayments[i]["bookingId"]} SIGUE SIN MONTO (${rawPayments[i]["clientName"]})');
          }
        }
        print('📊 RESUMEN: $amountGreaterThanZero con monto, $amountIsZero sin monto');
        
        // 🆕 SEGUNDO PASE: Para pagos que siguen con amount=0, intentar GET directo del booking
        for (int i = 0; i < rawPayments.length; i++) {
          final payment = rawPayments[i];
          final currentAmount = payment['amount'] ?? 0.0;
          
          if ((currentAmount as num) == 0) {
            final bookingId = payment['bookingId'];
            if (bookingId != null && (bookingId as String).isNotEmpty) {
              final amount = await _getBookingAmount(bookingId);
              if (amount > 0) {
                payment['amount'] = amount;
                amountIsZero--;
                amountGreaterThanZero++;
              }
            }
          }
        }
        print('📊 RESUMEN FINAL: $amountGreaterThanZero con monto, $amountIsZero sin monto');
        
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
  /// ⚠️ CRÍTICO: El endpoint DEBE retornar amount, esto es fallback
  Future<void> _enrichPaymentsWithBookingData(List<Map<String, dynamic>> payments) async {
    int enrichedCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    
    print('🔄 INICIANDO ENRIQUECIMIENTO DE PAGOS');
    print('📊 Total de pagos a procesar: ${payments.length}');
    
    // Procesar TODOS los pagos, no solo los primeros 10
    for (int idx = 0; idx < payments.length; idx++) {
      final payment = payments[idx];
      final bookingId = payment['bookingId'];
      
      try {
        // ✅ PASO 1: Verificar si YA tiene amount válido
        final currentAmount = payment['amount'];
        print('📋 [${idx + 1}/${payments.length}] bookingId=$bookingId, amount actual=$currentAmount');
        
        if (currentAmount != null && currentAmount is num && currentAmount > 0) {
          skippedCount++;
          print('   ✅ SKIP - Ya tiene amount válido: $currentAmount');
          continue;
        }
        
        // ✅ PASO 2: Validar que bookingId existe y es válido
        if (bookingId == null || (bookingId is String && bookingId.isEmpty)) {
          failedCount++;
          print('   ❌ FAIL - bookingId inválido');
          payment['amount'] = 0.0;
          continue;
        }
        
        // ✅ PASO 3: Obtener detalles del booking SINCRONAMENTE
        print('   🔍 Buscando booking...');
        final bookingRes = await ApiClient.instance.get(
          '/api/v1/bookings/$bookingId',
          headers: {'Authorization': 'Bearer ${widget.token}'},
        ).timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print('   ⏱️ TIMEOUT al obtener booking');
            throw Exception('Timeout obteniendo booking');
          },
        );
        
        // ✅ PASO 4: Parsear respuesta del booking
        if (bookingRes.statusCode == 200) {
          try {
            final bookingData = jsonDecode(bookingRes.body);
            print('   📦 Booking encontrado: ${bookingData.toString().substring(0, 100)}...');
            
            // ✅ PASO 5: Extraer precio de múltiples campos posibles
            double? price;
            
            // Intento 1: precio (el más común en nuestro sistema)
            if (bookingData['precio'] != null) {
              price = (bookingData['precio'] as num).toDouble();
              print('   💰 Precio encontrado en campo "precio": $price');
            } 
            // Intento 2: price (alternativa en inglés)
            else if (bookingData['price'] != null) {
              price = (bookingData['price'] as num).toDouble();
              print('   💰 Precio encontrado en campo "price": $price');
            } 
            // Intento 3: total (si se suma)
            else if (bookingData['total'] != null) {
              price = (bookingData['total'] as num).toDouble();
              print('   💰 Precio encontrado en campo "total": $price');
            }
            // Intento 4: Buscar en objeto service
            else if (bookingData['service'] != null && bookingData['service']['precio'] != null) {
              price = (bookingData['service']['precio'] as num).toDouble();
              print('   💰 Precio encontrado en service.precio: $price');
            }
            // Intento 5: Si aún no hay precio, buscar por nombre del servicio
            else if (price == null && payment.containsKey('serviceName') && payment['serviceName'] != null) {
              print('   🔎 Buscando servicio por nombre: "${payment["serviceName"]}"');
              try {
                final serviceRes = await ApiClient.instance.get(
                  '/api/v1/services?search=${Uri.encodeComponent(payment["serviceName"])}',
                  headers: {'Authorization': 'Bearer ${widget.token}'},
                ).timeout(Duration(seconds: 3));
                
                if (serviceRes.statusCode == 200) {
                  final serviceData = jsonDecode(serviceRes.body);
                  final services = serviceData['data'] ?? serviceData;
                  
                  if (services is List && services.isNotEmpty) {
                    final matchingService = services.firstWhere(
                      (s) => (s['nombre'] ?? '').toString().toLowerCase() == payment["serviceName"].toString().toLowerCase(),
                      orElse: () => services[0], // Fallback al primero si no hay match exacto
                    );
                    
                    if (matchingService['precio'] != null) {
                      price = (matchingService['precio'] as num).toDouble();
                      print('   💰 Precio encontrado en catálogo de servicios: $price');
                    }
                  }
                }
              } catch (e) {
                print('   ⚠️ Error buscando en catálogo: $e');
              }
            }
            
            // ✅ PASO 6: Validar que el precio es válido
            if (price != null && price > 0) {
              payment['amount'] = price;
              enrichedCount++;
              print('   ✅ ENRIQUECIDO - Amount actualizado a: $price');
            } else {
              failedCount++;
              payment['amount'] = 0.0;
              print('   ⚠️  FALLO - Precio no encontrado o es 0 en booking');
            }
          } catch (parseError) {
            failedCount++;
            payment['amount'] = 0.0;
            print('   ❌ ERROR PARSE - ${parseError.toString()}');
          }
        } else {
          failedCount++;
          payment['amount'] = 0.0;
          print('   ❌ FALLO HTTP - Status: ${bookingRes.statusCode}');
          print('      Body: ${bookingRes.body.substring(0, 100)}');
        }
      } catch (e) {
        failedCount++;
        payment['amount'] = 0.0;
        print('   ❌ EXCEPCIÓN - ${e.toString()}');
      }
    }
    
    print('✅ ENRIQUECIMIENTO COMPLETADO');
    print('📊 RESULTADOS: Enriquecidos=$enrichedCount, YaTenían=$skippedCount, Fallidos=$failedCount');
    final paymentsWithAmount = payments.where((p) {
      final amount = p['amount'];
      return amount is num && amount > 0;
    }).length;
    print('📊 TOTAL DE PAGOS CON MONTO: $paymentsWithAmount');
  }

  /// 🆕 FUNCIÓN: Obtener precio del booking obteniendo el servicio
  Future<double> _getBookingAmount(String bookingId) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/v1/bookings/$bookingId',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(Duration(seconds: 5));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        if (data['precio'] != null && (data['precio'] as num) > 0) {
          return (data['precio'] as num).toDouble();
        }
        if (data['price'] != null && (data['price'] as num) > 0) {
          return (data['price'] as num).toDouble();
        }
        if (data['total'] != null && (data['total'] as num) > 0) {
          return (data['total'] as num).toDouble();
        }
        if (data['servicePrice'] != null && (data['servicePrice'] as num) > 0) {
          return (data['servicePrice'] as num).toDouble();
        }
        
        // Obtener precio del servicio
        if (data['servicioId'] != null && (data['servicioId'] as String).isNotEmpty) {
          try {
            final serviceRes = await ApiClient.instance.get(
              '/api/v1/services/${data["servicioId"]}',
              headers: {'Authorization': 'Bearer ${widget.token}'},
            ).timeout(Duration(seconds: 5));
            
            if (serviceRes.statusCode == 200) {
              final serviceData = jsonDecode(serviceRes.body);
              
              if (serviceData['precio'] != null && (serviceData['precio'] as num) > 0) {
                return (serviceData['precio'] as num).toDouble();
              }
              if (serviceData['price'] != null && (serviceData['price'] as num) > 0) {
                return (serviceData['price'] as num).toDouble();
              }
              if (serviceData['costo'] != null && (serviceData['costo'] as num) > 0) {
                return (serviceData['costo'] as num).toDouble();
              }
            }
          } catch (e) {
            print('⚠️ Error obteniendo servicio: $e');
          }
        }
      }
      
      return 0.0;
    } catch (e) {
      print('❌ Error en _getBookingAmount: $e');
      return 0.0;
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
    // ✅ VALIDACIÓN CRÍTICA: Admin debe revisar comprobante ANTES de confirmar
    // Según pagoyfactura.md:
    // 1. Verificar imagen: transferProofUrl (debe ser legible)
    // 2. Verificar monto: amount debe coincidir con lo transferido
    // 3. Verificar referencia: transactionRef debe estar en el comprobante
    // 4. Verificar fecha: debe ser reciente (hoy/ayer máximo)
    // 5. Verificar banco: debe ser Banco Pichincha
    
    // Encontrar el pago para obtener el monto y datos
    final payment = payments.firstWhere(
      (p) => p['bookingId'] == bookingId,
      orElse: () => {},
    );
    
    // ✅ INTEGRACIÓN PRECIO: Obtener amount de múltiples fuentes
    // El flujo es: Booking.precio → Payment.amount → Factura.total
    // Estos DEBEN ser iguales después de que el estilista completa
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
            // Título de confirmación
            Text(
              '¿Confirmar este pago?',
              style: TextStyle(
                color: const Color(0xFF6B6B6B),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 12),
            
            // ✅ CHECKLIST DE VALIDACIÓN (Según pagoyfactura.md)
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Validación antes de confirmar:',
                    style: TextStyle(
                      color: const Color(0xFF6B6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildChecklistItem('Imagen legible del comprobante'),
                  _buildChecklistItem('Monto coincide: \$${amount.toStringAsFixed(2)}'),
                  _buildChecklistItem('Referencia (RES-...) visible'),
                  _buildChecklistItem('Banco: Pichincha'),
                  _buildChecklistItem('Fecha reciente (hoy/ayer)'),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Datos del pago
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
        print('🔄 Confirmando pago para booking: $bookingId');
        
        final res = await _paymentsApi.confirmTransferPayment(
          bookingId: bookingId,
          token: widget.token,
        );

        print('✅ Response status: ${res.statusCode}');
        print('📦 Response body: ${res.body}');

        if (res.statusCode == 200) {
          if (!mounted) return;
          
          final responseData = jsonDecode(res.body);
          final invoiceNumber = responseData['invoiceNumber'] ?? 'N/A';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Pago confirmado\nFactura: $invoiceNumber'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          print('⏳ Recargando pagos...');
          await _fetchPayments();
          print('✅ Pagos recargados');
        } else {
          if (!mounted) return;
          
          try {
            final errorData = jsonDecode(res.body);
            final errorMsg = errorData['message'] ?? errorData['error'] ?? 'Error desconocido';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: $errorMsg'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error ${res.statusCode}: ${res.body}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Exception: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => loading = false);
          print('✅ Loading terminó');
        }
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
    // ✅ IMPORTANTE: El backend SIEMPRE debería tener amount > 0
    // Si no lo tiene, ya fue enriquecido en _enrichPaymentsWithBookingData()
    double amount = 0.0;
    String amountSource = 'DESCONOCIDA';
    
    if (payment['amount'] != null && (payment['amount'] as num) > 0) {
      amount = (payment['amount'] as num).toDouble();
      amountSource = 'payment.amount';
    } else if (payment['price'] != null) {
      amount = (payment['price'] as num).toDouble();
      amountSource = 'payment.price';
    } else if (payment['total'] != null) {
      amount = (payment['total'] as num).toDouble();
      amountSource = 'payment.total';
    }
    
    print('💳 [PAYMENT CARD] amount: $amount (origen: $amountSource)');

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
                  // Monto - REFERENCIA CLARA DE CUÁNTO DEBE PAGAR
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount > 0 
                          ? '\$${amount.toStringAsFixed(2)}'
                          : '⚠️ SIN MONTO',
                        style: TextStyle(
                          color: amount > 0 ? AppColors.gold : Colors.red,
                          fontSize: amount > 0 ? 20 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Subtítulo descriptivo según estado
                      if (amount > 0)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            paymentStatus == 'PAID' 
                              ? '✅ Pagado'
                              : paymentStatus == 'PENDING' 
                                ? '⏳ A PAGAR'
                                : paymentStatus.toUpperCase(),
                            style: TextStyle(
                              color: paymentStatus == 'PAID' 
                                ? Colors.green.shade300
                                : paymentStatus == 'PENDING'
                                  ? Colors.orange.shade300
                                  : Colors.grey.shade400,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Error: revisar',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
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
                        label: Text(amount > 0 ? 'Confirmar' : '✅ Confirmar Sin Monto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: amount > 0 ? Colors.green : Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        // Permitir confirmar incluso sin monto - el backend validará
                        onPressed: () => _confirmPayment(bookingId),
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

  /// ✅ MÉTODO AUXILIAR: Construcción de item de checklist de validación
  Widget _buildChecklistItem(String item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: Colors.blue.shade600),
          SizedBox(width: 8),
          Text(
            item,
            style: TextStyle(
              color: const Color(0xFF6B6B6B),
              fontSize: 11,
            ),
          ),
        ],
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

  /// 🎯 OBTENER PRECIO: Busca el monto a pagar desde booking (EN TIEMPO REAL)
  /// ✅ Intenta 4 fuentes:
  /// 1. booking.precio (actualizado por estilista)
  /// 2. booking.price (alternativa en inglés)
  /// 3. booking.total (si se suma)
  /// 4. booking.service.precio (fallback de servicio)
  /// ⚠️ NUNCA usa payment.amount (está guardado como 0.0 en el backend)
  Future<double> _getRealAmountFromBooking(String bookingId) async {
    try {
      if (bookingId.isEmpty) {
        print('❌ getRealAmount: bookingId vacío');
        return 0.0;
      }
      
      print('🔍 getRealAmount: Obteniendo precio para booking=$bookingId');
      
      final res = await ApiClient.instance.get(
        '/api/v1/bookings/$bookingId',
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(
        Duration(seconds: 3),
        onTimeout: () {
          print('⏱️ getRealAmount: TIMEOUT');
          throw Exception('Timeout');
        },
      );
      
      if (res.statusCode == 200) {
        final bookingData = jsonDecode(res.body);
        
        // Intento 1: precio (más común)
        if (bookingData['precio'] != null) {
          final price = (bookingData['precio'] as num).toDouble();
          print('✅ getRealAmount: Encontrado en precio=$price');
          return price;
        }
        
        // Intento 2: price
        if (bookingData['price'] != null) {
          final price = (bookingData['price'] as num).toDouble();
          print('✅ getRealAmount: Encontrado en price=$price');
          return price;
        }
        
        // Intento 3: total
        if (bookingData['total'] != null) {
          final price = (bookingData['total'] as num).toDouble();
          print('✅ getRealAmount: Encontrado en total=$price');
          return price;
        }
        
        // Intento 4: service.precio
        if (bookingData['service'] != null && bookingData['service']['precio'] != null) {
          final price = (bookingData['service']['precio'] as num).toDouble();
          print('✅ getRealAmount: Encontrado en service.precio=$price');
          return price;
        }
        
        print('⚠️ getRealAmount: No se encontró precio en booking');
        return 0.0;
      } else {
        print('❌ getRealAmount: HTTP ${res.statusCode}');
        return 0.0;
      }
    } catch (e) {
      print('❌ getRealAmount: Error - $e');
      return 0.0;
    }
  }
}