import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salufit_app/core/config/app_config.dart';

class AdminClassManagerScreen extends StatefulWidget {
  const AdminClassManagerScreen({super.key});

  @override
  State<AdminClassManagerScreen> createState() => _AdminClassManagerScreenState();
}

class _AdminClassManagerScreenState extends State<AdminClassManagerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  String _nombreClase = 'Entrenamiento Funcional';
  String _profesional = 'Equipo Salufit';
  final int _aforoMax = 8;
  final int _selectedMonth = DateTime.now().month;
  final int _selectedYear = DateTime.now().year;

  final Map<int, bool> _diasSeleccionados = {
    0: false, 1: false, 2: false, 3: false, 4: false, 5: false, 6: false,
  };
  final List<String> _nombresDias = const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  final List<TimeOfDay> _horarios = [const TimeOfDay(hour: 16, minute: 0)];

  bool _isProcessing = false;

  void _addHorario() {
    setState(() => _horarios.add(const TimeOfDay(hour: 17, minute: 0)));
  }

  void _removeHorario(int index) {
    if (_horarios.length > 1) {
      setState(() => _horarios.removeAt(index));
    }
  }

  Future<void> _generarClases() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_diasSeleccionados.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      final diasEnvio = _diasSeleccionados.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final horasEnvio = _horarios.map((t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
      ).toList();

      final response = await http.post(
        Uri.parse(AppConfig.urlGenerarClases),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': _nombreClase,
          'profesional': _profesional,
          'diasSemana': diasEnvio,
          'horarios': horasEnvio,
          'mes': _selectedMonth,
          'anio': _selectedYear,
          'aforoMax': _aforoMax,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Clases generadas correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Clases'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Configuración de la Clase'),
              TextFormField(
                initialValue: _nombreClase,
                decoration: const InputDecoration(
                  labelText: 'Tipo (ej. Entrenamiento)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _nombreClase = v,
              ),
              const SizedBox(height: 15),
              TextFormField(
                initialValue: _profesional,
                decoration: const InputDecoration(
                  labelText: 'Monitor',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _profesional = v,
              ),
              const SizedBox(height: 25),
              _buildSectionTitle('Días de la Semana (L y X)'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // ignore: avoid_final_parameters
                children: List.generate(7, (final int index) {
                  return Column(
                    children: [
                      Text(_nombresDias[index], 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Checkbox(
                        value: _diasSeleccionados[index],
                        activeColor: Colors.teal,
                        onChanged: (val) => 
                          setState(() => _diasSeleccionados[index] = val!),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 25),
              _buildSectionTitle('Horarios'),
              // ignore: avoid_final_parameters
              ..._horarios.asMap().entries.map((final entry) {
                final idx = entry.key;
                final time = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context, 
                              initialTime: time,
                            );
                            if (picked != null) {
                              setState(() => _horarios[idx] = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(time.format(context)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeHorario(idx),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              // EL BOTÓN "+" QUE SOLICITASTE PARA LOS HORARIOS
              Center(
                child: FloatingActionButton.small(
                  onPressed: _addHorario,
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _generarClases,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'GENERAR CLASES DEL MES',
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          color: Colors.teal,
        ),
      ),
    );
  }
}
