import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; 

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  
  bool _politicaAceptada = false;

  final String _activarUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/activarCuenta';
  final Uri _urlPrivacidad = Uri.parse('https://www.centrosalufit.com/politica-de-privacidad');

  Future<void> _abrirPrivacidad() async {
    if (!await launchUrl(_urlPrivacidad, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la web')));
      }
    }
  }

  Future<void> _activar() async {
    if (!_politicaAceptada) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes aceptar la Política de Privacidad'), backgroundColor: Colors.orange));
       return;
    }

    if (_idController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rellena todos los campos')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse(_activarUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _idController.text.trim(),
          'email': _emailController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('¡Email Enviado!', style: TextStyle(color: Colors.green)),
              content: const Text('Revisa tu correo. Hemos enviado un enlace para que crees tu contraseña.\n\nUna vez la tengas, vuelve aquí e inicia sesión con Email.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(c); 
                    Navigator.pop(context); 
                  },
                  child: const Text('Entendido')
                )
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activar Cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Para acceder por primera vez, introduce tu número de historia y tu email registrado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número de Historia / ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
            ),
            
            const SizedBox(height: 20),

            // --- CHECKBOX DE PRIVACIDAD ---
            Row(
              children: [
                Checkbox(
                  value: _politicaAceptada,
                  onChanged: (val) => setState(() => _politicaAceptada = val!),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _abrirPrivacidad,
                    child: const Text.rich(
                      TextSpan(
                        text: 'He leído y acepto la ',
                        style: TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Política de Privacidad',
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' de Salufit.'),
                        ]
                      ),
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _activar,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ENVIAR ENLACE DE ACTIVACIÓN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}