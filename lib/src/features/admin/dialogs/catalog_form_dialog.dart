import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../api/api_client.dart';
import '../../../api/catalogs_api.dart';
import '../../../core/theme/app_theme.dart';

class CatalogFormDialog extends StatefulWidget {
  final String token;
  final Function(String) onCatalogCreated;

  const CatalogFormDialog({super.key, 
    required this.token,
    required this.onCatalogCreated,
  });

  @override
  State<CatalogFormDialog> createState() => _CatalogFormDialogState();
}

class _CatalogFormDialogState extends State<CatalogFormDialog> {
  final nombreCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final imageUrlCtrl = TextEditingController();
  bool _isSaving = false;
  late CatalogsApi _catalogsApi;

  @override
  void initState() {
    super.initState();
    _catalogsApi = CatalogsApi(ApiClient.instance);
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (nombreCtrl.text.isEmpty || descripcionCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final res = await _catalogsApi.createCatalog(
        nombre: nombreCtrl.text,
        descripcion: descripcionCtrl.text,
        imageUrl: imageUrlCtrl.text.isEmpty ? null : imageUrlCtrl.text,
        token: widget.token,
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final catalogId = data['_id'] ?? data['id'];
        widget.onCatalogCreated(catalogId);
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catálogo creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear catálogo: ${res.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.charcoal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Crear Nuevo Catálogo',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(nombreCtrl, 'Nombre *', Icons.category),
              SizedBox(height: 12),
              _buildTextField(
                descripcionCtrl,
                'Descripción *',
                Icons.description,
                maxLines: 3,
              ),
              SizedBox(height: 12),
              _buildTextField(imageUrlCtrl, 'URL de Imagen', Icons.image),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gray,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            'Crear',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.gold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.gray),
        prefixIcon: Icon(icon, color: AppColors.gold),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}
