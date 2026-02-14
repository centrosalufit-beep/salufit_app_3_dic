import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class AdminExerciseLibraryScreen extends StatefulWidget {
  const AdminExerciseLibraryScreen({
    super.key,
    this.isSelectionMode = false,
    this.onExercisesSelected,
  });
  final bool isSelectionMode;
  final void Function(List<Map<String, dynamic>>)? onExercisesSelected;

  @override
  State<AdminExerciseLibraryScreen> createState() =>
      _AdminExerciseLibraryScreenState();
}

class _AdminExerciseLibraryScreenState
    extends State<AdminExerciseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String _filtroFamilia = 'Todas';
  final List<String> _familiasFiltro = <String>[
    'Todas',
    'Fisioterapia',
    'Psicología',
    'Odontología',
    'Entrenamiento',
    'Nutrición',
    'Cervical',
    'Lumbar',
    'Hombro',
    'Rodilla',
    'Cadera',
    'Tobillo',
  ];
  final Set<String> _selectedIds = <String>{};
  final List<Map<String, dynamic>> _selectedExercises =
      <Map<String, dynamic>>[];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _ordenController = TextEditingController();

  String _selectedFamilyUpload = 'Entrenamiento';
  final List<String> _familiasUpload = <String>[
    'Fisioterapia',
    'Psicología',
    'Odontología',
    'Entrenamiento',
    'Nutrición',
    'Cervical',
    'Lumbar',
    'Hombro',
    'Rodilla',
    'Cadera',
    'Tobillo',
  ];
  File? _archivoSeleccionado;
  bool _isVideo = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase());
    });
  }

  Future<bool> _checkPermission(bool forVideo) async {
    if (Platform.isAndroid) {
      final permission = forVideo ? Permission.videos : Permission.photos;

      final status = await permission.request();

      if (status.isGranted || status.isLimited) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          _mostrarAlertaPermisos();
        }
        return false;
      }
      return false;
    }
    return true;
  }

  void _mostrarAlertaPermisos() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso denegado'),
        content: const Text(
          'Necesitamos acceso a tu galería para subir el ejercicio. Por favor, habilítalo en Ajustes.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(String id, Map<String, dynamic> data) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectedExercises
            .removeWhere((Map<String, dynamic> e) => e['id'] == id);
      } else {
        _selectedIds.add(id);
        final exerciseData = Map<String, dynamic>.from(data);
        exerciseData['id'] = id;
        _selectedExercises.add(exerciseData);
      }
    });
  }

  Future<void> _borrarTodaLaLibreria() async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('⚠️ PELIGRO: Borrar TODO'),
        content: const Text(
          '¿Estás seguro de que quieres BORRAR TODOS los ejercicios de la base de datos?\n\nEsta acción no se puede deshacer.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'BORRAR TODO',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm1 != true) return;

    if (!mounted) return;
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Confirmación final'),
        content: const Text(
          'Escribe "BORRAR" mentalmente y pulsa confirmar. Se eliminarán todas las referencias.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'CONFIRMAR',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm2 != true) return;

    setState(() => _isUploading = true);
    try {
      final instance = FirebaseFirestore.instance;
      final snapshot = await instance.collection('exercises').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base de datos limpiada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _iniciarSubidaMasiva() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: <String>['mp4', 'mov', 'avi', 'mkv'],
      );
      if (result == null || result.files.isEmpty) return;

      var familiaLote = 'Entrenamiento';

      if (!mounted) return;
      final continuar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c) => AlertDialog(
          title: Text('Subir ${result.files.length} vídeos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Se subirán con el nombre del archivo.'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: familiaLote,
                items: _familiasUpload
                    .map(
                      (String f) => DropdownMenuItem(value: f, child: Text(f)),
                    )
                    .toList(),
                onChanged: (String? v) => familiaLote = v!,
                decoration: const InputDecoration(
                  labelText: 'Asignar Familia a todos',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('EMPEZAR SUBIDA'),
            ),
          ],
        ),
      );
      if (continuar != true) return;

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _ProgressDialog(files: result.files, familia: familiaLote);
        },
      );
    } catch (e) {
      debugPrint('Error en subida masiva: $e');
    }
  }

  Future<void> _eliminarEjercicio(String docId) async {
    await FirebaseFirestore.instance
        .collection('exercises')
        .doc(docId)
        .delete();
  }

  Future<void> _sugerirSiguienteNumero() async {
    final query = await FirebaseFirestore.instance
        .collection('exercises')
        .orderBy('orden', descending: true)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      final ultimo = (data['orden'] is int) ? data['orden'] as int : 0;
      _ordenController.text = (ultimo + 1).toString();
    } else {
      _ordenController.text = '1';
    }
  }

  Future<void> _guardarNuevoEjercicio() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);
    try {
      var downloadUrl = '';
      if (_archivoSeleccionado != null) {
        final fileName = path.basename(_archivoSeleccionado!.path);
        final ref = FirebaseStorage.instance.ref().child(
              'ejercicios/$fileName',
            );
        await ref.putFile(_archivoSeleccionado!);
        downloadUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('exercises')
          .add(<String, dynamic>{
        'nombre': _nombreController.text,
        'orden': int.tryParse(_ordenController.text) ?? 999,
        'familia': _selectedFamilyUpload,
        'urlVideo': downloadUrl,
        'esVideo': _isVideo,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ejercicio creado'),
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

  void _mostrarModalSubida() {
    _nombreController.clear();
    _archivoSeleccionado = null;
    _sugerirSiguienteNumero();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext c) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(c).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Nuevo Ejercicio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFamilyUpload,
                  items: _familiasUpload
                      .map(
                        (String f) =>
                            DropdownMenuItem(value: f, child: Text(f)),
                      )
                      .toList(),
                  onChanged: (String? v) => _selectedFamilyUpload = v!,
                  decoration: const InputDecoration(labelText: 'Familia'),
                ),
                TextField(
                  controller: _ordenController,
                  decoration: const InputDecoration(labelText: 'Orden'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (String? v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 15),
                Row(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        Icons.image,
                        color: !_isVideo && _archivoSeleccionado != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: () async {
                        final hasPermission = await _checkPermission(false);
                        if (!hasPermission) return;

                        final picker = ImagePicker();
                        final img = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (img != null) {
                          setState(() {
                            _archivoSeleccionado = File(img.path);
                            _isVideo = false;
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.videocam,
                        color: _isVideo && _archivoSeleccionado != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: () async {
                        final hasPermission = await _checkPermission(true);
                        if (!hasPermission) return;

                        final picker = ImagePicker();
                        final vid = await picker.pickVideo(
                          source: ImageSource.gallery,
                        );
                        if (vid != null) {
                          setState(() {
                            _archivoSeleccionado = File(vid.path);
                            _isVideo = true;
                          });
                        }
                      },
                    ),
                    if (_archivoSeleccionado != null)
                      const Expanded(
                        child: Text(
                          'Archivo seleccionado',
                          style: TextStyle(color: Colors.green),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _guardarNuevoEjercicio,
                    child: _isUploading
                        ? const CircularProgressIndicator()
                        : const Text('GUARDAR'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.isSelectionMode
                ? 'Buscar para asignar...'
                : 'Gestionar librería...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: <Widget>[
          if (widget.isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Center(
                child: Text(
                  '${_selectedIds.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          if (!widget.isSelectionMode)
            IconButton(
              tooltip: 'Subida Masiva (Archivos)',
              icon: const Icon(Icons.drive_folder_upload, size: 28),
              onPressed: _iniciarSubidaMasiva,
            ),
          if (!widget.isSelectionMode)
            PopupMenuButton<String>(
              onSelected: (String val) {
                if (val == 'bulk') _iniciarSubidaMasiva();
                if (val == 'delete_all') _borrarTodaLaLibreria();
              },
              itemBuilder: (BuildContext c) => <PopupMenuEntry<String>>[
                const PopupMenuItem(
                  value: 'bulk',
                  child: Text('Subida Masiva (PC)'),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Text(
                    '⚠️ Borrar Todo (Admin)',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            color: Colors.teal.shade700,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _familiasFiltro.length,
              separatorBuilder: (BuildContext c, int i) =>
                  const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                final fam = _familiasFiltro[index];
                final isSelected = _filtroFamilia == fam;
                return GestureDetector(
                  onTap: () => setState(() => _filtroFamilia = fam),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.teal.shade900,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      fam,
                      style: TextStyle(
                        color: isSelected ? Colors.teal : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: widget.isSelectionMode && _selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                widget.onExercisesSelected?.call(_selectedExercises);
                Navigator.pop(context);
              },
              label: Text('AÑADIR (${_selectedIds.length})'),
              icon: const Icon(Icons.check),
              backgroundColor: Colors.orange,
            )
          : (!widget.isSelectionMode
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    FloatingActionButton.small(
                      heroTag: 'btnMasivo',
                      backgroundColor: Colors.blueGrey,
                      onPressed: _iniciarSubidaMasiva,
                      tooltip: 'Subida Masiva (PC)',
                      child: const Icon(
                        Icons.drive_folder_upload,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'btnIndividual',
                      onPressed: _mostrarModalSubida,
                      backgroundColor: Colors.teal,
                      tooltip: 'Nuevo Ejercicio',
                      child: const Icon(Icons.add),
                    ),
                  ],
                )
              : null),
      body: StreamBuilder<QuerySnapshot<Object?>>(
        stream: FirebaseFirestore.instance
            .collection('exercises')
            .orderBy('orden')
            .snapshots(),
        builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot<Object?>> snapshot,
        ) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs =
              snapshot.data!.docs.where((QueryDocumentSnapshot<Object?> d) {
            final data = d.data()! as Map<String, dynamic>;
            final name = (data['nombre'] ?? '').toString().toLowerCase();
            final familia = (data['familia'] ?? 'General').toString();

            final matchesText = name.contains(_searchText);
            final matchesFamily =
                _filtroFamilia == 'Todas' || familia == _filtroFamilia;

            return matchesText && matchesFamily;
          }).toList();
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay ejercicios.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: docs.length,
            itemBuilder: (BuildContext context, int index) {
              final doc = docs[index];
              final data = doc.data()! as Map<String, dynamic>;
              final isSelected = _selectedIds.contains(doc.id);
              final orden = data['orden'] is int ? data['orden'] as int : 0;

              return Card(
                color: isSelected ? Colors.orange.shade50 : Colors.white,
                elevation: isSelected ? 4 : 1,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isSelected ? Colors.orange : Colors.teal.shade100,
                    child: Text(
                      '$orden',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.teal.shade900,
                      ),
                    ),
                  ),
                  title: Text(
                    (data['nombre'] as String?) ?? 'Sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text((data['familia'] as String?) ?? 'General'),
                  trailing: widget.isSelectionMode
                      ? Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.orange : Colors.grey,
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _eliminarEjercicio(doc.id),
                        ),
                  onTap: () {
                    if (widget.isSelectionMode) _toggleSelection(doc.id, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({required this.files, required this.familia});
  final List<PlatformFile> files;
  final String familia;
  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  int _currentIndex = 0;
  double _progress = 0;
  final List<String> _errors = <String>[];

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    final total = widget.files.length;
    var ordenBase = 0;
    try {
      final q = await FirebaseFirestore.instance
          .collection('exercises')
          .orderBy('orden', descending: true)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        ordenBase = q.docs.first.data()['orden'] as int;
      }
    } catch (_) {}

    for (var i = 0; i < total; i++) {
      if (!mounted) return;
      setState(() {
        _currentIndex = i + 1;
        _progress = i / total;
      });
      final file = widget.files[i];
      final nombreLimpio = path
          .basenameWithoutExtension(file.name)
          .replaceAll('_', ' ')
          .replaceAll('-', ' ');
      try {
        final ref = FirebaseStorage.instance.ref().child(
              'ejercicios/${file.name}',
            );
        if (file.bytes != null) {
          await ref.putData(file.bytes!);
        } else if (file.path != null) {
          await ref.putFile(File(file.path!));
        }

        final url = await ref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('exercises')
            .add(<String, dynamic>{
          'nombre': nombreLimpio,
          'familia': widget.familia,
          'urlVideo': url,
          'esVideo': true,
          'orden': ordenBase + i + 1,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        _errors.add('Error en ${file.name}: $e');
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Subida finalizada. ${_errors.isEmpty ? "Todo correcto" : "${_errors.length} errores"}',
        ),
        backgroundColor: _errors.isEmpty ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Subiendo vídeos...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 20),
          Text('Procesando $_currentIndex de ${widget.files.length}'),
          const SizedBox(height: 5),
          Text(
            widget.files[_currentIndex > 0 ? _currentIndex - 1 : 0].name,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
