import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/init_helper.dart';
import 'package:salufit_app/features/auth/presentation/login_screen.dart';
import 'package:salufit_app/features/home/presentation/screens/main_client_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InitHelper.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: const Color(0xFF009688), 
        fontFamily: 'serif'
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF009688))
            )
          );
        }

        final user = snapshot.data;

        // Si no hay usuario, cargamos tu pantalla de login real
        if (user == null) {
          return const LoginScreen();
        }

        // Si hay usuario, entramos al portal del cliente
        return MainClientDashboardScreen(userId: user.uid, userRole: "cliente");
      },
    );
  }
}
