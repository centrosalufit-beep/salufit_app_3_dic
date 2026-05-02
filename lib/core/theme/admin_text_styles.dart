import 'package:flutter/material.dart';
import 'package:salufit_app/core/theme/app_colors.dart';

/// Estilos de texto convencionales para el panel admin Windows.
///
/// Las pantallas del DesktopScaffold se renderizan sobre el wallpaper
/// `assets/login_bg.jpg` (verde acuático CLARO). Por eso los textos del
/// body usan tonos OSCUROS por defecto. Los títulos blancos solo viven
/// dentro de barras oscuras (AppBar, _FeatureToolbar, headers de sección
/// con fondo `Color(0xFF1E293B)`).
///
/// Convención de uso:
/// * `screenTitle` — H1 dentro del body, sobre fondo claro.
/// * `sectionTitle` — H2 de sección dentro del body.
/// * `bodyPrimary` — texto principal de párrafo / contenido.
/// * `bodySecondary` — texto secundario, descripciones, metadatos.
/// * `bodyMuted` — texto terciario casi marca de agua.
/// * `emptyState` — mensaje "no hay X" centrado.
/// * `onDarkTitle` / `onDarkBody` — variantes para fondos oscuros.
abstract final class AdminTextStyles {
  // ── Sobre fondo claro (wallpaper) ──────────────────────────
  static const TextStyle screenTitle = TextStyle(
    color: AppColors.sidebar,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.sidebar,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyPrimary = TextStyle(
    color: AppColors.textDark,
    fontSize: 14,
  );

  static const TextStyle bodySecondary = TextStyle(
    color: AppColors.textMuted,
    fontSize: 13,
  );

  static const TextStyle bodyMuted = TextStyle(
    color: Colors.black54,
    fontSize: 12,
  );

  static const TextStyle emptyState = TextStyle(
    color: AppColors.sidebar,
    fontSize: 14,
  );

  static const TextStyle fieldLabel = TextStyle(
    color: AppColors.sidebar,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // ── Sobre fondo oscuro (AppBar, headers, toolbars) ─────────
  static const TextStyle onDarkTitle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle onDarkBody = TextStyle(
    color: Colors.white,
    fontSize: 13,
  );

  static const TextStyle onDarkMuted = TextStyle(
    color: Colors.white70,
    fontSize: 12,
  );

  // ── Acentos / estados ──────────────────────────────────────
  static const TextStyle accentTeal = TextStyle(
    color: AppColors.primary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle errorText = TextStyle(
    color: AppColors.error,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}

/// Containers convencionales para el panel admin.
///
/// `AdminSurfaces.emptyChip` — chip blanco semi-transparente para estados
/// vacíos (centra un mensaje sobre el wallpaper sin que se pierda).
abstract final class AdminSurfaces {
  static BoxDecoration get emptyChip => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      );

  static BoxDecoration get card => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static const EdgeInsets emptyChipPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 10);
}

/// Helper para envolver un texto vacío en un chip legible centrado.
///
/// Uso:
/// ```dart
/// AdminEmptyState('No hay registros para este día.')
/// ```
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState(this.message, {this.icon, super.key});
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: AdminSurfaces.emptyChipPadding,
        decoration: AdminSurfaces.emptyChip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
            ],
            Text(message, style: AdminTextStyles.emptyState),
          ],
        ),
      ),
    );
  }
}
