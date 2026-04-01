import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_edit_time_records_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_time_report_screen.dart';

class AdminRRHHScreen extends StatelessWidget {
  const AdminRRHHScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          title: const Text(
            'Gestión de RRHH',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync, size: 22),
              tooltip: 'Migrar nombres en fichajes antiguos',
              onPressed: () => _runMigration(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.tealAccent,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white70,
            tabs: <Widget>[
              Tab(icon: Icon(Icons.summarize), text: 'DESCARGAR INFORMES'),
              Tab(icon: Icon(Icons.edit_calendar), text: 'CORREGIR FICHAJES'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            AdminTimeReportScreen(),
            AdminEditTimeRecordsScreen(),
          ],
        ),
      ),
    );
  }

  Future<void> _runMigration(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Migrar fichajes antiguos'),
        content: const Text(
          'Se añadirá el nombre del profesional a todos los '
          'fichajes que no lo tengan.\n\n'
          'Esta operación puede tardar unos segundos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
              foregroundColor: Colors.white,
            ),
            child: const Text('MIGRAR'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    // Mostrar progreso
    final messenger = ScaffoldMessenger.of(context)
      ..showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Migrando fichajes...'),
            ],
          ),
          duration: Duration(minutes: 2),
          backgroundColor: Color(0xFF1E293B),
        ),
      );

    try {
      final result = await _migrateTimeClockRecords();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Migración completada: ${result['updated']} actualizados, '
              '${result['skipped']} ya tenían nombre, '
              '${result['failed']} sin resolver.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
        SnackBar(
          content: Text('Error en migración: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, int>> _migrateTimeClockRecords() async {
    final firestore = FirebaseFirestore.instance;
    var updated = 0;
    var skipped = 0;
    var failed = 0;

    // 1. Obtener todos los fichajes
    final allRecords =
        await firestore.collection('timeClockRecords').get();

    // 2. Recopilar UIDs únicos sin userName
    final uidsToResolve = <String>{};
    final docsToUpdate = <QueryDocumentSnapshot>[];

    for (final doc in allRecords.docs) {
      final data = doc.data();
      final existingName = data.safeString('userName');
      if (existingName.isNotEmpty) {
        skipped++;
        continue;
      }
      final uid = data.safeString('userId');
      if (uid.isNotEmpty) {
        uidsToResolve.add(uid);
        docsToUpdate.add(doc);
      }
    }

    // 3. Resolver nombres en lote
    final nameMap = <String, String>{};
    for (final uid in uidsToResolve) {
      try {
        final userDoc =
            await firestore.collection('users_app').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final full = userData.safeString('nombreCompleto');
          if (full.isNotEmpty) {
            nameMap[uid] = full;
            continue;
          }
          final name =
              '${userData.safeString('nombre')} ${userData.safeString('apellidos')}'
                  .trim();
          if (name.isNotEmpty) {
            nameMap[uid] = name;
            continue;
          }
          final email = userData.safeString('email');
          if (email.isNotEmpty) {
            nameMap[uid] = email;
            continue;
          }
        }
      } catch (_) {}
      // No se pudo resolver
      nameMap[uid] = '';
    }

    // 4. Actualizar en lotes de 500 (límite Firestore batch)
    var batch = firestore.batch();
    var batchCount = 0;

    for (final doc in docsToUpdate) {
      final docData = doc.data()! as Map<String, dynamic>;
      final uid = docData.safeString('userId');
      final resolvedName = nameMap[uid] ?? '';
      if (resolvedName.isEmpty) {
        failed++;
        continue;
      }

      batch.update(doc.reference, {'userName': resolvedName});
      updated++;
      batchCount++;

      if (batchCount >= 500) {
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    return {'updated': updated, 'skipped': skipped, 'failed': failed};
  }
}
