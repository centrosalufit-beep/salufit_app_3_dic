import 'package:flutter/material.dart';
import 'package:salufit_app/layouts/desktop_scaffold.dart';

void main() {
  // Inicialización necesaria para asegurar que los servicios de plataforma respondan
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const AdminWindowsApp(),
  );
}

class AdminWindowsApp extends StatelessWidget {
  const AdminWindowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salufit Admin Console',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0055FF),
        brightness: Brightness.light,
      ),
      // Según la auditoría, DesktopScaffold solo requiere userId y userRole.
      // La navegación interna se encarga de mostrar la AdminScreen inicial.
      home: const DesktopScaffold(
        userId: 'admin_debug_session',
        userRole: 'admin',
      ),
    );
  }
}
