import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCreatePatientScreen extends StatefulWidget {
  const AdminCreatePatientScreen({super.key});

  @override
  State<AdminCreatePatientScreen> createState() =>
      _AdminCreatePatientScreenState();
}

class _AdminCreatePatientScreenState extends State<AdminCreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dniController = TextEditingController();

  Future<void> _crearPaciente() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('users_app').add({
        'nombreCompleto': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'dni': _dniController.text.trim().toUpperCase(),
        'rol': 'cliente',
        'activado': true,
        'creadoEn': FieldValue.serverTimestamp(),
        'keywords': [
          _nameController.text.toLowerCase(),
          _dniController.text.toLowerCase(),
        ],
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alta de Nuevo Paciente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
              validator: (v) => v!.isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => !v!.contains('@') ? 'Email inválido' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _dniController,
              decoration: const InputDecoration(labelText: 'DNI / NIE'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _crearPaciente,
              child: const Text('GUARDAR PACIENTE'),
            ),
          ],
        ),
      ),
    );
  }
}
