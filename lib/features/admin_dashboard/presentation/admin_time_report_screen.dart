import 'package:flutter/material.dart';

class AdminTimeReportScreen extends StatefulWidget {
  const AdminTimeReportScreen({super.key});
  @override
  State<AdminTimeReportScreen> createState() => _AdminTimeReportScreenState();
}

class _AdminTimeReportScreenState extends State<AdminTimeReportScreen> {
  // Corregido: Se eliminan campos y imports no usados para limpiar los 12 errores de linter
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 60, color: Colors.white70),
            SizedBox(height: 20),
            Text(
              'Módulo de Informes de Jornada',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text(
                'Aquí se generarán los informes PDF para RRHH una vez se sincronicen los fichajes de los profesionales.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
