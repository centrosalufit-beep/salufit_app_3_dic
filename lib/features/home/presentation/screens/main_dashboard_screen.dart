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

  const MainClientDashboardScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabProvider);

    final List<Widget> views = [
      ClientDashboardScreen(userId: userId),
      ClientClassListScreen(userId: userId, userRole: userRole),
      ClientMaterialScreen(userId: userId),
      ClientDocumentsScreen(userId: userId),
      ClientProfileScreen(userId: userId),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => 
            ref.read(homeTabProvider.notifier).setTab(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Clases'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Material'),
          NavigationDestination(icon: Icon(Icons.description), label: 'Docs'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
