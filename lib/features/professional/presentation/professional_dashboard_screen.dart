import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_crm_screen.dart';
import 'package:salufit_app/features/communication/presentation/widgets/chat_list_widget.dart';
import 'package:salufit_app/features/professional/presentation/professional_assign_screen.dart';
import 'package:salufit_app/features/professional/presentation/professional_class_screen.dart';
import 'package:salufit_app/features/professional/presentation/professional_tasks_screen.dart';
import 'package:salufit_app/shared/widgets/salufit_header.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ProfessionalDashboardScreen extends StatelessWidget {
  const ProfessionalDashboardScreen({
    required this.userId,
    required this.userRole,
    super.key,
  });
  final String userId;
  final String userRole;

  @override
  Widget build(BuildContext context) {
    return SalufitScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SalufitHeader(
                title: 'SALUFIT PRO',
                subtitle: 'panel profesional',
                trailing: _NotificationBell(userId: userId),
              ),
              const SizedBox(height: 16),

              // Tarjeta de jornada
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _JornadaCard(userId: userId),
              ),
              const SizedBox(height: 24),

              // Accesos rápidos
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'ACCESOS RÁPIDOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _QuickAccessGrid(userId: userId, userRole: userRole),
              ),
              const SizedBox(height: 24),

              // Tareas pendientes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _PendingTasksPreview(userId: userId),
              ),
              const SizedBox(height: 24),

              // Mini CRM
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _MiniCrmCard(userId: userId),
              ),
              const SizedBox(height: 30),

              // Cerrar sesión
              Center(
                child: TextButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(
                    Icons.power_settings_new,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CAMPANA DE NOTIFICACIONES
// ═══════════════════════════════════════════════════════════════

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .snapshots(),
      builder: (context, chatSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('staff_tasks')
              .where('asignadoAId', isEqualTo: userId)
              .where('estado', isEqualTo: 'pendiente')
              .snapshots(),
          builder: (context, taskSnap) {
            var count = 0;

            // Mensajes sin leer
            if (chatSnap.hasData) {
              for (final doc in chatSnap.data!.docs) {
                final data = doc.data()! as Map<String, dynamic>;
                final lastMsgTime =
                    (data['lastMessageTime'] as Timestamp?)?.toDate();
                final lastRead =
                    (data['lastReadBy_$userId'] as Timestamp?)?.toDate();
                final lastSender =
                    (data['lastMessageSenderId'] as String?) ?? '';
                if (lastMsgTime != null && lastSender != userId) {
                  if (lastRead == null || lastMsgTime.isAfter(lastRead)) {
                    count++;
                  }
                }
              }
            }

            // Tareas pendientes
            if (taskSnap.hasData) {
              count += taskSnap.data!.docs.length;
            }

            return GestureDetector(
              onTap: () => _showNotificationSheet(context, chatSnap, taskSnap),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    '$count',
                    style: const TextStyle(fontSize: 9),
                  ),
                  child: Icon(
                    count > 0
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    color: count > 0 ? AppColors.primary : Colors.grey,
                    size: 26,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationSheet(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot> chatSnap,
    AsyncSnapshot<QuerySnapshot> taskSnap,
  ) {
    var unreadChats = 0;
    if (chatSnap.hasData) {
      for (final doc in chatSnap.data!.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final lastMsgTime =
            (data['lastMessageTime'] as Timestamp?)?.toDate();
        final lastRead =
            (data['lastReadBy_$userId'] as Timestamp?)?.toDate();
        final lastSender = (data['lastMessageSenderId'] as String?) ?? '';
        if (lastMsgTime != null && lastSender != userId) {
          if (lastRead == null || lastMsgTime.isAfter(lastRead)) {
            unreadChats++;
          }
        }
      }
    }
    final pendingTasks = taskSnap.data?.docs.length ?? 0;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (unreadChats > 0)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.chat, color: Colors.white, size: 20),
                  ),
                  title: Text('$unreadChats mensajes sin leer'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Equipo'),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          body: ChatListWidget(
                            currentUserId: userId,
                            isStaffOnly: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (pendingTasks > 0)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade700,
                    child: const Icon(
                      Icons.task_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text('$pendingTasks tareas pendientes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ProfessionalTasksScreen(
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
              if (unreadChats == 0 && pendingTasks == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Sin notificaciones pendientes',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TARJETA DE JORNADA (fichaje)
// ═══════════════════════════════════════════════════════════════

class _JornadaCard extends StatelessWidget {
  const _JornadaCard({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final isClockedIn = snapshot.hasData &&
            snapshot.data!.docs.isNotEmpty &&
            snapshot.data!.docs.first.get('type') == 'IN';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isClockedIn
                  ? [const Color(0xFF009688), const Color(0xFF4DB6AC)]
                  : [const Color(0xFF455A64), const Color(0xFF78909C)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isClockedIn
                        ? const Color(0xFF009688)
                        : const Color(0xFF455A64))
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isClockedIn ? Icons.timer : Icons.timer_off,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isClockedIn ? 'JORNADA ACTIVA' : 'FUERA DE JORNADA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isClockedIn
                          ? 'Conectado desde el centro'
                          : 'Pulsa para fichar entrada',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _fichar(context, isClockedIn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor:
                      isClockedIn ? Colors.red : const Color(0xFF009688),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  isClockedIn ? 'SALIDA' : 'ENTRADA',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fichar(BuildContext context, bool isClockedIn) async {
    try {
      // Escritura directa a Firestore (validación WiFi la hace StaffService si se usa)
      final userName = await _resolveUserName(userId);
      await FirebaseFirestore.instance.collection('timeClockRecords').add({
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': isClockedIn ? 'OUT' : 'IN',
        'isManualEntry': false,
        'device': 'Android Pro',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isClockedIn ? 'Salida registrada' : 'Entrada registrada',
            ),
            backgroundColor: const Color(0xFF009688),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _resolveUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users_app')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final full = data.safeString('nombreCompleto');
        if (full.isNotEmpty) return full;
        return data.safeString('nombre');
      }
    } catch (_) {}
    return uid;
  }
}

// ═══════════════════════════════════════════════════════════════
// GRID DE ACCESOS RÁPIDOS
// ═══════════════════════════════════════════════════════════════

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.userId, required this.userRole});
  final String userId;
  final String userRole;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(
        icon: Icons.calendar_month,
        label: 'Clases',
        color: const Color(0xFF1976D2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProfessionalClassScreen(userId: userId),
          ),
        ),
      ),
      _QuickItem(
        icon: Icons.fitness_center,
        label: 'Asignar',
        color: const Color(0xFFE64A19),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const ProfessionalAssignScreen(),
          ),
        ),
      ),
      _QuickItem(
        icon: Icons.leaderboard,
        label: 'CRM',
        color: const Color(0xFF7B1FA2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: AdminCrmScreen(userId: userId, userRole: userRole),
            ),
          ),
        ),
      ),
      _QuickItem(
        icon: Icons.forum,
        label: 'Equipo',
        color: const Color(0xFF00796B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Equipo'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              body: ChatListWidget(
                currentUserId: userId,
                isStaffOnly: true,
              ),
            ),
          ),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items
          .map(
            (item) => _QuickAccessTile(item: item),
          )
          .toList(),
    );
  }
}

class _QuickItem {
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});
  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.color.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 32),
              const SizedBox(height: 8),
              Text(
                item.label.toUpperCase(),
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PREVIEW DE TAREAS PENDIENTES
// ═══════════════════════════════════════════════════════════════

class _PendingTasksPreview extends StatelessWidget {
  const _PendingTasksPreview({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('staff_tasks')
          .where('asignadoAId', isEqualTo: userId)
          .where('estado', isEqualTo: 'pendiente')
          .orderBy('fechaLimite')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'TAREAS PENDIENTES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ProfessionalTasksScreen(userId: userId),
                    ),
                  ),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...docs.map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              final titulo = data.safeString('titulo');
              final from = data.safeString('creadoPorNombre');
              final limite = data.safeDateTime('fechaLimite');
              final isOverdue = limite.isBefore(DateTime.now());

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isOverdue
                        ? Colors.red.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      color: isOverdue ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'De: $from · Límite: ${limite.day.toString().padLeft(2, '0')}/${limite.month.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue
                                  ? Colors.red.shade700
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      onPressed: () => doc.reference.update({
                        'estado': 'completada',
                        'completadaEl': FieldValue.serverTimestamp(),
                      }),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MINI CRM CARD
// ═══════════════════════════════════════════════════════════════

class _MiniCrmCard extends StatelessWidget {
  const _MiniCrmCard({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('crm_entries')
          .where('profesionalId', isEqualTo: userId)
          .where('mes', isEqualTo: now.month)
          .where('anio', isEqualTo: now.year)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        final resenas = docs
            .where(
              (d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == 'resena',
            )
            .length;
        final refs = docs
            .where(
              (d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == 'referencia',
            )
            .length;
        final grupales = docs
            .where(
              (d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == 'grupal',
            )
            .length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TU RENDIMIENTO ESTE MES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('⭐', '$resenas', 'Reseñas'),
                  _miniStat('🔗', '$refs', 'Referencias'),
                  _miniStat('🏋️', '$grupales/4', 'Grupales'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
