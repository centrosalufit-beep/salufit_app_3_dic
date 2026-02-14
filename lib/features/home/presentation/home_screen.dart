import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/class_list_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_profile_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/dashboard_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/documents_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/material_screen.dart';
import 'package:salufit_app/layouts/desktop_scaffold.dart';
import 'package:salufit_app/layouts/mobile_scaffold.dart';
import 'package:salufit_app/layouts/responsive_layout.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

final StateProvider<int> homeTabProvider = StateProvider<int>((ref) => 0);
final StateProvider<DateTime?> bookingDateProvider =
    StateProvider<DateTime?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    required this.userId,
    required this.userRole,
    super.key,
  });
  final String userId;
  final String userRole;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    if (AppConfig.esStaff(widget.userRole)) {
      return ResponsiveLayout(
        mobileScaffold: MobileScaffold(
          userId: widget.userId,
          userRole: widget.userRole,
        ),
        desktopScaffold: DesktopScaffold(
          userId: widget.userId,
          userRole: widget.userRole,
        ),
      );
    }

    final selectedIndex = ref.watch(homeTabProvider);
    final targetDate = ref.watch(bookingDateProvider);

    final screens = <Widget>[
      DashboardScreen(userId: widget.userId),
      ClassListScreen(
        key: ValueKey(targetDate),
        userId: widget.userId,
        userRole: widget.userRole,
        initialDate: targetDate,
      ),
      MaterialScreen(userId: widget.userId),
      DocumentsScreen(userId: widget.userId),
      ClientProfileScreen(userId: widget.userId),
    ];

    return SalufitScaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: const Color(0xFF009688),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => ref.read(homeTabProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Clases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Material',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Docs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
