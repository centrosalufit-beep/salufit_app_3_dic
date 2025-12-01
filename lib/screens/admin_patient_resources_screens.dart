import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 

class AdminPatientMaterialScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminPatientMaterialScreen({super.key, required this.userId, required this.userName});

  @override
  State<AdminPatientMaterialScreen> createState() => _AdminPatientMaterialScreenState();
}

class _AdminPatientMaterialScreenState extends State<AdminPatientMaterialScreen> {
  final String _instruccionesDefecto = '2 series de 1 minuto y en cada serie todas las repeticiones que puedas dejando un minuto de descanso entre ellas.';

  Future<void> _borrarEjercicio(String assignmentId) async {
    final bool? confirm = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: const Text('Borrar Ejercicio'), 
        content: const Text('¿Eliminar esta pauta?'), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), 
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Borrar', style: TextStyle(color: Colors.red)))
        ]
      )
    );
    
    if (confirm != true) return;
    
    await FirebaseFirestore.instance.collection('exercise_assignments').doc(assignmentId).delete();
  }

  void _abrirAsignador() {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), 
        child: _ExerciseSelector(userId: widget.userId, instruccionesDefecto: _instruccionesDefecto)
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const Text('Gestión Material', style: TextStyle(fontSize: 14)), 
            Text(widget.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]
        ), 
        backgroundColor: Colors.blue, 
        foregroundColor: Colors.white
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirAsignador, 
        backgroundColor: Colors.blue, 
        icon: const Icon(Icons.add, color: Colors.white), 
        label: const Text('PAUTAR EJERCICIO', style: TextStyle(color: Colors.white))
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('exercise_assignments').where('userId', isEqualTo: widget.userId).orderBy('fechaAsignacion', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library_outlined, size: 60, color: Colors.grey), SizedBox(height: 10), Text('Sin ejercicios asignados')]));
          
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.play_arrow, color: Colors.white)),
                  title: FutureBuilder<QuerySnapshot>(
                     future: FirebaseFirestore.instance.collection('exercises').where('codigoInterno', isEqualTo: int.tryParse(data['exerciseId'].toString()) ?? -1).limit(1).get(),
                     builder: (c, s) => Text((s.hasData && s.data!.docs.isNotEmpty) ? s.data!.docs.first['nombre'] : 'Ejercicio #${data['exerciseId']}', style: const TextStyle(fontWeight: FontWeight.bold))
                  ),
                  subtitle: Text(data['instrucciones'] ?? ''),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _borrarEjercicio(doc.id)),
                ),
              );
            },
          );
        }
      ),
    );
  }
}

class AdminPatientDocumentsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String viewerRole; 

  const AdminPatientDocumentsScreen({super.key, required this.userId, required this.userName, required this.viewerRole});

  @override
  State<AdminPatientDocumentsScreen> createState() => _AdminPatientDocumentsScreenState();
}

class _AdminPatientDocumentsScreenState extends State<AdminPatientDocumentsScreen> {
  bool _isUploading = false;
  final List<String> _plantillas = ['Consentimiento RGPD', 'Consentimiento Punción Seca', 'Consentimiento Electrólisis (EPTE)', 'Consentimiento Odontología General', 'Normativa del Centro'];

  Future<String?> _getUserEmail() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) return doc.data()?['email'];
    } catch (e) { 
      debugPrint('Error obteniendo email: $e'); 
    }
    return null;
  }

  Future<void> _borrarDocumentoSeguro(String docId, String urlPdf) async {
    if (widget.viewerRole != 'admin') { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solo administradores pueden borrar documentos'))); 
      return; 
    }
    
    final TextEditingController c1 = TextEditingController(); 
    final TextEditingController c2 = TextEditingController();
    
    final bool? auth = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: const Text('Borrado Seguro'), 
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            const Text('Se requiere doble firma admin:'), 
            TextField(controller: c1, obscureText: true, decoration: const InputDecoration(labelText: 'Clave 1')), 
            TextField(controller: c2, obscureText: true, decoration: const InputDecoration(labelText: 'Clave 2'))
          ]
        ), 
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(c, (c1.text == 'Clave.2020' && c2.text == 'MarciCanela2023*')), 
            child: const Text('BORRAR')
          )
        ]
      )
    );
    
    if (auth != true) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claves incorrectas'), backgroundColor: Colors.red)); 
      return; 
    }
    
    setState(() => _isUploading = true);
    try {
      if (urlPdf.isNotEmpty) await FirebaseStorage.instance.refFromURL(urlPdf).delete();
      await FirebaseFirestore.instance.collection('documents').doc(docId).delete();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento borrado'), backgroundColor: Colors.green));
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); 
    } finally { 
      if(mounted) setState(() => _isUploading = false); 
    }
  }

  Future<void> _subirPdf() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final String? userEmail = await _getUserEmail();
        
        final PlatformFile file = result.files.first;
        final ref = FirebaseStorage.instance.ref().child('documentos_pacientes/${widget.userId}/${file.name}');
        await ref.putFile(File(file.path!));
        final String url = await ref.getDownloadURL();
        final String id = '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';
        
        await FirebaseFirestore.instance.collection('documents').doc(id).set({
          'id': id, 'userId': widget.userId, 
          'userEmail': userEmail,
          'titulo': file.name.replaceAll('.pdf', ''), 
          'tipo': 'Personalizado', 'firmado': false, 'urlPdf': url, 'fechaCreacion': FieldValue.serverTimestamp()
        });
        
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subido correctamente'), backgroundColor: Colors.green));
      } catch (e) { 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); 
      } finally { 
        if(mounted) setState(() => _isUploading = false); 
      }
    }
  }

  Future<void> _enviarPlantilla(String titulo) async {
    final String? userEmail = await _getUserEmail();

    final String id = '${widget.userId}_${titulo.replaceAll(' ', '_')}';
    await FirebaseFirestore.instance.collection('documents').doc(id).set({
      'id': id, 'userId': widget.userId, 
      'userEmail': userEmail,
      'titulo': titulo, 'tipo': 'Legal', 'firmado': false, 'urlPdf': '', 'fechaCreacion': FieldValue.serverTimestamp()
    });
    
    if(mounted) { 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plantilla enviada'), backgroundColor: Colors.green)); 
    }
  }

  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context, 
      builder: (c) => Container(
        padding: const EdgeInsets.all(20), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.blue), 
              title: const Text('Subir PDF Personalizado'), 
              onTap: () { 
                Navigator.pop(c); 
                _subirPdf(); 
              }
            ),
            const Divider(),
            const Text('Enviar Plantilla para Firmar:', style: TextStyle(color: Colors.grey)),
            ..._plantillas.map((p) => ListTile(leading: const Icon(Icons.description, color: Colors.orange), title: Text(p), onTap: () => _enviarPlantilla(p)))
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const Text('Gestión Documentos', style: TextStyle(fontSize: 14)), 
            Text(widget.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]
        ), 
        backgroundColor: Colors.orange, 
        foregroundColor: Colors.white
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarOpciones, 
        backgroundColor: Colors.orange, 
        icon: const Icon(Icons.add, color: Colors.white), 
        label: const Text('NUEVO DOCUMENTO', style: TextStyle(color: Colors.white))
      ),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator()) 
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('documents').where('userId', isEqualTo: widget.userId).orderBy('fechaCreacion', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_off, size: 60, color: Colors.grey), SizedBox(height: 10), Text('Sin documentos')]));
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final bool firmado = data['firmado'] ?? false;
                  return Card(
                    child: ListTile(
                      leading: Icon(firmado ? Icons.check_circle : Icons.pending, color: firmado ? Colors.green : Colors.orange, size: 30),
                      title: Text(data['titulo'] ?? 'Documento', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(firmado ? 'Firmado' : 'Pendiente de firma'),
                      trailing: widget.viewerRole == 'admin' ? IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => _borrarDocumentoSeguro(snapshot.data!.docs[index].id, data['urlPdf'] ?? '')) : null,
                    ),
                  );
                }
              );
            }
          ),
    );
  }
}

// --- WIDGET: SELECTOR DE EJERCICIOS ---
class _ExerciseSelector extends StatefulWidget {
  final String userId; final String instruccionesDefecto;
  const _ExerciseSelector({required this.userId, required this.instruccionesDefecto});
  @override State<_ExerciseSelector> createState() => _ExerciseSelectorState();
}
class _ExerciseSelectorState extends State<_ExerciseSelector> {
  String _search = ''; late TextEditingController _instructionsController;
  @override void initState() { super.initState(); _instructionsController = TextEditingController(text: widget.instruccionesDefecto); }
  
  Future<void> _asignar(Map<String, dynamic> exerciseData) async {
    String? userEmail;
    try {
       final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
       if (doc.exists) userEmail = doc.data()?['email'];
    } catch (e) { debugPrint('Error email: $e'); }

    final String code = (exerciseData['codigoInterno'] ?? 0).toString();
    final String id = '${widget.userId}_${code}_${DateTime.now().millisecondsSinceEpoch}';
    
    await FirebaseFirestore.instance.collection('exercise_assignments').doc(id).set({
      'id': id, 'userId': widget.userId, 
      'userEmail': userEmail,
      'exerciseId': exerciseData['codigoInterno'], 
      'fechaAsignacion': DateTime.now().toIso8601String(), 'instrucciones': _instructionsController.text, 
      'profesionalId': 'App', 'completado': false, 'feedback': null
    });
    
    if(mounted) { 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignado'), backgroundColor: Colors.green)); 
    }
  }
  
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20), 
      height: 600, 
      child: Column(
        children: [
          const Text('Seleccionar Ejercicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 10),
          TextField(decoration: const InputDecoration(hintText: 'Buscar...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), filled: true), onChanged: (v)=>setState(()=>_search=v.toLowerCase())),
          const SizedBox(height: 10), 
          TextField(controller: _instructionsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Instrucciones', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('exercises').orderBy('orden').limit(100).snapshots(), 
              builder: (c, s) {
                if(!s.hasData) return const Center(child:CircularProgressIndicator());
                final f = s.data!.docs.where((d) => (d.data() as Map<String,dynamic>)['nombre'].toString().toLowerCase().contains(_search)).toList();
                return ListView.separated(
                  itemCount:f.length, 
                  separatorBuilder:(c,i)=>const Divider(), 
                  itemBuilder:(c,i) { 
                    final dt=f[i].data() as Map<String,dynamic>; 
                    return ListTile(
                      title:Text(dt['nombre']), 
                      trailing:ElevatedButton(onPressed:()=>_asignar(dt), child:const Text('ASIGNAR'))
                    ); 
                  }
                );
              }
            )
          )
        ]
      )
    );
  }
}