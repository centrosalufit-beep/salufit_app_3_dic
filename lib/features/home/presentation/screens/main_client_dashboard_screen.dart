import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/home/presentation/home_providers.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_dashboard_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_class_list_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_material_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_documents_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_profile_screen.dart';

class MainClientDashboardScreen extends ConsumerWidget {
  final String userId;
  final String userRole;
  const MainClientDashboardScreen({super.key, required this.userId, required this.userRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabProvider);
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: [
        ClientDashboardScreen(userId: userId),
        ClientClassListScreen(userId: userId, userRole: userRole),
        ClientMaterialScreen(userId: userId),
        ClientDocumentsScreen(userId: userId),
        ClientProfileScreen(userId: userId),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => ref.read(homeTabProvider.notifier).setTab(i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.class_), label: 'Clases'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Material'),
          NavigationDestination(icon: Icon(Icons.description), label: 'Docs'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
