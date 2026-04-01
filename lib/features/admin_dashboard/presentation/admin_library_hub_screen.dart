import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_exercise_library_screen.dart';

class AdminLibraryHubScreen extends StatefulWidget {
  const AdminLibraryHubScreen({super.key});
  @override
  State<AdminLibraryHubScreen> createState() => _AdminLibraryHubScreenState();
}

class _AdminLibraryHubScreenState extends State<AdminLibraryHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Librería Central', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.tealAccent,
          tabs: const [
            Tab(text: 'EJERCICIOS', icon: Icon(Icons.fitness_center, size: 20)),
            Tab(text: 'PLANTILLAS LEGALES', icon: Icon(Icons.gavel, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminExerciseLibraryScreen(),
          _ConsentTemplateTab(),
        ],
      ),
    );
  }
}

class _ConsentTemplateTab extends StatefulWidget {
  const _ConsentTemplateTab();
  @override
  State<_ConsentTemplateTab> createState() => _ConsentTemplateTabState();
}

class _ConsentTemplateTabState extends State<_ConsentTemplateTab> {
  bool _isUploading = false;

  Future<void> _uploadTemplate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final config = await _showTemplateConfigDialog(file.name.replaceAll('.pdf', ''));
    if (config == null) return;

    setState(() => _isUploading = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('consent_templates/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await ref.putFile(File(file.path!));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('consent_templates').add({
        'titulo': config['titulo'] as String,
        'urlPdf': url,
        'activo': true,
        'requiereDobleFirma': config['dobleFirma'] as bool,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla subida correctamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error upload template: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la plantilla'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<Map<String, dynamic>?> _showTemplateConfigDialog(String defaultName) async {
    final controller = TextEditingController(text: defaultName);
    var dobleFirma = false;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nueva plantilla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(), hintText: 'Ej: Consentimiento Cirugia'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: dobleFirma ? Colors.orange.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dobleFirma ? Colors.orange : Colors.grey.shade300),
                  ),
                  child: CheckboxListTile(
                    value: dobleFirma,
                    onChanged: (v) => setDialogState(() => dobleFirma = v!),
                    title: const Text('Requiere doble firma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(dobleFirma ? 'Profesional + Cliente (cirugia, anestesia)' : 'Solo firma del cliente', style: TextStyle(fontSize: 11, color: dobleFirma ? Colors.orange.shade700 : Colors.grey)),
                    activeColor: Colors.orange,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: controller.text.trim().isNotEmpty ? () => Navigator.pop(ctx, {'titulo': controller.text.trim(), 'dobleFirma': dobleFirma}) : null,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('GUARDAR', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTemplate(String docId, String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: const Text('Esta accion no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('consent_templates').doc(docId).delete();
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('consent_templates')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gavel, size: 60, color: Colors.white54),
                    SizedBox(height: 16),
                    Text('No hay plantillas de consentimiento', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text('Sube un PDF para empezar', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data()! as Map<String, dynamic>;
                final nombre = data.safeString('titulo').isNotEmpty ? data.safeString('titulo') : data.safeString('nombre');
                final url = data.safeString('urlPdf');
                final fecha = (data['fechaCreacion'] as Timestamp?)?.toDate();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.picture_as_pdf, color: Colors.red.shade400),
                    ),
                    title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: fecha != null
                        ? Text('Subida: ${DateFormat('dd/MM/yyyy').format(fecha)}', style: const TextStyle(fontSize: 11))
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                      onPressed: () => _deleteTemplate(doc.id, url),
                    ),
                  ),
                );
              },
            );
          },
        ),

        // FAB subir plantilla
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: _isUploading ? null : _uploadTemplate,
            backgroundColor: AppColors.primary,
            icon: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file, color: Colors.white),
            label: const Text('SUBIR PLANTILLA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
