// lib/core/config/app_config.dart

class AppConfig {
  AppConfig._(); // Constructor privado

  // --- TIEMPOS ---
  static const Duration apiTimeout = Duration(seconds: 30);

  // --- DATOS DE CONTACTO ---
  static const String urlWhatsApp = 'https://wa.me/34629011055';
  static const String urlPrivacidad =
      'https://centrosalufit.com/politica-de-privacidad/';

  // --- ROLES DEL SISTEMA ---
  static const String rolCliente = 'cliente';
  static const String rolAdmin = 'admin';
  static const String rolProfesional = 'profesional';

  // --- SEGURIDAD Y HARDWARE ---
  // INFO (Arquitectura): Sincronizar con Firestore config/time_clock_settings
  static const String wifiPermitida = 'DIGIFIBRA-3AE9';

  // --- BACKEND / CLOUD FUNCTIONS (Gen 2 - Producción) ---
  // ID del proyecto extraído: 6cmp56xv3a

  // Reservas
  static const String urlCrearReserva =
      'https://crearreserva-6cmp56xv3a-uc.a.run.app';
  static const String urlCancelarReserva =
      'https://cancelarreserva-6cmp56xv3a-uc.a.run.app';

  // Administración
  static const String urlGenerarClases =
      'https://generarclasesmensuales-6cmp56xv3a-uc.a.run.app';
  static const String urlRenovarBonos =
      'https://renovarbonosbatch-6cmp56xv3a-uc.a.run.app';

  // Autenticación
  static const String urlOtpEnviar =
      'https://enviarcodigootp-6cmp56xv3a-uc.a.run.app';
  static const String urlActivarCuenta =
      'https://activarcuenta-6cmp56xv3a-uc.a.run.app';
  // He añadido esta porque aparece en tu lista y será necesaria para el login:
  static const String urlOtpVerificar =
      'https://verificarcodigootp-6cmp56xv3a-uc.a.run.app';

  // Staff
  static const String urlFichar =
      'https://registrarfichaje-6cmp56xv3a-uc.a.run.app';

  /// Lógica centralizada de permisos
  static bool esStaff(String? role) {
    if (role == null) return false;
    final staffRoles = [rolAdmin, rolProfesional];
    return staffRoles.contains(role.toLowerCase());
  }
}
