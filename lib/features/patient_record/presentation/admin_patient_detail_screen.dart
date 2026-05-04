import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AdminPatientDetailScreen extends StatefulWidget {
  const AdminPatientDetailScreen({
    required this.userId,
    required this.userName,
    required this.viewerRole,
    super.key,
  });
  final String userId;
  final String userName;
  final String viewerRole;

  @override
  State<AdminPatientDetailScreen> createState() =>
      _AdminPatientDetailScreenState();
}

class _AdminPatientDetailScreenState extends State<AdminPatientDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _registrarAcceso();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _registrarAcceso() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid != widget.userId) {
        await FirebaseFirestore.instance
            .collection('audit_logs')
            .add(<String, dynamic>{
          'tipo': 'ACCESO_FICHA',
          'pacienteId': widget.userId,
          'pacienteNombre': widget.userName,
          'profesionalId': currentUser.uid,
          'profesionalEmail': currentUser.email,
          'fecha': FieldValue.serverTimestamp(),
          'detalles': 'Apertura de ficha completa',
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error auditoría: $e');
    }
  }

  // REPARADO: Ahora se usa en las listas de abajo
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Pendiente';
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    }
    return 'Sin fecha';
  }

  Future<void> _subirDocClinico() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final file = result.files.first;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('documentos_pacientes/${widget.userId}/${file.name}');
        await storageRef.putFile(File(file.path!));
        final downloadUrl = await storageRef.getDownloadURL();

        final userDoc = await FirebaseFirestore.instance
            .collection('users_app')
            .doc(widget.userId)
            .get();
        final userEmail = userDoc.data().safeString('email');

        await FirebaseFirestore.instance
            .collection('documents')
            .add(<String, dynamic>{
          'userId': widget.userId,
          'userEmail': userEmail,
          'titulo': file.name.replaceAll('.pdf', ''),
          'tipo': 'Clínico',
          'firmado': false,
          'urlPdf': downloadUrl,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<Map<String, String>?> _seleccionarProfesional() async {
    final snap = await FirebaseFirestore.instance
        .collection('users_app')
        .get();

    final profesionales = snap.docs.where((d) {
      final data = d.data();
      final rol = (data['rol'] as String?) ?? '';
      return rol == 'admin' || rol == 'administrador' || rol == 'profesional';
    }).toList();

    if (!mounted) return null;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.medical_services, color: Colors.deepOrange, size: 36),
              const SizedBox(height: 12),
              const Text('Profesional responsable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Selecciona quien debe firmar este documento', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              if (profesionales.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Text('No hay profesionales registrados'))
              else
                ...profesionales.map((doc) {
                  final data = doc.data();
                  final nombre = (data['nombreCompleto'] as String?) ?? (data['nombre'] as String?) ?? 'Sin nombre';
                  final rol = (data['rol'] as String?) ?? '';
                  final email = (data['email'] as String?) ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rol == 'admin' || rol == 'administrador' ? Colors.purple.shade100 : Colors.blue.shade100,
                      child: Icon(rol == 'admin' || rol == 'administrador' ? Icons.admin_panel_settings : Icons.medical_services, color: rol == 'admin' || rol == 'administrador' ? Colors.purple : Colors.blue, size: 20),
                    ),
                    title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('$rol | $email', style: const TextStyle(fontSize: 10)),
                    onTap: () => Navigator.pop(ctx, {'id': doc.id, 'nombre': nombre}),
                  );
                }),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _lanzarConsentimiento(String titulo, String urlPlantilla, {bool requiereDobleFirma = false}) async {
    // Si requiere doble firma, pedir profesional responsable
    Map<String, String>? profesionalData;
    if (requiereDobleFirma) {
      profesionalData = await _seleccionarProfesional();
      if (profesionalData == null) return; // Cancelado
    }

    setState(() => _isUploading = true);
    try {
      debugPrint('>>> [CONSENT] Asignando "$titulo" a ${widget.userId}');

      final userDoc = await FirebaseFirestore.instance
          .collection('users_app')
          .doc(widget.userId)
          .get();
      final userEmail = userDoc.data().safeString('email');

      await FirebaseFirestore.instance.collection('documents').add({
        'userId': widget.userId,
        'userEmail': userEmail,
        'titulo': titulo,
        'tipo': 'Legal',
        'firmado': false,
        'urlPdf': urlPlantilla,
        'requiereDobleFirma': requiereDobleFirma,
        'firmaCliente': null,
        'firmaProfesional': null,
        if (profesionalData != null) 'profesionalAsignadoId': profesionalData['id'],
        if (profesionalData != null) 'profesionalAsignadoNombre': profesionalData['nombre'],
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      debugPrint('>>> [CONSENT] Documento asignado correctamente${profesionalData != null ? ' (profesional: ${profesionalData['nombre']})' : ''}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Consentimiento "$titulo" asignado a ${widget.userName}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('>>> [CONSENT] ERROR: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al asignar consentimiento'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _mostrarPlantillas() async {
    try {
    debugPrint('>>> [PLANTILLAS] Consultando consent_templates...');
    final snap = await FirebaseFirestore.instance
        .collection('consent_templates')
        .get();
    debugPrint('>>> [PLANTILLAS] Encontradas: ${snap.docs.length}');

    if (!mounted) return;

    final activeDocs = snap.docs.where((d) {
      final data = d.data();
      return data['activa'] == true || data['activo'] == true;
    }).toList();

    if (activeDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay plantillas. Sube una desde Libreria.'), backgroundColor: Colors.orange),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Asignar Consentimiento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Paciente: ${widget.userName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              ...activeDocs.map((doc) {
                final data = doc.data();
                final nombre = (data['titulo'] as String?) ?? (data['nombre'] as String?) ?? 'Sin nombre';
                final url = (data['urlPdf'] as String?) ?? '';
                final dobleFirma = data['requiereDobleFirma'] == true;
                return ListTile(
                  leading: Icon(dobleFirma ? Icons.people : Icons.description, color: dobleFirma ? Colors.deepOrange : Colors.orange),
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: dobleFirma ? const Text('Doble firma (profesional + cliente)', style: TextStyle(fontSize: 10, color: Colors.deepOrange)) : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    _lanzarConsentimiento(nombre, url, requiereDobleFirma: dobleFirma);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
    } catch (e) {
      debugPrint('Error cargando plantillas: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar plantillas'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarMenuPrincipal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Asignar recurso', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 4),
              Text('Paciente: ${widget.userName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMenuIconBtn(
                    icon: Icons.fitness_center,
                    color: Colors.blue,
                    label: 'Ejercicio',
                    onTap: () => Navigator.pop(ctx),
                  ),
                  _buildMenuIconBtn(
                    icon: Icons.upload_file,
                    color: Colors.teal,
                    label: 'Documento',
                    onTap: () {
                      Navigator.pop(ctx);
                      _subirDocClinico();
                    },
                  ),
                  _buildMenuIconBtn(
                    icon: Icons.gavel,
                    color: Colors.orange,
                    label: 'Legal',
                    onTap: () {
                      Navigator.pop(ctx);
                      _mostrarPlantillas();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIconBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'EJERCICIOS', icon: Icon(Icons.fitness_center)),
            Tab(text: 'MÉTRICAS', icon: Icon(Icons.show_chart)),
            Tab(text: 'CLÍNICOS', icon: Icon(Icons.folder_shared)),
            Tab(text: 'LEGALES', icon: Icon(Icons.gavel)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _mostrarMenuPrincipal,
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListPlaceholder('Lista de Ejercicios'),
          _MetricsManagementTab(
            userId: widget.userId,
            userName: widget.userName,
          ),
          _buildListPlaceholder('Documentos Clínicos'),
          _buildListPlaceholder('Documentos Legales'),
        ],
      ),
    );
  }

  Widget _buildListPlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          const SizedBox(height: 10),
          Text(
            'Actualizado: ${_formatDate(Timestamp.now())}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB MÉTRICAS — GESTIÓN DESDE WINDOWS
// ═══════════════════════════════════════════════════════════════

const Map<String, List<Map<String, String>>> _kMetrics = {
  'Entrenamiento': [
    {'nombre': '1RM Press Banca', 'unidad': 'kg', 'polaridad': 'up'},
    {'nombre': '1RM Sentadilla', 'unidad': 'kg', 'polaridad': 'up'},
    {'nombre': '1RM Peso Muerto', 'unidad': 'kg', 'polaridad': 'up'},
    {'nombre': 'Peso Corporal', 'unidad': 'kg', 'polaridad': 'neutral'},
    {'nombre': 'Repeticiones máx', 'unidad': 'reps', 'polaridad': 'up'},
  ],
  'Fisioterapia': [
    {'nombre': 'EVA Dolor', 'unidad': '/10', 'polaridad': 'down'},
    {'nombre': 'ROM Hombro', 'unidad': '°', 'polaridad': 'up'},
    {'nombre': 'ROM Rodilla', 'unidad': '°', 'polaridad': 'up'},
    {'nombre': 'Fuerza (Daniels)', 'unidad': '/5', 'polaridad': 'up'},
  ],
  'Nutrición': [
    {'nombre': 'Peso', 'unidad': 'kg', 'polaridad': 'neutral'},
    {'nombre': 'IMC', 'unidad': '', 'polaridad': 'down'},
    {'nombre': '% Grasa', 'unidad': '%', 'polaridad': 'down'},
    {'nombre': 'Perímetro Cintura', 'unidad': 'cm', 'polaridad': 'down'},
  ],
  'Psicología': [
    {'nombre': 'GAD-7 Ansiedad', 'unidad': '/21', 'polaridad': 'down'},
    {'nombre': 'PHQ-9 Depresión', 'unidad': '/27', 'polaridad': 'down'},
  ],
  'Medicina': [
    {'nombre': 'Tensión Sistólica', 'unidad': 'mmHg', 'polaridad': 'down'},
    {'nombre': 'FC Reposo', 'unidad': 'bpm', 'polaridad': 'down'},
  ],
  'Odontología': [
    {'nombre': 'Índice de Placa', 'unidad': '%', 'polaridad': 'down'},
  ],
};

class _MetricsManagementTab extends StatelessWidget {
  const _MetricsManagementTab({
    required this.userId,
    required this.userName,
  });
  final String userId;
  final String userName;

  Future<void> _addMetric(BuildContext context) async {
    var selectedCat = 'Entrenamiento';
    Map<String, String>? selectedMetric;
    final valorCtrl = TextEditingController();
    final notaCtrl = TextEditingController();
    var customName = '';
    var customUnit = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) {
          final metricsForCat = _kMetrics[selectedCat] ?? [];
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.show_chart, color: Color(0xFF009688)),
                const SizedBox(width: 8),
                Expanded(child: Text('Registrar métrica · $userName')),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría
                    DropdownButtonFormField<String>(
                      initialValue: selectedCat,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: _kMetrics.keys
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setDs(() {
                        selectedCat = v!;
                        selectedMetric = null;
                      }),
                    ),
                    const SizedBox(height: 14),
                    // Métrica
                    const Text(
                      'Métrica:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...metricsForCat.map((m) {
                          final isSelected = selectedMetric == m;
                          return ChoiceChip(
                            label: Text(m['nombre']!),
                            selected: isSelected,
                            selectedColor: const Color(0xFF009688).withValues(alpha: 0.2),
                            onSelected: (_) => setDs(() {
                              selectedMetric = m;
                              customName = '';
                            }),
                          );
                        }),
                        ChoiceChip(
                          label: const Text('+ Personalizada'),
                          selected: selectedMetric == null && customName.isNotEmpty,
                          selectedColor: Colors.orange.shade100,
                          onSelected: (_) => setDs(() {
                            selectedMetric = null;
                            customName = ' ';
                          }),
                        ),
                      ],
                    ),
                    if (selectedMetric == null && customName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => customName = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Unidad',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => customUnit = v,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Valor
                    TextField(
                      controller: valorCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Valor',
                        border: const OutlineInputBorder(),
                        suffixText: selectedMetric?['unidad'] ?? customUnit,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Nota
                    TextField(
                      controller: notaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Buena técnica, sin dolor',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  foregroundColor: Colors.white,
                ),
                child: const Text('REGISTRAR'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;

    final valor = double.tryParse(
      valorCtrl.text.replaceAll(',', '.').trim(),
    );
    if (valor == null) return;

    final nombre = selectedMetric?['nombre'] ?? customName.trim();
    final unidad = selectedMetric?['unidad'] ?? customUnit.trim();
    final polaridad = selectedMetric?['polaridad'] ?? 'neutral';
    if (nombre.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    var proNombre = currentUser?.displayName ?? '';
    if (proNombre.isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users_app')
            .doc(currentUser?.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          proNombre = (data['nombreCompleto'] as String?) ??
              (data['nombre'] as String?) ??
              '';
        }
      } catch (_) {}
    }

    await FirebaseFirestore.instance.collection('patient_metrics').add({
      'userId': userId,
      'profesionalId': currentUser?.uid ?? '',
      'profesionalNombre': proNombre,
      'categoria': selectedCat.toLowerCase(),
      'nombre': nombre,
      'valor': valor,
      'unidad': unidad,
      'polaridad': polaridad,
      'nota': notaCtrl.text.trim(),
      'fecha': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nombre: $valor$unidad registrado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('patient_metrics')
              .where('userId', isEqualTo: userId)
              .limit(100)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'Sin métricas registradas',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            // Ordenar por fecha en código
            final sorted = docs.toList()
              ..sort((a, b) {
                final tsA = ((a.data()! as Map<String, dynamic>)['fecha']
                            as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    0;
                final tsB = ((b.data()! as Map<String, dynamic>)['fecha']
                            as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    0;
                return tsB.compareTo(tsA);
              });

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: sorted.length,
              itemBuilder: (context, i) {
                final data = sorted[i].data()! as Map<String, dynamic>;
                final nombre = (data['nombre'] as String?) ?? '';
                final valor = (data['valor'] as num?)?.toDouble() ?? 0;
                final unidad = (data['unidad'] as String?) ?? '';
                final cat = (data['categoria'] as String?) ?? '';
                final pro = (data['profesionalNombre'] as String?) ?? '';
                final nota = (data['nota'] as String?) ?? '';
                final fecha =
                    (data['fecha'] as Timestamp?)?.toDate();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: Text(
                        valor.toStringAsFixed(valor == valor.roundToDouble() ? 0 : 1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF009688),
                        ),
                      ),
                    ),
                    title: Text(
                      '$nombre $unidad',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${cat.isNotEmpty ? "$cat · " : ""}'
                      '${pro.isNotEmpty ? "por $pro · " : ""}'
                      '${fecha != null ? DateFormat("dd/MM/yyyy").format(fecha) : ""}'
                      '${nota.isNotEmpty ? '\n"$nota"' : ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => sorted[i].reference.delete(),
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addMetric',
            onPressed: () => _addMetric(context),
            backgroundColor: const Color(0xFF009688),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'REGISTRAR MÉTRICA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
