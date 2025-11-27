import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AdminClassManagerScreen extends StatefulWidget {
  final String currentUserId;

  const AdminClassManagerScreen({super.key, required this.currentUserId});

  @override
  State<AdminClassManagerScreen> createState() => _AdminClassManagerScreenState();
}

class _AdminClassManagerScreenState extends State<AdminClassManagerScreen> {
  DateTime _selectedDate = DateTime.now();
  final String _crearReservaUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/crearReserva';
  final String _cancelarReservaUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/cancelarReserva';

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _removeUser(String bookingId, String classId, String userName) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Dar de baja"),
        content: Text("¿Sacar a $userName de la clase?\nSe devolverá el token si corresponde."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Sacar", style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse(_cancelarReservaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ 'userId': widget.currentUserId, 'bookingId': bookingId }), 
      );
      
      if (response.statusCode != 200) {
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
        await FirebaseFirestore.instance.collection('groupClasses').doc(classId).update({
          'aforoActual': FieldValue.increment(-1)
        });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario eliminado manualmente (Admin override)")));
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario eliminado correctamente")));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _promoteUser(String bookingId, String classId, String userName) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Forzar Entrada"),
        content: Text("¿Pasar a $userName de 'Espera' a 'Confirmado'?\n\n⚠️ Esto aumentará el aforo aunque esté lleno."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text("FORZAR ENTRADA")
          ),
        ],
      )
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'estado': 'reservada'});
      await FirebaseFirestore.instance.collection('groupClasses').doc(classId).update({'aforoActual': FieldValue.increment(1)});
      
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario movido a Confirmados")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showAddUserDialog(String classId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _UserSearchSheet(classId: classId, apiUrl: _crearReservaUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Gestión de Clases", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.teal.shade50,
            width: double.infinity,
            child: Text(
              DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('groupClasses')
                  .where('fechaHoraInicio', isGreaterThanOrEqualTo: startOfDay)
                  .where('fechaHoraInicio', isLessThanOrEqualTo: endOfDay)
                  .orderBy('fechaHoraInicio')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No hay clases programadas para este día"));

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var classDoc = snapshot.data!.docs[index];
                    var data = classDoc.data() as Map<String, dynamic>;
                    
                    String nombre = data['nombre'] ?? "Clase";
                    String hora = DateFormat('HH:mm').format((data['fechaHoraInicio'] as Timestamp).toDate());
                    int aforo = data['aforoActual'] ?? 0;
                    int max = data['aforoMaximo'] ?? 12;
                    String monitor = data['monitor'] ?? "Staff";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(hora, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("$monitor • $aforo/$max inscritos"),
                        children: [
                          _AttendeesList(
                            classId: classDoc.id, 
                            onRemove: (bid, name) => _removeUser(bid, classDoc.id, name),
                            onPromote: (bid, name) => _promoteUser(bid, classDoc.id, name),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddUserDialog(classDoc.id),
                                icon: const Icon(Icons.person_add),
                                label: const Text("AÑADIR CLIENTE MANUALMENTE"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade50, foregroundColor: Colors.teal),
                              ),
                            ),
                          )
                        ],
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

class _AttendeesList extends StatelessWidget {
  final String classId;
  final Function(String, String) onRemove;
  final Function(String, String) onPromote;

  const _AttendeesList({required this.classId, required this.onRemove, required this.onPromote});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings')
          .where('groupClassId', isEqualTo: classId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs;
        var confirmados = docs.where((d) => (d.data() as Map<String,dynamic>)['estado'] != 'espera').toList();
        var espera = docs.where((d) => (d.data() as Map<String,dynamic>)['estado'] == 'espera').toList();

        return Column(
          children: [
            if (confirmados.isEmpty && espera.isEmpty) 
              const Padding(padding: EdgeInsets.all(15), child: Text("Nadie inscrito aún", style: TextStyle(color: Colors.grey))),

            if (confirmados.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                color: Colors.green.shade50,
                child: Text("CONFIRMADOS (${confirmados.length})", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              ...confirmados.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  title: Text(data['userName'] ?? "Usuario ${data['userId']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => onRemove(doc.id, data['userName'] ?? "Usuario"),
                  ),
                );
              }),
            ],

            if (espera.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                color: Colors.orange.shade50,
                child: Text("LISTA DE ESPERA (${espera.length})", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              ...espera.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
                  title: Text(data['userName'] ?? "Usuario"),
                  subtitle: const Text("En espera de plaza"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Forzar entrada (Superar aforo)",
                        icon: const Icon(Icons.vertical_align_top, color: Colors.green),
                        onPressed: () => onPromote(doc.id, data['userName'] ?? "Usuario"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => onRemove(doc.id, data['userName'] ?? "Usuario"),
                      ),
                    ],
                  ),
                );
              }),
            ]
          ],
        );
      },
    );
  }
}

class _UserSearchSheet extends StatefulWidget {
  final String classId;
  final String apiUrl;
  const _UserSearchSheet({required this.classId, required this.apiUrl});

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  String _search = "";
  
  String removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  Future<void> _inscribir(String userId, String userName) async {
    try {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Inscribiendo a $userName...")));
      
      final response = await http.post(
        Uri.parse(widget.apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ 'userId': userId, 'groupClassId': widget.classId }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inscrito correctamente"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? "Error"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- BÚSQUEDA MEJORADA ---
  Stream<QuerySnapshot> _getUsersStream() {
    // Si no hay búsqueda, mostramos los primeros 50 ordenados alfabéticamente
    if (_search.isEmpty) {
      return FirebaseFirestore.instance.collection('users').orderBy('nombreCompleto').limit(50).snapshots();
    }
    
    // Si hay búsqueda, usamos la búsqueda por keywords (que ya reparamos con el script)
    return FirebaseFirestore.instance.collection('users')
        .where('keywords', arrayContains: _search)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 600,
      child: Column(
        children: [
          const Text("Añadir Asistente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            decoration: InputDecoration(
              hintText: "Buscar paciente...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey.shade100
            ),
            onChanged: (v) => setState(() => _search = removeDiacritics(v.toLowerCase().trim())),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs;

                // Filtro adicional en cliente para búsquedas parciales si keywords falla o para ID numérico
                if (_search.isNotEmpty) {
                  docs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String nombre = removeDiacritics((data['nombreCompleto'] ?? "").toString().toLowerCase());
                    String id = doc.id;
                    // Si Firebase ya filtró por keywords, esto es redundante pero seguro
                    // Si Firebase no filtró (ej: buscamos por ID), esto lo atrapa
                    return nombre.contains(_search) || id.contains(_search);
                  }).toList();
                }

                if (docs.isEmpty) return const Center(child: Text("No se encontraron usuarios"));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    var user = docs[index];
                    var data = user.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['nombreCompleto'] ?? "Usuario"),
                      subtitle: Text("ID: ${user.id}"),
                      trailing: ElevatedButton(
                        onPressed: () => _inscribir(user.id, data['nombreCompleto'] ?? "Usuario"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        child: const Text("AÑADIR"),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}