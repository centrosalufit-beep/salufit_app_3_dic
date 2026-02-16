import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart'; 
import 'package:salufit_app/features/patient_record/providers/material_providers.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class MaterialScreen extends StatelessWidget {
  const MaterialScreen({required this.userId, super.key, this.embedMode = false});
  final String userId;
  final bool embedMode;
  static const Color salufitTeal = Color(0xFF009688);

  @override
  Widget build(BuildContext context) {
    if (embedMode) return const _MaterialListBody();
    return const SalufitScaffold(
      backgroundColor: Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'TU MATERIAL',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: salufitTeal),
            ),
          ),
          Expanded(child: _MaterialListBody()),
        ]),
      ),
    );
  }
}

class _MaterialListBody extends ConsumerWidget {
  const _MaterialListBody();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    return userProfileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Error al cargar perfil')),
      data: (userDoc) => const _ClientExerciseList(),
    );
  }
}

class _ClientExerciseList extends ConsumerWidget {
  const _ClientExerciseList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(myAssignmentsProvider);
    final completedSet = ref.watch(dailyProgressProvider);
    
    return assignmentsAsync.when(
      data: (docs) {
        final completedCount = docs.where((d) => completedSet.contains(d['id'].toString())).length;
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Progreso: $completedCount / ${docs.length}'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic> data = docs[index];
                  final String id = data['id']?.toString() ?? '';
                  return ListTile(
                    title: Text(data['nombre']?.toString() ?? 'Ejercicio'),
                    trailing: Checkbox(
                      value: completedSet.contains(id),
                      onChanged: (_) => ref.read(dailyProgressProvider.notifier).markAsDone(id),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Error al cargar ejercicios')),
    );
  }
}
