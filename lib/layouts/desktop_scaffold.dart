import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_analysis_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_crm_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_exercise_feedback_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_library_hub_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_renewal_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_rrhh_screen.dart';
import 'package:salufit_app/features/bookings/presentation/admin_class_manager_screen.dart';
import 'package:salufit_app/features/communication/presentation/internal_management_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_detail_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_list_screen.dart';
import 'package:salufit_app/features/professional/presentation/professional_desktop_dashboard_screen.dart';
import 'package:salufit_app/features/tasks/application/task_providers.dart';
import 'package:salufit_app/features/tasks/presentation/tasks_screen.dart';
import 'package:salufit_app/features/whatsapp_bot/presentation/whatsapp_bot_screen.dart';

/// Identificadores de las features accesibles desde el Hub.
/// Sustituye al antiguo `_selectedIndex: int`.
enum HomeFeature {
  dashboard,
  classes,
  patientsAdmin,
  bonos,
  patientsPro,
  team,
  crm,
  tasks,
  rrhh,
  library,
  feedback,
  botWa,
}

class DesktopScaffold extends ConsumerStatefulWidget {
  const DesktopScaffold({required this.userId, required this.userRole, super.key});
  final String userId;
  final String userRole;
  @override
  ConsumerState<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends ConsumerState<DesktopScaffold> {
  /// `null` = mostrar el Hub. Cualquier otro valor = mostrar esa feature.
  HomeFeature? _current;
  String _currentUserName = '';

  bool get _isAdmin =>
      widget.userRole == 'admin' || widget.userRole == 'administrador';

  bool get _showTasks =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    try {
      final doc = await ref
          .read(firebaseFirestoreProvider)
          .collection('users_app')
          .doc(widget.userId)
          .get();
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;
      final full = (data['nombreCompleto'] as String?) ?? '';
      final nombre = (data['nombre'] as String?) ?? '';
      final apellidos = (data['apellidos'] as String?) ?? '';
      final combined = full.isNotEmpty ? full : '$nombre $apellidos'.trim();
      final email = (data['email'] as String?) ?? '';
      setState(() {
        _currentUserName = combined.isNotEmpty ? combined : email;
      });
    } catch (_) {
      // noop; dejamos vacío
    }
  }

  void _openPatient(String uid, String name) {
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
  }

  void _goHome() => setState(() => _current = null);
  void _open(HomeFeature f) => setState(() => _current = f);

  /// Lista ordenada de features visibles según rol/plataforma.
  ///
  /// **Profesional ve solo 6**: Clases, Recursos, Equipo, CRM, Tareas, Feedback.
  /// **Admin ve las 12**.
  List<HomeFeature> get _visibleFeatures => [
        if (_isAdmin) HomeFeature.dashboard,
        HomeFeature.classes,
        if (_isAdmin) HomeFeature.patientsAdmin,
        if (_isAdmin) HomeFeature.bonos,
        HomeFeature.patientsPro,
        HomeFeature.team,
        HomeFeature.crm,
        if (_showTasks) HomeFeature.tasks,
        if (_isAdmin) HomeFeature.rrhh,
        if (_isAdmin) HomeFeature.library,
        HomeFeature.feedback,
        if (_isAdmin) HomeFeature.botWa,
      ];

  String _labelOf(HomeFeature f) {
    switch (f) {
      case HomeFeature.dashboard:
        return 'Dashboard';
      case HomeFeature.classes:
        return 'Clases';
      case HomeFeature.patientsAdmin:
        return 'Pacientes';
      case HomeFeature.bonos:
        return 'Bonos';
      case HomeFeature.patientsPro:
        return 'Recursos';
      case HomeFeature.team:
        return 'Equipo';
      case HomeFeature.crm:
        return 'CRM';
      case HomeFeature.tasks:
        return 'Tareas';
      case HomeFeature.rrhh:
        return 'RRHH';
      case HomeFeature.library:
        return 'Librería';
      case HomeFeature.feedback:
        return 'Feedback';
      case HomeFeature.botWa:
        return 'Bot WA';
    }
  }

  IconData _iconOf(HomeFeature f) {
    switch (f) {
      case HomeFeature.dashboard:
        return _isAdmin ? Icons.analytics : Icons.space_dashboard_outlined;
      case HomeFeature.classes:
        return Icons.calendar_month;
      case HomeFeature.patientsAdmin:
        return Icons.people;
      case HomeFeature.bonos:
        return Icons.confirmation_number;
      case HomeFeature.patientsPro:
        return Icons.assignment;
      case HomeFeature.team:
        return Icons.forum;
      case HomeFeature.crm:
        return Icons.leaderboard;
      case HomeFeature.tasks:
        return Icons.task_alt;
      case HomeFeature.rrhh:
        return Icons.badge;
      case HomeFeature.library:
        return Icons.auto_stories;
      case HomeFeature.feedback:
        return Icons.thumbs_up_down_outlined;
      case HomeFeature.botWa:
        return Icons.smart_toy_outlined;
    }
  }

  /// Color del icono de cada tarjeta del Hub.
  /// Paleta semánticamente coherente: tonos cálidos para negocio, azules
  /// para datos, verdes para comunicación, rojo para urgencia.
  Color _colorOf(HomeFeature f) {
    switch (f) {
      case HomeFeature.dashboard:
        return const Color(0xFF009688); // teal corporativo
      case HomeFeature.classes:
        return const Color(0xFF1976D2); // azul calendario
      case HomeFeature.patientsAdmin:
        return const Color(0xFF0097A7); // cyan oscuro
      case HomeFeature.bonos:
        return const Color(0xFFF57C00); // ámbar (dinero)
      case HomeFeature.patientsPro:
        return const Color(0xFF7E57C2); // violeta
      case HomeFeature.team:
        return const Color(0xFF43A047); // verde comunicación
      case HomeFeature.crm:
        return const Color(0xFF3949AB); // indigo (datos)
      case HomeFeature.tasks:
        return const Color(0xFFE53935); // rojo (urgencia)
      case HomeFeature.rrhh:
        return const Color(0xFF8D6E63); // marrón cálido
      case HomeFeature.library:
        return const Color(0xFF5E35B1); // púrpura oscuro
      case HomeFeature.feedback:
        return const Color(0xFF00BCD4); // cyan brillante
      case HomeFeature.botWa:
        return const Color(0xFF25D366); // verde WhatsApp
    }
  }

  Widget _buildPage(HomeFeature f) {
    switch (f) {
      case HomeFeature.dashboard:
        return _isAdmin
            ? const AdminAnalysisScreen()
            : ProfessionalDesktopDashboardScreen(
                userId: widget.userId,
                userRole: widget.userRole,
              );
      case HomeFeature.classes:
        return AdminClassManagerScreen(
          currentUserId: widget.userId,
          userRole: widget.userRole,
        );
      case HomeFeature.patientsAdmin:
        return AdminPatientListScreen(
          viewerRole: widget.userRole,
          onUserSelected: _openPatient,
        );
      case HomeFeature.bonos:
        return const AdminRenewalScreen();
      case HomeFeature.patientsPro:
        return AdminPatientListScreen(
          viewerRole: 'profesional',
          onUserSelected: _openPatient,
        );
      case HomeFeature.team:
        return InternalManagementScreen(
          currentUserId: widget.userId,
          userRole: widget.userRole,
        );
      case HomeFeature.crm:
        return AdminCrmScreen(
          userId: widget.userId,
          userRole: widget.userRole,
        );
      case HomeFeature.tasks:
        return TasksScreen(
          currentUserId: widget.userId,
          currentUserName: _currentUserName,
        );
      case HomeFeature.rrhh:
        return const AdminRRHHScreen();
      case HomeFeature.library:
        return const AdminLibraryHubScreen();
      case HomeFeature.feedback:
        return const AdminExerciseFeedbackScreen();
      case HomeFeature.botWa:
        return const WhatsAppBotScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          children: [
            // ── Sidebar minimalista (72px) ──────────────────────
            SizedBox(
              width: 72,
              child: ColoredBox(
                color: const Color(0xFF1E293B).withValues(alpha: 0.92),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    // Logo clickable → vuelve al Hub
                    Tooltip(
                      message: 'Inicio',
                      child: InkWell(
                        onTap: _goHome,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/logo_salufit.png',
                            height: 40,
                            color: Colors.white,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AdminClockSwitch(userId: widget.userId),
                    const Spacer(),
                    _UnreadBellBadge(
                      userId: widget.userId,
                      onTap: () => _open(HomeFeature.team),
                    ),
                    const SizedBox(height: 8),
                    if (_showTasks)
                      _TasksBadgeIcon(
                        userId: widget.userId,
                        onTap: () => _open(HomeFeature.tasks),
                      ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Cerrar sesión',
                      button: true,
                      child: IconButton(
                        icon: const Icon(
                          Icons.power_settings_new,
                          color: Colors.redAccent,
                          size: 26,
                        ),
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
            // ── Área de contenido ───────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: 0.05,
                      child: Image.asset(
                        'assets/logo_salufit.png',
                        width: 450,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        scaffoldBackgroundColor: Colors.transparent,
                        // Toda AppBar de las features hereda esto:
                        // mismo fondo oscuro, mismo título blanco bold 18.
                        appBarTheme: const AppBarTheme(
                          backgroundColor: Color(0xFF1E293B),
                          elevation: 0,
                          foregroundColor: Colors.white,
                          centerTitle: false,
                          titleTextStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          iconTheme: IconThemeData(color: Colors.white),
                        ),
                        // Toda TabBar dentro de un AppBar usa esto.
                        tabBarTheme: const TabBarThemeData(
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          indicatorColor: Colors.tealAccent,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        cardColor: Colors.white.withValues(alpha: 0.9),
                        // Labels de TextField legibles sobre el wallpaper
                        // claro. Antes heredaban un teal light casi invisible.
                        inputDecorationTheme: const InputDecorationTheme(
                          labelStyle: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 13,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: Color(0xFF00796B),
                            fontWeight: FontWeight.w600,
                          ),
                          hintStyle: TextStyle(color: Colors.black54),
                          helperStyle: TextStyle(
                            color: Color(0xFF454545),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      child: _current == null
                          ? _HomeHubScreen(
                              userName: _currentUserName,
                              features: _visibleFeatures,
                              labelOf: _labelOf,
                              iconOf: _iconOf,
                              colorOf: _colorOf,
                              onOpen: _open,
                            )
                          : Column(
                              children: [
                                _FeatureToolbar(
                                  title: _labelOf(_current!),
                                  icon: _iconOf(_current!),
                                  onHome: _goHome,
                                ),
                                Expanded(child: _buildPage(_current!)),
                              ],
                            ),
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

// ════════════════════════════════════════════════════════════════
// SIDEBAR — fichaje, campana, tareas
// ════════════════════════════════════════════════════════════════

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
      final doc = await ref
          .read(firebaseFirestoreProvider)
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
    final user = ref.read(firebaseAuthProvider).currentUser;
    _cachedName = user?.displayName ?? user?.email ?? widget.userId;
    return _cachedName!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .read(firebaseFirestoreProvider)
          .collection('timeClockRecords')
          .where('userId', isEqualTo: widget.userId)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        var active = false;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final sorted = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final tsA = ((a.data()! as Map<String, dynamic>)['timestamp']
                          as Timestamp?)
                      ?.millisecondsSinceEpoch ??
                  0;
              final tsB = ((b.data()! as Map<String, dynamic>)['timestamp']
                          as Timestamp?)
                      ?.millisecondsSinceEpoch ??
                  0;
              return tsB.compareTo(tsA);
            });
          active = (sorted.first.data()! as Map<String, dynamic>)['type'] ==
              'IN';
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
              scale: 0.75,
              child: Switch(
                value: active,
                activeThumbColor: Colors.tealAccent,
                onChanged: (v) async {
                  final userName = await _resolveUserName();
                  await ref
                      .read(firebaseFirestoreProvider)
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
class _UnreadBellBadge extends ConsumerWidget {
  const _UnreadBellBadge({required this.userId, required this.onTap});
  final String userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .watch(firebaseFirestoreProvider)
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
          tooltip: 'Mensajes',
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount', style: const TextStyle(fontSize: 9)),
            child: Icon(
              unreadCount > 0
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: unreadCount > 0 ? Colors.tealAccent : Colors.white60,
              size: 26,
            ),
          ),
          onPressed: onTap,
        );
      },
    );
  }
}

/// Icono de Tareas con badge del número de pendientes.
/// Ahora clickable: navega a la feature Tareas.
class _TasksBadgeIcon extends ConsumerWidget {
  const _TasksBadgeIcon({required this.userId, required this.onTap});
  final String userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingTasksCountProvider(userId)).value ?? 0;
    return IconButton(
      tooltip: 'Tareas',
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: Colors.red,
        label: Text('$count', style: const TextStyle(fontSize: 9)),
        child: Icon(
          Icons.task_alt,
          color: count > 0 ? Colors.tealAccent : Colors.white60,
          size: 26,
        ),
      ),
      onPressed: onTap,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// HOME HUB — grilla de tarjetas
// ════════════════════════════════════════════════════════════════

class _HomeHubScreen extends StatelessWidget {
  const _HomeHubScreen({
    required this.userName,
    required this.features,
    required this.labelOf,
    required this.iconOf,
    required this.colorOf,
    required this.onOpen,
  });

  final String userName;
  final List<HomeFeature> features;
  final String Function(HomeFeature) labelOf;
  final IconData Function(HomeFeature) iconOf;
  final Color Function(HomeFeature) colorOf;
  final void Function(HomeFeature) onOpen;

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingForHour(DateTime.now().hour);
    final displayName = userName.isNotEmpty ? userName.split(' ').first : '';
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 16),
          sliver: SliverToBoxAdapter(
            child: Text(
              displayName.isEmpty ? greeting : '$greeting, $displayName',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 26,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(blurRadius: 6, color: Colors.black54),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final f = features[index];
                return _HubCard(
                  label: labelOf(f),
                  icon: iconOf(f),
                  color: colorOf(f),
                  onTap: () => onOpen(f),
                );
              },
              childCount: features.length,
            ),
          ),
        ),
      ],
    );
  }

  String _greetingForHour(int hour) {
    if (hour < 12) return 'Buenos días';
    if (hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

class _HubCard extends StatefulWidget {
  const _HubCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<_HubCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _hover ? 0.97 : 0.9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.25 : 0.12),
              blurRadius: _hover ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _hover
                ? widget.color
                : Colors.white.withValues(alpha: 0.4),
            width: _hover ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 52,
                    color: widget.color,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FEATURE TOOLBAR — breadcrumb 36px con "← Inicio"
// ════════════════════════════════════════════════════════════════

class _FeatureToolbar extends StatelessWidget {
  const _FeatureToolbar({
    required this.title,
    required this.icon,
    required this.onHome,
  });
  final String title;
  final IconData icon;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onHome,
            icon: const Icon(Icons.home_outlined, size: 18, color: Colors.white),
            label: const Text(
              'Inicio',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Text(
            '·',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 16, color: Colors.tealAccent),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
