import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class AdminClassDetailsScreen extends ConsumerWidget {
  const AdminClassDetailsScreen({
    required this.classId,
    super.key,
  });

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SalufitScaffold(
      appBar: AppBar(
        title: const Text('Detalles de Clase'),
      ),
      body: const Center(
        child: Text('Gestión de inscritos disponible pronto'),
      ),
    );
  }
}
