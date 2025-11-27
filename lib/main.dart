import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; 
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/update_required_screen.dart'; 
import 'screens/home_screen.dart';
import 'screens/terms_acceptance_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // --- CAPA DE SEGURIDAD 2: APP CHECK (PRODUCCIÓN) ---
  // Solo activamos App Check si NO estamos en Web Debug para evitar bloqueos locales.
  if (!kIsWeb || !kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      // ANDROID:
      // - Si estamos programando (Debug) -> Usamos el proveedor Debug.
      // - Si es la app real (Release) -> Usamos Play Integrity (Seguridad máxima).
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      
      // IOS:
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      
      // WEB:
      // Necesitas una clave reCAPTCHA v3 real aquí para producción.
      webProvider: ReCaptchaV3Provider('TU_CLAVE_RECAPTCHA_V3_AQUI'),
    );
    print('🛡️ App Check activado (${kDebugMode ? "Modo Debug" : "Modo Producción"}).');
  } else {
    print('⚠️ App Check DESACTIVADO en Web (Debug).');
  }
  
  // Configuración Web (Persistencia)
  if (kIsWeb) {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, 
        sslEnabled: true
      );
    } catch (e) {
      print('Nota Web: $e');
    }
  }

  // MODO HÍBRIDO (DEBUG)
  if (kDebugMode) {
    final String host = kIsWeb ? 'localhost' : '10.0.2.2';
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
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      String currentVersion = '1.0.0'; 
      try {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;
      } catch (e) {
        print('Error obteniendo versión: $e');
      }

      DocumentSnapshot config = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_settings')
          .get();

      if (config.exists) {
        String minVersion = config.get('min_version') ?? '1.0.0';
        if (_isVersionLower(currentVersion, minVersion)) {
          if (mounted) {
            setState(() {
              _updateRequired = true;
              _isLoadingVersion = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      print('Error conexión versión: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingVersion = false;
        _updateRequired = false;
      });
    }
  }

  bool _isVersionLower(String current, String min) {
    try {
      List<int> c = current.split('.').map(int.parse).toList();
      List<int> m = min.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        int valC = (i < c.length) ? c[i] : 0;
        int valM = (i < m.length) ? m[i] : 0;
        if (valC < valM) return true;
        if (valC > valM) return false;
      }
    } catch (e) {
      return false; 
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingVersion) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_updateRequired) return const UpdateRequiredScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        User authUser = snapshot.data!;
        
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: authUser.email)
              .limit(1)
              .get(),
          builder: (context, userQuerySnapshot) {
            
            if (userQuerySnapshot.connectionState == ConnectionState.waiting) {
               return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            String finalUserId = authUser.uid; 
            String role = 'cliente'; 
            bool termsAccepted = false;

            if (userQuerySnapshot.hasData && userQuerySnapshot.data!.docs.isNotEmpty) {
              var doc = userQuerySnapshot.data!.docs.first;
              finalUserId = doc.id; 
              var data = doc.data() as Map<String, dynamic>;
              role = data['rol'] ?? 'cliente';
              termsAccepted = data['termsAccepted'] == true;
            } 
            else {
               return FutureBuilder<DocumentSnapshot>(
                 future: FirebaseFirestore.instance.collection('users').doc(authUser.uid).get(),
                 builder: (context, adminSnap) {
                    if (adminSnap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    
                    if (adminSnap.hasData && adminSnap.data!.exists) {
                       var data = adminSnap.data!.data() as Map<String, dynamic>;
                       role = data['rol'] ?? 'cliente';
                       termsAccepted = data['termsAccepted'] == true;
                    }
                    
                    if (!termsAccepted) {
                      return TermsAcceptanceScreen(userId: authUser.uid, userRole: role);
                    }

                    return HomeScreen(userId: authUser.uid, userRole: role);
                 }
               );
            }

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