import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/auth/domain/user_model.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/features/auth/providers/user_profile_provider.dart';
import 'package:salufit_app/features/bookings/data/class_repository.dart';
import 'package:salufit_app/features/home/presentation/home_providers.dart';
import 'package:salufit_app/l10n/generated/app_localizations.dart';
import 'package:salufit_app/shared/widgets/language_flag_picker.dart';
import 'package:salufit_app/shared/widgets/salufit_header.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({required this.userId, super.key});
  final String userId;

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  bool _isActionLoading = false;

  Future<void> _handleSmartNavigation(String keyword) async {
    setState(() => _isActionLoading = true);
    try {
      final now = DateTime.now();
      final snapshot = await ref.read(firebaseFirestoreProvider)
          .collection('groupClasses')
          .where('fechaHoraInicio', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('fechaHoraInicio')
          .limit(30)
          .get();

      DateTime? targetDate;
      for (final doc in snapshot.docs) {
        final nombre = doc.data().safeString('nombre').toLowerCase();
        if (nombre.contains(keyword.toLowerCase())) {
          targetDate = doc.data().safeDateTime('fechaHoraInicio');
          break;
        }
      }

      if (!mounted) {
        return;
      }

      if (targetDate != null) {
        ref.read(homeTabProvider.notifier).setTab(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ubicando próxima clase de $keyword...'), 
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay clases de ese tipo esta semana.'), 
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error Nav: $e');
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  void _mostrarQrGrande() {
    showDialog<void>(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PASAPORTE SALUFIT',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: widget.userId,
                size: 240,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: AppColors.primary),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('CERRAR')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final passesStream = ref.read(firebaseFirestoreProvider).collection('passes').where('userId', isEqualTo: widget.userId).where('activo', isEqualTo: true).snapshots();
    final bookingsStream = ref.read(firebaseFirestoreProvider).collection('bookings').where('userId', isEqualTo: widget.userId).limit(20).snapshots();

    return profileAsync.when(
      loading: () => const SalufitScaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SalufitScaffold(body: Center(child: Text('Ha ocurrido un error. Intentalo de nuevo.'))),
      data: (UserModel? user) {
        final name = (user?.nombre ?? 'USUARIO').toUpperCase();
        return SalufitScaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          body: SafeArea(
            child: _isActionLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SalufitHeader(title: name, subtitle: AppLocalizations.of(context).profileTitle.toUpperCase()),
                        StreamBuilder<QuerySnapshot>(
                          stream: passesStream,
                          builder: (context, snap) {
                            var tokens = 0;
                            var isActive = false;
                            if (snap.hasData && snap.data != null && snap.data!.docs.isNotEmpty) {
                              // CORRECCIÓN: Not-null assertion antes del cast
                              final d = snap.data!.docs.first.data()! as Map<String, dynamic>;
                              tokens = d.safeInt('tokensRestantes');
                              isActive = tokens > 0;
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Expanded(flex: 6, child: _buildTokenCard(tokens, isActive)),
                                    const SizedBox(width: 15),
                                    Expanded(flex: 4, child: _buildQrCard()),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: GoldenGiftCard(
                            userId: widget.userId,
                            onNavigate: _handleSmartNavigation,
                          ),
                        ),
                        _buildSectionTitle(AppLocalizations.of(context).dashboardYourClasses.toUpperCase()),
                        StreamBuilder<QuerySnapshot>(
                          stream: bookingsStream,
                          builder: (context, snap) {
                            if (!snap.hasData || snap.data == null || snap.data!.docs.isEmpty) {
                              return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No tienes reservas próximas')));
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snap.data!.docs.length,
                              itemBuilder: (context, index) {
                                // CORRECCIÓN: Not-null assertion antes del cast
                                final bData = snap.data!.docs[index].data()! as Map<String, dynamic>;
                                final classId = bData.safeString('groupClassId');
                                if (classId.isEmpty) {
                                  return const SizedBox();
                                }
                                return FutureBuilder<DocumentSnapshot>(
                                  future: ref.read(firebaseFirestoreProvider).collection('groupClasses').doc(classId).get(),
                                  builder: (context, classSnap) {
                                    if (!classSnap.hasData || !classSnap.data!.exists) {
                                      return const SizedBox();
                                    }
                                    final cData = classSnap.data!.data()! as Map<String, dynamic>;
                                    final nombre = cData.safeString('nombre');
                                    final fecha = cData.safeDateTime('fechaHoraInicio');
                                    if (fecha.isBefore(DateTime.now().subtract(const Duration(hours: 1)))) {
                                      return const SizedBox();
                                    }
                                    final bookingId = snap.data!.docs[index].id;
                                    return _buildBookingCard(
                                      nombre: nombre,
                                      fecha: fecha,
                                      bookingId: bookingId,
                                      classId: classId,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        _buildSectionTitle(AppLocalizations.of(context).profileLanguage.toUpperCase()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  AppLocalizations.of(context).settingsLanguageSubtitle,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                LanguageFlagPicker(
                                  onChanged: (_) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(AppLocalizations.of(context).settingsLanguageChanged),
                                          backgroundColor: AppColors.primary,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(padding: const EdgeInsets.fromLTRB(20, 30, 20, 10), child: _buildLogoutButton()),
                        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: _buildDeleteAccountButton()),
                        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 60), child: _buildExportDataLink()),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(25, 20, 20, 12), child: Text(title, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 2)));

  Widget _buildTokenCard(int tokens, bool isActive) {
    final colors = isActive ? [Colors.lightGreenAccent.shade700, Colors.tealAccent.shade700] : [Colors.deepOrangeAccent, Colors.orange.shade800];
    return Container(
      height: 180,
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Stack(children: [
        const Positioned(right: -30, bottom: -30, child: Icon(Icons.bolt, size: 200, color: Colors.white12)),
        Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: Text(isActive ? 'ACTIVO' : 'AGOTADO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
          const Spacer(),
          Text('$tokens', style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
          const Text('SESIONES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1)),
        ])),
      ]),
    );
  }

  Widget _buildQrCard() => InkWell(onTap: _mostrarQrGrande, borderRadius: BorderRadius.circular(25), child: Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))]), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code_scanner, size: 60, color: AppColors.primary), SizedBox(height: 10), Text('ACCESO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)), Text('Toca para ampliar', style: TextStyle(fontSize: 9, color: Colors.grey))])));

  Future<void> _handleCancelBooking({
    required String bookingId,
    required String classId,
    required DateTime fecha,
  }) async {
    final horasRestantes = fecha.difference(DateTime.now()).inHours;
    final perderaToken = horasRestantes < 24;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: perderaToken ? Colors.red.shade50 : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                perderaToken ? Icons.token : Icons.refresh,
                color: perderaToken ? Colors.red : Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              perderaToken ? 'Perderas tu token' : 'Cancelar reserva',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              perderaToken
                  ? 'Faltan menos de 24h. El token no se devolvera segun nuestra politica de cancelacion.'
                  : 'Se cancelara tu reserva y se te devolvera el token.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('VOLVER', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: perderaToken ? Colors.red : Colors.orange,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CANCELAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final tokenDevuelto = await ref.read(classRepositoryProvider).cancelarReserva(
        bookingId: bookingId,
        classId: classId,
        userId: widget.userId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tokenDevuelto ? 'Reserva cancelada y token devuelto' : 'Reserva cancelada (token no devuelto)'),
            backgroundColor: tokenDevuelto ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ha ocurrido un error. Intentalo de nuevo.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildBookingCard({
    required String nombre,
    required DateTime fecha,
    required String bookingId,
    required String classId,
  }) {
    final n = nombre.toLowerCase();
    var colors = [const Color(0xFF009688), const Color(0xFF4DB6AC)];
    var icon = Icons.fitness_center;
    if (n.contains('entrena')) {
      colors = [const Color(0xFFC62828), const Color(0xFFFF5252)];
    } else if (n.contains('medita')) {
      colors = [const Color(0xFF4A148C), const Color(0xFFAB47BC)];
      icon = Icons.self_improvement;
    } else if (n.contains('tribu')) {
      colors = [const Color(0xFFE65100), const Color(0xFFFFB74D)];
      icon = Icons.directions_walk;
    } else if (n.contains('terapéutico') || n.contains('terapeutico')) {
      colors = [const Color(0xFF0D47A1), const Color(0xFF42A5F5)];
      icon = Icons.self_improvement;
    } else if (n.contains('kids') || n.contains('explora')) {
      colors = [const Color(0xFF00897B), const Color(0xFF4DB6AC)];
      icon = Icons.escalator_warning;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 30),
        title: Text(nombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'serif')),
        subtitle: Text(DateFormat('EEEE d - HH:mm', 'es').format(fecha).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 22),
          onPressed: () => _handleCancelBooking(bookingId: bookingId, classId: classId, fecha: fecha),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() => OutlinedButton.icon(
    onPressed: () async {
      setState(() => _isActionLoading = true);
      await ref.read(authServiceProvider).signOut();
    },
    icon: const Icon(Icons.logout, color: Colors.orange),
    label: Text(
      AppLocalizations.of(context).profileLogoutAction.toUpperCase(),
      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900),
    ),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(18),
      side: const BorderSide(color: Colors.orange, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
  );

  Widget _buildExportDataLink() => GestureDetector(
    onTap: _handleExportData,
    child: Text('Solicitar copia de mis datos', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
  );

  Future<void> _handleExportData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar datos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Se generara un archivo con todos tus datos personales conforme al RGPD (Art. 20). Esto puede tardar unos segundos.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('EXPORTAR', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isActionLoading = true);
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return;
      final db = ref.read(firebaseFirestoreProvider);

      final profile = (await db.collection('users_app').doc(uid).get()).data() ?? {};
      final bookings = (await db.collection('bookings').where('userId', isEqualTo: uid).get()).docs.map((d) => d.data()).toList();
      final passes = (await db.collection('passes').where('userId', isEqualTo: uid).get()).docs.map((d) => d.data()).toList();
      final documents = (await db.collection('documents').where('userId', isEqualTo: uid).get()).docs.map((d) => d.data()).toList();

      final export = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': uid,
        'profile': profile,
        'bookings': bookings,
        'passes': passes,
        'documents': documents,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(export);

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  const Text('Datos exportados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('${bookings.length} reservas, ${passes.length} bonos, ${documents.length} documentos', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: SingleChildScrollView(child: SelectableText(jsonString, style: const TextStyle(fontSize: 9, fontFamily: 'monospace'))),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonString));
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles'), backgroundColor: Colors.green));
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('COPIAR TODO'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CERRAR')),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error export: ${e.runtimeType}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al exportar datos'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Widget _buildDeleteAccountButton() => TextButton(
    onPressed: _handleDeleteAccount,
    child: const Text('Eliminar mi cuenta', style: TextStyle(color: Colors.red, fontSize: 12, decoration: TextDecoration.underline)),
  );

  Future<void> _handleDeleteAccount() async {
    // Paso 1: Confirmacion inicial
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: Icon(Icons.warning_amber, color: Colors.red.shade700, size: 36)),
              const SizedBox(height: 16),
              const Text('Eliminar cuenta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text('Esta accion eliminara permanentemente tu cuenta y todos tus datos. No se puede deshacer.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
              const SizedBox(height: 8),
              Text('Se eliminaran: perfil, reservas, documentos, tokens y todo el historial.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CONTINUAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirm1 != true || !mounted) return;

    // Paso 2: Escribir ELIMINAR para confirmar
    final confirmText = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Confirmacion final', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                const Text('Escribe ELIMINAR para confirmar', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'ELIMINAR'), textCapitalization: TextCapitalization.characters, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CANCELAR'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('ELIMINAR CUENTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                ]),
              ],
            ),
          ),
        );
      },
    );
    if (confirmText != 'ELIMINAR' || !mounted) {
      if (confirmText != null && confirmText != 'ELIMINAR' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texto incorrecto. Escribe ELIMINAR.'), backgroundColor: Colors.orange));
      }
      return;
    }

    // Paso 3: Ejecutar eliminacion
    setState(() => _isActionLoading = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return;
      final uid = user.uid;
      final db = ref.read(firebaseFirestoreProvider);

      // Registro de auditoria ANTES de borrar
      await db.collection('audit_logs').add({
        'tipo': 'ELIMINACION_CUENTA',
        'userId': uid,
        'email': user.email,
        'fecha': FieldValue.serverTimestamp(),
        'detalles': 'Solicitud de eliminacion por el usuario',
      });

      // Borrar datos en cascada
      final collections = ['bookings', 'passes', 'documents', 'exercise_assignments'];
      for (final col in collections) {
        final snap = await db.collection(col).where('userId', isEqualTo: uid).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }

      // Borrar perfil de users_app
      await db.collection('users_app').doc(uid).delete();

      // Borrar usuario de Firebase Auth
      await user.delete();

      debugPrint('>>> [DELETE] Cuenta $uid eliminada completamente');
    } on FirebaseException catch (e) {
      if (e.code == 'requires-recent-login' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por seguridad, cierra sesion, vuelve a entrar e intentalo de nuevo.'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      debugPrint('Error eliminacion: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar la cuenta'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }
}

class GoldenGiftCard extends ConsumerStatefulWidget {
  const GoldenGiftCard({required this.userId, required this.onNavigate, super.key});
  final String userId;
  final void Function(String) onNavigate;

  @override
  ConsumerState<GoldenGiftCard> createState() => _GoldenGiftCardState();
}

class _GoldenGiftCardState extends ConsumerState<GoldenGiftCard> {
  bool _isOpened = false;
  String _recommendedKeyword = 'entrena';
  String _recommendationText = 'Prueba una clase de Entrenamiento.';

  @override
  void initState() {
    super.initState();
    _initCard();
  }

  Future<void> _initCard() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'gift_opened_${DateTime.now().month}_${DateTime.now().year}';
    if (prefs.getBool(key) ?? false) {
      if (mounted) {
        setState(() => _isOpened = true);
      }
    }
    _calculateSmartBenefit();
  }

  Future<void> _calculateSmartBenefit() async {
    final bookings = await ref.read(firebaseFirestoreProvider).collection('bookings').where('userId', isEqualTo: widget.userId).limit(20).get();
    final history = bookings.docs.map((d) => d.data().safeString('groupClassId')).toList();
    
    if (!history.any((id) => id.contains('medita'))) {
      if (mounted) {
        setState(() { _recommendedKeyword = 'medita'; _recommendationText = 'Disfruta de una sesión extra de Meditación este mes.'; });
      }
    } else {
      if (mounted) {
        setState(() { _recommendedKeyword = 'terap'; _recommendationText = 'Prueba nuestra clase de Ejercicio Terapéutico.'; });
      }
    }
  }

  Future<void> _openGift() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gift_opened_${DateTime.now().month}_${DateTime.now().year}', true);
    if (mounted) {
      setState(() => _isOpened = true);
    }
  }

  Future<void> _launchWhatsApp() async {
    const phone = '+34629011055';
    const message = 'Hola! Me gustaría disfrutar de mi beneficio exclusivo del 25% de descuento en el pack de 5 sesiones de INDIBA o NESA.';
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 600),
      crossFadeState: _isOpened ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: InkWell(
        onTap: _openGift,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 5))]),
          child: const Row(children: [Icon(Icons.card_giftcard, color: Colors.white, size: 30), SizedBox(width: 20), Text('TIENES UN REGALO', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)), Spacer(), Icon(Icons.chevron_right, color: Colors.white)]),
        ),
      ),
      secondChild: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.amber, width: 2)),
        child: Column(children: [
          const Text('ELIGE TU BENEFICIO MENSUAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13, color: Colors.brown)),
          const SizedBox(height: 20),
          _buildOption(
            icon: Icons.auto_awesome,
            title: 'CLASE RECOMENDADA',
            desc: _recommendationText,
            btnLabel: 'RESERVAR CLASE',
            onTap: () => widget.onNavigate(_recommendedKeyword),
          ),
          const Divider(height: 30),
          _buildOption(
            icon: Icons.percent,
            title: 'DESCUENTO ESPECIAL',
            desc: '25% DTO. en pack de 5 sesiones de INDIBA o NESA.',
            btnLabel: 'RECLAMAR POR WHATSAPP',
            onTap: _launchWhatsApp,
          ),
        ]),
      ),
    );
  }

  Widget _buildOption({required IconData icon, required String title, required String desc, required String btnLabel, required VoidCallback onTap}) {
    return Column(children: [
      Row(children: [
        Icon(icon, color: Colors.amber.shade800, size: 24),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
      ]),
      const SizedBox(height: 8),
      Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(btnLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    ]);
  }
}
