import 'package:flutter/material.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_analysis_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_resources_hub_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_rrhh_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_upload_excel_screen.dart';
import 'package:salufit_app/features/bookings/presentation/admin_class_manager_screen.dart';
import 'package:salufit_app/features/communication/presentation/internal_management_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_detail_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_list_screen.dart';

class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({
    required this.userId,
    required this.userRole,
    super.key,
  });
  final String userId;
  final String userRole;

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        widget.userRole == 'admin' || widget.userRole == 'administrador';

    final pages = <Widget>[
      const AdminAnalysisScreen(),
      AdminClassManagerScreen(currentUserId: widget.userId),
      AdminPatientListScreen(
        viewerRole: widget.userRole,
        onUserSelected: (String uid, String name) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => AdminPatientDetailScreen(
                userId: uid,
                userName: name,
                viewerRole: widget.userRole,
              ),
            ),
          );
        },
      ),
      InternalManagementScreen(
        currentUserId: widget.userId,
        userRole: widget.userRole,
        viewType: 'chat',
      ),
      if (isAdmin) const AdminRRHHScreen(),
      if (isAdmin) AdminResourcesHubScreen(userRole: widget.userRole),
      if (isAdmin) const AdminUploadExcelScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF1E293B),
            selectedIconTheme: const IconThemeData(color: Colors.tealAccent),
            unselectedIconTheme: const IconThemeData(color: Colors.white54),
            selectedLabelTextStyle:
                const TextStyle(color: Colors.tealAccent, fontSize: 12),
            unselectedLabelTextStyle:
                const TextStyle(color: Colors.white54, fontSize: 12),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('AnÃ¡lisis'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.calendar_month),
                label: Text('Clases'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Pacientes'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.chat),
                label: Text('Equipo'),
              ),
              if (isAdmin)
                const NavigationRailDestination(
                  icon: Icon(Icons.badge),
                  label: Text('RRHH'),
                ),
              if (isAdmin)
                const NavigationRailDestination(
                  icon: Icon(Icons.folder_special),
                  label: Text('Recursos'),
                ),
              if (isAdmin)
                const NavigationRailDestination(
                  icon: Icon(Icons.upload_file),
                  label: Text('Importar'),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }
}
