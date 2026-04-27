import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

const List<Locale> kSupportedLocales = [
  Locale('es'),
  Locale('en'),
  Locale('fr'),
  Locale('de'),
  Locale('nl'),
];

const Locale kFallbackLocale = Locale('es');
const String kLocalePrefsKey = 'app_locale';

bool _isSupported(String code) =>
    kSupportedLocales.any((l) => l.languageCode == code);

Locale resolveInitialLocale(String? savedCode) {
  if (savedCode != null && _isSupported(savedCode)) {
    return Locale(savedCode);
  }
  final deviceCode = PlatformDispatcher.instance.locale.languageCode;
  if (_isSupported(deviceCode)) {
    return Locale(deviceCode);
  }
  return kFallbackLocale;
}

@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  Locale build() => kFallbackLocale;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(kLocalePrefsKey);
      state = resolveInitialLocale(saved);
    } catch (e) {
      debugPrint('LocaleController init error: $e');
      state = resolveInitialLocale(null);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) return;
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kLocalePrefsKey, locale.languageCode);
    } catch (e) {
      debugPrint('LocaleController save error: $e');
    }
  }
}
