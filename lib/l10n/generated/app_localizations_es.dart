// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Salufit';

  @override
  String get appSlogan => 'Tu salud en manos PROFESIONALES';

  @override
  String get loginEmailLabel => 'Correo Electrónico';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginInvalidEmail => 'Correo inválido';

  @override
  String get loginEmptyPassword => 'Introduce tu contraseña';

  @override
  String get loginSubmit => 'INICIAR SESIÓN';

  @override
  String get loginFirstTime => 'Primera vez';

  @override
  String get loginForgotPassword => '¿Olvidaste contraseña?';

  @override
  String get loginGenericError =>
      'No se pudo iniciar sesión. Revisa tus credenciales.';

  @override
  String get languagePickerTitle => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonError => 'Error';

  @override
  String get commonLoading => 'Cargando…';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonRequired => 'Campo obligatorio';

  @override
  String get commonNoData => 'Sin datos';

  @override
  String get errorGeneric =>
      'Ha ocurrido un error.\nPor favor, reinicia la aplicación.';

  @override
  String get errorNoConnection => 'Sin conexión a internet';

  @override
  String get errorTryAgain => 'Inténtalo de nuevo';

  @override
  String get logoutConfirmTitle => 'Cerrar sesión';

  @override
  String get logoutConfirmMessage => '¿Seguro que quieres cerrar sesión?';

  @override
  String get logoutAction => 'Cerrar sesión';

  @override
  String get navHome => 'Inicio';

  @override
  String get navClasses => 'Clases';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navDocuments => 'Documentos';

  @override
  String get navMaterial => 'Material';

  @override
  String get navChat => 'Chat';

  @override
  String get navBookings => 'Reservas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String dashboardWelcome(String name) {
    return 'Hola, $name';
  }

  @override
  String get dashboardYourPasses => 'Tus bonos';

  @override
  String get dashboardYourClasses => 'Tus clases';

  @override
  String get dashboardUpcomingClass => 'Próxima clase';

  @override
  String get dashboardNoUpcoming => 'No tienes clases programadas';

  @override
  String get dashboardSeeAll => 'Ver todo';

  @override
  String passesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bonos disponibles',
      one: '1 bono disponible',
      zero: 'Sin bonos',
    );
    return '$_temp0';
  }

  @override
  String passesExpiresOn(String date) {
    return 'Caduca el $date';
  }

  @override
  String get classBookSubmit => 'Reservar plaza';

  @override
  String get classBookSuccess => 'Plaza reservada';

  @override
  String get classBookError => 'No se pudo reservar la plaza';

  @override
  String get classCancelSubmit => 'Cancelar reserva';

  @override
  String get classCancelConfirm => '¿Cancelar tu reserva?';

  @override
  String get classFull => 'Clase completa';

  @override
  String get classMyReservation => 'Tu reserva';

  @override
  String classCapacity(int occupied, int capacity) {
    return '$occupied/$capacity plazas';
  }

  @override
  String get classWaitlist => 'Lista de espera';

  @override
  String get classWaitlistJoin => 'Unirme a la lista de espera';

  @override
  String classWaitlistPosition(int position) {
    return 'Posición en lista: $position';
  }

  @override
  String get profileTitle => 'Mi perfil';

  @override
  String get profileFullName => 'Nombre completo';

  @override
  String get profilePhone => 'Teléfono';

  @override
  String get profileBirthdate => 'Fecha de nacimiento';

  @override
  String get profileGender => 'Género';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileSaved => 'Perfil guardado';

  @override
  String get profileLanguage => 'Idioma de la aplicación';

  @override
  String get documentsTitle => 'Documentos';

  @override
  String get documentsEmpty => 'No tienes documentos disponibles';

  @override
  String get documentsView => 'Ver documento';

  @override
  String get documentsSign => 'Firmar';

  @override
  String get documentsSigned => 'Firmado';

  @override
  String get materialTitle => 'Material';

  @override
  String get materialEmpty => 'No tienes material asignado';

  @override
  String get materialView => 'Ver material';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatEmpty => 'No tienes conversaciones activas';

  @override
  String get chatTypeMessage => 'Escribe un mensaje…';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatNew => 'Nueva conversación';

  @override
  String get chatYou => 'Tú';

  @override
  String get termsTitle => 'Términos y condiciones';

  @override
  String get termsAcceptButton => 'Acepto los términos';

  @override
  String get termsReadFirst =>
      'Debes leer y aceptar los términos para continuar';

  @override
  String get privacyTitle => 'Política de privacidad';

  @override
  String get privacyAcceptButton => 'Acepto la política de privacidad';

  @override
  String get activationTitle => 'Activar cuenta';

  @override
  String get activationCodePrompt =>
      'Introduce el código de activación que te hemos enviado';

  @override
  String get activationCodeLabel => 'Código';

  @override
  String get activationSubmit => 'Activar';

  @override
  String get activationInvalidCode => 'Código no válido';

  @override
  String get activationSendAgain => 'Reenviar código';

  @override
  String get activationFirstTime => 'Es mi primera vez en Salufit';

  @override
  String get forgotTitle => 'Recuperar contraseña';

  @override
  String get forgotInstructions =>
      'Introduce tu correo y te enviaremos un enlace para restablecer la contraseña';

  @override
  String get forgotSubmit => 'Enviar enlace';

  @override
  String get forgotSuccess =>
      'Te hemos enviado un correo. Revisa tu bandeja de entrada.';

  @override
  String get forgotErrorEmail => 'Comprueba el correo introducido';

  @override
  String get passwordMigrationTitle => 'Establece una contraseña nueva';

  @override
  String get passwordMigrationMessage =>
      'Por seguridad, te pedimos crear una nueva contraseña.';

  @override
  String get passwordMigrationLabel => 'Nueva contraseña';

  @override
  String get passwordMigrationConfirm => 'Confirmar contraseña';

  @override
  String get passwordMigrationMismatch => 'Las contraseñas no coinciden';

  @override
  String get passwordMigrationMinLength => 'Debe tener al menos 8 caracteres';

  @override
  String get passwordMigrationSubmit => 'Guardar contraseña';

  @override
  String get consentGranularTitle => 'Tus preferencias de privacidad';

  @override
  String get consentMarketing => 'Comunicaciones comerciales';

  @override
  String get consentAnalytics => 'Mejora del servicio (analítica)';

  @override
  String get consentMedical => 'Tratamiento de datos clínicos';

  @override
  String get consentSubmit => 'Guardar preferencias';

  @override
  String get birthDateDialogTitle => 'Fecha de nacimiento';

  @override
  String get birthDateDialogPrompt =>
      'Confirma tu fecha de nacimiento para continuar';

  @override
  String get birthDateDialogSubmit => 'Confirmar';

  @override
  String get updateRequiredTitle => 'Actualización necesaria';

  @override
  String get updateRequiredMessage =>
      'Hay una nueva versión disponible. Por favor, actualiza la app para continuar.';

  @override
  String get updateRequiredAction => 'Actualizar';

  @override
  String get qrWalkInTitle => 'Acceso por QR';

  @override
  String get qrWalkInPrompt =>
      'Escanea el código QR del centro para registrar tu entrada';

  @override
  String get qrWalkInSuccess => 'Acceso registrado';

  @override
  String get scheduleEmpty => 'No hay clases en este día';

  @override
  String get scheduleToday => 'Hoy';

  @override
  String get scheduleTomorrow => 'Mañana';

  @override
  String get scheduleYesterday => 'Ayer';

  @override
  String get errorPassesEmpty => 'No tienes bonos disponibles para esta clase';

  @override
  String get errorClassFull => 'La clase está completa';

  @override
  String get errorAlreadyBooked => 'Ya tienes una reserva en esta clase';

  @override
  String get errorBookingClosed =>
      'Las reservas para esta clase están cerradas';

  @override
  String get appOfflineBanner =>
      'Sin conexión. Algunos datos pueden no estar actualizados.';

  @override
  String get syncingData => 'Sincronizando datos…';

  @override
  String get commonGotIt => 'Entendido';

  @override
  String get commonAccept => 'Aceptar';

  @override
  String get commonDecline => 'Rechazar';

  @override
  String get commonGoBack => 'Volver';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get activationLinkPrompt =>
      'Introduce tus datos para vincular tu ficha médica con la App.';

  @override
  String get activationHistoryNumber => 'Nº Historia';

  @override
  String get activationVerifyIdentity => 'VERIFICAR MI IDENTIDAD';

  @override
  String get activationVerifiedTitle => '¡Identidad verificada!';

  @override
  String activationVerifiedMessage(String email) {
    return 'Hemos enviado un enlace a $email para crear tu contraseña.';
  }

  @override
  String get activationServerError => 'Error de comunicación con el servidor.';

  @override
  String get activationDataMismatch =>
      'Los datos no coinciden con nuestra base de datos.';

  @override
  String get activationAlreadyRegisteredTitle => 'Ya estás registrado';

  @override
  String get activationAlreadyRegisteredMessage =>
      'Esta ficha ya tiene una cuenta activa. Si has olvidado la contraseña, te enviaremos un enlace para recuperarla.';

  @override
  String get activationAlreadyRegisteredAction => 'Enviar enlace';

  @override
  String get termsAcceptanceTitle => 'Términos y privacidad';

  @override
  String get termsAcceptancePrompt =>
      'Para continuar, lee y acepta los siguientes documentos:';

  @override
  String get termsAcceptanceTerms =>
      'He leído y acepto los Términos y Condiciones';

  @override
  String get termsAcceptancePrivacy =>
      'He leído y acepto la Política de Privacidad';

  @override
  String get termsAcceptanceContinue => 'Continuar';

  @override
  String get termsAcceptanceRequired =>
      'Debes aceptar ambos documentos para continuar';

  @override
  String get termsViewLink => 'Ver documento';

  @override
  String get consentMarketingDescription =>
      'Recibir información comercial y promociones del centro.';

  @override
  String get consentAnalyticsDescription =>
      'Permitir analíticas anónimas para mejorar la app.';

  @override
  String get consentMedicalDescription =>
      'Tratamiento de tus datos clínicos según RGPD/HIPAA.';

  @override
  String get consentRequiredMedical =>
      'El tratamiento de datos clínicos es necesario para usar el servicio.';

  @override
  String get updateRequiredAppStore => 'Abrir App Store';

  @override
  String get updateRequiredPlayStore => 'Abrir Play Store';

  @override
  String get permissionDeniedTitle => 'Permiso denegado';

  @override
  String get permissionDeniedMessage =>
      'Concede el permiso desde los ajustes del sistema para continuar.';

  @override
  String get permissionOpenSettings => 'Abrir ajustes';

  @override
  String homeWelcome(String name) {
    return 'Bienvenido/a, $name';
  }

  @override
  String get homeFitTrack => 'Tu seguimiento';

  @override
  String get homeQuickActions => 'Acciones rápidas';

  @override
  String get homeBookClass => 'Reservar clase';

  @override
  String get homeMyDocuments => 'Mis documentos';

  @override
  String get homeMyMaterial => 'Mi material';

  @override
  String get homeContactPro => 'Contactar con mi profesional';

  @override
  String get classListTitle => 'Clases del centro';

  @override
  String get classListEmptyDay => 'No hay clases programadas';

  @override
  String get classListLoading => 'Cargando clases…';

  @override
  String classDetailsDuration(int minutes) {
    return 'Duración: $minutes min';
  }

  @override
  String classDetailsCoach(String name) {
    return 'Profesional: $name';
  }

  @override
  String classDetailsLocation(String room) {
    return 'Sala: $room';
  }

  @override
  String classDetailsTime(String time) {
    return 'Horario: $time';
  }

  @override
  String get tokenSyncing => 'Actualizando bonos…';

  @override
  String get tokenError => 'No se pudieron cargar tus bonos';

  @override
  String get documentsSignPrompt => 'Necesitamos tu firma para este documento';

  @override
  String get documentsSignSuccess => 'Documento firmado correctamente';

  @override
  String get qrAccessTitle => 'Acceso por QR';

  @override
  String get qrAccessRetry => 'Volver a escanear';

  @override
  String get chatNoMessages => 'Aún no hay mensajes';

  @override
  String get chatComposeHint => 'Escribe tu mensaje…';

  @override
  String get chatSendError => 'No se pudo enviar el mensaje';

  @override
  String get chatProfessional => 'Profesional';

  @override
  String get chatStaff => 'Equipo Salufit';

  @override
  String get profileLogoutAction => 'Cerrar sesión';

  @override
  String get profileSection => 'Sección';

  @override
  String get profileSectionAccount => 'Cuenta';

  @override
  String get profileSectionApp => 'Aplicación';

  @override
  String get profileSectionPrivacy => 'Privacidad y datos';

  @override
  String get profileVersionLabel => 'Versión';

  @override
  String get settingsLanguageSubtitle =>
      'Selecciona el idioma de la aplicación';

  @override
  String get settingsLanguageChanged => 'Idioma actualizado';

  @override
  String get validationFieldRequired => 'Este campo es obligatorio';

  @override
  String get validationEmailInvalid => 'Correo electrónico no válido';

  @override
  String get validationPasswordWeak =>
      'La contraseña no es lo suficientemente segura';
}
