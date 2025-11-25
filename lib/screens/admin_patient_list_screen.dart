import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_patient_detail_screen.dart'; 
import 'admin_create_patient_screen.dart';

class AdminPatientListScreen extends StatefulWidget {
  final String viewerRole; 

  const AdminPatientListScreen({super.key, required this.viewerRole});

  @override
  State<AdminPatientListScreen> createState() => _AdminPatientListScreenState();
}

class _AdminPatientListScreenState extends State<AdminPatientListScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.viewerRole == 'admin';

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text("Pacientes y Staff"), // Cambio de título
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      
      floatingActionButton: isAdmin 
        ? FloatingActionButton(
            backgroundColor: Colors.teal,
            child: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminCreatePatientScreen()),
              );
            },
          )
        : null,

      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15.0),
            color: Colors.teal,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por Nombre o ID...",
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ""); }) : null
              ),
              onChanged: (value) { setState(() { _searchQuery = value.trim().toLowerCase(); }); },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("No se encontraron usuarios"));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String nombre = (data['nombreCompleto'] ?? data['nombre'] ?? "Sin nombre").toString();
                    String id = docs[index].id;
                    String rol = (data['rol'] ?? "cliente").toString();
                    String telefono = (data['telefono'] ?? "").toString(); 
                    bool showPhone = widget.viewerRole == 'admin';

                    return ListTile(
                      tileColor: Colors.white,
                      leading: CircleAvatar(
                        // Color diferente para profesional/admin
                        backgroundColor: rol == 'profesional' || rol == 'admin' ? Colors.orange.shade400 : Colors.blue.shade400,
                        child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("ID: $id • ${rol.toUpperCase()} ${showPhone && telefono.isNotEmpty ? '• $telefono' : ''}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminPatientDetailScreen(
                              userId: id, 
                              userName: nombre,
                              viewerRole: widget.viewerRole,
                            ),
                          ),
                        );
                      },
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

  Stream<QuerySnapshot> _getUsersStream() {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    // 1. Sin búsqueda: Mostrar todos (ya no filtramos por rol)
    if (_searchQuery.isEmpty) {
      return users.orderBy(FieldPath.documentId).limit(50).snapshots();
    }

    // 2. Búsqueda por keywords (ya busca en todos porque el campo keywords existe en todos)
    return users
        .where('keywords', arrayContains: _searchQuery)
        .limit(50)
        .snapshots();
  }
}