import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

// PANTALLA 1: GESTIÓN DE DOCUMENTOS DEL PACIENTE
class AdminPatientDocumentsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String viewerRole;

  const AdminPatientDocumentsScreen({super.key, required this.userId, required this.userName, required this.viewerRole});

  @override
  State<AdminPatientDocumentsScreen> createState() => _AdminPatientDocumentsScreenState();
}

class _AdminPatientDocumentsScreenState extends State<AdminPatientDocumentsScreen> {
  bool _isUploading = false;

  Future<void> _subirArchivoPrivado() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null) {
      setState(() => _isUploading = true);
      try {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        Reference ref = FirebaseStorage.instance.ref().child('pacientes/${widget.userId}/documentos/$fileName');
        await ref.putFile(file);
        String url = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('documents').add({
          'userId': widget.userId,
          'titulo': fileName,
          'urlPdf': url,
          'tipo': 'Privado',
          'firmado': false,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subido correctamente'), backgroundColor: Colors.green));
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if(mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Docs: ${widget.userName}'), backgroundColor: Colors.orange),
      floatingActionButton: FloatingActionButton(onPressed: _subirArchivoPrivado, child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('documents').where('userId', isEqualTo: widget.userId).orderBy('fechaCreacion', descending: true).snapshots(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          if (s.data!.docs.isEmpty) return const Center(child: Text('Sin documentos'));
          return ListView.builder(
            itemCount: s.data!.docs.length,
            itemBuilder: (c, i) {
              var d = s.data!.docs[i];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(d['titulo']),
                subtitle: Text(d['tipo'] ?? 'General'),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => d.reference.delete()),
              );
            },
          );
        },
      ),
    );
  }
}

// PANTALLA 2: GESTIÓN DE MATERIAL DEL PACIENTE
class AdminPatientMaterialScreen extends StatelessWidget {
  final String userId;
  final String userName;
  const AdminPatientMaterialScreen({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Material: $userName'), backgroundColor: Colors.indigo),
      body: const Center(child: Text('Gestión de ejercicios asignados (Use el botón en detalle de paciente)')),
    );
  }
}