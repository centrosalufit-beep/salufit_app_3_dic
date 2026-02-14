import 'package:flutter/material.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_renewal_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_exercise_library_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_detail_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_list_screen.dart';

class AdminResourcesHubScreen extends StatelessWidget {
  const AdminResourcesHubScreen({
    super.key,
    this.userRole = 'admin',
  });

  final String userRole;

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole == 'admin' || userRole == 'administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Recursos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Text(
            'Gestión Administrativa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 20),
          if (isAdmin) ...<Widget>[
            _ResourceCard(
              icon: Icons.confirmation_number,
              color: Colors.teal,
              title: 'Gestión de Bonos (Tokens)',
              subtitle: 'Asignar sesiones mensuales (9, 13, 17...).',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext c) => const AdminRenewalScreen(),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
          _ResourceCard(
            icon: Icons.video_library,
            color: Colors.blue,
            title: 'Biblioteca de Ejercicios',
            subtitle: 'Gestionar videos generales.',
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext c) => const AdminExerciseLibraryScreen(),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          _ResourceCard(
            icon: Icons.person_search,
            color: Colors.blueGrey,
            title: 'Subir Radiografía / Receta',
            subtitle: 'Archivos privados para un paciente.',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => AdminPatientListScreen(
                    viewerRole: userRole,
                    onUserSelected: (String uid, String name) {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext c) => AdminPatientDetailScreen(
                            userId: uid,
                            userName: name,
                            viewerRole: userRole,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
