import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/patient_document.dart';
import 'sign_document_screen.dart'; 
import '../widgets/salufit_scaffold.dart'; // <--- IMPORT NUEVO

class DocumentsScreen extends StatelessWidget {
  final String userId;
  const DocumentsScreen({super.key, required this.userId});

  Map<String, dynamic> _getDocVisuals(bool firmado) {
    if (firmado) {
      return {'colors': [const Color(0xFF43A047), const Color(0xFF66BB6A)], 'icon': Icons.task_alt, 'textColor': Colors.green.shade900, 'statusText': 'FIRMADO'};
    } else {
      return {'colors': [const Color(0xFFFB8C00), const Color(0xFFFFA726)], 'icon': Icons.history_edu, 'textColor': Colors.orange.shade900, 'statusText': 'PENDIENTE'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return const Center(child: Text("Error sesión"));

    return SalufitScaffold( // <--- CAMBIO A WIDGET CON FONDO
      appBar: AppBar(title: const Text('Mis Documentos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('userEmail', isEqualTo: userEmail)
            .orderBy('fechaCreacion', descending: true) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: SelectableText("Error Docs: ${snapshot.error}", style: const TextStyle(color: Colors.red))));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open, size: 60, color: Colors.grey.shade300), const SizedBox(height: 10), const Text('No tienes documentos pendientes', style: TextStyle(color: Colors.grey))]));
          }

          final docs = snapshot.data!.docs.map((doc) => PatientDocument.fromFirestore(doc)).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              final doc = docs[index];
              var visual = _getDocVisuals(doc.firmado);
              String fechaStr = doc.firmado && doc.fechaFirma != null ? "Firmado el ${DateFormat('dd/MM/yyyy').format(doc.fechaFirma!)}" : "Acción requerida";

              return Container(
                height: 110,
                decoration: BoxDecoration(gradient: LinearGradient(colors: visual['colors'] as List<Color>, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: (visual['colors'][0] as Color).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]),
                child: Stack(
                  children: [
                    Positioned(right: -15, bottom: -15, child: Icon(visual['icon'] as IconData, size: 120, color: Colors.white.withOpacity(0.15))),
                    Padding(padding: const EdgeInsets.all(15.0), child: Row(children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(visual['icon'] as IconData, color: Colors.white, size: 24)),
                        const SizedBox(width: 15),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(doc.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)), child: Text(visual['statusText'] as String, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))), const SizedBox(height: 2), Text(fechaStr, style: const TextStyle(fontSize: 11, color: Colors.white70))])),
                        if (!doc.firmado) ElevatedButton(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => SignDocumentScreen(userId: userId, documentId: doc.id, documentTitle: doc.titulo))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: visual['textColor'] as Color, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(80, 36)), child: const Text('FIRMAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))
                        else IconButton(icon: const Icon(Icons.visibility, color: Colors.white), tooltip: 'Ver Documento', onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visualizar PDF: Próximamente'))); })
                    ]))
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}