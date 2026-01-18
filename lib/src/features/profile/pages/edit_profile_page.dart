import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/edit_profile_section.dart';

class EditProfilePage extends StatelessWidget {
  final String token;
  final Map<String, dynamic> user;
  final String userRole;

  const EditProfilePage({
    super.key,
    required this.token,
    required this.user,
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
          'Editar Perfil',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: EditProfileSection(
          token: token,
          user: user,
          userRole: userRole,
          onSuccess: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
