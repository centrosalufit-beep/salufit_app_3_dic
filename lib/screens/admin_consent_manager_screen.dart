import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class AdminConsentManagerScreen extends StatefulWidget {
  const AdminConsentManagerScreen({super.key});

  @override
  State<AdminConsentManagerScreen> createState() => _AdminConsentManagerScreenState();
}

class _AdminConsentManagerScreenState extends State<AdminConsentManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _isUploading = false;

  // Variables para el Modal de Subida
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  File? _pdfSeleccionado;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  // ==========================================
  // 🗑️ LÓGICA DE ELIMINAR
  // ==========================================
  Future<void> _eliminarPlantilla(String docId, String pdfUrl) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Plantilla?'),
        content: const Text('Se borrará el PDF y nadie podrá firmarlo de nuevo.\nEsta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploading = true);

    try {
      // 1. Borrar de Firestore
      await FirebaseFirestore.instance.collection('consent_templates').doc(docId).delete();

      // 2. Borrar de Storage (El archivo PDF)
      try {
        await FirebaseStorage.instance.refFromURL(pdfUrl).delete();
      } catch (e) {
        debugPrint('El archivo en Storage ya no existía o hubo error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla eliminada correctamente'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ==========================================
  // ✏️ LÓGICA DE EDITAR (Solo Título)
  // ==========================================
  void _mostrarDialogoEditar(String docId, String tituloActual) {
    final TextEditingController editController = TextEditingController(text: tituloActual);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Título'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'Nombre del Consentimiento'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;

              await FirebaseFirestore.instance.collection('consent_templates').doc(docId).update({
                'titulo': editController.text.trim(),
              });

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Título actualizado'))
              );
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 🚀 LÓGICA DE SUBIDA (NUEVA)
  // ==========================================
  Future<void> _subirNuevaPlantilla(StateSetter setModalState) async {
    if (!_formKey.currentState!.validate()) return;
    if (_pdfSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes seleccionar un PDF')));
      return;
    }

    setModalState(() => _isUploading = true);

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

      if (!mounted) return;
      Navigator.pop(context); // Cerrar modal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantilla subida con éxito'), backgroundColor: Colors.green)
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setModalState(() => _isUploading = false);
    }
  }

  Future<void> _seleccionarPdf(StateSetter setModalState) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setModalState(() {
        _pdfSeleccionado = File(result.files.single.path!);
      });
    }
  }

  void _mostrarModalSubida() {
    _tituloController.clear();
    _pdfSeleccionado = null;
    _isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Para que el teclado no tape
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nueva Plantilla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Título (Ej: Consentimiento Capilar)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 20),
                      
                      // Selector de PDF
                      InkWell(
                        onTap: () => _seleccionarPdf(setModalState),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _pdfSeleccionado != null ? Colors.green.shade50 : Colors.orange.shade50,
                            border: Border.all(color: _pdfSeleccionado != null ? Colors.green : Colors.orange),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.picture_as_pdf, 
                                size: 40, 
                                color: _pdfSeleccionado != null ? Colors.green : Colors.orange
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _pdfSeleccionado != null 
                                  ? _pdfSeleccionado!.path.split('/').last 
                                  : 'Toca para seleccionar PDF',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _pdfSeleccionado != null ? Colors.green.shade900 : Colors.orange.shade900
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : () => _subirNuevaPlantilla(setModalState),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          child: _isUploading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('SUBIR PLANTILLA'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Buscar plantilla...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarModalSubida,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('consent_templates').orderBy('fechaCreacion', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final titulo = (data['titulo'] ?? '').toString().toLowerCase();
            return titulo.contains(_searchText);
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No hay plantillas de consentimiento.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange, 
                    child: Icon(Icons.description, color: Colors.white)
                  ),
                  title: Text(data['titulo'] ?? 'Sin Título', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Plantilla PDF', style: TextStyle(fontSize: 12)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _mostrarDialogoEditar(doc.id, data['titulo']);
                      if (value == 'delete') _eliminarPlantilla(doc.id, data['urlPdf']);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Renombrar')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Eliminar')])),
                    ],
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