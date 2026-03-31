import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/patient_record/presentation/sign_document_screen.dart';

/// Widget que verifica si hay documentos pendientes de firma.
/// Si los hay, muestra un popup obligatorio antes de permitir
/// navegar por la app. Se firman uno a uno.
class PendingSignatureGate extends StatefulWidget {
  const PendingSignatureGate({
    required this.userId,
    required this.userRole,
    required this.child,
    super.key,
  });

  final String userId;
  final String userRole;
  final Widget child;

  @override
  State<PendingSignatureGate> createState() => _PendingSignatureGateState();
}

class _PendingSignatureGateState extends State<PendingSignatureGate> {
  bool _checking = true;
  Map<String, dynamic>? _pendingDoc;
  String? _pendingDocId;

  @override
  void initState() {
    super.initState();
    _checkPendingSignatures();
  }

  Future<void> _checkPendingSignatures() async {
    setState(() => _checking = true);
    try {
      final uid = widget.userId;
      final role = widget.userRole;
      final isStaff = role == 'admin' || role == 'administrador' || role == 'profesional';

      // Buscar documentos pendientes de firma para este usuario
      QuerySnapshot snap;
      if (isStaff) {
        // Profesionales: buscar documentos asignados a ESTE profesional
        snap = await FirebaseFirestore.instance
            .collection('documents')
            .where('tipo', isEqualTo: 'Legal')
            .get();

        // Filtrar los asignados a este profesional y sin firma
        final pendientes = snap.docs.where((d) {
          final data = d.data()! as Map<String, dynamic>;
          return data['requiereDobleFirma'] == true &&
              data['profesionalAsignadoId'] == uid &&
              data['firmaProfesional'] == null;
        }).toList();

        if (pendientes.isNotEmpty) {
          _pendingDoc = pendientes.first.data()! as Map<String, dynamic>;
          _pendingDocId = pendientes.first.id;
        }
      } else {
        // Clientes: buscar sus documentos pendientes
        snap = await FirebaseFirestore.instance
            .collection('documents')
            .where('userId', isEqualTo: uid)
            .get();

        final pendientes = snap.docs.where((d) {
          final data = d.data()! as Map<String, dynamic>;
          if (data['firmaCliente'] != null) return false;
          if (data['tipo'] != 'Legal') return false;
          return true;
        }).toList();

        if (pendientes.isNotEmpty) {
          _pendingDoc = pendientes.first.data()! as Map<String, dynamic>;
          _pendingDocId = pendientes.first.id;
        }
      }
    } catch (e) {
      debugPrint('Error checking pending signatures: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openSignature() async {
    if (_pendingDoc == null || _pendingDocId == null) return;

    final role = widget.userRole;
    final isStaff = role == 'admin' || role == 'administrador' || role == 'profesional';

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => SignDocumentScreen(
          documentId: _pendingDocId!,
          documentTitle: _pendingDoc!.safeString('titulo'),
          pdfUrl: _pendingDoc!.safeString('urlPdf'),
          signerRole: isStaff ? 'profesional' : 'cliente',
          requiereDobleFirma: _pendingDoc!['requiereDobleFirma'] == true,
        ),
      ),
    );

    if (result ?? false) {
      // Despues de firmar, verificar si hay mas pendientes
      _pendingDoc = null;
      _pendingDocId = null;
      await _checkPendingSignatures();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return widget.child;
    }

    if (_pendingDoc != null) {
      // Mostrar la app con el popup encima
      return Stack(
        children: [
          widget.child,
          // Overlay semi-transparente
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                        child: Icon(Icons.gavel, color: Colors.orange.shade700, size: 36),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Firma pendiente',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _pendingDoc!.safeString('titulo'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tienes un consentimiento pendiente de firma. Debes firmarlo para continuar usando la aplicacion.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _openSignature,
                        icon: const Icon(Icons.draw, size: 20),
                        label: const Text('FIRMAR AHORA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}
