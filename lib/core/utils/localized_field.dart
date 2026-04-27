import 'dart:ui' show Locale;

/// Helpers para resolver campos localizados leídos desde Firestore con
/// fallback al texto en español.
///
/// Forma del campo Firestore esperada (opcional):
/// ```json
/// {
///   "nombre": "Pilates",
///   "nombreTranslations": {
///     "en": "Pilates",
///     "fr": "Pilates",
///     "de": "Pilates",
///     "nl": "Pilates"
///   }
/// }
/// ```
/// Si el documento no contiene `nombreTranslations` o no incluye el idioma
/// solicitado, se devuelve el valor del campo base (`nombre`), que en el
/// schema actual está en español.
class LocalizedField {
  const LocalizedField._();

  /// Devuelve el texto del campo `baseField` en el idioma de `locale`.
  ///
  /// `data` es el `Map<String, dynamic>` del documento Firestore.
  /// `baseField` es el nombre del campo principal (p.ej. `'nombre'`).
  /// El campo de traducciones se busca en `${baseField}Translations`
  /// (p.ej. `'nombreTranslations'`) como `Map<String, String>`.
  static String resolve(
    Map<String, dynamic> data,
    String baseField,
    Locale locale, {
    String defaultLanguage = 'es',
  }) {
    final base = data[baseField];
    final baseString = base is String ? base : '';

    final translationsRaw = data['${baseField}Translations'];
    if (translationsRaw is! Map) return baseString;

    final translations = translationsRaw.cast<String, dynamic>();
    final code = locale.languageCode;
    final translated = translations[code];
    if (translated is String && translated.isNotEmpty) return translated;

    if (code != defaultLanguage) {
      final fallback = translations[defaultLanguage];
      if (fallback is String && fallback.isNotEmpty) return fallback;
    }

    return baseString;
  }

  /// Construye el sub-mapa que se debe escribir en Firestore para registrar
  /// las traducciones de un campo.
  ///
  /// Útil para el admin cuando introduce traducciones de clases / bonos /
  /// ejercicios. Filtra entradas vacías.
  static Map<String, String> buildTranslationsMap(
    Map<String, String?> input,
  ) {
    final out = <String, String>{};
    for (final entry in input.entries) {
      final value = entry.value?.trim();
      if (value == null || value.isEmpty) continue;
      out[entry.key] = value;
    }
    return out;
  }
}

extension LocalizedFieldExtension on Map<String, dynamic> {
  /// Atajo: `data.localized('nombre', locale)` devuelve el nombre traducido
  /// con fallback al campo español original.
  String localized(String baseField, Locale locale) =>
      LocalizedField.resolve(this, baseField, locale);
}
