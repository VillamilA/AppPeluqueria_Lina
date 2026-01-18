import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'src/routes/app_routes.dart';
import 'src/core/theme/app_theme.dart';
import 'src/services/notification_service.dart';
import 'src/services/session_manager.dart';
import 'src/core/error_handler.dart' show navigatorKey;
import 'src/providers/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  
  // Inicializar servicio de notificaciones
  try {
    await NotificationService().initialize();
    print('[NOTIFICATIONS] Servicio inicializado correctamente');
  } catch (e) {
    print('[NOTIFICATIONS] Error al inicializar: $e');
  }
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Archivo .env no encontrado, usando valores por defecto');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peluquería Lina',
      navigatorKey: navigatorKey,
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
      // Wrapper para registrar contexto del SessionManager y ErrorHandler y detectar interacciones
      builder: (context, child) {
        // Registrar contexto para el SessionManager
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            SessionManager().registerContext(context);
            // ErrorHandler usa navigatorKey, no necesita contexto
          }
        });
        
        // Envolver en GestureDetector para detectar interacciones del usuario
        return GestureDetector(
          onTap: () => SessionManager().resetInactivityTimer(),
          onPanDown: (_) => SessionManager().resetInactivityTimer(),
          onScaleStart: (_) => SessionManager().resetInactivityTimer(),
          behavior: HitTestBehavior.translucent,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}