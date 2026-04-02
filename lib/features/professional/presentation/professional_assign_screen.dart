import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_exercise_library_screen.dart';

/// Buscar paciente → seleccionar ejercicios → asignar.
class ProfessionalAssignScreen extends StatefulWidget {
  const ProfessionalAssignScreen({super.key});
  @override
  State<ProfessionalAssignScreen> createState() =>
      _ProfessionalAssignScreenState();
}

class _ProfessionalAssignScreenState extends State<ProfessionalAssignScreen> {
  String _query = '';

  Future<void> _assignToPatient(
    BuildContext context,
    String patientId,
    String patientName,
    String patientEmail,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AdminExerciseLibraryScreen(
          isSelectionMode: true,
          onExercisesSelected: (selectedList) async {
            final batch = FirebaseFirestore.instance.batch();
            final staffId =
                FirebaseAuth.instance.currentUser?.uid ?? 'profesional';

            for (final ex in selectedList) {
              final docRef = FirebaseFirestore.instance
                  .collection('exercise_assignments')
                  .doc();
              batch.set(docRef, <String, Object>{
                'id': docRef.id,
                'userId': patientId,
                'userEmail': patientEmail,
                'exerciseId': (ex['id'] ?? '').toString(),
                'nombre': (ex['nombre'] ?? '').toString(),
                'urlVideo': (ex['urlVideo'] ?? '').toString(),
                'familia': (ex['familia'] ?? 'Entrenamiento').toString(),
                'codigoInterno': (ex['codigoInterno'] as int?) ?? 0,
                'fechaAsignacion': DateTime.now().toIso8601String(),
                'asignadoEl': FieldValue.serverTimestamp(),
                'completado': false,
                'profesionalId': staffId,
              });
            }

            await batch.commit();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${selectedList.length} ejercicios asignados a $patientName',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Ejercicios'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar paciente por nombre...',
                prefixIcon:
                    const Icon(Icons.person_search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          // Lista de pacientes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users_app')
                  .where('rol', isEqualTo: 'cliente')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.where((d) {
                  if (_query.isEmpty) return true;
                  final data = d.data()! as Map<String, dynamic>;
                  final name =
                      data.safeString('nombreCompleto').toLowerCase();
                  final nombre = data.safeString('nombre').toLowerCase();
                  final numH = data.safeString('numHistoria');
                  return name.contains(_query) ||
                      nombre.contains(_query) ||
                      numH.contains(_query);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron pacientes',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data()! as Map<String, dynamic>;
                    final name = data.safeString('nombreCompleto').isNotEmpty
                        ? data.safeString('nombreCompleto')
                        : data.safeString('nombre');
                    final email = data.safeString('email');
                    final numH = data.safeString('numHistoria');

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        numH.isNotEmpty ? 'Nº $numH · $email' : email,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
                      ),
                      onTap: () => _assignToPatient(
                        context,
                        docs[i].id,
                        name,
                        email,
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
