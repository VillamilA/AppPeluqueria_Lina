import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/core/theme/app_theme.dart';
import 'package:peluqueria_lina_app/src/api/ratings_api.dart';
import 'package:peluqueria_lina_app/src/api/api_client.dart';

class RatingDialog extends StatefulWidget {
  final String bookingId;
  final String stylistName;
  final String serviceName;
  final String token;

  const RatingDialog({
    super.key,
    required this.bookingId,
    required this.stylistName,
    required this.serviceName,
    required this.token,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _stars = 0;
  final _comentarioCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  String _getStarLabel(int stars) {
    switch (stars) {
      case 1:
        return '😢 Malo';
      case 2:
        return '😐 Podría mejorar';
      case 3:
        return '🙂 Bueno';
      case 4:
        return '😊 Muy bueno';
      case 5:
        return '😍 Excelente';
      default:
        return '';
    }
  }

  Future<void> _submitRating() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona una calificación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await RatingsApi(ApiClient.instance).createRating(
        bookingId: widget.bookingId,
        estrellas: _stars,
        comentario: _comentarioCtrl.text,
        token: widget.token,
      );

      setState(() => _loading = false);

      print('[RATING] Response status: ${response.statusCode}');
      print('[RATING] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la calificación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      print('[RATING] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 48,
                ),
              ),
              SizedBox(height: 24),
              Text(
                '¡Gracias por calificar!',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Tu opinión nos ayuda a mejorar',
                style: TextStyle(color: AppColors.gray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  'Continuar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 12 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenWidth - 24 : 450,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.gold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Califica tu servicio',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.stylistName,
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: isSmallScreen ? 11 : 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.gold, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // CONTENIDO SCROLLABLE
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Servicio
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cut, color: AppColors.gold, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.serviceName,
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: isSmallScreen ? 12 : 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // SELECTOR DE ESTRELLAS
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '¿Qué te pareció?',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: isSmallScreen ? 6 : 8,
                              children: List.generate(5, (index) {
                                final isFilled = index < _stars;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _stars = index + 1);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isFilled
                                          ? AppColors.gold.withOpacity(0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isFilled
                                          ? Icons.star
                                          : Icons.star_outline,
                                      color: AppColors.gold,
                                      size: isSmallScreen ? 36 : 48,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: 12),
                            if (_stars > 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStarLabel(_stars),
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // CAMPO DE COMENTARIO
                      Text(
                        'Comentario (opcional)',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _comentarioCtrl,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: InputDecoration(
                          hintText: 'Cuéntanos tu experiencia...',
                          hintStyle: TextStyle(
                            color: AppColors.gray,
                            fontSize: isSmallScreen ? 12 : 13,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade800,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // BOTONES
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.gold,
                                side: BorderSide(
                                  color: AppColors.gold,
                                  width: 2,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 12 : 13,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _loading ? null : _submitRating,
                              child: _loading
                                  ? SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Enviar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 12 : 13,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
