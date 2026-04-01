import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salufit_app/features/auth/presentation/auth_wrapper.dart';
import 'package:salufit_app/features/auth/presentation/version_gate.dart';
import 'package:salufit_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('es_ES');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Sesión persistente activada (sin signOut)
    runApp(const ProviderScope(child: SalufitAdminApp()));
  } catch (e) {
    debugPrint('Error Salufit Start: $e');
  }
}

class SalufitAdminApp extends StatelessWidget {
  const SalufitAdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salufit Admin 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF009688),
      ),
      home: const VersionGate(child: AuthWrapper()),
    );
  }
}
