import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';


class ServicesTab extends StatelessWidget {
  final List<dynamic> services;
  final List<dynamic> categories;
  final String selectedCategoryId;
  final Function(String) onCategorySelected;
  const ServicesTab({
    Key? key,
    required this.services,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  List<dynamic> get filteredServices {
    if (selectedCategoryId.isEmpty) return services;
    final category = categories.firstWhere((cat) => cat['_id'] == selectedCategoryId, orElse: () => null);
    if (category == null) return services;
    final serviceIds = category['services'] ?? [];
    return services.where((s) => serviceIds.contains(s['_id'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Servicios', style: TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          if (categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('Todos', style: TextStyle(color: selectedCategoryId.isEmpty ? Colors.black : AppColors.gold)),
                    selected: selectedCategoryId.isEmpty,
                    selectedColor: AppColors.gold,
                    backgroundColor: AppColors.charcoal,
                    onSelected: (_) => onCategorySelected(''),
                  ),
                  ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat['nombre'], style: TextStyle(color: selectedCategoryId == cat['_id'] ? Colors.black : AppColors.gold)),
                      selected: selectedCategoryId == cat['_id'],
                      selectedColor: AppColors.gold,
                      backgroundColor: AppColors.charcoal,
                      onSelected: (_) => onCategorySelected(cat['_id']),
                    ),
                  )),
                ],
              ),
            ),
          SizedBox(height: 16),
          Expanded(
            child: filteredServices.isEmpty
                ? Center(child: Text('No hay servicios disponibles.', style: TextStyle(color: AppColors.gray)))
                : ListView.separated(
                    itemCount: filteredServices.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final service = filteredServices[i];
                      return Card(
                        color: AppColors.charcoal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.gold,
                            child: Icon(Icons.content_cut, color: AppColors.charcoal),
                          ),
                          title: Text(service['nombre'] ?? 'Servicio', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service['descripcion'] ?? '', style: TextStyle(color: AppColors.gray)),
                              SizedBox(height: 4),
                              Text('Duración: ${service['duracionMin'] ?? '-'} min', style: TextStyle(color: AppColors.gray)),
                              Text('Precio: ${service['precio'] ?? '-'}', style: TextStyle(color: AppColors.gold)),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.charcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Reservar'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Reservar servicio: ${service['nombre']}')),
                              );
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
