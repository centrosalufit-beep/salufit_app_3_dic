import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class AdminUploadTemplateScreen extends StatefulWidget {
  const AdminUploadTemplateScreen({super.key});

  @override
  State<AdminUploadTemplateScreen> createState() => _AdminUploadTemplateScreenState();
}

class _AdminUploadTemplateScreenState extends State<AdminUploadTemplateScreen> {
  final TextEditingController _tituloController = TextEditingController();
  File? _archivoSeleccionado;
  bool _isLoading = false;

  Future<void> _seleccionarPDF() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() {
        _archivoSeleccionado = File(result.files.single.path!);
        if (_tituloController.text.isEmpty) _tituloController.text = result.files.single.name.replaceAll('.pdf', '');
      });
    }
  }

  Future<void> _subirPlantilla() async {
    if (_tituloController.text.isEmpty || _archivoSeleccionado == null) return;
    setState(() => _isLoading = true);
    try {
      final String fileName = 'plantilla_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final Reference ref = FirebaseStorage.instance.ref().child('plantillas_globales/$fileName');
      await ref.putFile(_archivoSeleccionado!);
      final String url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('document_templates').add({
        'titulo': _tituloController.text.trim(),
        'urlPdf': url,
        'activo': true,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado'), backgroundColor: Colors.green)); }
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if(mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Plantilla'), backgroundColor: Colors.orange),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _tituloController, decoration: const InputDecoration(labelText: 'Título')),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _seleccionarPDF, child: Text(_archivoSeleccionado != null ? 'PDF Seleccionado' : 'Seleccionar PDF')),
        const Spacer(),
        ElevatedButton(onPressed: _isLoading ? null : _subirPlantilla, child: _isLoading ? const CircularProgressIndicator() : const Text('SUBIR'))
      ])),
    );
  }
}