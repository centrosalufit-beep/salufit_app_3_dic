import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para obtener ID del staff actual
import 'admin_exercise_library_screen.dart'; 

// ============================================================================
// PANTALLA 1: GESTIÓN DE DOCUMENTOS DEL PACIENTE
// ============================================================================
class AdminPatientDocumentsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String viewerRole;

  const AdminPatientDocumentsScreen({
    super.key, 
    required this.userId, 
    required this.userName, 
    required this.viewerRole
  });

  @override
  State<AdminPatientDocumentsScreen> createState() => _AdminPatientDocumentsScreenState();
}

class _AdminPatientDocumentsScreenState extends State<AdminPatientDocumentsScreen> {
  bool _isUploading = false;

  void _mostrarOpcionesSubida() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
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
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null) {
      await _procesarSubida(File(photo.path), photo.name);
    }
  }

  Future<void> _seleccionarArchivoExistente() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg']
    );
    if (result != null) {
      await _procesarSubida(File(result.files.single.path!), result.files.single.name);
    }
  }

  Future<void> _procesarSubida(File file, String fileName) async {
    setState(() => _isUploading = true);
    try {
      // 🔒 CORRECCIÓN SEGURIDAD:
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('documentos_pacientes/${widget.userId}/$fileName');
          
      await ref.putFile(file);
      final String url = await ref.getDownloadURL();

      // Obtenemos el email para las reglas de seguridad
      String userEmail = '';
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
        if (userDoc.exists) {
          userEmail = userDoc.data()?['email'] ?? '';
        }
      } catch (e) {
        debugPrint('No se pudo obtener el email del usuario.');
      }

      await FirebaseFirestore.instance.collection('documents').add({
        'userId': widget.userId,
        'userEmail': userEmail, // Vital para que el paciente lo vea
        'titulo': fileName,
        'urlPdf': url,
        'tipo': 'Privado',
        'firmado': false,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subido correctamente'), backgroundColor: Colors.green));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Docs: ${widget.userName}'), backgroundColor: Colors.orange),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _mostrarOpcionesSubida,
        child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('documents')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('fechaCreacion', descending: true)
            .snapshots(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          if (s.data!.docs.isEmpty) return const Center(child: Text('Sin documentos'));
          
          return ListView.builder(
            itemCount: s.data!.docs.length,
            itemBuilder: (c, i) {
              final d = s.data!.docs[i];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(d['titulo']),
                subtitle: Text(d['tipo'] ?? 'General'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red), 
                  onPressed: () => d.reference.delete()
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// PANTALLA 2: GESTIÓN DE MATERIAL (PAUTA DE EJERCICIOS)
// ============================================================================
class AdminPatientMaterialScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const AdminPatientMaterialScreen({super.key, required this.userId, required this.userName});

  @override
  State<AdminPatientMaterialScreen> createState() => _AdminPatientMaterialScreenState();
}

class _AdminPatientMaterialScreenState extends State<AdminPatientMaterialScreen> {
  
  // Abrir la librería para seleccionar ejercicios
  void _abrirAsignador() async {
    // 1. OBTENER EMAIL DEL PACIENTE (Vital para las nuevas reglas de seguridad)
    // Como no lo tenemos en el constructor, lo buscamos un momento.
    String userEmail = '';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        userEmail = userDoc.data()?['email'] ?? '';
      }
    } catch (e) {
      debugPrint('Error buscando email: $e');
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminExerciseLibraryScreen(
          isSelectionMode: true, // MODO SELECCIÓN ACTIVADO
          onExercisesSelected: (selectedList) async {
            
            final batch = FirebaseFirestore.instance.batch();
            final String currentStaffId = FirebaseAuth.instance.currentUser?.uid ?? 'Admin';
            
            for (var ex in selectedList) {
              // 2. CAMBIO CRÍTICO: Guardamos en la colección GLOBAL 'exercise_assignments'
              // Antes se guardaba en users/{id}/assignedExercises (sitio incorrecto)
              final docRef = FirebaseFirestore.instance
                  .collection('exercise_assignments') 
                  .doc(); // Auto ID
              
              batch.set(docRef, {
                'id': docRef.id,
                'userId': widget.userId,
                'userEmail': userEmail, // <--- CAMPO OBLIGATORIO NUEVO
                
                // Datos del ejercicio
                'exerciseId': ex['id'],
                'nombre': ex['nombre'],
                'urlVideo': ex['urlVideo'],
                
                // Metadatos
                'fechaAsignacion': DateTime.now().toIso8601String(), // String ISO para evitar líos de Timestamp
                'asignadoEl': FieldValue.serverTimestamp(),
                'completado': false,
                'profesionalId': currentStaffId,
              });
            } 

            await batch.commit();

            // 3. SEGURIDAD DE CONTEXTO: Verificamos si la pantalla sigue viva
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${selectedList.length} ejercicios asignados correctamente'))
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pauta: ${widget.userName}'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirAsignador,
        label: const Text('Asignar Ejercicios'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 4. CAMBIO DE LECTURA: Leemos de la colección GLOBAL
        // Así el Admin ve exactamente lo mismo que verá el cliente en su app.
        stream: FirebaseFirestore.instance
            .collection('exercise_assignments') // <--- CAMBIO AQUÍ
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;

          // Ordenamos en memoria para evitar errores de índices faltantes en Firebase
          // (Lo más nuevo arriba)
          docs.sort((a, b) {
             final dataA = a.data() as Map<String, dynamic>;
             final dataB = b.data() as Map<String, dynamic>;
             
             // Intentamos usar asignadoEl (Timestamp) o fechaAsignacion (String)
             DateTime dateA = DateTime(1970);
             DateTime dateB = DateTime(1970);

             if (dataA['asignadoEl'] is Timestamp) {
               dateA = (dataA['asignadoEl'] as Timestamp).toDate();
             } else if (dataA['fechaAsignacion'] is String) {
               dateA = DateTime.tryParse(dataA['fechaAsignacion']) ?? DateTime(1970);
             }

             if (dataB['asignadoEl'] is Timestamp) {
               dateB = (dataB['asignadoEl'] as Timestamp).toDate();
             } else if (dataB['fechaAsignacion'] is String) {
               dateB = DateTime.tryParse(dataB['fechaAsignacion']) ?? DateTime(1970);
             }

             return dateB.compareTo(dateA);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, size: 50, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text('${widget.userName} no tiene ejercicios asignados.', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  const Text('Pulsa el botón "Asignar" para empezar.')
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              // Helper para mostrar la fecha bonita
              String fechaStr = 'Reciente';
              if (data['fechaAsignacion'] != null && data['fechaAsignacion'] is String) {
                 try {
                   final d = DateTime.parse(data['fechaAsignacion']);
                   fechaStr = '${d.day}/${d.month}/${d.year}';
                 } catch (_) {}
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.play_arrow, color: Colors.white)),
                  title: Text(data['nombre'] ?? 'Ejercicio'),
                  subtitle: Text('Asignado: $fechaStr'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Borra directamente de la colección global
                      docs[index].reference.delete();
                    },
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