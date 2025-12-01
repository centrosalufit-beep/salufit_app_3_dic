import 'package:flutter/material.dart';
import 'material_screen.dart'; // Reutilizamos la pantalla de vídeos
import 'documents_screen.dart'; // Reutilizamos la pantalla de docs

class ProfessionalResourcesScreen extends StatelessWidget {
  final String userId;

  const ProfessionalResourcesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Usamos DefaultTabController para gestionar las pestañas superiores
    return DefaultTabController(
      length: 2, // Dos pestañas: Docs y Material
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Recursos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: [
              Tab(icon: Icon(Icons.folder_open), text: 'Documentos'),
              Tab(icon: Icon(Icons.play_circle_outline), text: 'Material / Vídeos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña 1: Documentos (Reutilizamos el widget que ya creamos)
            // OJO: DocumentsScreen tiene su propio Scaffold/AppBar. 
            // Al meterlo aquí, podría duplicarse la barra. 
            // Lo ideal es refactorizar, pero para ir rápido, Flutter suele gestionarlo bien
            // o podemos envolverlo en un Navigator, pero probemos directo.
            DocumentsScreen(userId: userId),
            
            // Pestaña 2: Material (Vídeos)
            MaterialScreen(userId: userId),
          ],
        ),
      ),
    );
  }
}