import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileHeaderCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String userRole;

  const ProfileHeaderCard({
    super.key,
    required this.user,
    required this.userRole,
  });

  String getRoleLabel() {
    switch (userRole) {
      case 'admin':
        return 'Administrador';
      case 'gerente':
      case 'manager':
        return 'Gerente';
      case 'stylist':
        return 'Estilista';
      case 'client':
      default:
        return 'Cliente';
    }
  }

  IconData getRoleIcon() {
    switch (userRole) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'gerente':
      case 'manager':
        return Icons.business;
      case 'stylist':
        return Icons.cut;
      case 'client':
      default:
        return Icons.person;
    }
  }

  Color getRoleColor() {
    switch (userRole) {
      case 'admin':
        return const Color(0xFFFF6B6B);
      case 'gerente':
      case 'manager':
        return const Color(0xFF4ECDC4);
      case 'stylist':
        return const Color(0xFFFFD93D);
      case 'client':
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = user['nombre'] ?? 'Usuario';
    final apellido = user['apellido'] ?? '';
    final email = user['email'] ?? '';
    final telefono = user['telefono'] ?? 'No disponible';
    final genero = user['genero'] ?? 'O';
    final roleColor = getRoleColor();

    String getGeneroLabel() {
      switch (genero) {
        case 'M':
          return 'Masculino';
        case 'F':
          return 'Femenino';
        default:
          return 'Otro';
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.charcoal,
            AppColors.charcoal.withOpacity(0.8),
          ],
        ),
        border: Border.all(
          color: roleColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado con rol y icono
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [
                  roleColor.withOpacity(0.2),
                  roleColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        getRoleIcon(),
                        color: roleColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      getRoleLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Perfil Verificado',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar y nombre
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 16, left: 20, right: 20),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        roleColor,
                        roleColor.withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${nombre[0]}${apellido.isNotEmpty ? apellido[0] : ''}',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nombre completo
                Text(
                  '$nombre $apellido',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Email
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Información de contacto
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: roleColor.withOpacity(0.15),
              ),
            ),
            child: Column(
              children: [
                // Teléfono
                _buildInfoItem(
                  icon: Icons.phone,
                  label: 'Teléfono',
                  value: telefono,
                  color: roleColor,
                ),
                const SizedBox(height: 12),
                Divider(
                  color: roleColor.withOpacity(0.2),
                  height: 1,
                ),
                const SizedBox(height: 12),

                // Género
                _buildInfoItem(
                  icon: Icons.person_outline,
                  label: 'Género',
                  value: getGeneroLabel(),
                  color: roleColor,
                  isCompact: true,
                ),
              ],
            ),
          ),

          // Estadísticas o resumen (opcional)
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCompact = false,
  }) {
    if (isCompact) {
      return Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
