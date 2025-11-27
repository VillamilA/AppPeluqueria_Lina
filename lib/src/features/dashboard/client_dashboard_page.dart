import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:peluqueria_lina_app/src/features/dashboard/services_tab.dart';
import 'package:peluqueria_lina_app/src/api/api_client.dart';
import 'package:peluqueria_lina_app/src/data/services/token_storage.dart';
import 'package:peluqueria_lina_app/src/api/catalog_api.dart';
import '../../api/services_api.dart';
import '../../api/stylists_api.dart';
import '../../core/theme/app_theme.dart';

class ClientDashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ClientDashboardPage({Key? key, required this.user}) : super(key: key);

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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.black), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.content_cut, color: Colors.black), label: 'Servicios'),
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
        return _buildLocationTab();
      case 3:
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
                      final image = stylist['image'] ?? null;
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
    );
  }

  Widget _buildLocationTab() {
    return Center(child: Text('Ubicación y Horario', style: TextStyle(color: AppColors.gold)));
  }

  Widget _buildProfileTab() {
    return Center(child: Text('Perfil', style: TextStyle(color: AppColors.gold)));
  }
}
