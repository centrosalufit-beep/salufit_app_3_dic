import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- HANDLER DE SEGUNDO PLANO (Fuera de la clase) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Notificacion Background recibida');
  }
}

class NotificationService {
  // Constructores primero
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal de Android
  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    'salufit_citas_channel', // id único
    'Avisos de Citas', // Nombre visible
    description: 'Notificaciones sobre el estado de tus reservas',
    importance: Importance.max,
  );

  bool _isInitialized = false;

  Future<void> initNotifications() async {
    if (_isInitialized) return;

    // 1. Solicitar Permisos
    final settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('🔔 Permiso notificaciones concedido');

      // 2. Configurar Notificaciones Locales
      await _setupLocalNotifications();

      // 3. Registrar Handler Background
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 4. Obtener Token y guardar
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) debugPrint('FCM Token obtenido');
        await _saveTokenToDatabase(token);
      }

      // Listener de refresco de token
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

      // 5. Configurar Listeners de Foreground
      _setupForegroundListeners();

      _isInitialized = true;
    } else {
      if (kDebugMode) print('🔕 Permiso denegado');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (kDebugMode) {
          debugPrint('Notificacion tocada');
        }
        // NOTA: Aquí es donde en el futuro puedes añadir la lógica para
        // navegar a la pantalla de reservas usando tu sistema de rutas.
        // Ejemplo: navigatorKey.currentState?.pushNamed('/reservas');
      },
    );

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_androidChannel);
    }
  }

  void _setupForegroundListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Mensaje recibido en primer plano');
      }
      _showPrivacyNotification(message);
    });
  }

  Future<void> _showPrivacyNotification(RemoteMessage message) async {
    final payloadData = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      '📅 Actualización de Agenda',
      'Tienes información importante sobre tu próxima cita. Entra para gestionarla.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Aviso de Salufit',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payloadData,
    );
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users_app').doc(user.uid).set(
          {
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
            'platform': defaultTargetPlatform.name,
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        if (kDebugMode) print('Error guardando token: $e');
      }
    }
  }
}
