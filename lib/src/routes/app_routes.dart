import 'package:flutter/material.dart';
import 'package:peluqueria_lina_app/src/features/admin/bookings_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/clients_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/managers_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/services_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/stylists_crud_page.dart';
import 'package:peluqueria_lina_app/src/features/admin/catalog_management_page.dart';
import '../features/slots/slot_management_page.dart';
import '../features/auth/pages/welcome_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/dashboard/stylist_dashboard_page.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const WelcomePage(),
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
  '/admin/clients': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    print('🔑 ClientsCrudPage received token: $token');
    return ClientsCrudPage(token: token);
  },
  '/admin/managers': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    print('🔑 ManagersCrudPage received token: $token');
    return ManagersCrudPage(token: token);
  },
  '/admin/services': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    print('🔑 ServicesCrudPage received token: $token');
    return ServicesCrudPage(token: token);
  },
  '/admin/stylists': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    print('🔑 StylistsCrudPage received token: $token');
    return StylistsCrudPage(token: token);
  },
  '/admin/bookings': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    print('🔑 BookingsCrudPage received token: $token');
    return BookingsCrudPage(token: token);
  },
  '/admin/slots': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    print('🔑 SlotManagementPage received token: $token');
    return SlotManagementPage(token: token, userRole: 'ADMIN');
  },
  '/admin/catalogs': (context) {
    final token = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    print('🔑 CatalogManagementPage received token: $token');
    return CatalogManagementPage(token: token);
  },
  '/stylist/dashboard': (context) {
    final userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    print('🔑 StylistDashboardPage received userData: $userData');
    return StylistDashboardPage(user: userData);
  },
};