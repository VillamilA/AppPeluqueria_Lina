import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Modelo para categorías con iconos
class ServiceCategory {
  final String id;
  final String nombre;
  final IconData icon;
  final Color color;

  ServiceCategory({
    required this.id,
    required this.nombre,
    required this.icon,
    required this.color,
  });
}

class ServicesCategoriesPage extends StatefulWidget {
  final String token;
  final List<dynamic> categories;

  const ServicesCategoriesPage({
    super.key,
    required this.token,
    required this.categories,
  });

  @override
  State<ServicesCategoriesPage> createState() => _ServicesCategoriesPageState();
}

class _ServicesCategoriesPageState extends State<ServicesCategoriesPage> {
  late List<ServiceCategory> serviceCategories;
  bool isLoading = true;

  Map<String, ServiceCategory> get categoryIcons => {
    'Maquillaje': ServiceCategory(
      id: '',
      nombre: 'Maquillaje',
      icon: Icons.face,
      color: Colors.pink,
    ),
    'Peinados': ServiceCategory(
      id: '',
      nombre: 'Peinados',
      icon: Icons.content_cut,
      color: Colors.purple,
    ),
    'Manos': ServiceCategory(
      id: '',
      nombre: 'Manos',
      icon: Icons.pan_tool,
      color: Colors.orange,
    ),
    'Hombre': ServiceCategory(
      id: '',
      nombre: 'Hombre',
      icon: Icons.face_6_outlined,
      color: Colors.blue,
    ),
    'Pies': ServiceCategory(
      id: '',
      nombre: 'Pies',
      icon: Icons.accessibility_new,
      color: Colors.brown,
    ),
    'Corte Dama': ServiceCategory(
      id: '',
      nombre: 'Corte Dama',
      icon: Icons.content_cut,
      color: Colors.red,
    ),
    'Cejas & Pestañas': ServiceCategory(
      id: '',
      nombre: 'Cejas & Pestañas',
      icon: Icons.remove_red_eye,
      color: Colors.blueGrey,
    ),
    'Tinte': ServiceCategory(
      id: '',
      nombre: 'Tinte',
      icon: Icons.palette,
      color: Colors.amber,
    ),
    'Depilación': ServiceCategory(
      id: '',
      nombre: 'Depilación',
      icon: Icons.waves,
      color: Colors.cyan,
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    // Mapear las categorías del backend con los iconos definidos
    serviceCategories = widget.categories.map((category) {
      final nombre = category['nombre'] ?? 'Sin nombre';
      final iconData = categoryIcons[nombre];
      return ServiceCategory(
        id: category['_id'] ?? '',
        nombre: nombre,
        icon: iconData?.icon ?? Icons.category,
        color: iconData?.color ?? AppColors.gold,
      );
    }).toList();

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Categorías de Servicios',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: isMobile ? 10 : 12,
                  mainAxisSpacing: isMobile ? 10 : 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: serviceCategories.length,
                itemBuilder: (context, index) {
                  final category = serviceCategories[index];
                  return _buildCategoryCard(category, context, isMobile);
                },
              ),
            ),
    );
  }

  Widget _buildCategoryCard(
    ServiceCategory category,
    BuildContext context,
    bool isMobile,
  ) {
    return GestureDetector(
      onTap: () {
        // Navegar a los servicios de esta categoría
        Navigator.pop(context, category.id);
      },
      child: Card(
        color: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                category.color.withOpacity(0.1),
                category.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isMobile ? 50 : 60,
                  height: isMobile ? 50 : 60,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: isMobile ? 28 : 32,
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 12),
                Text(
                  category.nombre,
                  style: TextStyle(
                    color: category.color,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 11 : 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
