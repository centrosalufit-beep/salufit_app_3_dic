import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_analysis_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_library_hub_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_renewal_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_rrhh_screen.dart';
import 'package:salufit_app/features/bookings/presentation/admin_class_manager_screen.dart';
import 'package:salufit_app/features/communication/presentation/internal_management_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_detail_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_list_screen.dart';

class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({required this.userId, required this.userRole, super.key});
  final String userId; final String userRole;
  @override State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  int _selectedIndex = 0;
  void _openPatient(String uid, String name) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => AdminPatientDetailScreen(userId: uid, userName: name, viewerRole: widget.userRole)));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.userRole == 'admin' || widget.userRole == 'administrador';
    final pages = <Widget>[
      const AdminAnalysisScreen(),
      AdminClassManagerScreen(currentUserId: widget.userId),
      AdminPatientListScreen(viewerRole: widget.userRole, onUserSelected: _openPatient),
      const AdminRenewalScreen(),
      AdminPatientListScreen(viewerRole: 'profesional', onUserSelected: _openPatient), 
      InternalManagementScreen(currentUserId: widget.userId, userRole: widget.userRole),
      if (isAdmin) const AdminRRHHScreen(),
      if (isAdmin) const AdminLibraryHubScreen(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/login_bg.jpg'), fit: BoxFit.cover)),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: ColoredBox(
                color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Image.asset('assets/logo_salufit.png', height: 60, color: Colors.white, colorBlendMode: BlendMode.srcIn),
                    const SizedBox(height: 25),
                    _AdminClockSwitch(userId: widget.userId),
                    const SizedBox(height: 15),
                    Expanded(
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: Colors.transparent,
                        indicatorColor: const Color(0xFF004D40),
                        selectedIconTheme: const IconThemeData(color: Colors.tealAccent, size: 28),
                        unselectedIconTheme: const IconThemeData(color: Colors.white60),
                        selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        unselectedLabelTextStyle: const TextStyle(color: Colors.white60, fontSize: 10),
                        destinations: [
                          const NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Dashboard')),
                          const NavigationRailDestination(icon: Icon(Icons.calendar_month), label: Text('Clases')),
                          const NavigationRailDestination(icon: Icon(Icons.people), label: Text('Pacientes')),
                          const NavigationRailDestination(icon: Icon(Icons.confirmation_number), label: Text('Bonos')),
                          const NavigationRailDestination(icon: Icon(Icons.assignment), label: Text('Recursos')),
                          const NavigationRailDestination(icon: Icon(Icons.forum), label: Text('Equipo')),
                          if (isAdmin) const NavigationRailDestination(icon: Icon(Icons.badge), label: Text('RRHH')),
                          if (isAdmin) const NavigationRailDestination(icon: Icon(Icons.auto_stories), label: Text('Librería')),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 30), onPressed: () => FirebaseAuth.instance.signOut()),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: Colors.white12),
            Expanded(
              child: Stack(
                children: [
                  Center(child: Opacity(opacity: 0.05, child: Image.asset('assets/logo_salufit.png', width: 450))),
                  Positioned.fill(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        scaffoldBackgroundColor: Colors.transparent,
                        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
                        cardColor: Colors.white.withValues(alpha: 0.9),
                      ),
                      child: pages[_selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminClockSwitch extends StatelessWidget {
  const _AdminClockSwitch({required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('timeClockRecords').where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).limit(1).snapshots(),
      builder: (context, snapshot) {
        final active = snapshot.hasData && snapshot.data!.docs.isNotEmpty && snapshot.data!.docs.first.get('type') == 'IN';
        return Column(children: [
          Text(active ? 'ACTIVO' : 'ENTRADA', style: TextStyle(color: active ? Colors.tealAccent : Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
          Transform.scale(scale: 0.8, child: Switch(value: active, activeThumbColor: Colors.tealAccent, onChanged: (v) async {
            await FirebaseFirestore.instance.collection('timeClockRecords').add({'userId': userId, 'timestamp': FieldValue.serverTimestamp(), 'type': v ? 'IN' : 'OUT', 'isManualEntry': false, 'device': 'Windows'});
          })),
        ]);
      },
    );
  }
}
