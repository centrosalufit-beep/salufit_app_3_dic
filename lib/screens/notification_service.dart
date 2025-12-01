import 'package:flutter/foundation.dart'; // <--- 1. IMPORTANTE: Para kDebugMode
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. Pedir permiso al usuario (Obligatorio en iOS/Android 13+)
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. CORREGIDO: Envuelto en kDebugMode
      if (kDebugMode) {
        print('🔔 Permiso de notificaciones concedido');
      }
      
      // 2. Obtener el token único del dispositivo
      final String? token = await _messaging.getToken();
      
      if (token != null) {
        // 3. CORREGIDO: Envuelto en kDebugMode
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        _saveTokenToDatabase(token);
      }

      // 3. Escuchar si el token cambia (refresh)
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
    } else {
      // 4. CORREGIDO: Envuelto en kDebugMode
      if (kDebugMode) {
        print('🔕 Permiso denegado');
      }
    }
  }

  // Guardar el token en el perfil del usuario
  Future<void> _saveTokenToDatabase(String token) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Usamos merge para no borrar otros datos
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}