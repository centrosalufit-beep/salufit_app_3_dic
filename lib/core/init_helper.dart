// FILE: lib/core/init_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salufit_app/firebase_options.dart';

// Función top-level para background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) print('🔔 Notificación en 2o plano: ${message.messageId}');
}

class InitHelper {
  static Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Orientación
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 2. Firebase Core
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 3. Configuración Específica de Firestore (FIX CRÍTICO WINDOWS)
    try {
      // Por defecto activamos persistencia para móviles (offline support)
      var enablePersistence = true;
      // En Windows/Web, la persistencia causa bloqueos de hilos. La desactivamos.
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        enablePersistence = false;
        if (kDebugMode) {
          debugPrint('Windows/Web: Persistencia Firestore desactivada');
        }
      }

      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: enablePersistence,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      if (kDebugMode) print('⚠️ Nota Firestore Init: $e');
    }

    // 4. Notificaciones (Solo móvil)
    if (defaultTargetPlatform != TargetPlatform.windows) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    }

    // 5. App Check
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
      // Activa siempre el provider de debug en desarrollo
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
    }

    // 6. Logs
    if (kDebugMode) {
      debugPrint('Salufit Dev Mode Activo');
    }

    // 7. Formatos de fecha (CORREGIDO: 'es' en lugar de 'es_ES')
    // Esto es crucial porque en tus pantallas usas DateFormat(..., 'es')
    await initializeDateFormatting('es');
  }
}
