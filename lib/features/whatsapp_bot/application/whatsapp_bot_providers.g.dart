// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whatsapp_bot_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream con las conversaciones más recientes del bot, ordenadas por
/// la última interacción (descendente). Limit 100 para no saturar la UI.

@ProviderFor(whatsappConversations)
const whatsappConversationsProvider = WhatsappConversationsProvider._();

/// Stream con las conversaciones más recientes del bot, ordenadas por
/// la última interacción (descendente). Limit 100 para no saturar la UI.

final class WhatsappConversationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WhatsAppConversation>>,
          List<WhatsAppConversation>,
          Stream<List<WhatsAppConversation>>
        >
    with
        $FutureModifier<List<WhatsAppConversation>>,
        $StreamProvider<List<WhatsAppConversation>> {
  /// Stream con las conversaciones más recientes del bot, ordenadas por
  /// la última interacción (descendente). Limit 100 para no saturar la UI.
  const WhatsappConversationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'whatsappConversationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whatsappConversationsHash();

  @$internal
  @override
  $StreamProviderElement<List<WhatsAppConversation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WhatsAppConversation>> create(Ref ref) {
    return whatsappConversations(ref);
  }
}

String _$whatsappConversationsHash() =>
    r'48c4201b9d8dfd4344d052d88b594081a08a3dc0';

/// Citas activas (futuras o de hoy) en `clinni_appointments`,
/// ordenadas por fecha ascendente. Limit 200.

@ProviderFor(upcomingAppointments)
const upcomingAppointmentsProvider = UpcomingAppointmentsProvider._();

/// Citas activas (futuras o de hoy) en `clinni_appointments`,
/// ordenadas por fecha ascendente. Limit 200.

final class UpcomingAppointmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClinniAppointment>>,
          List<ClinniAppointment>,
          Stream<List<ClinniAppointment>>
        >
    with
        $FutureModifier<List<ClinniAppointment>>,
        $StreamProvider<List<ClinniAppointment>> {
  /// Citas activas (futuras o de hoy) en `clinni_appointments`,
  /// ordenadas por fecha ascendente. Limit 200.
  const UpcomingAppointmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingAppointmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingAppointmentsHash();

  @$internal
  @override
  $StreamProviderElement<List<ClinniAppointment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ClinniAppointment>> create(Ref ref) {
    return upcomingAppointments(ref);
  }
}

String _$upcomingAppointmentsHash() =>
    r'3d0496db9a9e3ebce9202a72d199594af63ea917';

/// Configuración del bot (`config/whatsapp_bot`). Si no existe, devuelve null.

@ProviderFor(botConfig)
const botConfigProvider = BotConfigProvider._();

/// Configuración del bot (`config/whatsapp_bot`). Si no existe, devuelve null.

final class BotConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          Stream<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $StreamProvider<Map<String, dynamic>?> {
  /// Configuración del bot (`config/whatsapp_bot`). Si no existe, devuelve null.
  const BotConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'botConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$botConfigHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>?> create(Ref ref) {
    return botConfig(ref);
  }
}

String _$botConfigHash() => r'52ef664b9d846cf9a425c03f3daf60fbb15f1a3a';

/// Llama a la Cloud Function `importClinniAppointments` (onRequest) con el
/// contenido del Excel codificado en base64. Usa http POST con Firebase Auth
/// ID token en header Authorization Bearer (cloud_functions plugin no
/// soporta Windows desktop).

@ProviderFor(importClinniExcel)
const importClinniExcelProvider = ImportClinniExcelFamily._();

/// Llama a la Cloud Function `importClinniAppointments` (onRequest) con el
/// contenido del Excel codificado en base64. Usa http POST con Firebase Auth
/// ID token en header Authorization Bearer (cloud_functions plugin no
/// soporta Windows desktop).

final class ImportClinniExcelProvider
    extends
        $FunctionalProvider<
          AsyncValue<ImportResult>,
          ImportResult,
          FutureOr<ImportResult>
        >
    with $FutureModifier<ImportResult>, $FutureProvider<ImportResult> {
  /// Llama a la Cloud Function `importClinniAppointments` (onRequest) con el
  /// contenido del Excel codificado en base64. Usa http POST con Firebase Auth
  /// ID token en header Authorization Bearer (cloud_functions plugin no
  /// soporta Windows desktop).
  const ImportClinniExcelProvider._({
    required ImportClinniExcelFamily super.from,
    required ({String fileBase64, String fileName}) super.argument,
  }) : super(
         retry: null,
         name: r'importClinniExcelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$importClinniExcelHash();

  @override
  String toString() {
    return r'importClinniExcelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ImportResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ImportResult> create(Ref ref) {
    final argument = this.argument as ({String fileBase64, String fileName});
    return importClinniExcel(
      ref,
      fileBase64: argument.fileBase64,
      fileName: argument.fileName,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ImportClinniExcelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$importClinniExcelHash() => r'3c6726f42822baed611e66d7f203339018cc4790';

/// Llama a la Cloud Function `importClinniAppointments` (onRequest) con el
/// contenido del Excel codificado en base64. Usa http POST con Firebase Auth
/// ID token en header Authorization Bearer (cloud_functions plugin no
/// soporta Windows desktop).

final class ImportClinniExcelFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ImportResult>,
          ({String fileBase64, String fileName})
        > {
  const ImportClinniExcelFamily._()
    : super(
        retry: null,
        name: r'importClinniExcelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Llama a la Cloud Function `importClinniAppointments` (onRequest) con el
  /// contenido del Excel codificado en base64. Usa http POST con Firebase Auth
  /// ID token en header Authorization Bearer (cloud_functions plugin no
  /// soporta Windows desktop).

  ImportClinniExcelProvider call({
    required String fileBase64,
    required String fileName,
  }) => ImportClinniExcelProvider._(
    argument: (fileBase64: fileBase64, fileName: fileName),
    from: this,
  );

  @override
  String toString() => r'importClinniExcelProvider';
}

/// Llama a la Cloud Function `importClinniPatients` (onRequest) con el
/// contenido del Excel `listado_v26.xlsx` codificado en base64.

@ProviderFor(importClinniPatientsExcel)
const importClinniPatientsExcelProvider = ImportClinniPatientsExcelFamily._();

/// Llama a la Cloud Function `importClinniPatients` (onRequest) con el
/// contenido del Excel `listado_v26.xlsx` codificado en base64.

final class ImportClinniPatientsExcelProvider
    extends
        $FunctionalProvider<
          AsyncValue<ImportPatientsResult>,
          ImportPatientsResult,
          FutureOr<ImportPatientsResult>
        >
    with
        $FutureModifier<ImportPatientsResult>,
        $FutureProvider<ImportPatientsResult> {
  /// Llama a la Cloud Function `importClinniPatients` (onRequest) con el
  /// contenido del Excel `listado_v26.xlsx` codificado en base64.
  const ImportClinniPatientsExcelProvider._({
    required ImportClinniPatientsExcelFamily super.from,
    required ({String fileBase64, String fileName}) super.argument,
  }) : super(
         retry: null,
         name: r'importClinniPatientsExcelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$importClinniPatientsExcelHash();

  @override
  String toString() {
    return r'importClinniPatientsExcelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ImportPatientsResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ImportPatientsResult> create(Ref ref) {
    final argument = this.argument as ({String fileBase64, String fileName});
    return importClinniPatientsExcel(
      ref,
      fileBase64: argument.fileBase64,
      fileName: argument.fileName,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ImportClinniPatientsExcelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$importClinniPatientsExcelHash() =>
    r'725e2e94054fbb97e67411042eab91f7bf2919d4';

/// Llama a la Cloud Function `importClinniPatients` (onRequest) con el
/// contenido del Excel `listado_v26.xlsx` codificado en base64.

final class ImportClinniPatientsExcelFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ImportPatientsResult>,
          ({String fileBase64, String fileName})
        > {
  const ImportClinniPatientsExcelFamily._()
    : super(
        retry: null,
        name: r'importClinniPatientsExcelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Llama a la Cloud Function `importClinniPatients` (onRequest) con el
  /// contenido del Excel `listado_v26.xlsx` codificado en base64.

  ImportClinniPatientsExcelProvider call({
    required String fileBase64,
    required String fileName,
  }) => ImportClinniPatientsExcelProvider._(
    argument: (fileBase64: fileBase64, fileName: fileName),
    from: this,
  );

  @override
  String toString() => r'importClinniPatientsExcelProvider';
}
