import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminCreatePatientScreen extends StatefulWidget {
  const AdminCreatePatientScreen({super.key});

  @override
  State<AdminCreatePatientScreen> createState() => _AdminCreatePatientScreenState();
}

class _AdminCreatePatientScreenState extends State<AdminCreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaController = TextEditingController();
  bool _isLoading = false;

  String removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  List<String> _generateKeywords(String nombre, String id) {
    List<String> keywords = [];
    String nombreLimpio = removeDiacritics(nombre.toLowerCase().trim());
    List<String> palabras = nombreLimpio.split(RegExp(r'\s+'));
    keywords.addAll(palabras);
    String idSinCeros = id.replaceFirst(RegExp(r'^0+'), '');
    keywords.add(id.toLowerCase());
    if (idSinCeros.isNotEmpty) keywords.add(idSinCeros);
    return keywords.toSet().toList();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaController.text = DateFormat('dd/MM/yyyy').format(picked));
    }
  }

  Future<void> _crearPaciente() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    String idRaw = _idController.text.trim();
    String idConCeros = idRaw.padLeft(6, '0');
    String nombreInput = _nombreController.text.trim();

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(idConCeros);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Error! Ya existe un paciente con ese ID."), backgroundColor: Colors.red));
        setState(() { _isLoading = false; });
        return;
      }

      List<String> searchKeywords = _generateKeywords(nombreInput, idConCeros);

      await docRef.set({
        'id': idConCeros,
        'nombreCompleto': nombreInput,
        'email': _emailController.text.trim().toLowerCase(),
        'telefono': _telefonoController.text.trim(),
        'fechaNacimiento': _fechaController.text.trim(),
        'rol': 'cliente',
        'activo': true,
        'creadoEn': FieldValue.serverTimestamp(),
        'keywords': searchKeywords, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Paciente $idConCeros creado con éxito"), backgroundColor: Colors.green));
        Navigator.pop(context); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al crear: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alta Nuevo Paciente"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 60, color: Colors.teal),
              const SizedBox(height: 20),
              TextFormField(controller: _idController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Número de Historia *", hintText: "Ej: 5800", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)), validator: (v) => v!.isEmpty ? "Obligatorio" : null),
              const SizedBox(height: 15),
              TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre y Apellidos *", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? "Obligatorio" : null),
              const SizedBox(height: 15),
              TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: "Email *", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)), validator: (v) => v!.contains('@') ? null : "Email inválido"),
              const SizedBox(height: 15),
              TextFormField(controller: _telefonoController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Teléfono", hintText: "34629011055", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 15),
              TextFormField(controller: _fechaController, readOnly: true, onTap: _selectDate, decoration: const InputDecoration(labelText: "Fecha Nacimiento", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today))),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _isLoading ? null : _crearPaciente, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("GUARDAR PACIENTE")))
            ],
          ),
        ),
      ),
    );
  }
}