import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUploadTemplateScreen extends StatefulWidget {
  const AdminUploadTemplateScreen({super.key});

  @override
  State<AdminUploadTemplateScreen> createState() => _AdminUploadTemplateScreenState();
}

class _AdminUploadTemplateScreenState extends State<AdminUploadTemplateScreen> {
  final TextEditingController _tituloController = TextEditingController();
  File? _pdfSeleccionado;
  bool _isLoading = false;

  Future<void> _seleccionarPdf() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfSeleccionado = File(result.files.single.path!);
      });
    }
  }

  Future<void> _subirPlantilla() async {
    if (_pdfSeleccionado == null || _tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta título o archivo')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String fileName = 'templates/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(_pdfSeleccionado!);
      final String url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('consent_templates').add({
        'titulo': _tituloController.text.trim(),
        'urlPdf': url,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'activo': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plantilla subida'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Plantilla'), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: SafeArea( // CORRECCIÓN: Evita zonas muertas del móvil
        child: SingleChildScrollView( // CORRECCIÓN: Permite scroll si el teclado tapa
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sube un consentimiento vacío (PDF) para que luego se pueda firmar.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título del Consentimiento',
                  hintText: 'Ej: Consentimiento Trasplante Capilar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _seleccionarPdf,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange, width: 2, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 50, color: Colors.orange.shade800),
                      const SizedBox(height: 10),
                      Text(
                        _pdfSeleccionado != null ? 'PDF Seleccionado' : 'Toca para buscar PDF',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)
                      ),
                      if (_pdfSeleccionado != null)
                        Text(_pdfSeleccionado!.path.split('/').last, style: const TextStyle(fontSize: 12))
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _subirPlantilla,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('SUBIR PLANTILLA'),
                ),
              ),
              // Espacio extra para asegurar que el botón se ve
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}