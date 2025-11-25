import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/routes/app_routes.dart';
import 'src/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peluquería Lina',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.charcoal,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          background: AppColors.charcoal,
          primary: AppColors.gold,
        ),
        fontFamily: 'Montserrat',
      ),
      initialRoute: '/',
      routes: appRoutes,
      debugShowCheckedModeBanner: false,
    );
  }
}