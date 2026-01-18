import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/booking_history_section.dart';

class BookingHistoryPage extends StatelessWidget {
  final String token;
  final String userRole;

  const BookingHistoryPage({
    super.key,
    required this.token,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Historial de Citas',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BookingHistorySection(
          token: token,
          userRole: userRole,
        ),
      ),
    );
  }
}
