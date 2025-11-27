import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'activation_screen.dart';
import 'terms_acceptance_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _canCheckBiometrics = false; 
  bool _hasStoredCredentials = false; 

  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  
  final Uri _urlPrivacidad = Uri.parse('https://www.centrosalufit.com/politica-de-privacidad');

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheck = false;
    try {
      canCheck = await auth.canCheckBiometrics;
    } catch (e) { /* Ignore */ }

    String? storedEmail = await storage.read(key: 'user_email');
    String? storedPass = await storage.read(key: 'user_pass');

    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
        _hasStoredCredentials = (storedEmail != null && storedPass != null);
      });
    }
  }

  Future<void> _abrirPrivacidad() async {
    if (!await launchUrl(_urlPrivacidad, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la web')));
      }
    }
  }

  Future<void> _loginBiometrico() async {
    try {
      final bool authenticated = await auth.authenticate(
        localizedReason: 'Accede a tu cuenta Salufit',
      );

      if (authenticated) {
        String? email = await storage.read(key: 'user_email');
        String? pass = await storage.read(key: 'user_pass');

        if (email != null && pass != null) {
          _emailController.text = email;
          _passwordController.text = pass;
          _login(isBiometric: true); 
        }
      }
    } catch (e) {
       debugPrint("Biometría cancelada o fallida: $e");
    }
  }

  Future<void> _login({bool isBiometric = false}) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rellena los campos')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Autenticación
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // 2. Búsqueda segura por EMAIL
      final String emailBuscado = userCredential.user!.email!;

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailBuscado)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        await FirebaseAuth.instance.signOut(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encuentra ficha médica asociada.'), backgroundColor: Colors.red));
          setState(() { _isLoading = false; });
        }
        return;
      }

      final userDoc = query.docs.first;
      final String userId = userDoc.id; 
      final data = userDoc.data();
      final String rol = data['rol'] ?? 'cliente';
      final bool termsAccepted = data['termsAccepted'] == true;

      // 3. Guardar credenciales si aplica
      if (!isBiometric && _canCheckBiometrics && !_hasStoredCredentials) {
        if (mounted) _offerBiometricSave();
      }

      // 4. Muro Legal
      if (mounted) {
        if (termsAccepted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userId: userId, userRole: rol)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TermsAcceptanceScreen(userId: userId, userRole: rol)),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      String msg = 'Error de acceso';
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        msg = 'Email o contraseña incorrectos';
      } else if (e.code == 'invalid-email') {
        msg = 'El formato del email no es válido';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error técnico: $e'), backgroundColor: Colors.red));
        setState(() { _isLoading = false; });
      }
    }
  }

  void _offerBiometricSave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Activar Acceso Rápido?'),
        content: const Text('Podemos guardar tu contraseña de forma segura para que entres con Huella o FaceID la próxima vez.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () async {
              await storage.write(key: 'user_email', value: _emailController.text.trim());
              await storage.write(key: 'user_pass', value: _passwordController.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Activado!'), backgroundColor: Colors.green));
                _checkBiometrics(); 
              }
            },
            child: const Text('Sí, Activar')
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos Stack para apilar el fondo y el contenido
      body: Stack(
        children: [
          // 1. IMAGEN DE FONDO (Hormigón)
          Positioned.fill(
            child: Image.asset(
              'assets/login_bg.jpg', // Asegúrate de que el nombre coincida
              fit: BoxFit.cover, // Cubre toda la pantalla sin deformarse
            ),
          ),
          
          // 2. CAPA DE OSCURECIMIENTO SUTIL (Opcional, para mejorar contraste)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1), // Un 10% de negro sobre el hormigón
            ),
          ),

          // 3. CONTENIDO PRINCIPAL
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO NUEVO
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0), 
                    child: Image.asset(
                      'assets/login_logo.png', // Asegúrate de que el nombre coincida
                      height: 180, // Un poco más grande ya que incluye texto
                      fit: BoxFit.contain,
                      errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, size: 120, color: Colors.white),
                    ),
                  ),
                  
                  // TARJETA DEL FORMULARIO
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white, // Tarjeta blanca sobre fondo de hormigón
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        children: [
                          const Text(
                            'Bienvenido',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 5),
                          const Text("Inicia sesión en tu cuenta", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 30),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivationScreen())),
                              child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.teal)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _login(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal, 
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                          ),
                          if (_hasStoredCredentials && !_isLoading) ...[
                            const SizedBox(height: 25),
                            const Divider(),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _loginBiometrico,
                              child: Column(
                                children: [
                                  Icon(Icons.fingerprint, size: 50, color: Colors.teal.shade300),
                                  const Text('Entrar con Huella / FaceID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // BOTONES INFERIORES (Texto blanco sobre el fondo oscuro)
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivationScreen())),
                    child: const Text.rich(
                      TextSpan(
                        text: "¿Primera vez? ",
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(text: "Activa tu cuenta aquí", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))
                        ]
                      )
                    ),
                  ),
                  TextButton(
                    onPressed: _abrirPrivacidad,
                    child: const Text('Política de Privacidad', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}