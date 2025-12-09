import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AdminExerciseLibraryScreen extends StatefulWidget {
  final bool isSelectionMode;
  final Function(List<Map<String, dynamic>>)? onExercisesSelected;

  const AdminExerciseLibraryScreen({
    super.key, 
    this.isSelectionMode = false,
    this.onExercisesSelected
  });

  @override
  State<AdminExerciseLibraryScreen> createState() => _AdminExerciseLibraryScreenState();
}

class _AdminExerciseLibraryScreenState extends State<AdminExerciseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  
  // FILTRO DE FAMILIA
  String _filtroFamilia = 'Todas';
  final List<String> _familiasFiltro = ['Todas', 'Fisioterapia', 'Psicología', 'Odontología', 'Entrenamiento', 'Nutrición'];

  final Set<String> _selectedIds = {}; 
  final List<Map<String, dynamic>> _selectedExercises = []; 
  bool _isBulkUploading = false; 

  // --- VARIABLES PARA EL MODAL DE SUBIDA INDIVIDUAL ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _ordenController = TextEditingController();
  String _selectedFamilyUpload = 'Entrenamiento';
  final List<String> _familiasUpload = ['Fisioterapia', 'Psicología', 'Odontología', 'Entrenamiento', 'Nutrición'];
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

  void _toggleSelection(String id, Map<String, dynamic> data) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectedExercises.removeWhere((e) => e['id'] == id);
      } else {
        _selectedIds.add(id);
        final exerciseData = Map<String, dynamic>.from(data);
        exerciseData['id'] = id;
        _selectedExercises.add(exerciseData);
      }
    });
  }

  // ==========================================
  // ☢️ BORRADO MASIVO (NUCLEAR)
  // ==========================================
  Future<void> _borrarTodaLaLibreria() async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ PELIGRO: Borrar TODO'),
        content: const Text('¿Estás seguro de que quieres BORRAR TODOS los ejercicios de la base de datos?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('BORRAR TODO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm1 != true) return;

    if (!mounted) return;
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿De verdad?'),
        content: const Text('Se eliminarán todas las referencias. Los pacientes perderán sus asignaciones si apuntan a estos ejercicios.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Me arrepiento')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('SÍ, BORRAR DEFINITIVAMENTE', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    setState(() => _isBulkUploading = true); 

    try {
      // Usamos final para la colección
      final collection = FirebaseFirestore.instance.collection('exercises');
      var snapshots = await collection.get();
      
      while (snapshots.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        snapshots = await collection.get();
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Librería vaciada por completo')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error borrando: $e')));
    } finally {
      if (mounted) setState(() => _isBulkUploading = false);
    }
  }

  // ==========================================
  // 🚀 SUBIDA MASIVA INTELIGENTE
  // ==========================================
  Future<void> _iniciarSubidaMasiva() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'mp4', 'mov', 'jpeg'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isBulkUploading = true);
    
    int successCount = 0;
    int failCount = 0;
    final List<String> errores = [];

    int ultimoNumero = 0;
    try {
      final q = await FirebaseFirestore.instance.collection('exercises').orderBy('orden', descending: true).limit(1).get();
      if(q.docs.isNotEmpty) ultimoNumero = q.docs.first.data()['orden'] ?? 0;
    } catch (_) {}

    for (final PlatformFile pFile in result.files) {
      if (pFile.path == null) continue;
      final File file = File(pFile.path!);
      final String filename = pFile.name; 

      try {
        // Regex
        final String nameWithoutExt = filename.split('.').first;
        final regExp = RegExp(r'^(\d+)[\s_\-\.]+(.*)$');
        final match = regExp.firstMatch(nameWithoutExt);

        int orden;
        String nombreFinal;

        if (match != null) {
          orden = int.parse(match.group(1)!);
          nombreFinal = match.group(2)!.trim().replaceAll('_', ' ');
        } else {
          ultimoNumero++;
          orden = ultimoNumero;
          nombreFinal = nameWithoutExt.replaceAll('_', ' ');
        }

        // Subida
        final String ext = filename.split('.').last;
        final String storageName = '${DateTime.now().millisecondsSinceEpoch}_$orden.$ext';
        final Reference ref = FirebaseStorage.instance.ref().child('ejercicios/$storageName');
        
        await ref.putFile(file);
        final String url = await ref.getDownloadURL();

        final bool isVideo = ['mp4', 'mov', 'avi'].contains(ext.toLowerCase());

        await FirebaseFirestore.instance.collection('exercises').add({
          'nombre': nombreFinal, 
          'familia': 'Entrenamiento', 
          'orden': orden,
          'urlVideo': url,
          'tipoArchivo': isVideo ? 'video' : 'imagen',
          'creadoEn': FieldValue.serverTimestamp(),
        });

        successCount++;

      } catch (e) {
        failCount++;
        errores.add(filename);
        debugPrint('Error subiendo $filename: $e');
      }
    }

    if (mounted) {
      setState(() => _isBulkUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Proceso terminado. Subidos: $successCount. Errores: $failCount'),
        backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  // ==========================================
  // 💾 GUARDADO INDIVIDUAL
  // ==========================================
  Future<bool> _guardarEjercicio() async {
    try {
      final int nuevoOrden = int.tryParse(_ordenController.text) ?? 999;

      final collisionQuery = await FirebaseFirestore.instance
          .collection('exercises')
          .where('orden', isEqualTo: nuevoOrden)
          .get();

      if (collisionQuery.docs.isNotEmpty) {
        final shiftQuery = await FirebaseFirestore.instance
            .collection('exercises')
            .where('orden', isGreaterThanOrEqualTo: nuevoOrden)
            .get();

        final WriteBatch batch = FirebaseFirestore.instance.batch();
        for (final doc in shiftQuery.docs) {
          final int currentOrd = doc.data()['orden'] ?? 0;
          batch.update(doc.reference, {'orden': currentOrd + 1});
        }
        await batch.commit();
      }

      final String ext = _archivoSeleccionado!.path.split('.').last;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      final Reference storageRef = FirebaseStorage.instance.ref().child('ejercicios/$fileName');
      await storageRef.putFile(_archivoSeleccionado!);
      final String url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('exercises').add({
        'nombre': _nombreController.text.trim(),
        'familia': _selectedFamilyUpload,
        'orden': nuevoOrden,
        'urlVideo': url,
        'tipoArchivo': _isVideo ? 'video' : 'imagen',
        'creadoEn': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error subiendo ejercicio: $e');
      return false;
    }
  }

  Future<void> _eliminarEjercicio(String docId, String? urlVideo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar ejercicio?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('exercises').doc(docId).delete();
      if (urlVideo != null && urlVideo.isNotEmpty) {
        try { await FirebaseStorage.instance.refFromURL(urlVideo).delete(); } catch (_) {}
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio eliminado')));
    }
  }

  void _mostrarDialogoEditar(String docId, Map<String, dynamic> data) {
    final nombreEditCtrl = TextEditingController(text: data['nombre']);
    String familiaEdit = data['familia'] ?? 'Entrenamiento';
    if (!_familiasUpload.contains(familiaEdit)) familiaEdit = 'Entrenamiento';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Editar Ejercicio'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreEditCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: familiaEdit,
                  items: _familiasUpload.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setStateDialog(() => familiaEdit = v!),
                  decoration: const InputDecoration(labelText: 'Familia'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('exercises').doc(docId).update({
                    'nombre': nombreEditCtrl.text.trim(),
                    'familia': familiaEdit,
                  });
                  
                  // Verificación estricta del contexto antes de usarlo
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Actualizado')));
                },
                child: const Text('Guardar'),
              )
            ],
          );
        }
      ),
    );
  }

  Future<void> _sugerirSiguienteNumero() async {
    final query = await FirebaseFirestore.instance.collection('exercises').orderBy('orden', descending: true).limit(1).get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      final int ultimo = (data['orden'] is int) ? data['orden'] : 0;
      _ordenController.text = (ultimo + 1).toString();
    } else {
      _ordenController.text = '1';
    }
  }

  void _mostrarModalSubida() {
    _nombreController.clear();
    _archivoSeleccionado = null;
    _isUploading = false;
    _sugerirSiguienteNumero();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Nuevo Ejercicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Si usas un Nº repetido, los demás se moverán automáticamente.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFamilyUpload,
                        items: _familiasUpload.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (v) => setModalState(() => _selectedFamilyUpload = v!),
                        decoration: const InputDecoration(labelText: 'Familia', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(flex: 1, child: TextFormField(controller: _ordenController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nº', border: OutlineInputBorder()))),
                          const SizedBox(width: 10),
                          Expanded(flex: 3, child: TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre Ejercicio', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () async { final picker = ImagePicker(); final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); if(file!=null) setModalState(() { _archivoSeleccionado = File(file.path); _isVideo = false; }); }, icon: const Icon(Icons.image), label: const Text('Foto'), style: OutlinedButton.styleFrom(backgroundColor: !_isVideo && _archivoSeleccionado != null ? Colors.teal.shade50 : null))),
                          const SizedBox(width: 10),
                          Expanded(child: OutlinedButton.icon(onPressed: () async { final picker = ImagePicker(); final XFile? file = await picker.pickVideo(source: ImageSource.gallery); if(file!=null) setModalState(() { _archivoSeleccionado = File(file.path); _isVideo = true; }); }, icon: const Icon(Icons.videocam), label: const Text('Vídeo'), style: OutlinedButton.styleFrom(backgroundColor: _isVideo && _archivoSeleccionado != null ? Colors.teal.shade50 : null))),
                        ],
                      ),
                      if (_archivoSeleccionado != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Archivo: ${_archivoSeleccionado!.path.split('/').last}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (_archivoSeleccionado == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes seleccionar un archivo'))); return; }
                            setModalState(() => _isUploading = true);
                            final bool exito = await _guardarEjercicio();
                            if (!context.mounted) return;
                            setModalState(() => _isUploading = false);
                            if (exito) { if (!context.mounted) return; Navigator.pop(context); if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio guardado'), backgroundColor: Colors.green)); } 
                            else { if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir'), backgroundColor: Colors.red)); }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                          child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR EJERCICIO'),
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
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: !widget.isSelectionMode 
                ? TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Buscar por Nombre o Nº...', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none, icon: Icon(Icons.search, color: Colors.white)),
                  )
                : Text('Seleccionados: ${_selectedIds.length}'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              if (widget.isSelectionMode && _selectedIds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () { if (widget.onExercisesSelected != null) { widget.onExercisesSelected!(_selectedExercises); } Navigator.pop(context); },
                )
              else 
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'bulk') _iniciarSubidaMasiva();
                    if (value == 'delete_all') _borrarTodaLaLibreria();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'bulk', child: Row(children: [Icon(Icons.upload_file, color: Colors.blue), SizedBox(width: 8), Text('Subida Masiva (Inteligente)')])),
                    const PopupMenuItem(value: 'delete_all', child: Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 8), Text('Borrar TODA la Librería')])),
                  ],
                )
            ],
          ),
          floatingActionButton: widget.isSelectionMode ? null : FloatingActionButton(onPressed: _mostrarModalSubida, backgroundColor: Colors.teal, child: const Icon(Icons.add, color: Colors.white)),
          body: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: Colors.grey.shade100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _familiasFiltro.length,
                  itemBuilder: (context, index) {
                    final fam = _familiasFiltro[index];
                    final isSelected = _filtroFamilia == fam;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(fam),
                        selected: isSelected,
                        selectedColor: Colors.teal.shade100,
                        checkmarkColor: Colors.teal,
                        labelStyle: TextStyle(color: isSelected ? Colors.teal.shade900 : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        onSelected: (bool selected) { setState(() { _filtroFamilia = selected ? fam : 'Todas'; }); },
                      ),
                    );
                  },
                ),
              ),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('exercises').orderBy('orden').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final docs = snapshot.data!.docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name = (data['nombre'] ?? '').toString().toLowerCase();
                      final orden = (data['orden'] ?? '').toString();
                      final familia = (data['familia'] ?? 'General').toString();

                      final bool matchesText = name.contains(_searchText) || orden.contains(_searchText);
                      final bool matchesFamily = _filtroFamilia == 'Todas' || familia == _filtroFamilia;

                      return matchesText && matchesFamily;
                    }).toList();

                    if (docs.isEmpty) return const Center(child: Text('No hay ejercicios con esos filtros'));

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80), 
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final isSelected = _selectedIds.contains(doc.id);
                        final bool isVideo = data['tipoArchivo'] == 'video';
                        final int orden = data['orden'] ?? 0;

                        return Card(
                          color: isSelected ? Colors.teal.shade50 : Colors.white,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: Icon(isVideo ? Icons.videocam : Icons.image, color: Colors.grey)),
                                if (isSelected) const Positioned(right: 0, bottom: 0, child: CircleAvatar(backgroundColor: Colors.teal, radius: 10, child: Icon(Icons.check, size: 12, color: Colors.white))),
                              ],
                            ),
                            title: Text('#$orden - ${data['nombre'] ?? 'Sin nombre'}', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                            subtitle: Text(data['familia'] ?? 'General', style: TextStyle(color: Colors.grey.shade600)),
                            onTap: () { if (widget.isSelectionMode) { _toggleSelection(doc.id, data); } },
                            trailing: !widget.isSelectionMode 
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') _mostrarDialogoEditar(doc.id, data);
                                    if (value == 'delete') _eliminarEjercicio(doc.id, data['urlVideo']);
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Editar')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Eliminar')])),
                                  ],
                                )
                              : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        if (_isBulkUploading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text('Procesando operación masiva...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Por favor, no cierres la app.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          )
      ],
    );
  }
}