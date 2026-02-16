import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_renewal_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/admin_upload_excel_screen.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/qr_scanner_screen.dart';
import 'package:salufit_app/features/auth/presentation/login_screen.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/features/bookings/presentation/admin_class_manager_screen.dart';
import 'package:salufit_app/features/bookings/services/class_generator_service.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/class_list_screen.dart';
import 'package:salufit_app/features/communication/presentation/internal_management_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_create_patient_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_detail_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_list_screen.dart';
import 'package:salufit_app/services/staff_service.dart';

class MobileScaffold extends ConsumerStatefulWidget {
  const MobileScaffold({
    required this.userId,
    required this.userRole,
    super.key,
  });
  final String userId;
  final String userRole;

  @override
  ConsumerState<MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends ConsumerState<MobileScaffold> {
  String _currentUserName = '';
  bool _isLoadingFichaje = false;

  @override
  void initState() {
    super.initState();
    _loadName();
    if (widget.userRole == 'admin' || widget.userRole == 'administrador') {
      _checkMonthlyClasses();
    }
  }

  Future<void> _checkMonthlyClasses() async {
    final now = DateTime.now();
    if (now.day > 5) return;

    final doc = await FirebaseFirestore.instance
        .collection('system_config')
        .doc('clases_generadas')
        .get();
    final monthKey = '${now.year}-${now.month}';

    if (!doc.exists || doc.data()?['ultimoMesGenerado'] != monthKey) {
      if (!mounted) return;
      _showGenerationPopup(now.month, now.year);
    }
  }

  void _showGenerationPopup(int month, int year) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('ðŸ“ AGENDA VACÃA'),
        content: const Text(
          'No se han generado las clases para este mes. Â¿Deseas crearlas ahora?',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoadingFichaje = true);
              await ClassGeneratorService.generateMonth(
                month: month,
                year: year,
              );
              if (mounted) {
                setState(() => _isLoadingFichaje = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('âœ… Clases generadas con Ã©xito'),
                  ),
                );
              }
            },
            child: const Text('GENERAR CLASES'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _currentUserName =
              data.safeString('nombreCompleto', defaultValue: 'Profesional');
        });
      }
    } on Exception catch (e) {
      debugPrint('Error cargando nombre: $e');
    }
  }

  Future<void> _handleFichaje() async {
    final tipo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Fichaje'),
        content: const Text('Selecciona el tipo de registro:'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'OUT'),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'SALIDA',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'IN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.login),
            label: const Text('ENTRADA'),
          ),
        ],
      ),
    );
    if (tipo == null || !mounted) return;

    setState(() => _isLoadingFichaje = true);
    try {
      await StaffService().registrarFichaje(userId: widget.userId, type: tipo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichaje de $tipo registrado OK'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al fichar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingFichaje = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar SesiÃ³n'),
        content: const Text('Â¿Quieres salir de la cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'SÃ­, Salir',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      ref
        ..invalidate(userProfileProvider)
        ..invalidate(authServiceProvider);
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on Exception catch (e) {
      debugPrint('Error logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        widget.userRole == 'admin' || widget.userRole == 'administrador';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _compactHeader(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 5, bottom: 10),
                child: Text(
                  'GestiÃ³n Diaria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
                children: <Widget>[
                  _card(
                    Icons.qr_code_scanner,
                    'QR',
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const QRScannerScreen(),
                      ),
                    ),
                  ),
                  _card(
                    Icons.person_add,
                    'Nuevo',
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminCreatePatientScreen(),
                      ),
                    ),
                  ),
                  _card(
                    Icons.people,
                    'Pacientes',
                    Colors.indigo,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AdminPatientListScreen(
                          viewerRole: widget.userRole,
                          onUserSelected: (u, n) => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => AdminPatientDetailScreen(
                                userId: u,
                                userName: n,
                                viewerRole: widget.userRole,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _card(
                    Icons.sports_gymnastics,
                    'Reservar',
                    const Color(0xFF009688),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ClassListScreen(
                          userId: widget.userId,
                          userRole: widget.userRole,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isAdmin) ...[
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 5, bottom: 10),
                  child: Text(
                    'AdministraciÃ³n',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  children: <Widget>[
                    _card(
                      Icons.sync,
                      'Renovar',
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminRenewalScreen(),
                        ),
                      ),
                    ),
                    _card(
                      Icons.task_alt,
                      'Tareas',
                      Colors.pink,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => InternalManagementScreen(
                            currentUserId: widget.userId,
                            userRole: widget.userRole,
                            viewType: 'TASKS',
                          ),
                        ),
                      ),
                    ),
                    _card(
                      Icons.upload_file,
                      'Importar',
                      Colors.blueGrey,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminUploadExcelScreen(),
                        ),
                      ),
                    ),
                    _card(
                      Icons.calendar_month,
                      'Clases',
                      Colors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AdminClassManagerScreen(
                            currentUserId: widget.userId,
                          ),
                        ),
                      ),
                    ),
                    _card(
                      Icons.forum,
                      'Chat',
                      Colors.cyan,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => InternalManagementScreen(
                            currentUserId: widget.userId,
                            userRole: widget.userRole,
                            viewType: 'CHAT',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hola,',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                Text(
                  _currentUserName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _headerActionBtn(
                icon: Icons.access_time_filled,
                color: Colors.teal,
                isLoading: _isLoadingFichaje,
                onTap: _handleFichaje,
              ),
              const SizedBox(width: 10),
              _headerActionBtn(
                icon: Icons.logout,
                color: Colors.red,
                onTap: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerActionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _card(IconData i, String l, Color c, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(i, color: c, size: 22),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                l,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
