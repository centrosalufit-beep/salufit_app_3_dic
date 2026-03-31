import 'package:flutter/material.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_edit_time_records_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_time_report_screen.dart';

class AdminRRHHScreen extends StatelessWidget {
  const AdminRRHHScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // UNIFICACIÓN FONDOS: Forzar transparencia (AQUÍ ESTABA EL FALLO PRINCIPAL)
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          // CORRECCIÓN: Gestión
          title: const Text(
            'Gestión de RRHH',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.tealAccent,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white70,
            tabs: <Widget>[
              Tab(icon: Icon(Icons.summarize), text: 'DESCARGAR INFORMES'),
              Tab(icon: Icon(Icons.edit_calendar), text: 'CORREGIR FICHES'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            // Aseguramos que las pantallas hijas hereden transparencia si es necesario
            AdminTimeReportScreen(),
            AdminEditTimeRecordsScreen(),
          ],
        ),
      ),
    );
  }
}
