import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AdminPatientListScreen extends StatefulWidget {
  const AdminPatientListScreen({
    required this.viewerRole,
    required this.onUserSelected,
    super.key,
  });
  final String viewerRole;
  final void Function(String uid, String name) onUserSelected;

  @override
  State<AdminPatientListScreen> createState() => _AdminPatientListScreenState();
}

class _AdminPatientListScreenState extends State<AdminPatientListScreen> {
  String _query = '';
  bool _searchInExcel = false;

  void _editEmail(String docId, String currentEmail) {
    final controller = TextEditingController(text: currentEmail);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Corregir Email en Ficha'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nuevo Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = controller.text.trim().toLowerCase();
              await FirebaseFirestore.instance
                  .collection('legacy_import')
                  .doc(docId)
                  .update({'email': newEmail});
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('ACTUALIZAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collection = _searchInExcel ? 'legacy_import' : 'users';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscador de Pacientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('En App'),
                  icon: Icon(Icons.smartphone),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('En Fichas'),
                  icon: Icon(Icons.table_view),
                ),
              ],
              selected: {_searchInExcel},
              onSelectionChanged: (val) =>
                  setState(() => _searchInExcel = val.first),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Nombre, Email o Historia...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _query.isEmpty
                  ? FirebaseFirestore.instance
                      .collection(collection)
                      .limit(10)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection(collection)
                      .where('rol', isEqualTo: 'cliente')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No hay resultados'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data()! as Map<String, dynamic>;
                    final nombre = data.safeString('nombreCompleto');
                    final email = data.safeString('email');

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _searchInExcel
                            ? Colors.orange.shade100
                            : Colors.teal.shade100,
                        child: Text(nombre.isNotEmpty ? nombre[0] : '?'),
                      ),
                      title: Text(nombre),
                      subtitle: Text('ID: ${doc.id} | $email'),
                      trailing: _searchInExcel
                          ? IconButton(
                              icon: const Icon(
                                Icons.edit_note,
                                color: Colors.orange,
                              ),
                              onPressed: () => _editEmail(doc.id, email),
                            )
                          : const Icon(Icons.check_circle, color: Colors.teal),
                      onTap: _searchInExcel
                          ? null
                          : () => widget.onUserSelected(doc.id, nombre),
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




