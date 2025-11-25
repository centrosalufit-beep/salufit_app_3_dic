import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Para saber mi versión
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/update_required_screen.dart'; // Importamos la pantalla roja

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009688)), // Teal
        useMaterial3: true,
        fontFamily: 'Roboto', // O la fuente que uses
      ),
      // EN VEZ DE IR AL LOGIN DIRECTO, PASAMOS POR EL CHEQUEO
      home: const VersionCheckWrapper(),
    );
  }
}

// --- EL PORTERO (CHECK DE VERSIÓN) ---
class VersionCheckWrapper extends StatefulWidget {
  const VersionCheckWrapper({super.key});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool _isLoading = true;
  bool _updateRequired = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      // 1. Obtener mi versión instalada
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version; // Ej: "1.0.0"

      // 2. Obtener versión mínima de Firebase
      DocumentSnapshot config = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_settings')
          .get();

      if (config.exists) {
        String minVersion = config.get('min_version') ?? "1.0.0";
        
        // 3. Comparar matemáticamente
        if (_isVersionLower(currentVersion, minVersion)) {
          setState(() {
            _updateRequired = true;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print("Error verificando versión: $e");
      // Si falla (ej: sin internet), dejamos pasar por defecto para no bloquear
    }

    // Si todo OK, pasamos
    setState(() {
      _isLoading = false;
      _updateRequired = false;
    });
  }

  // Función auxiliar para comparar versiones tipo "1.0.2" vs "1.0.5"
  bool _isVersionLower(String current, String min) {
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> m = min.split('.').map(int.parse).toList();

    // Comparamos número a número (Major.Minor.Patch)
    for (int i = 0; i < 3; i++) { // Asumimos formato X.Y.Z
      int valC = (i < c.length) ? c[i] : 0;
      int valM = (i < m.length) ? m[i] : 0;
      if (valC < valM) return true; // Es menor
      if (valC > valM) return false; // Es mayor
    }
    return false; // Son iguales
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Pantalla de carga inicial blanca (Splash)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_updateRequired) {
      // BLOQUEO
      return const UpdateRequiredScreen();
    }

    // TODO OK -> LOGIN
    return const LoginScreen();
  }
}