import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:peluqueria_lina_app/src/features/dashboard/services_tab.dart';
import 'package:peluqueria_lina_app/src/features/dashboard/my_bookings_tab.dart';
import 'package:peluqueria_lina_app/src/features/dashboard/my_ratings_tab.dart';
import 'package:peluqueria_lina_app/src/api/api_client.dart';
import 'package:peluqueria_lina_app/src/data/services/token_storage.dart';
import 'package:peluqueria_lina_app/src/api/catalog_api.dart';
import 'package:peluqueria_lina_app/src/features/booking/rating_dialog.dart';
import '../../api/services_api.dart';
import '../../api/stylists_api.dart';
import '../../api/bookings_api.dart';
import '../../api/ratings_api.dart';
import '../../core/theme/app_theme.dart';

class ClientDashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ClientDashboardPage({super.key, required this.user});

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
    String selectedCategoryId = '';
  int _currentTab = 0;
  String clientName = '';
  String token = '';
  String userId = '';
  List<dynamic> services = [];
  List<dynamic> stylists = [];
  bool isLoading = true;
  String errorMessage = '';
  List<String> carouselImages = [
    'https://images.unsplash.com/photo-1517841905240-472988babdf9',
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
  ];
  List<dynamic> catalogs = [];

  @override
  void initState() {
    super.initState();
    userId = widget.user['id'] ?? '';
    clientName = widget.user['nombre'] ?? widget.user['name'] ?? '';
    if (clientName.isEmpty) {
      clientName = 'Cliente';
    }
    _initDashboard();
    _fetchCatalogs();
  }

  Future<void> _initDashboard() async {
    // Obtener token de storage
    final storedToken = await TokenStorage.instance.getAccessToken();
    print('Token leído del storage: $storedToken');
    if (storedToken != null) {
      setState(() {
        token = storedToken;
      });
      await _fetchData();
      // Verificar citas completadas sin calificar
      await _checkUnratedCompletedBookings();
    } else {
      setState(() {
        errorMessage = 'No se encontró el token de autenticación.';
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchCatalogs() async {
    final storedToken = await TokenStorage.instance.getAccessToken();
    if (storedToken == null) return;
    try {
      final api = CatalogApi();
      final result = await api.getCatalogs(storedToken);
      setState(() {
        catalogs = result;
      });
    } catch (e) {
      print('Error al cargar catálogos: $e');
    }
  }

  Future<void> _fetchData() async {
    try {
      final servicesRes = await ServicesApi(ApiClient.instance).listServices(token: token);
      print('Respuesta servicios: status=${servicesRes.statusCode}, body=${servicesRes.body}');
      if (servicesRes.statusCode == 200) {
        final servicesData = jsonDecode(servicesRes.body);
        setState(() {
          services = servicesData is List ? servicesData : [];
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar servicios: ${servicesRes.statusCode}';
        });
      }

      // Fetch stylists desde la base de datos
      final stylistsRes = await StylistsApi(ApiClient.instance).listStylists(token: token);
      print('Respuesta estilistas: status=${stylistsRes.statusCode}, body=${stylistsRes.body}');
      if (stylistsRes.statusCode == 200) {
        final stylistsData = jsonDecode(stylistsRes.body);
        // Si la respuesta es { "stylists": [...] }
        if (stylistsData is Map && stylistsData.containsKey('stylists')) {
          setState(() {
            stylists = stylistsData['stylists'] ?? [];
          });
        } else if (stylistsData is List) {
          setState(() {
            stylists = stylistsData;
          });
        } else {
          setState(() {
            stylists = [];
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error al cargar estilistas: ${stylistsRes.statusCode}';
        });
      }
    } catch (e) {
      print('Error en _fetchData: $e');
      setState(() {
        errorMessage = 'Error al obtener datos: $e';
      });
    }
  }

  Future<void> _checkUnratedCompletedBookings() async {
    try {
      print('🟢 [CHECK_RATINGS] Iniciando verificación de citas sin calificar...');
      
      // Obtener citas del cliente
      final bookingsRes = await BookingsApi(ApiClient.instance).getClientBookings(token);
      if (bookingsRes.statusCode != 200) {
        print('❌ [CHECK_RATINGS] Error al obtener citas: ${bookingsRes.statusCode}');
        return;
      }

      final bookingsData = jsonDecode(bookingsRes.body);
      final bookings = bookingsData is List ? bookingsData : (bookingsData['data'] ?? []);
      print('📋 [CHECK_RATINGS] Total de citas: ${bookings.length}');

      // Filtrar citas completadas
      final completedBookings = bookings.where((b) => (b['estado'] ?? '').toUpperCase() == 'COMPLETED').toList();
      print('✅ [CHECK_RATINGS] Citas completadas: ${completedBookings.length}');

      if (completedBookings.isEmpty) {
        print('ℹ️  [CHECK_RATINGS] No hay citas completadas');
        return;
      }

      // Obtener calificaciones del cliente
      final ratingsRes = await RatingsApi(ApiClient.instance).getMyRatings(token);
      if (ratingsRes.statusCode != 200) {
        print('❌ [CHECK_RATINGS] Error al obtener calificaciones: ${ratingsRes.statusCode}');
        return;
      }

      final ratingsData = jsonDecode(ratingsRes.body);
      final ratings = ratingsData is List ? ratingsData : (ratingsData['data'] ?? []);
      print('⭐ [CHECK_RATINGS] Total de calificaciones: ${ratings.length}');

      // Obtener IDs de booking que ya tienen calificación
      final ratedBookingIds = ratings.map((r) => r['bookingId'] is Map ? r['bookingId']['_id'] : r['bookingId']).toSet();
      print('📍 [CHECK_RATINGS] Booking IDs calificados: $ratedBookingIds');

      // Encontrar citas completadas sin calificar
      final unratedBookings = completedBookings.where((b) => !ratedBookingIds.contains(b['_id'])).toList();
      print('🎯 [CHECK_RATINGS] Citas sin calificar: ${unratedBookings.length}');

      if (unratedBookings.isEmpty) {
        print('✔️  [CHECK_RATINGS] Todas las citas completadas han sido calificadas');
        return;
      }

      // Mostrar diálogo para la primera cita sin calificar
      if (mounted && unratedBookings.isNotEmpty) {
        final booking = unratedBookings.first;
        _showRatingPrompt(booking);
      }
    } catch (e, st) {
      print('❌ [CHECK_RATINGS] Error: $e');
      print('   Stack: $st');
    }
  }

  void _showRatingPrompt(dynamic booking) {
    final servicioNombre = booking['servicioNombre'] ?? 'Servicio';
    final estilistaNombre = '${booking['estilistaNombre'] ?? ''} ${booking['estilistaApellido'] ?? ''}';
    final bookingId = booking['_id'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_outline, color: AppColors.gold, size: 48),
              SizedBox(height: 16),
              Text(
                '¿Califica este servicio?',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                servicioNombre,
                style: TextStyle(color: AppColors.gray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              Text(
                'con $estilistaNombre',
                style: TextStyle(color: AppColors.gray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Después'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => RatingDialog(
                          bookingId: bookingId,
                          stylistName: estilistaNombre.trim(),
                          serviceName: servicioNombre,
                          token: token,
                        ),
                      );
                    },
                    child: Text('Calificar ahora'),
                  ),
                ],
              ),
            ],
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
        backgroundColor: AppColors.charcoal,
        title: Text('Peluquería Lina', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(errorMessage, style: TextStyle(color: Colors.red)),
                  ),
                )
              : _buildTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        backgroundColor: AppColors.gold,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.black), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.content_cut, color: Colors.black), label: 'Servicios'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today, color: Colors.black), label: 'Mis Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.star, color: Colors.black), label: 'Calificaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on, color: Colors.black), label: 'Ubicación'),
          BottomNavigationBarItem(icon: Icon(Icons.person, color: Colors.black), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildServicesTab();
      case 2:
        return MyBookingsTab(token: token);
      case 3:
        return MyRatingsTab(token: token);
      case 4:
        return _buildLocationTab();
      case 5:
        return _buildProfileTab();
      default:
        return Container();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hey, $clientName', style: TextStyle(color: AppColors.gold, fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Bienvenido a Peluquería Lina', style: TextStyle(color: AppColors.gray, fontSize: 16)),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '¿Qué estás buscando?',
                hintStyle: TextStyle(color: AppColors.gray),
                filled: true,
                fillColor: AppColors.charcoal.withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: AppColors.gold),
              ),
            ),
          ),
          SizedBox(height: 16),
          CarouselSlider(
            options: CarouselOptions(height: 140.0, autoPlay: true),
            items: carouselImages.map((img) => Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Descuento 50%', style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold)),
                ),
              ),
            )).toList(),
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text('Catálogos', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 12),
          catalogs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text('No hay categorías disponibles.', style: TextStyle(color: AppColors.gray)),
                )
              : SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: catalogs.length,
                    separatorBuilder: (_, __) => SizedBox(width: 16),
                    itemBuilder: (context, i) {
                      final catalog = catalogs[i];
                      final name = catalog['nombre'] ?? 'Catálogo';
                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.gold,
                            child: Icon(Icons.content_cut, color: AppColors.charcoal, size: 28),
                          ),
                          SizedBox(height: 6),
                          Text(name, style: TextStyle(color: AppColors.gold, fontSize: 13)),
                        ],
                      );
                    },
                  ),
                ),
          SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estilistas', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Ver más', style: TextStyle(color: AppColors.gray, fontSize: 14)),
              ],
            ),
          ),
          SizedBox(height: 12),
          stylists.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text('No hay estilistas disponibles.', style: TextStyle(color: AppColors.gray)),
                )
              : SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: stylists.length,
                    separatorBuilder: (_, __) => SizedBox(width: 16),
                    itemBuilder: (context, i) {
                      final stylist = stylists[i];
                      final nombre = stylist['nombre'] ?? '';
                      final apellido = stylist['apellido'] ?? '';
                      final name = (nombre.isNotEmpty || apellido.isNotEmpty)
                          ? '$nombre $apellido'
                          : 'Estilista';
                      final image = stylist['image'];
                      final rating = stylist['rating'] ?? 5.0;
                      return Container(
                        width: 110,
                        decoration: BoxDecoration(
                          color: AppColors.charcoal,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 6),
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: image != null && image.isNotEmpty
                                  ? NetworkImage(image)
                                  : null,
                              child: image == null || image.isEmpty
                                  ? Icon(Icons.person, color: AppColors.gold, size: 18)
                                  : null,
                            ),
                            SizedBox(height: 2),
                            Text(name, style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 11)),
                            SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (star) => Icon(
                                Icons.star,
                                color: star < rating ? AppColors.gold : AppColors.gray,
                                size: 11,
                              )),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return ServicesTab(
      services: services,
      categories: catalogs,
      selectedCategoryId: selectedCategoryId,
      onCategorySelected: (id) => setState(() => selectedCategoryId = id),
      stylists: stylists,
      clienteId: userId,
      token: token,
    );
  }

  Widget _buildLocationTab() {
    return Center(child: Text('Ubicación y Horario', style: TextStyle(color: AppColors.gold)));
  }

  Widget _buildProfileTab() {
    return Center(child: Text('Perfil', style: TextStyle(color: AppColors.gold)));
  }
}
