import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  // Función para abrir la tienda (Android/iOS)
  // Si es Windows manual, puedes poner un link a tu Drive o web
  Future<void> _abrirTienda() async {
    final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.tuempresa.salufit'); // Pon aquí tu link real cuando lo tengas
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "Actualización Necesaria",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                "Hemos mejorado Salufit. Tu versión actual es antigua y ya no funciona correctamente.\n\nPor favor, actualiza para continuar.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _abrirTienda,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("DESCARGAR NUEVA VERSIÓN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}