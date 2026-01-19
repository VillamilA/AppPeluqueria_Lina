import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/category_card.dart';
import 'services_category_page.dart';

class ServicesBookingPage extends StatefulWidget {
  final String token;
  final String clienteId;
  final List<dynamic> categories;
  final List<dynamic> services;
  final List<dynamic> stylists;

  const ServicesBookingPage({
    super.key,
    required this.token,
    required this.clienteId,
    required this.categories,
    required this.services,
    required this.stylists,
  });

  @override
  State<ServicesBookingPage> createState() => _ServicesBookingPageState();
}

class _ServicesBookingPageState extends State<ServicesBookingPage> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openCategoryServices(dynamic category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServicesCategoryPage(
          token: widget.token,
          clienteId: widget.clienteId,
          category: category,
          services: widget.services,
          stylists: widget.stylists,
        ),
      ),
    );
  }

  int _getServiceCountByCategory(String categoryId) {
    final category = widget.categories.firstWhere(
      (cat) => cat['_id'] == categoryId,
      orElse: () => null,
    );
    if (category == null) return 0;
    final serviceIds = category['services'] as List? ?? [];
    return serviceIds.length;
  }

  List<dynamic> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return widget.categories;
    }
    return widget.categories
        .where((cat) {
          final nombre = (cat['nombre'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          return nombre.contains(query);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar compacto con búsqueda
          SliverAppBar(
            expandedHeight: isMobile ? 120 : 130,
            pinned: true,
            backgroundColor: AppColors.charcoal,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              collapseMode: CollapseMode.parallax,
              background: Container(
                color: AppColors.charcoal,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Título compacto
                    Padding(
                      padding: EdgeInsets.only(bottom: isMobile ? 8 : 10),
                      child: Text(
                        'Servicios',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Campo de búsqueda compacto
                    SizedBox(
                      height: isMobile ? 40 : 44,
                      child: TextField(
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        style: TextStyle(color: Colors.white, fontSize: isMobile ? 12 : 13),
                        cursorColor: AppColors.gold,
                        decoration: InputDecoration(
                          hintText: '🔍 Buscar...',
                          hintStyle: TextStyle(
                            color: AppColors.gray.withOpacity(0.6),
                            fontSize: isMobile ? 12 : 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Icon(
                                    Icons.clear,
                                    color: AppColors.gold,
                                    size: 18,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 12,
                            vertical: isMobile ? 8 : 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.gold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.gold.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.gold.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: SizedBox.shrink(),
            ),
          ),
          // Grid de categorías
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: _filteredCategories.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.gold.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron categorías',
                            style: TextStyle(
                              color: AppColors.gray.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile
                            ? 2
                            : isTablet
                                ? 3
                                : 4,
                        crossAxisSpacing: isMobile ? 12 : 16,
                        mainAxisSpacing: isMobile ? 12 : 16,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: _filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = _filteredCategories[index];
                        final categoryName = category['nombre'] ?? 'Sin nombre';
                        final serviceCount =
                            _getServiceCountByCategory(category['_id']);

                        return GestureDetector(
                          onTap: () => _openCategoryServices(category),
                          child: CategoryCard(
                            categoryName: categoryName,
                            serviceCount: serviceCount,
                            icon: Icons.spa,
                            onTap: () => _openCategoryServices(category),
                            isSelected: false,
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
