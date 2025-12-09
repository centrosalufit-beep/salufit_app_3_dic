import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 Necesario para Log Out
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'login_screen.dart'; // Asegúrate de importar tu login

class TermsAcceptanceScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const TermsAcceptanceScreen({super.key, required this.userId, required this.userRole});

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _isLoading = false;

  final Uri _urlPrivacidad = Uri.parse('https://www.centrosalufit.com/politica-de-privacidad');
  final Uri _urlTerminos = Uri.parse('https://www.centrosalufit.com/terminos-y-condiciones');

  Future<void> _abrirWeb(Uri url) async {
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
        }
      }
    } catch (e) {
      debugPrint('Error lanzando URL: $e');
    }
  }

  /// 🚪 Función de Salida de Emergencia (Rompe el bucle)
  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _guardarConsentimiento() async {
    if (!_acceptedTerms || !_acceptedPrivacy) return;

    setState(() { _isLoading = true; });

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      final docSnap = await docRef.get();

      // DATOS BASE
      final Map<String, dynamic> dataToSave = {
        'termsAccepted': true,
        'privacyAccepted': true,
        'consentVersion': 'v1.0', 
        'consentDate': FieldValue.serverTimestamp(),
        'deviceInfo': 'App Mobile',
      };

      // 🛡️ LÓGICA DE AUTOCORRECCIÓN:
      // Si el documento NO existe, significa que es un usuario nuevo (o borrado).
      // Las reglas exigen que si creas tu propio doc, DEBES tener rol 'cliente'.
      if (!docSnap.exists) {
        dataToSave['rol'] = 'cliente'; // Forzamos el rol para pasar la regla de seguridad
        dataToSave['email'] = FirebaseAuth.instance.currentUser?.email ?? ''; // Útil tenerlo
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
      }

      // Usamos set con merge. Si no existe, lo crea con los datos de arriba.
      await docRef.set(dataToSave, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          // Pasamos 'cliente' o el rol que tuviera, para evitar nulos
          MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId, userRole: dataToSave['rol'] ?? widget.userRole)),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Error al guardar. Contacta con soporte.';
        if (e.toString().contains('permission-denied')) {
           msg = '⛔ Permiso denegado. Revisa las reglas de Firestore.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos WillPopScope (o PopScope en Flutter nuevo) para controlar el botón "Atrás" físico
    return PopScope(
      canPop: false, // Bloqueamos el "Atrás" nativo para evitar cerrar la app sin querer
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Opcional: Mostrar aviso o no hacer nada (obligando a usar los botones de la UI)
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finalizar Registro', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Quitamos la flecha de atrás automática
          actions: [
            // BOTÓN SALIDA DE EMERGENCIA
            TextButton.icon(
              onPressed: _cerrarSesion, 
              icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
              label: const Text('Salir', style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.security, size: 60, color: Colors.teal),
                const SizedBox(height: 20),
                const Text(
                  'Protección de Datos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Para garantizar la seguridad de tus datos médicos y cumplir con la normativa vigente, necesitamos tu consentimiento explícito antes de continuar.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                
                // CHECK 1: PRIVACIDAD
                CheckboxListTile(
                  value: _acceptedPrivacy,
                  activeColor: Colors.teal,
                  onChanged: (v) => setState(() => _acceptedPrivacy = v!),
                  title: GestureDetector(
                    onTap: () => _abrirWeb(_urlPrivacidad),
                    child: const Text.rich(
                      TextSpan(text: 'He leído y acepto la ', children: [
                        TextSpan(text: 'Política de Privacidad', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        TextSpan(text: ' (Tratamiento de datos de salud).'),
                      ]),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),

                // CHECK 2: TÉRMINOS
                CheckboxListTile(
                  value: _acceptedTerms,
                  activeColor: Colors.teal,
                  onChanged: (v) => setState(() => _acceptedTerms = v!),
                  title: GestureDetector(
                    onTap: () => _abrirWeb(_urlTerminos),
                    child: const Text.rich(
                      TextSpan(text: 'Acepto los ', children: [
                        TextSpan(text: 'Términos y Condiciones', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        TextSpan(text: ' del servicio Salufit.'),
                      ]),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (_acceptedPrivacy && _acceptedTerms) ? _guardarConsentimiento : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('ACEPTAR Y CONTINUAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _cerrarSesion,
                    child: const Text('Cancelar y usar otra cuenta', style: TextStyle(color: Colors.grey)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}