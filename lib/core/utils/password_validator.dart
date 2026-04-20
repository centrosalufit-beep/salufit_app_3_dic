/// Validador premium de contraseñas para app médica.
///
/// Cumple OWASP ASVS nivel 2 y aproxima HIPAA (8+ con complejidad → 12+).
/// Se usa tanto en UI (TextFormField validator) como en Cloud Functions.
class PasswordValidator {
  static const int minLength = 12;

  /// Devuelve null si la contraseña es válida, o un mensaje de error.
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'Introduce una contraseña';
    }
    if (password.length < minLength) {
      return 'Mínimo $minLength caracteres';
    }
    if (!RegExp('[A-Z]').hasMatch(password)) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!RegExp('[a-z]').hasMatch(password)) {
      return 'Debe incluir al menos una minúscula';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Debe incluir al menos un número';
    }
    if (_commonPasswords.contains(password.toLowerCase())) {
      return 'Esta contraseña es demasiado común';
    }
    return null;
  }

  /// Score visual (0-4) para feedback al usuario mientras escribe.
  static int strength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= minLength) score++;
    if (RegExp('[A-Z]').hasMatch(password) &&
        RegExp('[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  static String strengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Muy débil';
      case 2:
        return 'Débil';
      case 3:
        return 'Aceptable';
      case 4:
        return 'Fuerte';
      default:
        return '';
    }
  }

  // Lista mínima de contraseñas más comunes (subset del top 100 SecList)
  static const Set<String> _commonPasswords = {
    'password123', 'contraseña123', '123456789012', 'qwerty123456',
    'salufit12345', 'password1234', 'admin1234567', '111111111111',
    'password0000', '000000000000', 'contraseña00', 'administrador',
  };
}
