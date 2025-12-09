import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; 
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔔 NUEVO

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/update_required_screen.dart'; 
import 'screens/home_screen.dart';
import 'screens/terms_acceptance_screen.dart'; 

// 🔔 Función para manejar notificaciones en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) print('🔔 Notificación en 2o plano: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- BLOQUEO DE ORIENTACIÓN ---
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // --- NOTIFICACIONES PUSH (CONFIGURACIÓN) ---
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // --- CAPA DE SEGURIDAD 2: APP CHECK ---
  if (!kIsWeb || !kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      // ⚠️ IMPORTANTE: Reemplaza esto con tu clave real de ReCaptcha V3
      webProvider: ReCaptchaV3Provider('TU_CLAVE_RECAPTCHA_V3_AQUI'),
    );
  }

  // Configuración Web (Persistencia DESACTIVADA como pediste)
  if (kIsWeb) {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, 
        sslEnabled: true
      );
    } catch (e) {
      if (kDebugMode) print('Nota Web: $e');
    }
  }

  // MODO HÍBRIDO (DEBUG - EMULADORES)
  if (kDebugMode) {
    const String host = kIsWeb ? 'localhost' : '10.0.2.2';
    // Opcional: Si usas emulador de Firestore, descomenta esto:
    // FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    try {
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      print('🚀 Salufit Dev: Cloud Functions -> $host:5001');
    } catch (e) {
      print('⚠️ Error conectando al emulador: $e');
    }
  }

  await initializeDateFormatting('es_ES', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salufit',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009688)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const VersionCheckWrapper(),
    );
  }
}

class VersionCheckWrapper extends StatefulWidget {
  const VersionCheckWrapper({super.key});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool _isLoadingVersion = true;
  bool _updateRequired = false;

  @override
  void initState() {
    super.initState();
    _checkVersionAndPermissions();
  }

  Future<void> _checkVersionAndPermissions() async {
    // 1. Pedir permiso de notificaciones al inicio (Android 13+ / iOS)
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) print('🔔 Permiso notificaciones: ${settings.authorizationStatus}');
    } catch (e) {
      if (kDebugMode) print('Error permisos push: $e');
    }

    // 2. Chequeo de Versión
    try {
      String currentVersion = '1.0.0'; 
      try {
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;
      } catch (e) { /* Fallback silencioso */ }

      final DocumentSnapshot config = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_settings')
          .get();

      if (config.exists) {
        final String minVersion = config.get('min_version') ?? '1.0.0';
        if (_isVersionLower(currentVersion, minVersion)) {
          if (mounted) setState(() { _updateRequired = true; _isLoadingVersion = false; });
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error conexión versión: $e');
    }

    if (mounted) setState(() { _isLoadingVersion = false; _updateRequired = false; });
  }

  bool _isVersionLower(String current, String min) {
    try {
      final List<int> c = current.split('.').map(int.parse).toList();
      final List<int> m = min.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final int valC = (i < c.length) ? c[i] : 0;
        final int valM = (i < m.length) ? m[i] : 0;
        if (valC < valM) return true;
        if (valC > valM) return false;
      }
    } catch (e) { return false; }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingVersion) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_updateRequired) return const UpdateRequiredScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Estado de carga inicial de Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // Usuario no logueado -> Login
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final User authUser = snapshot.data!;
        
        // --- LÓGICA DE USUARIO SIMPLIFICADA ---
        // Priorizamos buscar por UID directamente (Más rápido y barato)
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(authUser.uid).get(),
          builder: (context, userSnap) {
            
            if (userSnap.connectionState == ConnectionState.waiting) {
               return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Datos por defecto
            String finalUserId = authUser.uid; 
            String role = 'cliente'; 
            bool termsAccepted = false;
            bool userDocExists = false;

            if (userSnap.hasData && userSnap.data!.exists) {
              // CASO 1: El usuario existe correctamente con su UID
              userDocExists = true;
              final data = userSnap.data!.data() as Map<String, dynamic>;
              role = data['rol'] ?? 'cliente';
              termsAccepted = data['termsAccepted'] == true;
            } 
            
            // CASO 2: FALLBACK (Código heredado)
            // Si no existe por UID, buscamos por Email (Solo si es estrictamente necesario)
            if (!userDocExists) {
               return FutureBuilder<QuerySnapshot>(
                 future: FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: authUser.email)
                    .limit(1)
                    .get(),
                 builder: (context, emailSnap) {
                    if (emailSnap.connectionState == ConnectionState.waiting) {
                       return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }

                    if (emailSnap.hasData && emailSnap.data!.docs.isNotEmpty) {
                      final doc = emailSnap.data!.docs.first;
                      finalUserId = doc.id;
                      final data = doc.data() as Map<String, dynamic>;
                      role = data['rol'] ?? 'cliente';
                      termsAccepted = data['termsAccepted'] == true;
                    } 
                    
                    // Renderizado final del Fallback
                    if (!termsAccepted) {
                      return TermsAcceptanceScreen(userId: finalUserId, userRole: role);
                    }
                    return HomeScreen(userId: finalUserId, userRole: role);
                 }
               );
            }

            // Renderizado caso normal (UID encontrado)
            if (!termsAccepted) {
              return TermsAcceptanceScreen(userId: finalUserId, userRole: role);
            }

            return HomeScreen(userId: finalUserId, userRole: role);
          },
        );
      },
    );
  }
}