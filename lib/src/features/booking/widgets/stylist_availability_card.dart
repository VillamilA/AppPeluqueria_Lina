import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class StylistAvailabilityCard extends StatelessWidget {
  final String stylistName;
  final double rating;
  final String startTime;
  final String endTime;
  final String date;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;
  final bool isMobile;

  const StylistAvailabilityCard({
    super.key,
    required this.stylistName,
    required this.rating,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.isSelected,
    required this.isAvailable,
    required this.onTap,
    required this.isMobile,
  });

  String _formatTime(String time) {
    try {
      // Si es formato HH:MM
      if (time.contains(':')) {
        return time;
      }
      // Si es ISO format
      final dateTime = DateTime.parse(time);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withOpacity(0.2)
              : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : isAvailable
                    ? AppColors.gold.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del estilista
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stylistName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                // Rating
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.gold,
                    ),
                    SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 10),
            // Horario
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: isMobile ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: isMobile ? 16 : 18,
                      color: AppColors.gold,
                    ),
                ],
              ),
            ),
            if (!isAvailable) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.block,
                    size: 14,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'No disponible',
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.7),
                      fontSize: isMobile ? 11 : 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
