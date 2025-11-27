import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; // <--- NUEVO: Para saber QUIÉN está mirando

class AdminPatientDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String viewerRole; // 'admin' o 'profesional'

  const AdminPatientDetailScreen({
    super.key, 
    required this.userId, 
    required this.userName, 
    required this.viewerRole
  });

  @override
  State<AdminPatientDetailScreen> createState() => _AdminPatientDetailScreenState();
}

class _AdminPatientDetailScreenState extends State<AdminPatientDetailScreen> {
  bool _isUploading = false; 

  // Plantillas estándar
  final List<String> _plantillasDocumentos = [
    'Consentimiento RGPD',
    'Consentimiento Punción Seca',
    'Consentimiento Electrólisis (EPTE)',
    'Consentimiento Odontología General',
    'Normativa del Centro'
  ];

  final String _instruccionesDefecto = '2 series de 1 minuto y en cada serie todas las repeticiones que puedas dejando un minuto de descanso entre ellas.';

  @override
  void initState() {
    super.initState();
    // --- EL GRAN HERMANO: REGISTRAR ACCESO ---
    _registrarAcceso();
  }

  // Función silenciosa que guarda el log en Firebase
  Future<void> _registrarAcceso() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Solo registramos si hay usuario logueado
      if (currentUser != null) {
        // Opcional: No registrar si el usuario se mira a sí mismo (aunque aquí es panel admin)
        if (currentUser.uid == widget.userId) return;

        await FirebaseFirestore.instance.collection('audit_logs').add({
          'tipo': 'ACCESO_FICHA',
          'pacienteId': widget.userId,
          'pacienteNombre': widget.userName,
          'profesionalId': currentUser.uid,
          'profesionalEmail': currentUser.email, // Importante para saber quién fue
          'fecha': FieldValue.serverTimestamp(),
          'detalles': 'Apertura de ficha clínica desde Panel Profesional'
        });
        
        print("🔒 Auditoría: Acceso registrado correctamente en audit_logs.");
      }
    } catch (e) {
      print("⚠️ Error registrando auditoría: $e");
      // No mostramos error al usuario para no interrumpir la experiencia,
      // pero el fallo queda en consola por si acaso.
    }
  }

  // --- FUNCIÓN: BORRAR EJERCICIO (Simple) ---
  Future<void> _borrarEjercicio(String assignmentId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Borrar Ejercicio'),
        content: const Text('¿Quieres eliminar esta pauta del paciente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Borrar', style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('exercise_assignments').doc(assignmentId).delete();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio eliminado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // --- FUNCIÓN: BORRAR DOCUMENTO (SEGURIDAD DOBLE LLAVE + AUDITORÍA CRÍTICA) ---
  Future<void> _borrarDocumentoSeguro(String docId, String urlPdf) async {
    TextEditingController clave1 = TextEditingController();
    TextEditingController clave2 = TextEditingController();

    bool? autorizado = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            SizedBox(width: 10),
            Text('Borrado Seguro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Estás a punto de eliminar un documento legal firmado. Esta acción es irreversible."),
            const SizedBox(height: 10),
            const Text("Se requiere la firma (clave) de ambos administradores:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: clave1,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Clave Admin 1", border: OutlineInputBorder(), prefixIcon: Icon(Icons.vpn_key)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: clave2,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Clave Admin 2", border: OutlineInputBorder(), prefixIcon: Icon(Icons.vpn_key)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (clave1.text == "Clave.2020" && clave2.text == "MarciCanela2023*") {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Claves incorrectas"), backgroundColor: Colors.red));
              }
            },
            child: const Text("AUTORIZAR BORRADO"),
          ),
        ],
      ),
    );

    if (autorizado != true) return;

    setState(() => _isUploading = true);

    try {
      // REGISTRO DE AUDITORÍA DE ALTA GRAVEDAD
      final currentUser = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('audit_logs').add({
          'tipo': 'BORRADO_DOCUMENTO',
          'pacienteId': widget.userId,
          'documentoId': docId,
          'autorEmail': currentUser?.email ?? 'Desconocido',
          'fecha': FieldValue.serverTimestamp(),
          'gravedad': 'CRÍTICA',
          'motivo': 'Borrado autorizado por doble clave'
      });

      if (urlPdf.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(urlPdf).delete();
        } catch (e) {
          print("Aviso: No se pudo borrar el archivo de Storage: $e");
        }
      }

      await FirebaseFirestore.instance.collection('documents').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Documento eliminado permanentemente"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error crítico al borrar: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- FUNCIÓN: SUBIR PDF PERSONALIZADO ---
  Future<void> _subirPdfPersonalizado() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], 
    );

    if (result != null) {
      setState(() => _isUploading = true);
      if (mounted) Navigator.pop(context); 

      try {
        PlatformFile file = result.files.first;
        String fileName = file.name;
        String filePath = file.path!;

        final storageRef = FirebaseStorage.instance.ref().child('documentos_pacientes/${widget.userId}/$fileName');
        await storageRef.putFile(File(filePath));
        String downloadUrl = await storageRef.getDownloadURL();

        String docId = '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';
        
        await FirebaseFirestore.instance.collection('documents').doc(docId).set({
          'id': docId, 
          'userId': widget.userId, 
          'titulo': fileName.replaceAll('.pdf', ''), 
          'tipo': 'Informe/Personalizado', 
          'firmado': false, 
          'urlPdf': downloadUrl, 
          'fechaCreacion': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF subido'), backgroundColor: Colors.green),
          );
        }

      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // --- FUNCIÓN: ENVIAR PLANTILLA ---
  Future<void> _enviarDocumentoReal(String titulo) async {
    try {
      String docId = '${widget.userId}_${titulo.replaceAll(' ', '_')}';
      await FirebaseFirestore.instance.collection('documents').doc(docId).set({
        'id': docId, 
        'userId': widget.userId, 
        'titulo': titulo, 
        'tipo': 'Legal', 
        'firmado': false, 
        'urlPdf': '', 
        'fechaCreacion': FieldValue.serverTimestamp(),
      }); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // --- FUNCIÓN: MODIFICAR TOKENS ---
  Future<void> _updateTokens(DocumentReference passRef, int currentTokens, int change) async {
    int newTotal = currentTokens + change;
    if (newTotal < 0) newTotal = 0; 
    try {
      await passRef.update({'tokensRestantes': newTotal});
      
      // AUDITORÍA DE TOKENS
      final currentUser = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('audit_logs').add({
          'tipo': 'MODIFICACION_TOKENS',
          'pacienteId': widget.userId,
          'autorEmail': currentUser?.email,
          'cambio': change,
          'nuevoSaldo': newTotal,
          'fecha': FieldValue.serverTimestamp(),
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tokens: $newTotal'), duration: const Duration(milliseconds: 500)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _mostrarDialogoEnviarDocumento() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enviar Documento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListTile(leading: const Icon(Icons.upload_file, color: Colors.blue), title: const Text('Subir PDF personalizado'), subtitle: const Text('Elegir archivo'), onTap: _subirPdfPersonalizado),
              const Divider(),
              const Text('Plantillas:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ..._plantillasDocumentos.map((titulo) => ListTile(
                leading: const Icon(Icons.description, color: Colors.orange), title: Text(titulo), trailing: const Icon(Icons.send, color: Colors.teal),
                onTap: () { _enviarDocumentoReal(titulo); Navigator.pop(context); },
              )),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoAsignarEjercicio() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: _ExerciseSelector(userId: widget.userId, instruccionesDefecto: _instruccionesDefecto)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
          Icon(icon, color: Colors.teal, size: 20), const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))])
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    String idConCeros = widget.userId.padLeft(6, '0');
    String idSinCeros = widget.userId.replaceFirst(RegExp(r'^0+'), '');
    List<dynamic> posiblesIds = [idConCeros, idSinCeros];
    if (int.tryParse(idSinCeros) != null) posiblesIds.add(int.parse(idSinCeros));

    bool isAdmin = widget.viewerRole == 'admin';

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(title: Text(widget.userName), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: _isUploading 
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 20), Text('Subiendo archivo...')]))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TARJETA DATOS PERSONALES
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    return Column(
                      children: [
                        const CircleAvatar(radius: 40, backgroundColor: Colors.teal, child: Icon(Icons.person, size: 50, color: Colors.white)),
                        const SizedBox(height: 15),
                        Text((data['nombreCompleto'] ?? widget.userName).toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        Text('ID: ${widget.userId}', style: const TextStyle(color: Colors.grey)),
                        const Divider(height: 30),
                        
                        if (isAdmin) ...[
                           _buildInfoRow(Icons.phone, 'Teléfono', (data['telefono'] ?? 'No registrado').toString()),
                           _buildInfoRow(Icons.email, 'Email', (data['email'] ?? 'No registrado').toString()),
                        ],

                        _buildInfoRow(Icons.badge, 'Rol', (data['rol'] ?? 'cliente').toString().toUpperCase()),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 2. GESTIÓN DE BONOS
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Gestión de Bonos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 15),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('passes').where('userId', whereIn: posiblesIds).limit(1).snapshots(),
                      builder: (context, snapshot) {
                        int tokens = 0; int total = 0; bool tieneBono = false; DocumentReference? passRef;
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                           var doc = snapshot.data!.docs[0]; var data = doc.data() as Map<String, dynamic>;
                           tokens = data['tokensRestantes'] ?? 0; total = data['tokensTotales'] ?? 0; passRef = doc.reference; tieneBono = true;
                        }
                        return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(tieneBono ? '$tokens / $total' : '0 / 0', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: tieneBono ? Colors.black : Colors.grey)),
                                Text(tieneBono ? 'Restantes' : 'Sin bono', style: const TextStyle(color: Colors.grey)),
                            ]),
                            Row(children: [
                                IconButton.filled(icon: const Icon(Icons.remove), style: IconButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red), onPressed: (!tieneBono || passRef == null) ? null : () => _updateTokens(passRef!, tokens, -1)),
                                const SizedBox(width: 10),
                                IconButton.filled(icon: const Icon(Icons.add), style: IconButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green), onPressed: (!tieneBono || passRef == null) ? null : () => _updateTokens(passRef!, tokens, 1)),
                            ])
                        ]);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. EJERCICIOS ASIGNADOS
            const Text('Ejercicios Asignados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('exercise_assignments').where('userId', whereIn: posiblesIds).orderBy('fechaAsignacion', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(15), child: Text('No tiene ejercicios asignados')));
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    
                    Map<String, dynamic>? feedback;
                    if (data['feedback'] != null && data['feedback'] is Map) {
                        feedback = Map<String, dynamic>.from(data['feedback'] as Map);
                    }
                    bool tieneAlerta = feedback != null && (feedback['alerta'] == true);

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: tieneAlerta ? const BorderSide(color: Colors.red, width: 1) : BorderSide.none),
                      color: tieneAlerta ? Colors.red.shade50 : Colors.white,
                      child: ListTile(
                        leading: tieneAlerta ? const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30) : const Icon(Icons.play_circle_outline, color: Colors.blue),
                        title: FutureBuilder<QuerySnapshot>(
                           future: FirebaseFirestore.instance.collection('exercises').where('codigoInterno', isEqualTo: int.tryParse(data['exerciseId'].toString()) ?? -1).limit(1).get(),
                           builder: (c, s) {
                             if (s.hasData && s.data!.docs.isNotEmpty) return Text(s.data!.docs.first['nombre']);
                             return Text('Ejercicio #${data['exerciseId']}');
                           }
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['instrucciones'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (tieneAlerta) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text('Feedback: ${feedback['dificultad']?.toString().toUpperCase() ?? ''} ${feedback['gustado'] == false ? '👎' : ''}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => _borrarEjercicio(doc.id)),
                      ),
                    );
                  }).toList(),
                );
              }
            ),
            const SizedBox(height: 20),

            // 4. DOCUMENTOS SOLICITADOS
            const Text('Documentos Solicitados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('documents').where('userId', whereIn: posiblesIds).orderBy('fechaCreacion', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(15), child: Text('No hay documentos')));
                
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool firmado = data['firmado'] ?? false;
                    String docId = doc.id;
                    String urlPdf = data['urlPdf'] ?? "";

                    return Card(
                      child: ListTile(
                        leading: Icon(firmado ? Icons.check_circle : Icons.pending, color: firmado ? Colors.green : Colors.orange),
                        title: Text(data['titulo'] ?? 'Doc'),
                        subtitle: Text(firmado ? 'Firmado' : 'Pendiente'),
                        // BOTÓN DE BORRAR SOLO PARA ADMINS
                        trailing: isAdmin 
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _borrarDocumentoSeguro(docId, urlPdf), 
                            )
                          : null,
                      ),
                    );
                  }).toList(),
                );
              }
            ),
            const SizedBox(height: 30),

            // BOTONES ACCIÓN
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: _mostrarDialogoEnviarDocumento, icon: const Icon(Icons.assignment_add, size: 18), label: const Text('ENVIAR DOC', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(onPressed: _mostrarDialogoAsignarEjercicio, icon: const Icon(Icons.video_library, size: 18), label: const Text('PAUTAR EJER', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white))),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// WIDGET ASIGNAR EJERCICIO
class _ExerciseSelector extends StatefulWidget {
  final String userId;
  final String instruccionesDefecto;
  const _ExerciseSelector({required this.userId, required this.instruccionesDefecto});
  @override State<_ExerciseSelector> createState() => _ExerciseSelectorState();
}
class _ExerciseSelectorState extends State<_ExerciseSelector> {
  String _search = "";
  final TextEditingController _daysController = TextEditingController(text: '30');
  late TextEditingController _instructionsController;
  @override void initState() { super.initState(); _instructionsController = TextEditingController(text: widget.instruccionesDefecto); }
  Future<void> _asignar(Map<String, dynamic> exerciseData, String exerciseIdDoc) async {
    if (_daysController.text.isEmpty) return;
    String code = (exerciseData['codigoInterno'] ?? 0).toString();
    String id = '${widget.userId}_${code}_${DateTime.now().millisecondsSinceEpoch}';
    try {
      await FirebaseFirestore.instance.collection('exercise_assignments').doc(id).set({
        'id': id, 'userId': widget.userId, 'exerciseId': code, 
        'fechaAsignacion': DateTime.now().toIso8601String(), 'instrucciones': _instructionsController.text, 
        'profesionalId': 'App', 'completado': false, 'feedback': null
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignado'), backgroundColor: Colors.green)); }
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20), height: 600, 
      child: Column(children: [
        const Text('Asignar Ejercicio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 10),
        TextField(decoration: InputDecoration(hintText: 'Buscar...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(), filled: true), onChanged: (v)=>setState(()=>_search=v.toLowerCase())),
        const SizedBox(height: 10),
        TextField(controller: _instructionsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Instrucciones', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('exercises').orderBy('orden').limit(100).snapshots(),
          builder: (c, s) {
             if(!s.hasData) return const Center(child:CircularProgressIndicator());
             var f = s.data!.docs.where((d) { var dt=d.data() as Map<String,dynamic>; return (dt['nombre']??'').toString().toLowerCase().contains(_search); }).toList();
             return ListView.separated(itemCount:f.length, separatorBuilder:(c,i)=>const Divider(), itemBuilder:(c,i) {
                var dt=f[i].data() as Map<String,dynamic>;
                return ListTile(title:Text(dt['nombre']??''), trailing:ElevatedButton(onPressed:()=>_asignar(dt, f[i].id), child:const Text('ASIGNAR')));
             });
          }
        ))
      ])
    );
  }
}