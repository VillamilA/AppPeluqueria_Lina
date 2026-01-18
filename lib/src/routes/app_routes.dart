import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/features/admin/bookings_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/clients_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/managers_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/services_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/stylists_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/catalog_management_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/payments_management_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/business_hours_management_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/ratings_management_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/ratings_admin_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/pages/gerente_schedule_options_page.dart';
import '../features/slots/slot_management_page.dart';
import '../features/auth/pages/splash_screen.dart';
import '../features/auth/pages/welcome_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/dashboard/stylist_dashboard_page.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const SplashScreen(),
  '/welcome': (context) => const WelcomePage(),
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
  '/admin/clients': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return ClientsCrudPage(token: token);
  },
  '/admin/users': (context) {
    // Alias de /admin/clients para gestión de usuarios
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return ClientsCrudPage(token: token);
  },
  '/admin/managers': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return ManagersCrudPage(token: token);
  },
  '/admin/services': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return ServicesCrudPage(token: token);
  },
  '/admin/stylists': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return StylistsCrudPage(token: token);
  },
  '/admin/bookings': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return BookingsCrudPage(token: token);
  },
  '/admin/payments': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return PaymentsManagementPage(token: token);
  },
  '/admin/business-hours': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final token = args['token'] as String? ?? '';
    final userRole = args['userRole'] as String? ?? 'ADMIN';
    return BusinessHoursManagementPage(token: token, userRole: userRole);
  },
  '/admin/slots': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return SlotManagementPage(token: token, userRole: 'ADMIN');
  },
  '/admin/catalogs': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return CatalogManagementPage(token: token);
  },
  '/admin/catalog': (context) {
    // Alias de /admin/catalogs
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return CatalogManagementPage(token: token);
  },
  '/admin/ratings': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final token = args['token'] as String? ?? '';
    final userRole = args['userRole'] as String? ?? 'ADMIN';
    
    // ADMIN accede a página completa con enriquecimiento
    if (userRole == 'ADMIN') {
      return RatingsAdminPage(token: token);
    }
    
    // GERENTE accede a página simplificada (solo ver promedio)
    return RatingsManagementPage(token: token);
  },
  '/admin/schedule-options': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return GerenteScheduleOptionsPage(token: token, userRole: 'GERENTE');
  },
  '/stylist/dashboard': (context) {
    final userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    return StylistDashboardPage(user: userData);
  },
};