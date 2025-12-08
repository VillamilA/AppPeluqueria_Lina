import 'package:peluqueria_lina_app/src/features/booking/reserve_booking_dialog.dart';
import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';
import '../client/services_categories_page.dart';

class ServicesTab extends StatefulWidget {
  final List<dynamic> services;
  final List<dynamic> categories;
  final String selectedCategoryId;
  final Function(String) onCategorySelected;
  final List<dynamic> stylists;
  final String clienteId;
  final String token;
  
  const ServicesTab({
    super.key,
    required this.services,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.stylists,
    required this.clienteId,
    required this.token,
  });

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  late String localSelectedCategoryId;

  @override
  void initState() {
    super.initState();
    localSelectedCategoryId = widget.selectedCategoryId;
  }

  List<dynamic> get filteredServices {
    if (localSelectedCategoryId.isEmpty) return widget.services;
    final category = widget.categories.firstWhere(
      (cat) => cat['_id'] == localSelectedCategoryId,
      orElse: () => null,
    );
    if (category == null) return widget.services;
    final serviceIds = category['services'] ?? [];
    return widget.services.where((s) => serviceIds.contains(s['_id'])).toList();
  }

  void _openCategoriesPage() async {
    final selectedCategoryId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ServicesCategoriesPage(
          token: widget.token,
          categories: widget.categories,
        ),
      ),
    );
    
    if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
      setState(() {
        localSelectedCategoryId = selectedCategoryId;
      });
      widget.onCategorySelected(selectedCategoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Servicios',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: isMobile ? 20 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.grid_view),
                label: Text('Categorías'),
                onPressed: _openCategoriesPage,
              ),
            ],
          ),
          SizedBox(height: 12),
          if (widget.categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      'Todos',
                      style: TextStyle(
                        color: localSelectedCategoryId.isEmpty
                            ? Colors.black
                            : AppColors.gold,
                      ),
                    ),
                    selected: localSelectedCategoryId.isEmpty,
                    selectedColor: AppColors.gold,
                    backgroundColor: AppColors.charcoal,
                    onSelected: (_) {
                      setState(() {
                        localSelectedCategoryId = '';
                      });
                      widget.onCategorySelected('');
                    },
                  ),
                  ...widget.categories.map((cat) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        cat['nombre'],
                        style: TextStyle(
                          color: localSelectedCategoryId == cat['_id']
                              ? Colors.black
                              : AppColors.gold,
                        ),
                      ),
                      selected: localSelectedCategoryId == cat['_id'],
                      selectedColor: AppColors.gold,
                      backgroundColor: AppColors.charcoal,
                      onSelected: (_) {
                        setState(() {
                          localSelectedCategoryId = cat['_id'];
                        });
                        widget.onCategorySelected(cat['_id']);
                      },
                    ),
                  )),
                ],
              ),
            ),
          SizedBox(height: 16),
          Expanded(
            child: filteredServices.isEmpty
                ? Center(
                    child: Text(
                      'No hay servicios disponibles.',
                      style: TextStyle(color: AppColors.gray),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredServices.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final service = filteredServices[i];
                      return Card(
                        color: AppColors.charcoal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.gold,
                            child: Icon(
                              Icons.content_cut,
                              color: AppColors.charcoal,
                            ),
                          ),
                          title: Text(
                            service['nombre'] ?? 'Servicio',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['descripcion'] ?? '',
                                style: TextStyle(color: AppColors.gray),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Duración: ${service['duracionMin'] ?? '-'} min',
                                style: TextStyle(color: AppColors.gray),
                              ),
                              Text(
                                'Precio: ${service['precio'] ?? '-'}',
                                style: TextStyle(color: AppColors.gold),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.charcoal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Reservar'),
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (_) => ReserveBookingDialog(
                                  clienteId: widget.clienteId,
                                  serviceId: service['_id'],
                                  catalogId: localSelectedCategoryId,
                                  precio: service['precio'] is num
                                      ? (service['precio'] as num).toDouble()
                                      : 0.0,
                                  stylists: widget.stylists,
                                  token: widget.token,
                                ),
                              );
                              if (result != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Reserva creada exitosamente'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
