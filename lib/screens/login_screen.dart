import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'activation_screen.dart';

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
  
  // Enlace a tu política de privacidad
  final Uri _urlPrivacidad = Uri.parse('https://www.centrosalufit.com/politica-de-privacidad');

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  // 1. Comprobar si el móvil tiene huella/cara y si hemos guardado datos antes
  Future<void> _checkBiometrics() async {
    bool canCheck = false;
    try {
      // Verificación simple compatible con todas las versiones
      canCheck = await auth.canCheckBiometrics;
    } catch (e) {
      // Ignoramos errores de hardware en silencio
    }

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

  // 2. Lógica de Login con Huella (SINTAXIS UNIVERSAL SIMPLIFICADA)
  Future<void> _loginBiometrico() async {
    try {
      // Esta llamada es la más compatible. Sin opciones extra que den error.
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
       print("Biometría cancelada o fallida: $e");
    }
  }

  // 3. Lógica de Login General
  Future<void> _login({bool isBiometric = false}) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rellena los campos')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // A. Autenticación contra Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // B. Buscar datos del usuario en Firestore (Base de Datos)
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Si entra en Auth pero no está en la BBDD de usuarios, es un error de integridad
        await FirebaseAuth.instance.signOut(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no encontrado en BBDD'), backgroundColor: Colors.red));
          setState(() { _isLoading = false; });
        }
        return;
      }

      final userDoc = query.docs.first;
      final String userId = userDoc.id; // ID tipo "000500"
      
      // Corrección: Casting seguro del mapa de datos
      final data = userDoc.data();
      final String rol = data['rol'] ?? 'cliente';

      // C. Ofrecer guardar huella si es la primera vez y el móvil lo soporta
      if (!isBiometric && _canCheckBiometrics && !_hasStoredCredentials) {
        if (mounted) _offerBiometricSave();
      }

      // D. Entrar a la App
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userId: userId, userRole: rol)),
        );
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
                _checkBiometrics(); // Refrescar para que aparezca el icono
              }
            },
            child: const Text('Sí, Activar')
          ),
        ],
      ),
    );
  }

  // --- DISEÑO ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // FONDO DEGRADADO CORPORATIVO
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF009688), Color(0xFF004D40)], // Teal claro a oscuro
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO TRANSPARENTE Y GRANDE
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0), 
                  child: Image.asset(
                    'assets/logo_salufit.png', // Asegúrate de tener este archivo
                    height: 160, 
                    fit: BoxFit.contain,
                    errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, size: 120, color: Colors.white),
                  ),
                ),
                
                // TARJETA DEL FORMULARIO
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white,
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

                        // EMAIL
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            filled: true,
                            fillColor: Colors.grey.shade50
                          ),
                        ),
                        const SizedBox(height: 20),

                        // CONTRASEÑA
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
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            filled: true,
                            fillColor: Colors.grey.shade50
                          ),
                        ),

                        // OLVIDÉ CONTRASEÑA
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivationScreen())),
                            child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.teal)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // BOTÓN LOGIN
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _login(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal, // Color corporativo
                              foregroundColor: Colors.white,
                              elevation: 5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),

                        // HUELLA
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
                
                // ACTIVACIÓN Y PRIVACIDAD (Fuera de la tarjeta)
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
      ),
    );
  }
}