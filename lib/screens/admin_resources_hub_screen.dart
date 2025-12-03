import 'package:flutter/material.dart';
// Imports corregidos (Ahora los archivos existen)
import 'admin_exercise_library_screen.dart';
import 'admin_upload_template_screen.dart';
import 'admin_patient_list_screen.dart';
import 'admin_patient_resources_screens.dart';

class AdminResourcesHubScreen extends StatelessWidget {
  const AdminResourcesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Centro de Recursos'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('¿Qué quieres añadir al sistema?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 20),
          _ResourceCard(icon: Icons.video_library, color: Colors.teal, title: 'Nuevo Ejercicio', subtitle: 'Biblioteca general.', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminExerciseLibraryScreen()))),
          const SizedBox(height: 15),
          _ResourceCard(icon: Icons.description, color: Colors.orange, title: 'Nueva Plantilla PDF', subtitle: 'Consentimientos vacíos.', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminUploadTemplateScreen()))),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          _ResourceCard(icon: Icons.person_search, color: Colors.blueGrey, title: 'Subir Radiografía / Receta', subtitle: 'Archivos privados para un paciente.', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPatientListScreen(viewerRole: 'admin', onUserSelected: (uid, name) {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPatientDocumentsScreen(userId: uid, userName: name, viewerRole: 'admin')));
                },
              )));
            },
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final IconData icon; final Color color; final String title; final String subtitle; final VoidCallback onTap;
  const _ResourceCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});
  @override Widget build(BuildContext context) {
    return Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 30, color: color)), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))])), const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)]))));
  }
}