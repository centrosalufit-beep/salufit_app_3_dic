import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salufit_app/features/auth/presentation/update_required_screen.dart';

/// Compara la versión actual contra `config/app_settings.minVersion` en Firestore.
/// Si la versión es inferior, muestra pantalla bloqueante.
class VersionGate extends StatefulWidget {
  const VersionGate({required this.child, super.key});
  final Widget child;

  @override
  State<VersionGate> createState() => _VersionGateState();
}

class _VersionGateState extends State<VersionGate> {
  bool _checking = true;
  bool _updateRequired = false;
  String _currentVersion = '';
  String _requiredVersion = '';

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;

      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_settings')
          .get();

      if (doc.exists) {
        final data = doc.data();
        _requiredVersion = (data?['minVersion'] as String?) ?? '0.0.0';
        _updateRequired = _isVersionLower(_currentVersion, _requiredVersion);
      }
    } catch (e) {
      debugPrint('VersionGate: Error al verificar versión: $e');
      // En caso de error, no bloquear al usuario
    }

    if (mounted) setState(() => _checking = false);
  }

  /// Devuelve true si [current] es estrictamente menor que [required].
  bool _isVersionLower(String current, String required) {
    final cParts = current.split('.').map(int.tryParse).toList();
    final rParts = required.split('.').map(int.tryParse).toList();

    for (var i = 0; i < 3; i++) {
      final c = i < cParts.length ? (cParts[i] ?? 0) : 0;
      final r = i < rParts.length ? (rParts[i] ?? 0) : 0;
      if (c < r) return true;
      if (c > r) return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_updateRequired) {
      return UpdateRequiredScreen(
        currentVersion: _currentVersion,
        requiredVersion: _requiredVersion,
      );
    }

    return widget.child;
  }
}
