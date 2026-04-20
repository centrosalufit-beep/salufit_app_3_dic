import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_analysis_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_crm_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_library_hub_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_renewal_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_rrhh_screen.dart';
import 'package:salufit_app/features/bookings/presentation/admin_class_manager_screen.dart';
import 'package:salufit_app/features/communication/presentation/internal_management_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_detail_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_list_screen.dart';
import 'package:salufit_app/features/professional/presentation/professional_desktop_dashboard_screen.dart';

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
      if (isAdmin)
        const AdminAnalysisScreen()
      else
        ProfessionalDesktopDashboardScreen(
          userId: widget.userId,
          userRole: widget.userRole,
        ),
      AdminClassManagerScreen(currentUserId: widget.userId),
      AdminPatientListScreen(viewerRole: widget.userRole, onUserSelected: _openPatient),
      if (isAdmin) const AdminRenewalScreen(),
      AdminPatientListScreen(viewerRole: 'profesional', onUserSelected: _openPatient),
      InternalManagementScreen(currentUserId: widget.userId, userRole: widget.userRole),
      AdminCrmScreen(userId: widget.userId, userRole: widget.userRole),
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
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 200,
                          ),
                          child: IntrinsicHeight(
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
                                NavigationRailDestination(
                                  icon: Icon(isAdmin ? Icons.analytics : Icons.space_dashboard_outlined),
                                  label: const Text('Dashboard'),
                                ),
                                const NavigationRailDestination(icon: Icon(Icons.calendar_month), label: Text('Clases')),
                                const NavigationRailDestination(icon: Icon(Icons.people), label: Text('Pacientes')),
                                if (isAdmin) const NavigationRailDestination(icon: Icon(Icons.confirmation_number), label: Text('Bonos')),
                                const NavigationRailDestination(icon: Icon(Icons.assignment), label: Text('Recursos')),
                                const NavigationRailDestination(icon: Icon(Icons.forum), label: Text('Equipo')),
                                const NavigationRailDestination(icon: Icon(Icons.leaderboard), label: Text('CRM')),
                                if (isAdmin) const NavigationRailDestination(icon: Icon(Icons.badge), label: Text('RRHH')),
                                if (isAdmin) const NavigationRailDestination(icon: Icon(Icons.auto_stories), label: Text('Librería')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _UnreadBellBadge(
                      userId: widget.userId,
                      onTap: () => setState(() => _selectedIndex = 5),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Cerrar sesión',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 30),
                        tooltip: 'Cerrar sesión',
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await FirebaseAuth.instance.signOut();
                        },
                      ),
                    ),
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
                        appBarTheme: const AppBarTheme(
                          backgroundColor: Color(0xFF1E293B),
                          elevation: 0,
                          foregroundColor: Colors.white,
                        ),
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

class _AdminClockSwitch extends StatefulWidget {
  const _AdminClockSwitch({required this.userId});
  final String userId;
  @override
  State<_AdminClockSwitch> createState() => _AdminClockSwitchState();
}

class _AdminClockSwitchState extends State<_AdminClockSwitch> {
  String? _cachedName;

  Future<String> _resolveUserName() async {
    if (_cachedName != null) return _cachedName!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users_app')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final full = (data['nombreCompleto'] as String?) ?? '';
        if (full.isNotEmpty) {
          _cachedName = full;
          return full;
        }
        final nombre = (data['nombre'] as String?) ?? '';
        final apellidos = (data['apellidos'] as String?) ?? '';
        final combined = '$nombre $apellidos'.trim();
        if (combined.isNotEmpty) {
          _cachedName = combined;
          return combined;
        }
        final email = (data['email'] as String?) ?? '';
        if (email.isNotEmpty) {
          _cachedName = email;
          return email;
        }
      }
    } catch (_) {}
    // Fallback: Firebase Auth displayName o email
    final user = FirebaseAuth.instance.currentUser;
    _cachedName = user?.displayName ?? user?.email ?? widget.userId;
    return _cachedName!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('userId', isEqualTo: widget.userId)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        var active = false;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final sorted = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final tsA = ((a.data()! as Map<String, dynamic>)['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final tsB = ((b.data()! as Map<String, dynamic>)['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return tsB.compareTo(tsA);
            });
          active = (sorted.first.data()! as Map<String, dynamic>)['type'] == 'IN';
        }
        return Column(
          children: [
            Text(
              active ? 'ACTIVO' : 'ENTRADA',
              style: TextStyle(
                color: active ? Colors.tealAccent : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: active,
                activeThumbColor: Colors.tealAccent,
                onChanged: (v) async {
                  final userName = await _resolveUserName();
                  await FirebaseFirestore.instance
                      .collection('timeClockRecords')
                      .add({
                    'userId': widget.userId,
                    'userName': userName,
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': v ? 'IN' : 'OUT',
                    'isManualEntry': false,
                    'device': 'Windows',
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Campana con badge rojo cuando hay mensajes sin leer.
/// Escucha la colección `chats` donde el usuario es participante.
class _UnreadBellBadge extends StatelessWidget {
  const _UnreadBellBadge({required this.userId, required this.onTap});
  final String userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        var unreadCount = 0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final lastMsgTime =
                (data['lastMessageTime'] as Timestamp?)?.toDate();
            final lastRead =
                (data['lastReadBy_$userId'] as Timestamp?)?.toDate();
            final lastSender = (data['lastMessageSenderId'] as String?) ?? '';

            if (lastMsgTime != null && lastSender != userId) {
              if (lastRead == null || lastMsgTime.isAfter(lastRead)) {
                unreadCount++;
              }
            }
          }
        }

        return IconButton(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              '$unreadCount',
              style: const TextStyle(fontSize: 9),
            ),
            child: Icon(
              unreadCount > 0
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: unreadCount > 0 ? Colors.tealAccent : Colors.white38,
              size: 26,
            ),
          ),
          onPressed: onTap,
        );
      },
    );
  }
}
