import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/patient_document.dart';
import 'sign_document_screen.dart'; 
import '../widgets/salufit_scaffold.dart';

class DocumentsScreen extends StatefulWidget {
  final String userId;
  const DocumentsScreen({super.key, required this.userId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color salufitTeal = const Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el email para pasarlo a todas las pestañas (CRÍTICO para tu seguridad)
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return const Center(child: Text('Error de sesión'));

    return SalufitScaffold(
      body: SafeArea(
        child: Column(
          children: [
             // --- CABECERA ---
             Padding(
               padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.center,
                 children: [
                   Image.asset('assets/logo_salufit.png', width: 50, fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.folder_shared, size: 50, color: salufitTeal)),
                   const SizedBox(width: 15),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('MI EXPEDIENTE', style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: salufitTeal, height: 1.0)),
                         const SizedBox(height: 4),
                         const Text('Historial, Datos y Evolución', style: TextStyle(color: Colors.grey, fontSize: 13)),
                     ],
                   ),
                   ),
                 ],
               ),
             ),

            const SizedBox(height: 15),

            // --- TABS ---
            TabBar(
              controller: _tabController,
              labelColor: salufitTeal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: salufitTeal,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'DOCUMENTOS'),
                Tab(text: 'MÉTRICAS'),
                Tab(text: 'DIARIO'),
              ],
            ),

            // --- CONTENIDO ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DocumentsTab(userEmail: userEmail, userId: widget.userId, themeColor: salufitTeal),
                  // Pasamos userEmail a las nuevas pestañas
                  _MetricsTab(userEmail: userEmail, userId: widget.userId, themeColor: salufitTeal),
                  _JournalTab(userEmail: userEmail, userId: widget.userId, themeColor: salufitTeal),
                ],
              ),
            ),
          ],
        ),
      ), 
    ); 
  }
}

// ============================================================================
// PESTAÑA 1: DOCUMENTOS (Sin cambios en lógica, ya funcionaba bien)
// ============================================================================
class _DocumentsTab extends StatelessWidget {
  final String userEmail;
  final String userId;
  final Color themeColor;

  const _DocumentsTab({required this.userEmail, required this.userId, required this.themeColor});

  Map<String, dynamic> _getDocVisuals(bool firmado) {
    if (firmado) {
      return {'colors': [const Color(0xFF43A047), const Color(0xFF66BB6A)], 'icon': Icons.task_alt, 'textColor': Colors.green.shade900, 'statusText': 'FIRMADO'};
    } else {
      return {'colors': [const Color(0xFFFB8C00), const Color(0xFFFFA726)], 'icon': Icons.history_edu, 'textColor': Colors.orange.shade900, 'statusText': 'PENDIENTE'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('documents').where('userEmail', isEqualTo: userEmail).orderBy('fechaCreacion', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const _EmptyState(icon: Icons.folder_open, text: 'No tienes documentos');

        final docs = snapshot.data!.docs.map((doc) => PatientDocument.fromFirestore(doc)).toList();

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final visual = _getDocVisuals(doc.firmado);
            final List<Color> gradient = visual['colors'];
            
            return Container(
              height: 100,
              decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(0, 3))]),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)), child: Icon(visual['icon'], color: Colors.white)),
                title: Text(doc.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(doc.firmado ? "Firmado el ${DateFormat('dd/MM/yy').format(doc.fechaFirma!)}" : 'Requiere firma', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                trailing: !doc.firmado 
                  ? ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignDocumentScreen(userId: userId, documentId: doc.id, documentTitle: doc.titulo))),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: visual['textColor'], padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(70, 30)),
                      child: const Text('FIRMAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))
                  : const Icon(Icons.check, color: Colors.white),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// PESTAÑA 2: MÉTRICAS (Corregido: Root Collection + Email Filter)
// ============================================================================
class _MetricsTab extends StatefulWidget {
  final String userEmail; // Necesario para seguridad
  final String userId;
  final Color themeColor;
  const _MetricsTab({required this.userEmail, required this.userId, required this.themeColor});

  @override
  State<_MetricsTab> createState() => _MetricsTabState();
}

class _MetricsTabState extends State<_MetricsTab> {
  String? _selectedMetricType;

  void _showAddMetricDialog(List<String> existingTypes) {
    final TextEditingController typeController = TextEditingController();
    final TextEditingController valueController = TextEditingController();
    final TextEditingController unitController = TextEditingController(); 
    
    if (_selectedMetricType != null && _selectedMetricType != 'Todo') {
      typeController.text = _selectedMetricType!;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Medición'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return const Iterable<String>.empty();
                  return existingTypes.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) => typeController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  controller.addListener(() { typeController.text = controller.text; });
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: const InputDecoration(labelText: 'Tipo (ej: Peso)', border: OutlineInputBorder(), hintText: 'Escribe o selecciona'),
                  );
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(flex: 2, child: TextField(controller: valueController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(flex: 1, child: TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unidad', hintText: 'kg', border: OutlineInputBorder()))),
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (typeController.text.isEmpty || valueController.text.isEmpty) return;
              
              final double? val = double.tryParse(valueController.text.replaceAll(',', '.'));
              if (val == null) return;

              // CORRECCIÓN: Guardamos en raíz 'metrics' con userEmail para validar reglas
              await FirebaseFirestore.instance.collection('metrics').add({
                'userEmail': widget.userEmail, // <--- CLAVE DE SEGURIDAD
                'userId': widget.userId,
                'type': typeController.text.trim(), 
                'value': val,
                'unit': unitController.text.trim(),
                'date': FieldValue.serverTimestamp(),
                'addedBy': 'client'
              });
              
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            }, 
            child: const Text('GUARDAR')
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consulta base filtrada por email
    final Query baseQuery = FirebaseFirestore.instance.collection('metrics').where('userEmail', isEqualTo: widget.userEmail);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Buscamos tipos existentes en sus métricas para sugerir
          baseQuery.get().then((snap) {
            final Set<String> types = {};
            for (var doc in snap.docs) {
               types.add(doc['type']);
            }
            _showAddMetricDialog(types.toList());
          });
        },
        backgroundColor: widget.themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: baseQuery.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              
              final Set<String> types = {'Todo'};
              for (var doc in snapshot.data!.docs) {
                types.add((doc['type'] as String));
              }
              final List<String> typeList = types.toList();
              typeList.sort();
  
              return Container(
                height: 50,
                margin: const EdgeInsets.only(top: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: typeList.length,
                  itemBuilder: (context, index) {
                    final String type = typeList[index];
                    final bool isSelected = _selectedMetricType == type || (_selectedMetricType == null && type == 'Todo');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: widget.themeColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(color: isSelected ? widget.themeColor : Colors.grey),
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedMetricType = type == 'Todo' ? null : type;
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
  
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: baseQuery.orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs;
                if (_selectedMetricType != null) {
                  docs = docs.where((d) => d['type'] == _selectedMetricType).toList();
                }
  
                if (docs.isEmpty) return const _EmptyState(icon: Icons.show_chart, text: 'Sin registros.\nAñade tus mediciones (Peso, RM...)');
  
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final DateTime date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                    
                    return Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: widget.themeColor.withValues(alpha: 0.1),
                          child: Icon(Icons.insights, color: widget.themeColor, size: 20),
                        ),
                        title: Text(data['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          "${data['value']} ${data['unit'] ?? ''}", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: widget.themeColor)
                        ),
                        subtitle: Text(DateFormat('dd MMM yyyy - HH:mm').format(date)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PESTAÑA 3: DIARIO (Corregido: Root Collection + Email Filter)
// ============================================================================
class _JournalTab extends StatefulWidget {
  final String userEmail; // Necesario para seguridad
  final String userId;
  final Color themeColor;
  const _JournalTab({required this.userEmail, required this.userId, required this.themeColor});

  @override
  State<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<_JournalTab> {
  void _addEntry() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'Sensaciones';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Entrada'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category, 
                items: ['Sensaciones', 'Dolor', 'Emoción', 'Logro', 'Otro'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v!,
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título breve', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                controller: contentController, 
                maxLines: 4, 
                decoration: const InputDecoration(labelText: '¿Qué quieres contar?', border: OutlineInputBorder(), alignLabelWithHint: true)
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (contentController.text.isEmpty) return;
              
              // CORRECCIÓN: Guardamos en raíz 'journal' con userEmail
              await FirebaseFirestore.instance.collection('journal').add({
                'userEmail': widget.userEmail, // <--- CLAVE DE SEGURIDAD
                'userId': widget.userId,
                'title': titleController.text.isEmpty ? 'Sin título' : titleController.text,
                'content': contentController.text,
                'category': category,
                'date': FieldValue.serverTimestamp(),
                'isStaffRead': false, 
              });

              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            }, 
            child: const Text('GUARDAR')
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consulta base filtrada por email
    final Query baseQuery = FirebaseFirestore.instance.collection('journal').where('userEmail', isEqualTo: widget.userEmail);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: widget.themeColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: baseQuery.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const _EmptyState(icon: Icons.book, text: 'Diario vacío.\nEscribe sensaciones o logros.');

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final DateTime date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
              final bool isRead = data['isStaffRead'] ?? false;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: widget.themeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(data['category'] ?? 'General', style: TextStyle(color: widget.themeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          if (isRead) 
                            const Tooltip(message: 'Visto por el profesional', child: Icon(Icons.done_all, size: 16, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 5),
                      Text(data['content'], style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                      const SizedBox(height: 10),
                      Text(DateFormat('dd MMM - HH:mm').format(date), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}