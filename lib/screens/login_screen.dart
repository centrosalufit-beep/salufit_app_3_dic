import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'activation_screen.dart';
import 'home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estado
  bool _isLoading = false;
  bool _isObscure = true;

  // Biometría y Estilos
  final LocalAuthentication auth = LocalAuthentication();
  final Color salufitGreen = const Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkBiometrics();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE REDIRECCIÓN INTELIGENTE ---
  Future<void> _navegarAlHome(String userId) async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      
      String role = 'cliente'; 
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        role = data['rol'] ?? 'cliente';
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userId: userId, userRole: role),
        ),
      );
    } catch (e) {
      debugPrint('Error obteniendo rol: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(userId: userId, userRole: 'cliente'),
          ),
        );
      }
    }
  }

  /// Verifica la huella
  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Error hardware: $e');
      return;
    }

    if (!canCheckBiometrics) return;

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Salufit requiere autenticación para acceder',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );

      if (didAuthenticate && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Identidad verificada'), backgroundColor: Colors.green));

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _navegarAlHome(user.uid);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Huella correcta. Inicia sesión para vincularla.'),
              backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      debugPrint('Error auth: $e');
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor rellena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted && credential.user != null) {
        await _navegarAlHome(credential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Error de autenticación';

      if (e.code == 'user-not-found') {
        msg = 'Usuario no encontrado';
      } else if (e.code == 'wrong-password') {
        msg = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        msg = 'Email inválido';
      } else if (e.code == 'too-many-requests') {
        msg = 'Demasiados intentos. Intenta más tarde.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. CAPA DE FONDO
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. CAPA DE CONTENIDO
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO XL (Tamaño restaurado a 0.35)
                    Image.asset(
                      'assets/login_logo.png',
                      height: size.height * 0.35, // <--- TAMAÑO ORIGINAL GRANDE
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.fitness_center,
                        size: 150,
                        color: salufitGreen,
                      ),
                    ),
                    
                    const SizedBox(height: 20), 

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                           borderSide: const BorderSide(color: Colors.white),
                        )
                      ),
                    ),
                    const SizedBox(height: 15), 

                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _isObscure = !_isObscure),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                           borderSide: BorderSide.none,
                        ),
                         enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white),
                        )
                      ),
                    ),
                    const SizedBox(height: 25),

                    // BOTÓN LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: salufitGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 5), 

                    // BOTÓN REGISTRO (Pegado al login)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ActivationScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '¿Primera vez? Activa tu cuenta aquí',
                        style: TextStyle(
                            color: salufitGreen,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                            shadows: [Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 2, offset: const Offset(0,1))]
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'O usa biometría',
                          style: TextStyle(color: Colors.grey.shade100, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ]),

                    const SizedBox(height: 15), 

                    // BOTÓN BIOMETRÍA COMPACTO
                    InkWell(
                      onTap: _checkBiometrics,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(10), 
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: salufitGreen.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child:
                            Icon(Icons.fingerprint, size: 32, color: salufitGreen), 
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Toca para validar',
                      style: TextStyle(color: Colors.grey.shade100, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}