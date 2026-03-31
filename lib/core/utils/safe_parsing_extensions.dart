import 'package:cloud_firestore/cloud_firestore.dart';

extension SafeParsing on Map<String, dynamic>? {
  String safeString(String key, {String defaultValue = ''}) {
    if (this == null) return defaultValue;
    final value = this![key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  int safeInt(String key, {int defaultValue = 0}) {
    if (this == null) return defaultValue;
    final value = this![key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  double safeDouble(String key, {double defaultValue = 0.0}) {
    if (this == null) return defaultValue;
    final value = this![key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? defaultValue;
    return defaultValue;
  }

  bool safeBool(String key, {bool defaultValue = false}) {
    if (this == null) return defaultValue;
    final value = this![key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  DateTime safeDateTime(String key, {DateTime? defaultValue}) {
    final def = defaultValue ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (this == null) return def;
    final value = this![key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? def;
    return def;
  }
}
