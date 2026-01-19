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
    final isPending = status == 'PENDING_STYLIST_CONFIRMATION';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending 
              ? Colors.orange 
              : statusColor.withOpacity(0.4),
          width: isPending ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isPending)
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: statusColor.withOpacity(0.08),
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
            // ALERTA DE CONFIRMACIÓN PENDIENTE
            // ══════════════════════════════════════════════
            if (isPending)
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '⚠️ Esta cita necesita tu confirmación',
                            style: TextStyle(
                              color: Colors.orange.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),

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
                          fontSize: isMobile ? 14 : 15,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 5 : 6),
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
                    horizontal: isMobile ? 11 : 13,
                    vertical: isMobile ? 6 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withOpacity(0.6),
                      width: 1.5,
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
            SizedBox(height: isMobile ? 14 : 16),

            // ══════════════════════════════════════════════
            // INFORMACIÓN DE FECHA Y HORA
            // ══════════════════════════════════════════════
            Container(
              padding: EdgeInsets.all(isMobile ? 11 : 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade800.withOpacity(0.6),
                    Colors.grey.shade900.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.gold,
                        size: isMobile ? 17 : 19,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          date != null
                              ? DateFormat('d MMMM, yyyy', 'es_ES').format(date!)
                              : 'Sin fecha',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 9 : 11),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.gold,
                        size: isMobile ? 17 : 19,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$startTime - $endTime',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 12 : 14),

            // ══════════════════════════════════════════════
            // NOTAS DEL CLIENTE (si existen)
            // ══════════════════════════════════════════════
            if (notes != null && notes!.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(isMobile ? 11 : 13),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_outlined,
                          color: Colors.blue.shade300,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Preferencias del cliente:',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      notes!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isMobile ? 12 : 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 12 : 14),
            ],

            // ══════════════════════════════════════════════
            // BOTONES DE ACCIÓN
            // ══════════════════════════════════════════════
            Row(
              children: [
                // BOTÓN CONFIRMAR (prominente si está pendiente)
                if (onConfirm != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isPending ? 12 : 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: isPending
                              ? LinearGradient(
                                  colors: [
                                    Colors.orange.shade700,
                                    Colors.orange.shade600,
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.blue.shade700,
                                    Colors.blue.shade600,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: isPending
                                  ? Colors.orange.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.2),
                              blurRadius: isPending ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isPending ? '🔔 CONFIRMAR' : '✓ Confirmar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 11 : 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ESPACIADOR
                if (onConfirm != null && (onComplete != null || onCancel != null))
                  SizedBox(width: 10),

                // BOTÓN COMPLETAR
                if (onComplete != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: onComplete,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '✓✓ Completar',
                            style: TextStyle(
                              color: Colors.green.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 11 : 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ESPACIADOR
                if ((onConfirm != null || onComplete != null) && onCancel != null)
                  SizedBox(width: 10),

                // BOTÓN CANCELAR
                if (onCancel != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '✕ Cancelar',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 11 : 12,
                            ),
                          ),
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
