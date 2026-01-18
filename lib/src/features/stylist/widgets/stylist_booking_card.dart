import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class StylistBookingCard extends StatelessWidget {
  final String clientName;
  final String serviceName;
  final DateTime? date;
  final String startTime;
  final String endTime;
  final String status;
  final String? notes;
  final VoidCallback? onConfirm;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final Color statusColor;
  final String statusLabel;

  const StylistBookingCard({
    super.key,
    required this.clientName,
    required this.serviceName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.statusColor,
    required this.statusLabel,
    this.notes,
    this.onConfirm,
    this.onComplete,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════════════
            // ENCABEZADO: Cliente y Estado
            // ══════════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 13 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 4 : 6),
                      Text(
                        serviceName,
                        style: TextStyle(
                          color: AppColors.gray.withOpacity(0.8),
                          fontSize: isMobile ? 12 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 12,
                    vertical: isMobile ? 5 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 10 : 11,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 14),

            // ══════════════════════════════════════════════
            // INFORMACIÓN DE FECHA Y HORA
            // ══════════════════════════════════════════════
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.gold,
                        size: isMobile ? 16 : 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        date != null
                            ? DateFormat('d MMMM, yyyy', 'es_ES').format(date!)
                            : 'Sin fecha',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 8 : 10),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.gold,
                        size: isMobile ? 16 : 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '$startTime - $endTime',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 10 : 12),

            // ══════════════════════════════════════════════
            // NOTAS DEL CLIENTE (si existen)
            // ══════════════════════════════════════════════
            if (notes != null && notes!.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferencias del cliente:',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      notes!,
                      style: TextStyle(
                        color: Colors.blue.shade100,
                        fontSize: isMobile ? 11 : 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 12 : 14),
            ],

            // ══════════════════════════════════════════════
            // BOTONES DE ACCIONES
            // ══════════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (status == 'SCHEDULED' || status == 'PENDING' && onConfirm != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onConfirm,
                      icon: Icon(Icons.check, size: isMobile ? 16 : 18),
                      label: Text(
                        'Confirmar',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (status == 'CONFIRMED' && onComplete != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onComplete,
                      icon: Icon(Icons.done_all, size: isMobile ? 16 : 18),
                      label: Text(
                        'Completar',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (status == 'SCHEDULED' ||
                    status == 'PENDING' ||
                    status == 'CONFIRMED')
                  SizedBox(width: isMobile ? 8 : 10),
                if (status == 'SCHEDULED' ||
                    status == 'PENDING' ||
                    status == 'CONFIRMED')
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onCancel,
                      icon: Icon(Icons.close, size: isMobile ? 16 : 18),
                      label: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
