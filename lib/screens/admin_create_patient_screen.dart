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
  
  // Controladores
  final _idController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaController = TextEditingController();

  bool _isLoading = false;

  // Selector de Fecha (CORREGIDO: Sin forzar locale para evitar crash)
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      // locale: const Locale('es', 'ES'), // <--- LÍNEA ELIMINADA PARA ARREGLAR EL ERROR
    );
    if (picked != null) {
      setState(() {
        _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _crearPaciente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    // 1. Formatear ID (Añadir ceros)
    String idRaw = _idController.text.trim();
    String idConCeros = idRaw.padLeft(6, '0');

    try {
      // 2. Verificar si ya existe
      final docRef = FirebaseFirestore.instance.collection('users').doc(idConCeros);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Error! Ya existe un paciente con ese ID."), backgroundColor: Colors.red),
        );
        setState(() { _isLoading = false; });
        return;
      }

      // 3. Crear Documento
      await docRef.set({
        'id': idConCeros,
        'nombreCompleto': _nombreController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'telefono': _telefonoController.text.trim(),
        'fechaNacimiento': _fechaController.text.trim(),
        'rol': 'cliente', // Por defecto siempre cliente
        'activo': true,
        'creadoEn': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Paciente $idConCeros creado con éxito"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volver atrás
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al crear: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alta Nuevo Paciente"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 60, color: Colors.teal),
              const SizedBox(height: 20),
              
              // ID
              TextFormField(
                controller: _idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Número de Historia *",
                  hintText: "Ej: 5800",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge)
                ),
                validator: (v) => v!.isEmpty ? "El ID es obligatorio" : null,
              ),
              const SizedBox(height: 15),

              // NOMBRE
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre y Apellidos *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person)
                ),
                validator: (v) => v!.isEmpty ? "El nombre es obligatorio" : null,
              ),
              const SizedBox(height: 15),

              // EMAIL
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email)
                ),
                validator: (v) => v!.contains('@') ? null : "Email inválido",
              ),
              const SizedBox(height: 15),

              // TELÉFONO (CON EL AVISO EN MAYÚSCULAS)
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Teléfono",
                  hintText: "INSERTAR PREFIJO EJ: 34629011055", // <--- CAMBIO AQUÍ
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone)
                ),
              ),
              const SizedBox(height: 15),

              // FECHA NACIMIENTO
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: "Fecha Nacimiento",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today)
                ),
              ),
              
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _crearPaciente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("GUARDAR PACIENTE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}