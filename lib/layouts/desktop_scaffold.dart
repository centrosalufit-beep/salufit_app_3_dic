import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
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

class DesktopScaffold extends ConsumerStatefulWidget {
  const DesktopScaffold({required this.userId, required this.userRole, super.key});
  final String userId; final String userRole;
  @override ConsumerState<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends ConsumerState<DesktopScaffold> {
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

    // Construir los destinations una sola vez para reutilizar en Rail y Drawer
    final destinations = <_NavItem>[
      _NavItem(icon: isAdmin ? Icons.analytics : Icons.space_dashboard_outlined, label: 'Dashboard'),
      const _NavItem(icon: Icons.calendar_month, label: 'Clases'),
      const _NavItem(icon: Icons.people, label: 'Pacientes'),
      if (isAdmin) const _NavItem(icon: Icons.confirmation_number, label: 'Bonos'),
      const _NavItem(icon: Icons.assignment, label: 'Recursos'),
      const _NavItem(icon: Icons.forum, label: 'Equipo'),
      const _NavItem(icon: Icons.leaderboard, label: 'CRM'),
      if (isAdmin) const _NavItem(icon: Icons.badge, label: 'RRHH'),
      if (isAdmin) const _NavItem(icon: Icons.auto_stories, label: 'Librería'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // En móvil/pantalla estrecha usamos Drawer + AppBar (hamburguesa).
        // En escritorio mantenemos el layout original con sidebar fijo.
        final isNarrow = constraints.maxWidth < 800;
        if (isNarrow) {
          return _buildNarrowLayout(destinations, pages);
        }
        return _buildWideLayout(destinations, pages, isAdmin);
      },
    );
  }

  Widget _buildNarrowLayout(List<_NavItem> destinations, List<Widget> pages) {
    final currentLabel = destinations[_selectedIndex.clamp(0, destinations.length - 1)].label;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text(currentLabel),
        actions: [
          _UnreadBellBadge(
            userId: widget.userId,
            onTap: () {
              final equipoIndex = destinations.indexWhere((d) => d.label == 'Equipo');
              if (equipoIndex >= 0) setState(() => _selectedIndex = equipoIndex);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E293B),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/logo_salufit.png',
                height: 60,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, __, ___) => const Icon(Icons.favorite, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 20),
              _AdminClockSwitch(userId: widget.userId),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: destinations.length,
                  itemBuilder: (ctx, i) {
                    final d = destinations[i];
                    final selected = _selectedIndex == i;
                    return ListTile(
                      leading: Icon(
                        d.icon,
                        color: selected ? Colors.tealAccent : Colors.white70,
                      ),
                      title: Text(
                        d.label,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: selected ? FontWeight.w900 : FontWeight.normal,
                        ),
                      ),
                      selected: selected,
                      selectedTileColor: const Color(0xFF004D40),
                      onTap: () {
                        setState(() => _selectedIndex = i);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              ListTile(
                leading: const Icon(Icons.power_settings_new, color: Colors.redAccent),
                title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(firebaseAuthProvider).signOut();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/login_bg.jpg'), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset('assets/logo_salufit.png', width: 300, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
            Positioned.fill(
              child: Theme(
                data: Theme.of(context).copyWith(
                  scaffoldBackgroundColor: Colors.transparent,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF1E293B),
                    elevation: 0,
                    foregroundColor: Colors.white,
                  ),
                  cardColor: Colors.white.withValues(alpha: 0.95),
                ),
                child: pages[_selectedIndex.clamp(0, pages.length - 1)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(List<_NavItem> destinations, List<Widget> pages, bool isAdmin) {
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
                              selectedIndex: _selectedIndex.clamp(0, destinations.length - 1),
                              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                              labelType: NavigationRailLabelType.all,
                              backgroundColor: Colors.transparent,
                              indicatorColor: const Color(0xFF004D40),
                              selectedIconTheme: const IconThemeData(color: Colors.tealAccent, size: 28),
                              unselectedIconTheme: const IconThemeData(color: Colors.white60),
                              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              unselectedLabelTextStyle: const TextStyle(color: Colors.white60, fontSize: 10),
                              destinations: destinations
                                  .map(
                                    (d) => NavigationRailDestination(
                                      icon: Icon(d.icon),
                                      label: Text(d.label),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _UnreadBellBadge(
                      userId: widget.userId,
                      onTap: () {
                        final equipoIndex = destinations.indexWhere((d) => d.label == 'Equipo');
                        if (equipoIndex >= 0) setState(() => _selectedIndex = equipoIndex);
                      },
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
                          await ref.read(firebaseAuthProvider).signOut();
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
                      child: pages[_selectedIndex.clamp(0, pages.length - 1)],
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

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _AdminClockSwitch extends ConsumerStatefulWidget {
  const _AdminClockSwitch({required this.userId});
  final String userId;
  @override
  ConsumerState<_AdminClockSwitch> createState() => _AdminClockSwitchState();
}

class _AdminClockSwitchState extends ConsumerState<_AdminClockSwitch> {
  String? _cachedName;

  Future<String> _resolveUserName() async {
    if (_cachedName != null) return _cachedName!;
    try {
      final doc = await ref.read(firebaseFirestoreProvider)
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
    final user = ref.read(firebaseAuthProvider).currentUser;
    _cachedName = user?.displayName ?? user?.email ?? widget.userId;
    return _cachedName!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.read(firebaseFirestoreProvider)
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
                  await ref.read(firebaseFirestoreProvider)
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
class _UnreadBellBadge extends ConsumerWidget {
  const _UnreadBellBadge({required this.userId, required this.onTap});
  final String userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.watch(firebaseFirestoreProvider)
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
