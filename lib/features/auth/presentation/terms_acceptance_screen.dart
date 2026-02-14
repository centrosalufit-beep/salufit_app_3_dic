// lib/features/auth/presentation/terms_acceptance_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/features/auth/presentation/login_screen.dart';
// NOTA: Ya no necesitamos importar HomeScreen aquí, el AuthWrapper se encarga.
import 'package:url_launcher/url_launcher.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  const TermsAcceptanceScreen({
    required this.userId,
    required this.userRole,
    super.key,
  });

  final String userId;
  final String userRole;

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _isLoading = false;

  final Uri _urlPrivacidad =
      Uri.parse('https://www.centrosalufit.com/politica-de-privacidad');
  final Uri _urlTerminos =
      Uri.parse('https://www.centrosalufit.com/terminos-y-condiciones');

  Future<void> _abrirWeb(Uri url) async {
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error lanzando URL: $e');
    }
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    // Al cerrar sesión, el AuthWrapper detectará user==null y mostrará LoginScreen automáticamente.
    // Pero por seguridad forzamos la navegación limpia.
    if (mounted) {
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _guardarConsentimiento() async {
    if (!_acceptedTerms || !_acceptedPrivacy) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final emailActual = user?.email ?? '';

      final docRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);
      final docSnap = await docRef.get();

      // Datos legales a guardar
      final dataToSave = <String, dynamic>{
        'termsAccepted': true, // CRÍTICO: Esto desbloquea el AuthWrapper
        'privacyAccepted': true,
        'consentVersion': 'v1.0', // Versión de los términos aceptados
        'consentDate':
            FieldValue.serverTimestamp(), // Fecha legal de aceptación
        'deviceInfo': 'App Mobile',
        'email': emailActual, // Guardamos email como evidencia
      };

      // Si el usuario estaba incompleto, rellenamos mínimos
      if (!docSnap.exists ||
          (docSnap.data() != null && docSnap.data()!['rol'] == null)) {
        dataToSave['rol'] = 'cliente';
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
      }

      // Guardamos en Firestore
      await docRef.set(dataToSave, SetOptions(merge: true));

      // NO NAVEGAMOS MANUALMENTE.
      // Al actualizarse Firestore, el stream de 'main.dart' detectará el cambio
      // y cambiará esta pantalla por HomeScreen automáticamente.
    } catch (e) {
      if (mounted) {
        var msg = 'Error al guardar. Contacta con soporte.';
        if (e.toString().contains('permission-denied')) {
          msg = '⛔ Error de permisos. No se pudo guardar la aceptación.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope impide volver atrás (Android botón físico / Gesto iOS)
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title:
              const Text('Finalizar Registro', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Quita flecha atrás
          actions: <Widget>[
            TextButton.icon(
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
              label: const Text('Salir', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 60,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Protección de Datos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Para garantizar la seguridad de tus datos médicos y cumplir con la normativa vigente, necesitamos tu consentimiento explícito antes de continuar.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),

                // CHECKBOX 1: PRIVACIDAD
                CheckboxListTile(
                  value: _acceptedPrivacy,
                  activeColor: Colors.teal,
                  onChanged: (bool? v) => setState(() => _acceptedPrivacy = v!),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: GestureDetector(
                    onTap: () => _abrirWeb(_urlPrivacidad),
                    child: const Text.rich(
                      TextSpan(
                        text: 'He leído y acepto la ',
                        children: <InlineSpan>[
                          TextSpan(
                            text: 'Política de Privacidad',
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' (Tratamiento de datos de salud).'),
                        ],
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),

                // CHECKBOX 2: TÉRMINOS
                CheckboxListTile(
                  value: _acceptedTerms,
                  activeColor: Colors.teal,
                  onChanged: (bool? v) => setState(() => _acceptedTerms = v!),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: GestureDetector(
                    onTap: () => _abrirWeb(_urlTerminos),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Acepto los ',
                        children: <InlineSpan>[
                          TextSpan(
                            text: 'Términos y Condiciones',
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' del servicio Salufit.'),
                        ],
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    // Botón deshabilitado hasta que marque ambos
                    onPressed:
                        (_acceptedPrivacy && _acceptedTerms && !_isLoading)
                            ? _guardarConsentimiento
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ACEPTAR Y CONTINUAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _cerrarSesion,
                    child: const Text(
                      'Cancelar y usar otra cuenta',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
