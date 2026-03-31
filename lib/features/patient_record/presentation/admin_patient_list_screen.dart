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

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text('Buscador Maestro de Clientes (App)'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por Nombre, Apellido o Nº Historia...',
                prefixIcon: Icon(Icons.person_search, color: Color(0xFF00796B)),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _query.isEmpty
                  ? FirebaseFirestore.instance
                      .collection('users_app')
                      .where('termsAccepted', isEqualTo: true)
                      .limit(20)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('users_app')
                      .where('termsAccepted', isEqualTo: true)
                      .where('keywords', arrayContains: _query)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No se encontraron clientes con App activa.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data()! as Map<String, dynamic>;
                    final nombre = data.safeString('nombreCompleto');
                    final idH = data.safeString('numHistoria');

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?'),
                        ),
                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Hª: $idH | ${data.safeString('email')}'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.teal),
                        onTap: () => widget.onUserSelected(docs[index].id, nombre),
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
