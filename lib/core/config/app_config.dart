// lib/core/config/app_config.dart

class AppConfig {
  AppConfig._(); // Constructor privado

  // --- TIEMPOS ---
  static const Duration apiTimeout = Duration(seconds: 30);

  // --- DATOS DE CONTACTO / LEGAL ---
  static const String urlWhatsApp = 'https://wa.me/34629011055';
  static const String urlWeb = 'https://www.centrosalufit.com';
  static const String urlPrivacidad =
      'https://centrosalufit.com/politica-de-privacidad/';
  static const String urlTerminos =
      'https://centrosalufit.com/terminos-y-condiciones/';
  static const String urlCookies =
      'https://centrosalufit.com/politica-de-cookies/';
  static const String emailSoporte = 'soporte@centrosalufit.com';
  static const String emailDpo = 'dpo@centrosalufit.com';
  static const String telefonoSoporte = '+34 629 011 055';
  static const String razonSocial = 'Centro Salufit';
  static const String direccionFiscal =
      'Centro Salufit, España';

  // --- VERSIONES LEGALES ---
  // Al incrementar estos valores, los usuarios serán obligados a re-aceptar
  // los términos correspondientes via MigrationGate.
  static const String consentVersionActual = '2026.2';
  static const String termsVersionActual = '2026.2';

  // --- SEGURIDAD ---
  // Edad mínima según LOPDGDD Art. 6.1 (España: 14 años)
  static const int edadMinima = 14;
  static const int edadMinimaRgpd = 16; // UE base

  // --- ROLES DEL SISTEMA ---
  static const String rolCliente = 'cliente';
  static const String rolAdmin = 'admin';
  static const String rolProfesional = 'profesional';

  // --- SEGURIDAD Y HARDWARE ---
  // INFO (Arquitectura): Sincronizar con Firestore config/time_clock_settings
  static const String wifiPermitida = 'DIGIFIBRA-3AE9';

  // --- BACKEND / CLOUD FUNCTIONS (Gen 2 - Producción) ---
  // ID del proyecto extraído: 6cmp56xv3a
  //
  // Nota: las llamadas modernas (activación, borrado de cuenta, password,
  // QR, auditoría) se hacen vía Callables (FirebaseFunctions.instance
  // .httpsCallable(...)) y no necesitan URL aquí. Solo dejamos las URLs
  // de funciones HTTP todavía en uso activo desde la app.

  // Reservas — onRequest (HTTP)
  static const String urlCancelarReserva =
      'https://cancelarreserva-6cmp56xv3a-uc.a.run.app';

  // Administración — en uso activo
  static const String urlGenerarClases =
      'https://generarclasesmensuales-6cmp56xv3a-uc.a.run.app';
  static const String urlRenovarBonos =
      'https://renovarbonosbatch-6cmp56xv3a-uc.a.run.app';

  // Staff — fichaje
  static const String urlFichar =
      'https://registrarfichaje-6cmp56xv3a-uc.a.run.app';

  /// Lógica centralizada de permisos
  static bool esStaff(String? role) {
    if (role == null) return false;
    final staffRoles = [rolAdmin, rolProfesional];
    return staffRoles.contains(role.toLowerCase());
  }
}
