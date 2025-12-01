import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';

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
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
      }
    }
  }

  Future<void> _guardarConsentimiento() async {
    if (!_acceptedTerms || !_acceptedPrivacy) return;

    setState(() { _isLoading = true; });

    try {
      // Guardamos la evidencia legal
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'termsAccepted': true,
        'privacyAccepted': true,
        'consentVersion': 'v1.0', // Cambia esto si actualizas los textos legales
        'consentDate': FieldValue.serverTimestamp(),
        'deviceInfo': 'App Mobile', // Podrías añadir info del dispositivo aquí
      });

      if (mounted) {
        // Pasamos a la App real
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId, userRole: widget.userRole)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
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
            ],
          ),
        ),
      ),
    );
  }
}