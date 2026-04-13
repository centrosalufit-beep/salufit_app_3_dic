import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_exercise_library_screen.dart';

// PANTALLA 1: GESTIÃ“N DE DOCUMENTOS DEL PACIENTE
class AdminPatientDocumentsScreen extends StatefulWidget {
  const AdminPatientDocumentsScreen({
    required this.userId,
    required this.userName,
    required this.viewerRole,
    super.key,
  });
  final String userId;
  final String userName;
  final String viewerRole;

  @override
  State<AdminPatientDocumentsScreen> createState() =>
      _AdminPatientDocumentsScreenState();
}

class _AdminPatientDocumentsScreenState
    extends State<AdminPatientDocumentsScreen> {
  bool _isUploading = false;

  void _mostrarOpcionesSubida() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Hacer foto (Receta/Papel)'),
              onTap: () {
                Navigator.pop(context);
                _tomarFotoCamara();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Subir Archivo (PDF/Imagen)'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarArchivoExistente();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tomarFotoCamara() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null) {
      await _procesarSubida(File(photo.path), photo.name);
    }
  }

  Future<void> _seleccionarArchivoExistente() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'jpg', 'png', 'jpeg'],
    );
    if (result != null) {
      await _procesarSubida(
        File(result.files.single.path!),
        result.files.single.name,
      );
    }
  }

  Future<void> _procesarSubida(File file, String fileName) async {
    setState(() => _isUploading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('documentos_pacientes/${widget.userId}/$fileName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      var userEmail = '';
      try {
        // FIX LÍNEA 101: Eliminado .where() para permitir el uso de .doc()
        final userDoc = await FirebaseFirestore.instance
            .collection('users_app')
            .doc(widget.userId)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          userEmail = data.safeString('email');
        }
      } catch (e) {
        debugPrint('No se pudo obtener el email del usuario.');
      }

      await FirebaseFirestore.instance
          .collection('documents')
          .add(<String, dynamic>{
        'userId': widget.userId,
        'userEmail': userEmail,
        'titulo': fileName,
        'urlPdf': url,
        'tipo': 'Privado',
        'firmado': false,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subido correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Docs: ${widget.userName}'),
        backgroundColor: Colors.orange,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _mostrarOpcionesSubida,
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (BuildContext c, AsyncSnapshot<QuerySnapshot<Object?>> s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.data!.docs.isEmpty) {
            return const Center(child: Text('Sin documentos'));
          }

          return ListView.builder(
            itemCount: s.data!.docs.length,
            itemBuilder: (BuildContext c, int i) {
              final d = s.data!.docs[i];
              final data = d.data() as Map<String, dynamic>?;
              final titulo = data.safeString('titulo');
              final tipo = data.safeString('tipo', defaultValue: 'General');

              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(titulo),
                subtitle: Text(tipo),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => d.reference.delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// PANTALLA 2: GESTIÃ“N DE MATERIAL (PAUTA DE EJERCICIOS)
class AdminPatientMaterialScreen extends StatefulWidget {
  const AdminPatientMaterialScreen({
    required this.userId,
    required this.userName,
    super.key,
  });
  final String userId;
  final String userName;

  @override
  State<AdminPatientMaterialScreen> createState() =>
      _AdminPatientMaterialScreenState();
}

class _AdminPatientMaterialScreenState
    extends State<AdminPatientMaterialScreen> {
  Future<void> _abrirAsignador() async {
    var userEmail = '';
    try {
      // FIX LÍNEA 218: Eliminado .where() para permitir el uso de .doc()
      final userDoc = await FirebaseFirestore.instance
          .collection('users_app')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        userEmail = data.safeString('email');
      }
    } catch (e) {
      debugPrint('Error buscando email: $e');
    }

    if (!mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => AdminExerciseLibraryScreen(
          isSelectionMode: true,
          onExercisesSelected: (List<Map<String, dynamic>> selectedList) async {
            final batch = FirebaseFirestore.instance.batch();
            final currentStaffId =
                FirebaseAuth.instance.currentUser?.uid ?? 'Admin';

            for (final ex in selectedList) {
              final docRef = FirebaseFirestore.instance
                  .collection('exercise_assignments')
                  .doc();

              final exerciseId = (ex['id'] ?? '').toString();
              final nombre = (ex['nombre'] ?? '').toString();
              final urlVideo = (ex['urlVideo'] ?? '').toString();
              final familia = (ex['familia'] ?? 'Entrenamiento').toString();
              final codigoInterno = (ex['codigoInterno'] as int?) ?? 0;

              batch.set(docRef, <String, Object>{
                'id': docRef.id,
                'userId': widget.userId,
                'userEmail': userEmail,
                'exerciseId': exerciseId,
                'nombre': nombre,
                'urlVideo': urlVideo,
                'familia': familia,
                'codigoInterno': codigoInterno,
                'fechaAsignacion': DateTime.now().toIso8601String(),
                'asignadoEl': FieldValue.serverTimestamp(),
                'completado': false,
                'profesionalId': currentStaffId,
              });
            }

            await batch.commit();

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${selectedList.length} ejercicios asignados correctamente',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pauta: ${widget.userName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirAsignador,
        label: const Text('Asignar Ejercicios'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exercise_assignments')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot<Object?>> snapshot,
        ) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs
            ..sort((
              QueryDocumentSnapshot<Object?> a,
              QueryDocumentSnapshot<Object?> b,
            ) {
              final dataA = a.data()! as Map<String, dynamic>;
              final dataB = b.data()! as Map<String, dynamic>;

              var dateA = DateTime(1970);
              var dateB = DateTime(1970);

              if (dataA['asignadoEl'] is Timestamp) {
                dateA = (dataA['asignadoEl'] as Timestamp).toDate();
              } else if (dataA['fechaAsignacion'] is String) {
                dateA = DateTime.tryParse(dataA['fechaAsignacion'] as String) ??
                    DateTime(1970);
              }

              if (dataB['asignadoEl'] is Timestamp) {
                dateB = (dataB['asignadoEl'] as Timestamp).toDate();
              } else if (dataB['fechaAsignacion'] is String) {
                dateB = DateTime.tryParse(dataB['fechaAsignacion'] as String) ??
                    DateTime(1970);
              }

              return dateB.compareTo(dateA);
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.fitness_center,
                    size: 50,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.userName} no tiene ejercicios.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text('Pulsa "Asignar" para empezar.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: docs.length,
            itemBuilder: (BuildContext context, int index) {
              final data = docs[index].data()! as Map<String, dynamic>;
              final nombre =
                  data.safeString('nombre', defaultValue: 'Ejercicio');
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  title: Text(nombre),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => docs[index].reference.delete(),
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
