import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'service_detail_page.dart';

class ServicesCategoryPage extends StatefulWidget {
  final String token;
  final String clienteId;
  final dynamic category;
  final List<dynamic> services;
  final List<dynamic> stylists;

  const ServicesCategoryPage({
    super.key,
    required this.token,
    required this.clienteId,
    required this.category,
    required this.services,
    required this.stylists,
  });

  @override
  State<ServicesCategoryPage> createState() => _ServicesCategoryPageState();
}

class _ServicesCategoryPageState extends State<ServicesCategoryPage> {
  String _searchQuery = '';

  List<dynamic> get _categoryServices {
    final serviceIds = widget.category['services'] as List? ?? [];
    return widget.services
        .where((s) => serviceIds.contains(s['_id']))
        .toList();
  }

  List<dynamic> get _filteredServices {
    if (_searchQuery.isEmpty) {
      return _categoryServices;
    }
    return _categoryServices
        .where((service) {
          final nombre = (service['nombre'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          return nombre.contains(query);
        })
        .toList();
  }

  void _openServiceDetail(dynamic service) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailPage(
          service: service,
          token: widget.token,
          clienteId: widget.clienteId,
          stylists: widget.stylists,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final categoryName = widget.category['nombre'] ?? 'Categoría';

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: CustomScrollView(
        slivers: [
          // AppBar con búsqueda
          SliverAppBar(
            expandedHeight: isMobile ? 160 : 175,
            pinned: true,
            backgroundColor: AppColors.charcoal,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.gold),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              collapseMode: CollapseMode.parallax,
              background: Container(
                color: AppColors.charcoal,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 12 : 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Título centrado
                    Padding(
                      padding: EdgeInsets.only(
                        top: isMobile ? 8 : 12,
                        bottom: isMobile ? 12 : 16,
                      ),
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Campo de búsqueda centrado
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 4 : 8,
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        style: const TextStyle(color: Colors.white),
                        cursorColor: AppColors.gold,
                        decoration: InputDecoration(
                          hintText: '🔍 Buscar servicio...',
                          hintStyle: TextStyle(
                            color: AppColors.gray.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.gold,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Icon(
                                    Icons.clear,
                                    color: AppColors.gold,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.gold.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.gold.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.gold,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 11 : 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Grid de servicios
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: _filteredServices.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.spa : Icons.search_off,
                            size: 64,
                            color: AppColors.gold.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No hay servicios en esta categoría'
                                : 'No se encontraron servicios',
                            style: TextStyle(
                              color: AppColors.gray.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = _filteredServices[index];
                        final serviceName = service['nombre'] ?? 'Sin nombre';
                        final price = (service['precio'] ?? 0).toDouble();
                        final duration = service['duracionMin'] ?? 0;
                        final description = service['descripcion'] ?? '';

                        return Container(
                          margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                          padding: EdgeInsets.all(isMobile ? 14 : 18),
                          decoration: BoxDecoration(
                            color: AppColors.charcoal,
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre del servicio
                              Text(
                                serviceName,
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: isMobile ? 10 : 12),

                              // Descripción
                              if (description.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      description,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: isMobile ? 13 : 14,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: isMobile ? 10 : 12),
                                  ],
                                ),

                              // Info: Duración y Precio (horizontal)
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          color: AppColors.gold,
                                          size: isMobile ? 16 : 18,
                                        ),
                                        SizedBox(width: isMobile ? 6 : 8),
                                        Text(
                                          '$duration min',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isMobile ? 12 : 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 20,
                                    width: 1,
                                    color: AppColors.gold.withOpacity(0.2),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(
                                          Icons.monetization_on,
                                          color: AppColors.gold,
                                          size: isMobile ? 16 : 18,
                                        ),
                                        SizedBox(width: isMobile ? 6 : 8),
                                        Text(
                                          '\$$price',
                                          style: TextStyle(
                                            color: AppColors.gold,
                                            fontSize: isMobile ? 13 : 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 14 : 16),

                              // Botón Agendar
                              SizedBox(
                                width: double.infinity,
                                height: isMobile ? 44 : 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openServiceDetail(service),
                                  icon: Icon(Icons.calendar_today, size: isMobile ? 16 : 18),
                                  label: Text(
                                    'Agendar',
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: AppColors.charcoal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          // Espacio al final
          SliverToBoxAdapter(
            child: SizedBox(height: isMobile ? 20 : 40),
          ),
        ],
      ),
    );
  }
}
