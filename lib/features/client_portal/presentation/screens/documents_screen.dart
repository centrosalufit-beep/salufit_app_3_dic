// lib/features/patient_record/presentation/documents_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/patient_record/presentation/sign_document_screen.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

// ============================================================================
// MODELOS LOCALES
// ============================================================================
class PatientDocument {
  const PatientDocument({
    required this.id,
    required this.title,
    required this.isSigned,
    required this.signedDate,
    required this.customConsents,
  });

  factory PatientDocument.fromMap(String id, Map<String, dynamic>? map) {
    return PatientDocument(
      id: id,
      title: map.safeString('titulo', defaultValue: 'Documento sin título'),
      isSigned: map.safeBool('firmado'),
      signedDate: map.safeDateTime('fechaFirma'),
      customConsents: map.safeList<String>(
        'customConsents',
        (e) => e.toString(),
      ),
    );
  }

  final String id;
  final String title;
  final bool isSigned;
  final DateTime signedDate;
  final List<String> customConsents;
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    required this.userId,
    super.key,
    this.embedMode = false,
  });
  final String userId;
  final bool embedMode;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color salufitTeal = Color(0xFF009688);

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
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return const Center(child: Text('Error de sesión'));
    }

    final Widget content = SafeArea(
      top: !widget.embedMode,
      bottom: false,
      child: Column(
        children: <Widget>[
          if (!widget.embedMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    'assets/logo_salufit.png',
                    width: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                        const Icon(
                      Icons.folder_shared,
                      size: 50,
                      color: salufitTeal,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'MI EXPEDIENTE',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: salufitTeal,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Historial, Datos y Evolución',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (!widget.embedMode) const SizedBox(height: 15),
          TabBar(
            controller: _tabController,
            labelColor: salufitTeal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: salufitTeal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const <Widget>[
              Tab(text: 'DOCUMENTOS'),
              Tab(text: 'MÉTRICAS'),
              Tab(text: 'DIARIO'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _DocumentsTab(
                  userEmail: userEmail,
                  userId: widget.userId,
                  themeColor: salufitTeal,
                ),
                _MetricsTab(
                  userEmail: userEmail,
                  userId: widget.userId,
                  themeColor: salufitTeal,
                ),
                _JournalTab(
                  userEmail: userEmail,
                  userId: widget.userId,
                  themeColor: salufitTeal,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.embedMode) {
      return content;
    } else {
      return SalufitScaffold(body: content);
    }
  }
}

// ============================================================================
// PESTAÑA 1: DOCUMENTOS (Refactorizado con Modelo Seguro)
// ============================================================================
class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({
    required this.userEmail,
    required this.userId,
    required this.themeColor,
  });
  final String userEmail;
  final String userId;
  final Color themeColor;

  Map<String, dynamic> _getDocVisuals(bool isSigned) {
    if (isSigned) {
      return <String, dynamic>{
        'colors': <Color>[const Color(0xFF43A047), const Color(0xFF66BB6A)],
        'icon': Icons.task_alt,
        'textColor': Colors.green.shade900,
        'statusText': 'FIRMADO',
      };
    } else {
      return <String, dynamic>{
        'colors': <Color>[const Color(0xFFFB8C00), const Color(0xFFFFA726)],
        'icon': Icons.history_edu,
        'textColor': Colors.orange.shade900,
        'statusText': 'PENDIENTE',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // CORRECCIÓN CRÍTICA: Filtrar por userId para cumplir reglas de seguridad
      stream: FirebaseFirestore.instance
          .collection('documents')
          .where('userId', isEqualTo: userId)
          .orderBy('fechaCreacion', descending: true)
          .snapshots(),
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Object?>> snapshot,
      ) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.folder_open,
            text: 'No tienes documentos',
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 15),
          itemBuilder: (BuildContext context, int index) {
            final rawDoc = docs[index];
            final document = PatientDocument.fromMap(
              rawDoc.id,
              rawDoc.data() as Map<String, dynamic>?,
            );

            final visual = _getDocVisuals(document.isSigned);
            final gradient = (visual['colors'] as List).cast<Color>();

            return Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(15),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(visual['icon'] as IconData, color: Colors.white),
                ),
                title: Text(
                  document.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  document.isSigned
                      ? "Firmado el ${DateFormat('dd/MM/yy').format(document.signedDate)}"
                      : 'Requiere firma',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: !document.isSigned
                    ? ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SignDocumentScreen(
                              userId: userId,
                              documentId: document.id,
                              documentTitle: document.title,
                              consentOptions: document.customConsents,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: visual['textColor'] as Color,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(70, 30),
                        ),
                        child: const Text(
                          'FIRMAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
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
// PESTAÑA 2: MÉTRICAS (Restaurada y corregida)
// ============================================================================
class _MetricsTab extends StatefulWidget {
  const _MetricsTab({
    required this.userEmail,
    required this.userId,
    required this.themeColor,
  });
  final String userEmail;
  final String userId;
  final Color themeColor;
  @override
  State<_MetricsTab> createState() => _MetricsTabState();
}

class _MetricsTabState extends State<_MetricsTab> {
  String? _selectedMetricType;

  // Restaurado: Diálogo para añadir métricas
  void _showAddMetricDialog(List<String> existingTypes) {
    final typeController = TextEditingController();
    final valueController = TextEditingController();
    final unitController = TextEditingController();

    if (_selectedMetricType != null && _selectedMetricType != 'Todo') {
      typeController.text = _selectedMetricType!;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Nueva Medición'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return existingTypes.where(
                    (String option) => option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()),
                  );
                },
                onSelected: (String selection) =>
                    typeController.text = selection,
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController controller,
                  FocusNode focusNode,
                  onEditingComplete,
                ) {
                  controller.addListener(() {
                    typeController.text = controller.text;
                  });
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: const InputDecoration(
                      labelText: 'Tipo (ej: Peso)',
                      border: OutlineInputBorder(),
                      hintText: 'Escribe o selecciona',
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: valueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        hintText: 'kg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (typeController.text.isEmpty || valueController.text.isEmpty) {
                return;
              }
              final val =
                  double.tryParse(valueController.text.replaceAll(',', '.'));
              if (val == null) return;

              // Guardar usando userId para cumplir reglas de seguridad
              await FirebaseFirestore.instance
                  .collection('metrics')
                  .add(<String, dynamic>{
                'userEmail': widget.userEmail,
                'userId': widget.userId,
                'type': typeController.text.trim(),
                'value': val,
                'unit': unitController.text.trim(),
                'date': FieldValue.serverTimestamp(),
                'addedBy': 'client',
              });

              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN CRÍTICA: Filtrar por userId
    final Query baseQuery = FirebaseFirestore.instance
        .collection('metrics')
        .where('userId', isEqualTo: widget.userId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          baseQuery.get().then((QuerySnapshot<Object?> snap) {
            final types = <String>{};
            for (final doc in snap.docs) {
              final d = doc.data() as Map<String, dynamic>?;
              types.add(d.safeString('type'));
            }
            _showAddMetricDialog(types.toList());
          });
        },
        backgroundColor: widget.themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: <Widget>[
          // Filtro de Chips
          StreamBuilder<QuerySnapshot>(
            stream: baseQuery.snapshots(),
            builder: (
              BuildContext context,
              AsyncSnapshot<QuerySnapshot<Object?>> snapshot,
            ) {
              if (!snapshot.hasData) return const SizedBox();
              final types = <String>{'Todo'};
              for (final doc in snapshot.data!.docs) {
                final d = doc.data() as Map<String, dynamic>?;
                types.add(d.safeString('type'));
              }
              final typeList = types.toList()..sort();

              return Container(
                height: 50,
                margin: const EdgeInsets.only(top: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: typeList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final type = typeList[index];
                    final isSelected = _selectedMetricType == type ||
                        (_selectedMetricType == null && type == 'Todo');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: widget.themeColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? widget.themeColor : Colors.grey,
                        ),
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

          // Lista de Métricas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: baseQuery.orderBy('date', descending: true).snapshots(),
              builder: (
                BuildContext context,
                AsyncSnapshot<QuerySnapshot<Object?>> snapshot,
              ) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;
                // Filtro local
                if (_selectedMetricType != null) {
                  docs = docs.where((QueryDocumentSnapshot<Object?> d) {
                    final map = d.data() as Map<String, dynamic>?;
                    return map.safeString('type') == _selectedMetricType;
                  }).toList();
                }
                if (docs.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.show_chart,
                    text: 'Sin registros.\nAñade tus mediciones (Peso, RM...)',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final data = docs[index].data() as Map<String, dynamic>?;

                    final type = data.safeString('type');
                    final value = data.safeDouble('value');
                    final unit = data.safeString('unit');
                    final date = data.safeDateTime('date');

                    return Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              widget.themeColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.insights,
                            color: widget.themeColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          type,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          '$value $unit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: widget.themeColor,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy - HH:mm').format(date),
                        ),
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
// PESTAÑA 3: DIARIO (Restaurada y corregida)
// ============================================================================
class _JournalTab extends StatefulWidget {
  const _JournalTab({
    required this.userEmail,
    required this.userId,
    required this.themeColor,
  });
  final String userEmail;
  final String userId;
  final Color themeColor;
  @override
  State<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<_JournalTab> {
  void _addEntry() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    var category = 'Sensaciones';

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Nueva Entrada'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: category,
                items: <String>[
                  'Sensaciones',
                  'Dolor',
                  'Emoción',
                  'Logro',
                  'Otro',
                ]
                    .map(
                      (String c) => DropdownMenuItem(value: c, child: Text(c)),
                    )
                    .toList(),
                onChanged: (String? v) => category = v!,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título breve',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '¿Qué quieres contar?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (contentController.text.isEmpty) return;

              // Guardar usando userId para cumplir reglas de seguridad
              await FirebaseFirestore.instance
                  .collection('journal')
                  .add(<String, dynamic>{
                'userEmail': widget.userEmail,
                'userId': widget.userId,
                'title': titleController.text.isEmpty
                    ? 'Sin título'
                    : titleController.text,
                'content': contentController.text,
                'category': category,
                'date': FieldValue.serverTimestamp(),
                'isStaffRead': false,
              });

              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN CRÍTICA: Filtrar por userId
    final Query baseQuery = FirebaseFirestore.instance
        .collection('journal')
        .where('userId', isEqualTo: widget.userId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: widget.themeColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: baseQuery.orderBy('date', descending: true).snapshots(),
        builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot<Object?>> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const _EmptyState(
              icon: Icons.book,
              text: 'Diario vacío.\nEscribe sensaciones o logros.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              final data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>?;

              final category =
                  data.safeString('category', defaultValue: 'General');
              final isRead = data.safeBool('isStaffRead');
              final title = data.safeString('title');
              final content = data.safeString('content');
              final date = data.safeDateTime('date');

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: widget.themeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isRead)
                            const Tooltip(
                              message: 'Visto por el profesional',
                              child: Icon(
                                Icons.done_all,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        content,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('dd MMM - HH:mm').format(date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
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
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
