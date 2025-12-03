import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminExerciseLibraryScreen extends StatefulWidget {
  const AdminExerciseLibraryScreen({super.key});

  @override
  State<AdminExerciseLibraryScreen> createState() => _AdminExerciseLibraryScreenState();
}

class _AdminExerciseLibraryScreenState extends State<AdminExerciseLibraryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _ordenController = TextEditingController();
  
  String _selectedFamily = 'Entrenamiento';
  final List<String> _familias = ['Fisioterapia', 'Psicología', 'Odontología', 'Entrenamiento', 'Nutrición'];

  File? _archivoSeleccionado;
  bool _isVideo = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sugerirSiguienteNumero();
  }

  Future<void> _sugerirSiguienteNumero() async {
    final query = await FirebaseFirestore.instance.collection('exercises').orderBy('orden', descending: true).limit(1).get();
    if (query.docs.isNotEmpty) {
      final ultimo = query.docs.first.data()['orden'] as int;
      setState(() => _ordenController.text = (ultimo + 1).toString());
    } else {
      setState(() => _ordenController.text = '1');
    }
  }

  Future<void> _seleccionarArchivo(bool video) async {
    final picker = ImagePicker();
    final XFile? pickedFile;
    if (video) {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    }
    if (pickedFile != null) {
      setState(() {
        _archivoSeleccionado = File(pickedFile!.path);
        _isVideo = video;
      });
    }
  }

  Future<void> _procesarGuardado() async {
    if (!_formKey.currentState!.validate()) return;
    if (_archivoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta vídeo/foto')));
      return;
    }

    final int ordenDeseado = int.parse(_ordenController.text);
    setState(() => _isLoading = true);

    try {
      final queryOcupado = await FirebaseFirestore.instance.collection('exercises').where('orden', isEqualTo: ordenDeseado).get();

      if (queryOcupado.docs.isNotEmpty) {
        if (mounted) {
          bool? confirm = await showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Posición ocupada'),
              content: const Text('¿Quieres mover los ejercicios siguientes para hacer hueco?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, mover')),
              ],
            )
          );
          if (confirm != true) { setState(() => _isLoading = false); return; }
          await _guardarConDesplazamiento(ordenDeseado);
        }
      } else {
        await _guardarFinal(ordenDeseado);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarConDesplazamiento(int ordenInicial) async {
    final String urlMedia = await _subirArchivo();
    final batch = FirebaseFirestore.instance.batch();
    final query = await FirebaseFirestore.instance.collection('exercises').where('orden', isGreaterThanOrEqualTo: ordenInicial).orderBy('orden', descending: true).get();

    for (var doc in query.docs) {
      final int actual = doc.data()['orden'];
      batch.update(doc.reference, {'orden': actual + 1});
    }

    final docRef = FirebaseFirestore.instance.collection('exercises').doc();
    batch.set(docRef, {
      'nombre': _nombreController.text.trim(),
      'familia': _selectedFamily,
      'orden': ordenInicial,
      'urlVideo': urlMedia,
      'tipoArchivo': _isVideo ? 'video' : 'imagen',
      'codigoInterno': ordenInicial,
      'creadoEn': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    _finalizarExito();
  }

  Future<void> _guardarFinal(int orden) async {
    final String urlMedia = await _subirArchivo();
    await FirebaseFirestore.instance.collection('exercises').add({
      'nombre': _nombreController.text.trim(),
      'familia': _selectedFamily,
      'orden': orden,
      'urlVideo': urlMedia,
      'tipoArchivo': _isVideo ? 'video' : 'imagen',
      'codigoInterno': orden,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    _finalizarExito();
  }

  Future<String> _subirArchivo() async {
    final String ext = _archivoSeleccionado!.path.split('.').last;
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final Reference storageRef = FirebaseStorage.instance.ref().child('ejercicios/$fileName');
    await storageRef.putFile(_archivoSeleccionado!);
    return await storageRef.getDownloadURL();
  }

  void _finalizarExito() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado correctamente'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Ejercicio'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(value: _selectedFamily, items: _familias.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(), onChanged: (v) => setState(() => _selectedFamily = v!)),
              const SizedBox(height: 20),
              TextFormField(controller: _ordenController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nº Orden')),
              const SizedBox(height: 20),
              TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: () => _seleccionarArchivo(false), child: const Text('FOTO'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () => _seleccionarArchivo(true), child: const Text('VÍDEO'))),
              ]),
              if (_archivoSeleccionado != null) Text('Archivo: ${_archivoSeleccionado!.path.split('/').last}'),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _procesarGuardado, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR')))
            ],
          ),
        ),
      ),
    );
  }
}