import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar cuando el usuario toca la notificación
        print('Notificación tocada: ${response.payload}');
      },
    );

    _initialized = true;
  }

  /// Solicitar permisos de notificación
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Notificación para el cliente cuando reserva una cita
  Future<void> notifyClientBookingCreated({
    required String stylistName,
    required String date,
    required String time,
    int notificationId = 0,
  }) async {
    await initialize();
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_client_channel',
      'Reservas de Citas',
      channelDescription: 'Notificaciones sobre tus citas reservadas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE4A853), // Gold color
      enableVibration: true,
      playSound: true,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      notificationId,
      '✅ Cita Reservada',
      'Has reservado una cita con $stylistName el $date a las $time. ¡Recuerda ir con tiempo!',
      details,
      payload: 'booking_client_$notificationId',
    );
  }

  /// Notificación para el estilista cuando le reservan una cita
  Future<void> notifyStylistBookingCreated({
    required String clientName,
    required String date,
    required String time,
    int notificationId = 1000,
  }) async {
    await initialize();
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_stylist_channel',
      'Nuevas Citas',
      channelDescription: 'Notificaciones sobre citas reservadas contigo',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFFD93D), // Yellow color for stylist
      enableVibration: true,
      playSound: true,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      notificationId,
      '📅 Nueva Cita Reservada',
      'Han reservado una cita contigo el $date a las $time. Mira tu agenda para ver todos los detalles.',
      details,
      payload: 'booking_stylist_$notificationId',
    );
  }

  /// Notificación cuando una cita es cancelada
  Future<void> notifyBookingCancelled({
    required String personName,
    required String date,
    required String time,
    required bool isClient,
    int notificationId = 2000,
  }) async {
    await initialize();
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_cancelled_channel',
      'Citas Canceladas',
      channelDescription: 'Notificaciones sobre citas canceladas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF6B6B), // Red color for cancellation
      enableVibration: true,
      playSound: true,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    final title = isClient ? '❌ Cita Cancelada' : '❌ Cita Cancelada por Cliente';
    final message = isClient
        ? 'Tu cita con $personName el $date a las $time ha sido cancelada.'
        : '$personName ha cancelado su cita del $date a las $time.';

    await _notifications.show(
      notificationId,
      title,
      message,
      details,
      payload: 'booking_cancelled_$notificationId',
    );
  }

  /// Notificación recordatoria de cita (próximamente)
  Future<void> scheduleBookingReminder({
    required String personName,
    required String date,
    required String time,
    required DateTime scheduledDate,
    int notificationId = 3000,
  }) async {
    await initialize();
    
    // Esta funcionalidad requiere configuración adicional
    // Por ahora solo se implementa la notificación inmediata
    print('Recordatorio programado para $scheduledDate');
  }

  /// Cancelar una notificación específica
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
