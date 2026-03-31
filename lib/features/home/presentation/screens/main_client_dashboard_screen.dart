import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_class_list_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_dashboard_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_documents_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_material_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_profile_screen.dart';
import 'package:salufit_app/features/home/presentation/home_providers.dart';

class MainClientDashboardScreen extends ConsumerWidget {
  const MainClientDashboardScreen({
    required this.userId, 
    required this.userRole, 
    super.key
  });
  
  final String userId;
  final String userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabProvider);
    return Scaffold(
      body: IndexedStack(
        index: currentIndex, 
        children: [
          ClientDashboardScreen(userId: userId),
          ClientClassListScreen(userId: userId, userRole: userRole),
          ClientMaterialScreen(userId: userId),
          ClientDocumentsScreen(userId: userId),
          ClientProfileScreen(userId: userId),
        ]
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        onDestinationSelected: (i) => ref.read(homeTabProvider.notifier).setTab(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), 
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Inicio'
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined), 
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Clases'
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center), 
            selectedIcon: Icon(Icons.fitness_center, color: AppColors.primary),
            label: 'Material'
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined), 
            selectedIcon: Icon(Icons.description, color: AppColors.primary),
            label: 'Docs'
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline), 
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Perfil'
          ),
        ],
      ),
    );
  }
}
