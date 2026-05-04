import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

// ═══════════════════════════════════════════════════════════════
// CONSTANTES
// ═══════════════════════════════════════════════════════════════

const List<String> _kFamilias = [
  'Fisioterapia',
  'Entrenamiento',
  'Psicología',
  'Nutrición',
  'Medicina',
  'Odontología',
  'Sin clasificar',
];

const List<String> _kFamiliasFiltro = ['Todas', ..._kFamilias];

// ═══════════════════════════════════════════════════════════════
// UTILIDAD: Parsear nombre de archivo
// ═══════════════════════════════════════════════════════════════

/// Primera letra mayúscula.
String _capitalize(String s) {
  if (s.isEmpty) return s;
  return '${s[0].toUpperCase()}${s.substring(1)}';
}

/// "100. abdomen mancuerna.mp4" → {codigo: 100, nombre: "Abdomen mancuerna"}
({int? codigo, String nombre}) _parseFileName(String fileName) {
  final sinExt = path.basenameWithoutExtension(fileName);
  // Buscar patrón: número seguido de punto y espacio(s)
  final regex = RegExp(r'^(\d+)\.\s*(.+)$');
  final match = regex.firstMatch(sinExt);

  if (match != null) {
    final codigo = int.tryParse(match.group(1)!);
    var nombre = match.group(2)!.trim();
    // Primera letra mayúscula
    nombre = nombre.replaceAll('_', ' ').replaceAll('-', ' ');
    if (nombre.isNotEmpty) {
      nombre = '${nombre[0].toUpperCase()}${nombre.substring(1)}';
    }
    return (codigo: codigo, nombre: nombre);
  }

  // Sin número: limpiar y capitalizar
  var nombre = sinExt.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  if (nombre.isNotEmpty) {
    nombre = '${nombre[0].toUpperCase()}${nombre.substring(1)}';
  }
  return (codigo: null, nombre: nombre);
}

// ═══════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═══════════════════════════════════════════════════════════════

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
  final Set<String> _selectedIds = <String>{};
  final List<Map<String, dynamic>> _selectedExercises = [];

  // Formulario individual
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _ordenController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  String _selectedFamilyUpload = 'Entrenamiento';
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

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _ordenController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  // ── Permisos ──────────────────────────────────────────────

  Future<bool> _checkPermission(bool forVideo) async {
    if (Platform.isAndroid) {
      final permission = forVideo ? Permission.videos : Permission.photos;
      final status = await permission.request();
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied && mounted) {
        _mostrarAlertaPermisos();
      }
      return false;
    }
    return true;
  }

  void _mostrarAlertaPermisos() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso denegado'),
        content: const Text(
          'Necesitamos acceso a tu galería para subir el ejercicio. '
          'Por favor, habilítalo en Ajustes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }

  // ── Selección de ejercicios (modo asignación) ──────────────

  void _toggleSelection(String id, Map<String, dynamic> data) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectedExercises.removeWhere((e) => e['id'] == id);
      } else {
        _selectedIds.add(id);
        _selectedExercises.add({...data, 'id': id});
      }
    });
  }

  // ── Borrar toda la librería ────────────────────────────────

  Future<void> _borrarTodaLaLibreria() async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PELIGRO: Borrar TODO'),
        content: const Text(
          '¿Estás seguro de que quieres BORRAR TODOS los ejercicios?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'BORRAR TODO',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm1 != true || !mounted) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmación final'),
        content: const Text('Se eliminarán TODOS los ejercicios y sus referencias.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRMAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm2 != true) return;

    setState(() => _isUploading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('exercises').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Librería vaciada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al borrar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Eliminar ejercicio individual ─────────────────────────

  Future<void> _eliminarEjercicio(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ejercicio'),
        content: const Text('¿Eliminar este ejercicio de la librería?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm ?? false) {
      await FirebaseFirestore.instance
          .collection('exercises')
          .doc(docId)
          .delete();
    }
  }

  // ── Editar ejercicio existente (nombre + código + familia) ──

  Future<void> _editarEjercicio(
    String docId, {
    required int currentCodigo,
    required String currentNombre,
    required String currentFamilia,
  }) async {
    final codigoCtrl = TextEditingController(text: '$currentCodigo');
    final nombreCtrl = TextEditingController(text: currentNombre);
    var familia = currentFamilia;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar ejercicio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _kFamilias.contains(familia) ? familia : 'Sin clasificar',
                items: _kFamilias
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setDialogState(() => familia = v!),
                decoration: const InputDecoration(
                  labelText: 'Familia',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = _capitalize(nombreCtrl.text.trim());
                if (nombre.isEmpty) return;
                Navigator.pop(ctx, {
                  'codigoInterno': int.tryParse(codigoCtrl.text) ?? 0,
                  'orden': int.tryParse(codigoCtrl.text) ?? 0,
                  'nombre': nombre,
                  'familia': familia,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
              ),
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await FirebaseFirestore.instance
          .collection('exercises')
          .doc(docId)
          .update(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ejercicio actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Auto-parsea el archivo seleccionado y rellena nombre + código.
  void _autoParseFile(String fileName) {
    final parsed = _parseFileName(fileName);
    _nombreController.text = parsed.nombre;
    if (parsed.codigo != null) {
      _codigoController.text = '${parsed.codigo}';
      _ordenController.text = '${parsed.codigo}';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SUBIDA MASIVA PREMIUM
  // ═══════════════════════════════════════════════════════════

  Future<void> _iniciarSubidaMasiva() async {
    try {
      // Preguntar al usuario: ¿carpeta o archivos individuales?
      if (!mounted) return;
      final mode = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Subida masiva de vídeos'),
          content: const Text(
            '¿Cómo quieres seleccionar los vídeos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'folder'),
              icon: const Icon(Icons.folder_open),
              label: const Text('CARPETA COMPLETA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'files'),
              icon: const Icon(Icons.video_file),
              label: const Text('ARCHIVOS'),
            ),
          ],
        ),
      );
      if (mode == null || !mounted) return;

      List<File> videoFiles;

      if (mode == 'folder') {
        // Seleccionar carpeta y leer todos los vídeos
        final folderPath =
            await FilePicker.getDirectoryPath();
        if (folderPath == null) return;

        const validExts = {'.mp4', '.mov', '.avi', '.mkv', '.webm'};
        final dir = Directory(folderPath);
        videoFiles = dir
            .listSync()
            .whereType<File>()
            .where(
              (f) => validExts.contains(
                path.extension(f.path).toLowerCase(),
              ),
            )
            .toList()
          ..sort((a, b) => path.basename(a.path).compareTo(
                path.basename(b.path),
              ));
      } else {
        // Seleccionar archivos individuales
        final result = await FilePicker.pickFiles(
          allowMultiple: true,
        );
        if (result == null || result.files.isEmpty) return;

        const validExts = {'.mp4', '.mov', '.avi', '.mkv', '.webm'};
        videoFiles = result.files
            .where(
              (f) =>
                  f.path != null &&
                  validExts.contains(
                    path.extension(f.path!).toLowerCase(),
                  ),
            )
            .map((f) => File(f.path!))
            .toList();
      }

      if (videoFiles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontraron vídeos válidos'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Parsear y mostrar preview editable
      if (!mounted) return;
      final entries = videoFiles.map((f) {
        final fileName = path.basename(f.path);
        final parsed = _parseFileName(fileName);
        return _UploadEntry(
          file: f,
          codigo: parsed.codigo ?? 0,
          nombre: parsed.nombre,
          familia: 'Entrenamiento',
        );
      }).toList();

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _BulkPreviewDialog(entries: entries),
      );
      if (confirmed != true || !mounted) return;

      // Subir con progreso real
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _BulkUploadProgressDialog(entries: entries),
      );
    } catch (e) {
      debugPrint('Error en subida masiva: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.runtimeType}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SUBIDA INDIVIDUAL
  // ═══════════════════════════════════════════════════════════

  Future<void> _sugerirSiguienteNumero() async {
    final query = await FirebaseFirestore.instance
        .collection('exercises')
        .orderBy('orden', descending: true)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final ultimo = (query.docs.first.data()['orden'] as int?) ?? 0;
      _ordenController.text = '${ultimo + 1}';
      _codigoController.text = '${ultimo + 1}';
    } else {
      _ordenController.text = '1';
      _codigoController.text = '1';
    }
  }

  Future<void> _guardarNuevoEjercicio() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);
    try {
      var downloadUrl = '';
      if (_archivoSeleccionado != null) {
        final fileName = path.basename(_archivoSeleccionado!.path);
        final ref =
            FirebaseStorage.instance.ref().child('ejercicios/$fileName');
        await ref.putFile(_archivoSeleccionado!);
        downloadUrl = await ref.getDownloadURL();
      }

      final codigo = int.tryParse(_codigoController.text) ?? 0;
      await FirebaseFirestore.instance.collection('exercises').add({
        'nombre': _capitalize(_nombreController.text.trim()),
        'orden': int.tryParse(_ordenController.text) ?? codigo,
        'codigoInterno': codigo,
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
          const SnackBar(
            content: Text('Error al subir el ejercicio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _mostrarModalSubida() {
    _nombreController.clear();
    _codigoController.clear();
    _archivoSeleccionado = null;
    _sugerirSiguienteNumero();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
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
              children: [
                const Text(
                  'Nuevo Ejercicio',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFamilyUpload,
                  items: _kFamilias
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => _selectedFamilyUpload = v!,
                  decoration: const InputDecoration(labelText: 'Familia'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codigoController,
                        decoration: const InputDecoration(labelText: 'Código'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _ordenController,
                        decoration: const InputDecoration(labelText: 'Orden'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.image,
                        color: !_isVideo && _archivoSeleccionado != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: () async {
                        if (!await _checkPermission(false)) return;
                        final img = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (img != null) {
                          _autoParseFile(path.basename(img.path));
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
                        if (!await _checkPermission(true)) return;
                        final vid = await ImagePicker()
                            .pickVideo(source: ImageSource.gallery);
                        if (vid != null) {
                          _autoParseFile(path.basename(vid.path));
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

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.isSelectionMode
                ? 'Buscar por nombre o código...'
                : 'Buscar por nombre o código...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
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
              tooltip: 'Subida Masiva',
              icon: const Icon(Icons.drive_folder_upload, size: 28),
              onPressed: _iniciarSubidaMasiva,
            ),
          if (!widget.isSelectionMode)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'delete_all') _borrarTodaLaLibreria();
              },
              itemBuilder: (c) => [
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Text(
                    'Borrar Todo (Admin)',
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
              itemCount: _kFamiliasFiltro.length,
              separatorBuilder: (c, i) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final fam = _kFamiliasFiltro[index];
                final isSelected = _filtroFamilia == fam;
                return GestureDetector(
                  onTap: () => setState(() => _filtroFamilia = fam),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.white : Colors.teal.shade900,
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
      floatingActionButton: _buildFAB(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exercises')
            .orderBy('orden')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((d) {
            final data = d.data()! as Map<String, dynamic>;
            final name = (data['nombre'] ?? '').toString().toLowerCase();
            final familia = (data['familia'] ?? 'General').toString();
            final codigo = data['codigoInterno']?.toString() ?? '';

            // Búsqueda por nombre O código
            final matchesText =
                name.contains(_searchText) || codigo.contains(_searchText);
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
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data()! as Map<String, dynamic>;
              final isSelected = _selectedIds.contains(doc.id);
              final codigo =
                  (data['codigoInterno'] as int?) ?? (data['orden'] as int?) ?? 0;
              final nombre = (data['nombre'] as String?) ?? 'Sin nombre';
              final familia = (data['familia'] as String?) ?? 'General';

              return Card(
                color: isSelected ? Colors.orange.shade50 : Colors.white,
                elevation: isSelected ? 4 : 1,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  leading: GestureDetector(
                    onTap: widget.isSelectionMode
                        ? null
                        : () => _editarEjercicio(
                            doc.id,
                            currentCodigo: codigo,
                            currentNombre: nombre,
                            currentFamilia: familia,
                          ),
                    child: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.orange : Colors.teal.shade100,
                      child: Text(
                        '$codigo',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.teal.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: codigo > 999 ? 10 : 14,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    familia,
                    style: TextStyle(
                      color: Colors.teal.shade600,
                      fontSize: 12,
                    ),
                  ),
                  trailing: widget.isSelectionMode
                      ? Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.orange : Colors.grey,
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                          ),
                          onPressed: () => _eliminarEjercicio(doc.id),
                        ),
                  onTap: () {
                    if (widget.isSelectionMode) {
                      _toggleSelection(doc.id, data);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget? _buildFAB() {
    if (widget.isSelectionMode && _selectedIds.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: () {
          widget.onExercisesSelected?.call(_selectedExercises);
          Navigator.pop(context);
        },
        label: Text('AÑADIR (${_selectedIds.length})'),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.orange,
      );
    }
    if (!widget.isSelectionMode) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'btnMasivo',
            backgroundColor: Colors.blueGrey,
            onPressed: _iniciarSubidaMasiva,
            tooltip: 'Subida Masiva',
            child: const Icon(Icons.drive_folder_upload, color: Colors.white),
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
      );
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════
// MODELO INTERNO: Entrada de subida
// ═══════════════════════════════════════════════════════════════

class _UploadEntry {
  _UploadEntry({
    required this.file,
    required this.codigo,
    required this.nombre,
    required this.familia,
  });
  final File file;
  int codigo;
  String nombre;
  String familia;

  String get fileName => path.basename(file.path);
}

// ═══════════════════════════════════════════════════════════════
// DIÁLOGO: Preview editable antes de subir
// ═══════════════════════════════════════════════════════════════

class _BulkPreviewDialog extends StatefulWidget {
  const _BulkPreviewDialog({required this.entries});
  final List<_UploadEntry> entries;
  @override
  State<_BulkPreviewDialog> createState() => _BulkPreviewDialogState();
}

class _BulkPreviewDialogState extends State<_BulkPreviewDialog> {
  String _familiaGlobal = 'Entrenamiento';
  int _rebuildKey = 0; // Fuerza rebuild de dropdowns al aplicar familia

  void _aplicarFamiliaATodos() {
    setState(() {
      for (final entry in widget.entries) {
        entry.familia = _familiaGlobal;
      }
      _rebuildKey++; // Cambia la key para forzar reconstrucción
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.preview, color: Color(0xFF009688)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${widget.entries.length} vídeos a subir',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 450,
        child: Column(
          children: [
            // Selector de familia global
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(
                children: [
                  const Text(
                    'Familia para todos:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _familiaGlobal,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: _kFamilias
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) => _familiaGlobal = v!,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _aplicarFamiliaATodos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('APLICAR', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            // Cabecera
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 70, child: Text('CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  Expanded(child: Text('NOMBRE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  SizedBox(width: 130, child: Text('FAMILIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  SizedBox(width: 36),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Lista editable
            Expanded(
              child: ListView.builder(
                key: ValueKey(_rebuildKey),
                itemCount: widget.entries.length,
                itemBuilder: (context, i) {
                  final entry = widget.entries[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            initialValue: '${entry.codigo}',
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => entry.codigo = int.tryParse(v) ?? 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: entry.nombre,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => entry.nombre = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 130,
                          child: DropdownButtonFormField<String>(
                            initialValue: entry.familia,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              border: OutlineInputBorder(),
                            ),
                            items: _kFamilias
                                .map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setState(() => entry.familia = v!),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => setState(() => widget.entries.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton.icon(
          onPressed: widget.entries.isEmpty ? null : () => Navigator.pop(context, true),
          icon: const Icon(Icons.cloud_upload),
          label: Text('SUBIR ${widget.entries.length} VÍDEOS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009688),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIÁLOGO: Progreso de subida masiva
// ═══════════════════════════════════════════════════════════════

class _BulkUploadProgressDialog extends StatefulWidget {
  const _BulkUploadProgressDialog({required this.entries});
  final List<_UploadEntry> entries;
  @override
  State<_BulkUploadProgressDialog> createState() =>
      _BulkUploadProgressDialogState();
}

class _BulkUploadProgressDialogState
    extends State<_BulkUploadProgressDialog> {
  int _currentIndex = 0;
  double _fileProgress = 0; // Progreso del archivo actual (0..1)
  String _currentFileName = '';
  String _statusText = 'Preparando...';
  final List<String> _errors = [];
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    final total = widget.entries.length;

    for (var i = 0; i < total; i++) {
      if (!mounted) return;
      final entry = widget.entries[i];
      final name = entry.fileName;
      setState(() {
        _currentIndex = i + 1;
        _fileProgress = 0;
        _currentFileName = entry.nombre.isNotEmpty ? entry.nombre : name;
        _statusText = 'Subiendo archivo...';
      });

      try {
        final ref = FirebaseStorage.instance.ref().child(
              'ejercicios/$name',
            );

        // Subir con seguimiento de progreso
        final task = ref.putFile(entry.file);

        task.snapshotEvents.listen((event) {
          if (!mounted) return;
          final progress = event.totalBytes > 0
              ? event.bytesTransferred / event.totalBytes
              : 0.0;
          setState(() {
            _fileProgress = progress;
            _statusText =
                '${(progress * 100).toInt()}% · '
                '${(event.bytesTransferred / 1024 / 1024).toStringAsFixed(1)} MB';
          });
        });

        await task;
        final url = await ref.getDownloadURL();

        if (!mounted) return;
        setState(() => _statusText = 'Guardando en base de datos...');

        await FirebaseFirestore.instance.collection('exercises').add({
          'nombre': _capitalize(entry.nombre.trim()),
          'codigoInterno': entry.codigo,
          'orden': entry.codigo,
          'familia': entry.familia,
          'urlVideo': url,
          'esVideo': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });

        _completedCount++;
      } catch (e) {
        _errors.add('$name: ${e.runtimeType}');
        debugPrint('Error subiendo $name: $e');
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Subida finalizada: $_completedCount/$total completados'
          '${_errors.isEmpty ? "" : " · ${_errors.length} errores"}',
        ),
        backgroundColor: _errors.isEmpty ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.entries.length;
    final globalProgress = total > 0
        ? ((_completedCount + _fileProgress) / total)
        : 0.0;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_upload, color: Color(0xFF009688)),
          SizedBox(width: 10),
          Text('Subiendo vídeos...'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progreso global
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: globalProgress,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF009688),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(globalProgress * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Archivo actual
            Text(
              'Archivo $_currentIndex de $total',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              _currentFileName,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Progreso del archivo actual
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _fileProgress,
                backgroundColor: Colors.grey.shade100,
                color: Colors.teal.shade300,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _statusText,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${_errors.length} errores',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
