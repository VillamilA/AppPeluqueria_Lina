import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StylistsSelectionCard extends StatelessWidget {
  final String stylistName;
  final double rating;
  final String specialization;
  final bool isSelected;
  final VoidCallback onTap;
  final List<String> workDays;

  const StylistsSelectionCard({
    super.key,
    required this.stylistName,
    required this.rating,
    required this.specialization,
    required this.isSelected,
    required this.onTap,
    required this.workDays,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 14,
          vertical: isMobile ? 8 : 10,
        ),
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.gray,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nombre + Check
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stylistName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.charcoal,
                      size: isMobile ? 16 : 18,
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 10),

            // Especialización
            Text(
              specialization,
              style: TextStyle(
                color: AppColors.gray,
                fontSize: isMobile ? 12 : 13,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 10),

            // Rating (estrellas)
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < rating.toInt() ? Icons.star : Icons.star_border,
                    color: AppColors.gold,
                    size: isMobile ? 14 : 15,
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 10),

            // Días de trabajo
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                border: Border.all(color: AppColors.gold, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trabaja:',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 5),
                  Text(
                    workDays.join(', '),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
