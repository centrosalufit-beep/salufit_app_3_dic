import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/patient_document.dart';
import 'sign_document_screen.dart'; 

class DocumentsScreen extends StatelessWidget {
  final String userId;

  const DocumentsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // 1. Lógica de IDs Robusta (Igual que en el panel profesional)
    String idConCeros = userId.padLeft(6, '0');
    String idSinCeros = userId.replaceFirst(RegExp(r'^0+'), '');
    List<dynamic> posiblesIds = [idConCeros, idSinCeros];
    if (int.tryParse(idSinCeros) != null) posiblesIds.add(int.parse(idSinCeros));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Mis Documentos", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('userId', whereIn: posiblesIds) // Buscamos por todas las variantes de ID
            .orderBy('fechaCreacion', descending: true) // COINCIDE CON EL ÍNDICE QUE YA TIENES ✅
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Si sigue fallando, nos lo dirá aquí
            return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error de conexión o índice: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
            ));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("No tienes documentos pendientes", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs.map((doc) => PatientDocument.fromFirestore(doc)).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              final doc = docs[index];
              
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: doc.firmado ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      doc.firmado ? Icons.check_circle : Icons.draw, 
                      color: doc.firmado ? Colors.green : Colors.orange
                    ),
                  ),
                  title: Text(doc.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(doc.tipo.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      if (doc.firmado && doc.fechaFirma != null)
                        Text("Firmado el ${DateFormat('dd/MM/yyyy').format(doc.fechaFirma!)}", style: const TextStyle(fontSize: 12, color: Colors.green)),
                      if (!doc.firmado)
                        const Text("Pendiente de firma", style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: doc.firmado 
                    ? IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.grey),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Visualizar PDF: Próximamente")));
                        },
                      )
                    : ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignDocumentScreen(
                                userId: userId,
                                documentId: doc.id,
                                documentTitle: doc.titulo,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                        ),
                        child: const Text("FIRMAR"),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}