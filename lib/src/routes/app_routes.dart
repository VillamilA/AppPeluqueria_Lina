import 'package:flutter/material.dart';
import '../features/auth/pages/welcome_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const WelcomePage(),
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
};
