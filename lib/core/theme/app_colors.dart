import 'package:flutter/material.dart';

/// Colores corporativos de Salufit.
/// Cualquier color hardcoded debe centralizarse aquí.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF009688);
  static const Color primaryDark = Color(0xFF00796B);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDeepDark = Color(0xFF004D40);

  // ── Sidebar / Desktop ──────────────────────────────────
  static const Color sidebar = Color(0xFF1E293B);

  // ── Fondos ─────────────────────────────────────────────
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceAlt = Color(0xFFF5F5F5);

  // ── Texto ──────────────────────────────────────────────
  static const Color textDark = Color(0xFF263238);
  static const Color textMuted = Color(0xFF454545);

  // ── Estado ─────────────────────────────────────────────
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFC62828);
  static const Color success = Color(0xFF43A047);
  static const Color successLight = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFF64B5F6);

  // ── Acento / Especiales ────────────────────────────────
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color accent = Color(0xFF6A1B9A);
}
