import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:peluqueria_lina_app/src/features/booking/services_booking_page.dart';
import 'package:peluqueria_lina_app/src/features/dashboard/my_bookings_tab.dart';
import 'package:peluqueria_lina_app/src/api/api_client.dart';
import 'package:peluqueria_lina_app/src/data/services/token_storage.dart';
import 'package:peluqueria_lina_app/src/api/catalog_api.dart';
import '../../api/services_api.dart';
import '../../api/stylists_api.dart';

import '../../core/theme/app_theme.dart';
import '../profile/pages/profile_page.dart';
import '../profile/widgets/location_card.dart';

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
    'assets/images/carousel/salon con gente.jpeg',
    'assets/images/carousel/chica rubia.jpeg',
    'assets/images/carousel/mechas.jpeg',
    'assets/images/carousel/cenizo mechas.jpeg',
    'assets/images/carousel/cenizo.jpeg',
    'assets/images/carousel/salon.jpeg',
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



  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        title: Text(
          'Peluquería Lina',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                _showSearchDialog();
              },
              child: Icon(
                Icons.search,
                color: AppColors.gold,
                size: isMobile ? 24 : 28,
              ),
            ),
          ),
        ],
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
        return _buildLocationTab();
      case 4:
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
          // Header con gradiente y mejor diseño
          Container(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.charcoal,
                  AppColors.charcoal.withOpacity(0.9),
                  Colors.black87,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, $clientName!',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Bienvenido a tu salón de belleza',
                            style: TextStyle(
                              color: AppColors.gray.withOpacity(0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge decorativo
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gold, AppColors.gold.withOpacity(0.7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.face_retouching_natural,
                        color: AppColors.charcoal,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Carrusel mejorado con efecto parallax
          SizedBox(
            height: 200,
            child: CarouselSlider(
              options: CarouselOptions(
                height: 200,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 5),
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                autoPlayCurve: Curves.fastOutSlowIn,
              ),
              items: carouselImages.asMap().entries.map((entry) {
                int index = entry.key;
                String img = entry.value;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Imagen
                        Positioned.fill(
                          child: Image.asset(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.gold.withOpacity(0.3),
                                      AppColors.charcoal,
                                    ],
                                  ),
                                ),
                                child: Icon(Icons.image, color: AppColors.gold, size: 50),
                              );
                            },
                          ),
                        ),
                        // Overlay oscuro
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Badge de promoción
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade600, Colors.red.shade400],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_offer, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  '¡COTIZA TU ESTILO!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Información de la promo
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                index == 0
                                    ? 'Promoción Especial'
                                    : index == 1
                                        ? 'Nuevos Servicios'
                                        : 'Reserva Ahora',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                index == 0
                                    ? 'En tratamientos capilares premium'
                                    : index == 1
                                        ? 'Descubre nuestros nuevos estilos'
                                        : 'Tu cita perfecta te espera',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: 28),
          
          // Sección de Accesos Rápidos
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gold, AppColors.gold.withOpacity(0.3)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Accesos Rápidos',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAccessCard(
                        icon: Icons.calendar_today,
                        title: 'Agendar',
                        subtitle: 'Nueva cita',
                        gradient: [AppColors.gold, AppColors.gold.withOpacity(0.7)],
                        onTap: () => setState(() => _currentTab = 1),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _buildQuickAccessCard(
                        icon: Icons.history,
                        title: 'Historial',
                        subtitle: 'Mis citas',
                        gradient: [Color(0xFF4A4A4A), Color(0xFF2C2C2C)],
                        onTap: () => setState(() => _currentTab = 2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 28),
          
          // Catálogos rediseñados
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gold, AppColors.gold.withOpacity(0.3)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Categorías',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentTab = 1),
                      child: Row(
                        children: [
                          Text(
                            'Ver todo',
                            style: TextStyle(color: AppColors.gold, fontSize: 13),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, color: AppColors.gold, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          catalogs.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.charcoal.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No hay categorías disponibles.',
                        style: TextStyle(color: AppColors.gray),
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: catalogs.length,
                    separatorBuilder: (_, __) => SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final catalog = catalogs[i];
                      final name = catalog['nombre'] ?? 'Catálogo';
                      final colors = _getCategoryColors(i);
                      
                      return GestureDetector(
                        onTap: () => setState(() => _currentTab = 1),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colors[0].withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getCategoryIcon(name),
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          
          SizedBox(height: 32),
          
          // Estilistas rediseñados
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gold, AppColors.gold.withOpacity(0.3)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Nuestros Estilistas',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${stylists.length} disponibles',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          stylists.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.charcoal.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No hay estilistas disponibles.',
                        style: TextStyle(color: AppColors.gray),
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: stylists.map((stylist) => Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: _buildStylistCardWidget(stylist),
                    )).toList(),
                  ),
                ),
          
          SizedBox(height: 32),
        ],
      ),
    );
  }

  // Helper para cards de acceso rápido
  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 95,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: gradient[0] == AppColors.gold ? Colors.black : Colors.white, 
                  size: 20,
                ),
              ),
              SizedBox(height: 8),
              // Título y subtítulo
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: gradient[0] == AppColors.gold ? Colors.black : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: gradient[0] == AppColors.gold ? Colors.black.withOpacity(0.75) : Colors.white.withOpacity(0.85),
                        fontSize: 10,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para colores de categorías (esquema negro-dorado)
  List<Color> _getCategoryColors(int index) {
    final colorSets = [
      [AppColors.gold, Color(0xFFB8860B)],                    // Dorado
      [Color(0xFF4A4A4A), Color(0xFF2C2C2C)],                 // Gris oscuro
      [Color(0xFFD4AF37), Color(0xFFC5A028)],                 // Dorado antiguo
      [Color(0xFF5A5A5A), Color(0xFF3A3A3A)],                 // Gris medio
      [AppColors.gold.withOpacity(0.8), Color(0xFF8B7355)],   // Dorado suave
      [Color(0xFF6B6B6B), Color(0xFF4A4A4A)],                 // Gris claro
    ];
    return colorSets[index % colorSets.length];
  }

  // Helper para iconos de categorías
  IconData _getCategoryIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('cabello') || nameLower.contains('corte')) {
      return Icons.content_cut;
    } else if (nameLower.contains('color') || nameLower.contains('tinte')) {
      return Icons.palette;
    } else if (nameLower.contains('uña') || nameLower.contains('manicure')) {
      return Icons.back_hand;
    } else if (nameLower.contains('facial') || nameLower.contains('rostro')) {
      return Icons.face_retouching_natural;
    } else if (nameLower.contains('maquillaje')) {
      return Icons.brush;
    } else if (nameLower.contains('masaje')) {
      return Icons.spa;
    }
    return Icons.star;
  }

  Widget _buildServicesTab() {
    return ServicesBookingPage(
      token: token,
      clienteId: userId,
      categories: catalogs,
      services: services,
      stylists: stylists,
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gold, AppColors.gold.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.location_on, color: Colors.black, size: 28),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Dónde Estamos?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Encuéntranos fácilmente',
                        style: TextStyle(color: AppColors.gray, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Location Card
            LocationCard(isCompact: false),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return ProfilePage(
      token: token,
      user: widget.user,
      userRole: 'client',
    );
  }

  Widget _buildStylistCardWidget(Map<String, dynamic> stylist) {
    final nombre = stylist['nombre'] ?? '';
    final apellido = stylist['apellido'] ?? '';
    final name = (nombre.isNotEmpty || apellido.isNotEmpty)
        ? '$nombre $apellido'
        : 'Estilista';
    final image = stylist['image'];
    final rating = (stylist['rating'] ?? 5.0).toDouble();
    final especialidad = stylist['especialidad'] ?? 'Estilista';

    return Container(
      width: 160,
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade800,
              AppColors.charcoal,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 12),
            // Avatar con borde dorado
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.gold, AppColors.gold.withOpacity(0.5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: image != null && image.isNotEmpty
                    ? NetworkImage(image)
                    : null,
                backgroundColor: AppColors.charcoal,
                child: image == null || image.isEmpty
                    ? Icon(
                        Icons.person,
                        color: AppColors.gold,
                        size: 35,
                      )
                    : null,
              ),
            ),
            SizedBox(height: 12),
            // Nombre
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 4),
            // Especialidad
            Text(
              especialidad,
              style: TextStyle(
                color: AppColors.gray,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            // Rating
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: AppColors.gold, size: 14),
                  SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
    );
  }



  void _showSearchDialog() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    String searchQuery = '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Filtrar servicios basado en búsqueda
          final filteredServices = services.where((service) {
            final nombre = (service['nombre'] ?? '').toString().toLowerCase();
            return nombre.contains(searchQuery.toLowerCase());
          }).toList();

          return AlertDialog(
            backgroundColor: AppColors.charcoal,
            surfaceTintColor: AppColors.charcoal,
            title: Text(
              'Buscar Servicios',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: isMobile ? double.maxFinite : 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo de búsqueda
                  TextField(
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppColors.gold,
                    decoration: InputDecoration(
                      hintText: '🔍 Escribe para buscar...',
                      hintStyle: TextStyle(
                        color: AppColors.gray.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.gold.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.gold.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.gold,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lista de resultados
                  if (filteredServices.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            searchQuery.isEmpty ? Icons.spa : Icons.search_off,
                            size: 48,
                            color: AppColors.gold.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchQuery.isEmpty
                                ? 'Escribe para buscar'
                                : 'No se encontraron servicios',
                            style: TextStyle(
                              color: AppColors.gray.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          final nombre = service['nombre'] ?? 'Sin nombre';
                          final precio = service['precio'] ?? 0;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            title: Text(
                              nombre,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '\$$precio',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward,
                              color: AppColors.gold,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              // Aquí puedes navegar a los detalles del servicio
                              // O abrir la página de servicios filtrada por este servicio
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
            ],
          );
        },
      ),
    );
  
}

}
