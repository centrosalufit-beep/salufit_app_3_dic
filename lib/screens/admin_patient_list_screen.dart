import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_patient_detail_screen.dart'; 
import 'admin_create_patient_screen.dart';

class AdminPatientListScreen extends StatefulWidget {
  final String viewerRole; 
  // Nueva función opcional para redirigir el clic
  final Function(String userId, String userName)? onUserSelected;

  const AdminPatientListScreen({
    super.key, 
    required this.viewerRole,
    this.onUserSelected, // <--- Si es null, abre perfil normal. Si tiene valor, ejecuta la acción.
  });

  @override
  State<AdminPatientListScreen> createState() => _AdminPatientListScreenState();
}

class _AdminPatientListScreenState extends State<AdminPatientListScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  String removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.viewerRole == 'admin';
    // Si estamos en modo selección, cambiamos el título y ocultamos el botón de crear
    bool isSelectionMode = widget.onUserSelected != null;

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(isSelectionMode ? "Seleccionar Paciente" : "Pacientes y Staff"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: (isAdmin && !isSelectionMode)
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
                hintText: "Buscar (Ej: Jose Baydal...)",
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ""); }) 
                  : null
              ),
              onChanged: (value) { 
                setState(() { _searchQuery = removeDiacritics(value.trim().toLowerCase()); }); 
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs;
                
                if (_searchQuery.isNotEmpty) {
                  List<String> terminosBusqueda = _searchQuery.split(' '); 
                  docs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String nombreOriginal = (data['nombreCompleto'] ?? data['nombre'] ?? "").toString();
                    String nombreLimpio = removeDiacritics(nombreOriginal.toLowerCase());
                    String id = doc.id.toLowerCase();
                    bool coincideTodo = true;
                    for (var termino in terminosBusqueda) {
                      if (termino.isEmpty) continue;
                      bool estaEnNombre = nombreLimpio.contains(termino);
                      bool estaEnId = id.contains(termino);
                      if (!estaEnNombre && !estaEnId) { coincideTodo = false; break; }
                    }
                    return coincideTodo;
                  }).toList();
                }

                if (docs.isEmpty) return const Center(child: Text("No se encontraron coincidencias"));

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
                        backgroundColor: rol == 'profesional' || rol == 'admin' ? Colors.orange.shade400 : Colors.blue.shade400,
                        child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("ID: $id • ${rol.toUpperCase()} ${showPhone && telefono.isNotEmpty ? '• $telefono' : ''}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        if (widget.onUserSelected != null) {
                          // MODO SELECCIÓN RÁPIDA
                          widget.onUserSelected!(id, nombre);
                        } else {
                          // MODO NORMAL (Perfil completo)
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPatientDetailScreen(userId: id, userName: nombre, viewerRole: widget.viewerRole)));
                        }
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
    if (_searchQuery.isEmpty) return users.orderBy('nombreCompleto').limit(50).snapshots();
    String primeraPalabra = _searchQuery.split(' ')[0]; 
    return users.where('keywords', arrayContains: primeraPalabra).limit(50).snapshots();
  }
}