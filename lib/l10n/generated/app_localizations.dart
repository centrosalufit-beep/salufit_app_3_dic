import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
    Locale('fr'),
    Locale('de'),
    Locale('nl'),
  ];

  /// Application title
  ///
  /// In es, this message translates to:
  /// **'Salufit'**
  String get appTitle;

  /// Login screen slogan
  ///
  /// In es, this message translates to:
  /// **'Tu salud en manos PROFESIONALES'**
  String get appSlogan;

  /// No description provided for @loginEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo Electrónico'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPasswordLabel;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo inválido'**
  String get loginInvalidEmail;

  /// No description provided for @loginEmptyPassword.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get loginEmptyPassword;

  /// No description provided for @loginSubmit.
  ///
  /// In es, this message translates to:
  /// **'INICIAR SESIÓN'**
  String get loginSubmit;

  /// No description provided for @loginFirstTime.
  ///
  /// In es, this message translates to:
  /// **'Primera vez'**
  String get loginFirstTime;

  /// No description provided for @loginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste contraseña?'**
  String get loginForgotPassword;

  /// No description provided for @loginGenericError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión. Revisa tus credenciales.'**
  String get loginGenericError;

  /// No description provided for @languagePickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languagePickerTitle;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In es, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In es, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageDutch.
  ///
  /// In es, this message translates to:
  /// **'Nederlands'**
  String get languageDutch;

  /// No description provided for @commonOk.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonError.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get commonLoading;

  /// No description provided for @commonYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get commonBack;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get commonAdd;

  /// No description provided for @commonSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get commonSearch;

  /// No description provided for @commonRequired.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get commonRequired;

  /// No description provided for @commonNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get commonNoData;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error.\nPor favor, reinicia la aplicación.'**
  String get errorGeneric;

  /// No description provided for @errorNoConnection.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet'**
  String get errorNoConnection;

  /// No description provided for @errorTryAgain.
  ///
  /// In es, this message translates to:
  /// **'Inténtalo de nuevo'**
  String get errorTryAgain;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres cerrar sesión?'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutAction.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutAction;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navClasses.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get navClasses;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get navDocuments;

  /// No description provided for @navMaterial.
  ///
  /// In es, this message translates to:
  /// **'Material'**
  String get navMaterial;

  /// No description provided for @navChat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navBookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get navBookings;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @dashboardWelcome.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String dashboardWelcome(String name);

  /// No description provided for @dashboardYourPasses.
  ///
  /// In es, this message translates to:
  /// **'Tus bonos'**
  String get dashboardYourPasses;

  /// No description provided for @dashboardYourClasses.
  ///
  /// In es, this message translates to:
  /// **'Tus clases'**
  String get dashboardYourClasses;

  /// No description provided for @dashboardUpcomingClass.
  ///
  /// In es, this message translates to:
  /// **'Próxima clase'**
  String get dashboardUpcomingClass;

  /// No description provided for @dashboardNoUpcoming.
  ///
  /// In es, this message translates to:
  /// **'No tienes clases programadas'**
  String get dashboardNoUpcoming;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get dashboardSeeAll;

  /// No description provided for @passesAvailable.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin bonos} =1{1 bono disponible} other{{count} bonos disponibles}}'**
  String passesAvailable(int count);

  /// No description provided for @passesExpiresOn.
  ///
  /// In es, this message translates to:
  /// **'Caduca el {date}'**
  String passesExpiresOn(String date);

  /// No description provided for @classBookSubmit.
  ///
  /// In es, this message translates to:
  /// **'Reservar plaza'**
  String get classBookSubmit;

  /// No description provided for @classBookSuccess.
  ///
  /// In es, this message translates to:
  /// **'Plaza reservada'**
  String get classBookSuccess;

  /// No description provided for @classBookError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reservar la plaza'**
  String get classBookError;

  /// No description provided for @classCancelSubmit.
  ///
  /// In es, this message translates to:
  /// **'Cancelar reserva'**
  String get classCancelSubmit;

  /// No description provided for @classCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar tu reserva?'**
  String get classCancelConfirm;

  /// No description provided for @classFull.
  ///
  /// In es, this message translates to:
  /// **'Clase completa'**
  String get classFull;

  /// No description provided for @classMyReservation.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva'**
  String get classMyReservation;

  /// No description provided for @classCapacity.
  ///
  /// In es, this message translates to:
  /// **'{occupied}/{capacity} plazas'**
  String classCapacity(int occupied, int capacity);

  /// No description provided for @classWaitlist.
  ///
  /// In es, this message translates to:
  /// **'Lista de espera'**
  String get classWaitlist;

  /// No description provided for @classWaitlistJoin.
  ///
  /// In es, this message translates to:
  /// **'Unirme a la lista de espera'**
  String get classWaitlistJoin;

  /// No description provided for @classWaitlistPosition.
  ///
  /// In es, this message translates to:
  /// **'Posición en lista: {position}'**
  String classWaitlistPosition(int position);

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get profileTitle;

  /// No description provided for @profileFullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get profileFullName;

  /// No description provided for @profilePhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get profilePhone;

  /// No description provided for @profileBirthdate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get profileBirthdate;

  /// No description provided for @profileGender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get profileGender;

  /// No description provided for @profileEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEditTitle;

  /// No description provided for @profileSaved.
  ///
  /// In es, this message translates to:
  /// **'Perfil guardado'**
  String get profileSaved;

  /// No description provided for @profileLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la aplicación'**
  String get profileLanguage;

  /// No description provided for @documentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get documentsTitle;

  /// No description provided for @documentsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes documentos disponibles'**
  String get documentsEmpty;

  /// No description provided for @documentsView.
  ///
  /// In es, this message translates to:
  /// **'Ver documento'**
  String get documentsView;

  /// No description provided for @documentsSign.
  ///
  /// In es, this message translates to:
  /// **'Firmar'**
  String get documentsSign;

  /// No description provided for @documentsSigned.
  ///
  /// In es, this message translates to:
  /// **'Firmado'**
  String get documentsSigned;

  /// No description provided for @materialTitle.
  ///
  /// In es, this message translates to:
  /// **'Material'**
  String get materialTitle;

  /// No description provided for @materialEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes material asignado'**
  String get materialEmpty;

  /// No description provided for @materialView.
  ///
  /// In es, this message translates to:
  /// **'Ver material'**
  String get materialView;

  /// No description provided for @chatTitle.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes conversaciones activas'**
  String get chatEmpty;

  /// No description provided for @chatTypeMessage.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje…'**
  String get chatTypeMessage;

  /// No description provided for @chatSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get chatSend;

  /// No description provided for @chatNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva conversación'**
  String get chatNew;

  /// No description provided for @chatYou.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get chatYou;

  /// No description provided for @termsTitle.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get termsTitle;

  /// No description provided for @termsAcceptButton.
  ///
  /// In es, this message translates to:
  /// **'Acepto los términos'**
  String get termsAcceptButton;

  /// No description provided for @termsReadFirst.
  ///
  /// In es, this message translates to:
  /// **'Debes leer y aceptar los términos para continuar'**
  String get termsReadFirst;

  /// No description provided for @privacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get privacyTitle;

  /// No description provided for @privacyAcceptButton.
  ///
  /// In es, this message translates to:
  /// **'Acepto la política de privacidad'**
  String get privacyAcceptButton;

  /// No description provided for @activationTitle.
  ///
  /// In es, this message translates to:
  /// **'Activar cuenta'**
  String get activationTitle;

  /// No description provided for @activationCodePrompt.
  ///
  /// In es, this message translates to:
  /// **'Introduce el código de activación que te hemos enviado'**
  String get activationCodePrompt;

  /// No description provided for @activationCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get activationCodeLabel;

  /// No description provided for @activationSubmit.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get activationSubmit;

  /// No description provided for @activationInvalidCode.
  ///
  /// In es, this message translates to:
  /// **'Código no válido'**
  String get activationInvalidCode;

  /// No description provided for @activationSendAgain.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get activationSendAgain;

  /// No description provided for @activationFirstTime.
  ///
  /// In es, this message translates to:
  /// **'Es mi primera vez en Salufit'**
  String get activationFirstTime;

  /// No description provided for @forgotTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get forgotTitle;

  /// No description provided for @forgotInstructions.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu correo y te enviaremos un enlace para restablecer la contraseña'**
  String get forgotInstructions;

  /// No description provided for @forgotSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get forgotSubmit;

  /// No description provided for @forgotSuccess.
  ///
  /// In es, this message translates to:
  /// **'Te hemos enviado un correo. Revisa tu bandeja de entrada.'**
  String get forgotSuccess;

  /// No description provided for @forgotErrorEmail.
  ///
  /// In es, this message translates to:
  /// **'Comprueba el correo introducido'**
  String get forgotErrorEmail;

  /// No description provided for @passwordMigrationTitle.
  ///
  /// In es, this message translates to:
  /// **'Establece una contraseña nueva'**
  String get passwordMigrationTitle;

  /// No description provided for @passwordMigrationMessage.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, te pedimos crear una nueva contraseña.'**
  String get passwordMigrationMessage;

  /// No description provided for @passwordMigrationLabel.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get passwordMigrationLabel;

  /// No description provided for @passwordMigrationConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get passwordMigrationConfirm;

  /// No description provided for @passwordMigrationMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordMigrationMismatch;

  /// No description provided for @passwordMigrationMinLength.
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos 8 caracteres'**
  String get passwordMigrationMinLength;

  /// No description provided for @passwordMigrationSubmit.
  ///
  /// In es, this message translates to:
  /// **'Guardar contraseña'**
  String get passwordMigrationSubmit;

  /// No description provided for @consentGranularTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus preferencias de privacidad'**
  String get consentGranularTitle;

  /// No description provided for @consentMarketing.
  ///
  /// In es, this message translates to:
  /// **'Comunicaciones comerciales'**
  String get consentMarketing;

  /// No description provided for @consentAnalytics.
  ///
  /// In es, this message translates to:
  /// **'Mejora del servicio (analítica)'**
  String get consentAnalytics;

  /// No description provided for @consentMedical.
  ///
  /// In es, this message translates to:
  /// **'Tratamiento de datos clínicos'**
  String get consentMedical;

  /// No description provided for @consentSubmit.
  ///
  /// In es, this message translates to:
  /// **'Guardar preferencias'**
  String get consentSubmit;

  /// No description provided for @birthDateDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get birthDateDialogTitle;

  /// No description provided for @birthDateDialogPrompt.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu fecha de nacimiento para continuar'**
  String get birthDateDialogPrompt;

  /// No description provided for @birthDateDialogSubmit.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get birthDateDialogSubmit;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualización necesaria'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In es, this message translates to:
  /// **'Hay una nueva versión disponible. Por favor, actualiza la app para continuar.'**
  String get updateRequiredMessage;

  /// No description provided for @updateRequiredAction.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get updateRequiredAction;

  /// No description provided for @qrWalkInTitle.
  ///
  /// In es, this message translates to:
  /// **'Acceso por QR'**
  String get qrWalkInTitle;

  /// No description provided for @qrWalkInPrompt.
  ///
  /// In es, this message translates to:
  /// **'Escanea el código QR del centro para registrar tu entrada'**
  String get qrWalkInPrompt;

  /// No description provided for @qrWalkInSuccess.
  ///
  /// In es, this message translates to:
  /// **'Acceso registrado'**
  String get qrWalkInSuccess;

  /// No description provided for @scheduleEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay clases en este día'**
  String get scheduleEmpty;

  /// No description provided for @scheduleToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get scheduleToday;

  /// No description provided for @scheduleTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get scheduleTomorrow;

  /// No description provided for @scheduleYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get scheduleYesterday;

  /// No description provided for @errorPassesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes bonos disponibles para esta clase'**
  String get errorPassesEmpty;

  /// No description provided for @errorClassFull.
  ///
  /// In es, this message translates to:
  /// **'La clase está completa'**
  String get errorClassFull;

  /// No description provided for @errorAlreadyBooked.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes una reserva en esta clase'**
  String get errorAlreadyBooked;

  /// No description provided for @errorBookingClosed.
  ///
  /// In es, this message translates to:
  /// **'Las reservas para esta clase están cerradas'**
  String get errorBookingClosed;

  /// No description provided for @appOfflineBanner.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Algunos datos pueden no estar actualizados.'**
  String get appOfflineBanner;

  /// No description provided for @syncingData.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando datos…'**
  String get syncingData;

  /// No description provided for @commonGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get commonGotIt;

  /// No description provided for @commonAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get commonAccept;

  /// No description provided for @commonDecline.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get commonDecline;

  /// No description provided for @commonGoBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonGoBack;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @activationLinkPrompt.
  ///
  /// In es, this message translates to:
  /// **'Introduce tus datos para vincular tu ficha médica con la App.'**
  String get activationLinkPrompt;

  /// No description provided for @activationHistoryNumber.
  ///
  /// In es, this message translates to:
  /// **'Nº Historia'**
  String get activationHistoryNumber;

  /// No description provided for @activationVerifyIdentity.
  ///
  /// In es, this message translates to:
  /// **'VERIFICAR MI IDENTIDAD'**
  String get activationVerifyIdentity;

  /// No description provided for @activationVerifiedTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Identidad verificada!'**
  String get activationVerifiedTitle;

  /// No description provided for @activationVerifiedMessage.
  ///
  /// In es, this message translates to:
  /// **'Hemos enviado un enlace a {email} para crear tu contraseña.'**
  String activationVerifiedMessage(String email);

  /// No description provided for @activationServerError.
  ///
  /// In es, this message translates to:
  /// **'Error de comunicación con el servidor.'**
  String get activationServerError;

  /// No description provided for @activationDataMismatch.
  ///
  /// In es, this message translates to:
  /// **'Los datos no coinciden con nuestra base de datos.'**
  String get activationDataMismatch;

  /// No description provided for @activationAlreadyRegisteredTitle.
  ///
  /// In es, this message translates to:
  /// **'Ya estás registrado'**
  String get activationAlreadyRegisteredTitle;

  /// No description provided for @activationAlreadyRegisteredMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta ficha ya tiene una cuenta activa. Si has olvidado la contraseña, te enviaremos un enlace para recuperarla.'**
  String get activationAlreadyRegisteredMessage;

  /// No description provided for @activationAlreadyRegisteredAction.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get activationAlreadyRegisteredAction;

  /// No description provided for @termsAcceptanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Términos y privacidad'**
  String get termsAcceptanceTitle;

  /// No description provided for @termsAcceptancePrompt.
  ///
  /// In es, this message translates to:
  /// **'Para continuar, lee y acepta los siguientes documentos:'**
  String get termsAcceptancePrompt;

  /// No description provided for @termsAcceptanceTerms.
  ///
  /// In es, this message translates to:
  /// **'He leído y acepto los Términos y Condiciones'**
  String get termsAcceptanceTerms;

  /// No description provided for @termsAcceptancePrivacy.
  ///
  /// In es, this message translates to:
  /// **'He leído y acepto la Política de Privacidad'**
  String get termsAcceptancePrivacy;

  /// No description provided for @termsAcceptanceContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get termsAcceptanceContinue;

  /// No description provided for @termsAcceptanceRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptar ambos documentos para continuar'**
  String get termsAcceptanceRequired;

  /// No description provided for @termsViewLink.
  ///
  /// In es, this message translates to:
  /// **'Ver documento'**
  String get termsViewLink;

  /// No description provided for @consentMarketingDescription.
  ///
  /// In es, this message translates to:
  /// **'Recibir información comercial y promociones del centro.'**
  String get consentMarketingDescription;

  /// No description provided for @consentAnalyticsDescription.
  ///
  /// In es, this message translates to:
  /// **'Permitir analíticas anónimas para mejorar la app.'**
  String get consentAnalyticsDescription;

  /// No description provided for @consentMedicalDescription.
  ///
  /// In es, this message translates to:
  /// **'Tratamiento de tus datos clínicos según RGPD/HIPAA.'**
  String get consentMedicalDescription;

  /// No description provided for @consentRequiredMedical.
  ///
  /// In es, this message translates to:
  /// **'El tratamiento de datos clínicos es necesario para usar el servicio.'**
  String get consentRequiredMedical;

  /// No description provided for @updateRequiredAppStore.
  ///
  /// In es, this message translates to:
  /// **'Abrir App Store'**
  String get updateRequiredAppStore;

  /// No description provided for @updateRequiredPlayStore.
  ///
  /// In es, this message translates to:
  /// **'Abrir Play Store'**
  String get updateRequiredPlayStore;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In es, this message translates to:
  /// **'Permiso denegado'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In es, this message translates to:
  /// **'Concede el permiso desde los ajustes del sistema para continuar.'**
  String get permissionDeniedMessage;

  /// No description provided for @permissionOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get permissionOpenSettings;

  /// No description provided for @homeWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido/a, {name}'**
  String homeWelcome(String name);

  /// No description provided for @homeFitTrack.
  ///
  /// In es, this message translates to:
  /// **'Tu seguimiento'**
  String get homeFitTrack;

  /// No description provided for @homeQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get homeQuickActions;

  /// No description provided for @homeBookClass.
  ///
  /// In es, this message translates to:
  /// **'Reservar clase'**
  String get homeBookClass;

  /// No description provided for @homeMyDocuments.
  ///
  /// In es, this message translates to:
  /// **'Mis documentos'**
  String get homeMyDocuments;

  /// No description provided for @homeMyMaterial.
  ///
  /// In es, this message translates to:
  /// **'Mi material'**
  String get homeMyMaterial;

  /// No description provided for @homeContactPro.
  ///
  /// In es, this message translates to:
  /// **'Contactar con mi profesional'**
  String get homeContactPro;

  /// No description provided for @classListTitle.
  ///
  /// In es, this message translates to:
  /// **'Clases del centro'**
  String get classListTitle;

  /// No description provided for @classListEmptyDay.
  ///
  /// In es, this message translates to:
  /// **'No hay clases programadas'**
  String get classListEmptyDay;

  /// No description provided for @classListLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando clases…'**
  String get classListLoading;

  /// No description provided for @classDetailsDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración: {minutes} min'**
  String classDetailsDuration(int minutes);

  /// No description provided for @classDetailsCoach.
  ///
  /// In es, this message translates to:
  /// **'Profesional: {name}'**
  String classDetailsCoach(String name);

  /// No description provided for @classDetailsLocation.
  ///
  /// In es, this message translates to:
  /// **'Sala: {room}'**
  String classDetailsLocation(String room);

  /// No description provided for @classDetailsTime.
  ///
  /// In es, this message translates to:
  /// **'Horario: {time}'**
  String classDetailsTime(String time);

  /// No description provided for @tokenSyncing.
  ///
  /// In es, this message translates to:
  /// **'Actualizando bonos…'**
  String get tokenSyncing;

  /// No description provided for @tokenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus bonos'**
  String get tokenError;

  /// No description provided for @documentsSignPrompt.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos tu firma para este documento'**
  String get documentsSignPrompt;

  /// No description provided for @documentsSignSuccess.
  ///
  /// In es, this message translates to:
  /// **'Documento firmado correctamente'**
  String get documentsSignSuccess;

  /// No description provided for @qrAccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Acceso por QR'**
  String get qrAccessTitle;

  /// No description provided for @qrAccessRetry.
  ///
  /// In es, this message translates to:
  /// **'Volver a escanear'**
  String get qrAccessRetry;

  /// No description provided for @chatNoMessages.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay mensajes'**
  String get chatNoMessages;

  /// No description provided for @chatComposeHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu mensaje…'**
  String get chatComposeHint;

  /// No description provided for @chatSendError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el mensaje'**
  String get chatSendError;

  /// No description provided for @chatProfessional.
  ///
  /// In es, this message translates to:
  /// **'Profesional'**
  String get chatProfessional;

  /// No description provided for @chatStaff.
  ///
  /// In es, this message translates to:
  /// **'Equipo Salufit'**
  String get chatStaff;

  /// No description provided for @profileLogoutAction.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileLogoutAction;

  /// No description provided for @profileSection.
  ///
  /// In es, this message translates to:
  /// **'Sección'**
  String get profileSection;

  /// No description provided for @profileSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionApp.
  ///
  /// In es, this message translates to:
  /// **'Aplicación'**
  String get profileSectionApp;

  /// No description provided for @profileSectionPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad y datos'**
  String get profileSectionPrivacy;

  /// No description provided for @profileVersionLabel.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get profileVersionLabel;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el idioma de la aplicación'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageChanged.
  ///
  /// In es, this message translates to:
  /// **'Idioma actualizado'**
  String get settingsLanguageChanged;

  /// No description provided for @validationFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get validationFieldRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico no válido'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordWeak.
  ///
  /// In es, this message translates to:
  /// **'La contraseña no es lo suficientemente segura'**
  String get validationPasswordWeak;

  /// No description provided for @activationAccountDetectedTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta detectada'**
  String get activationAccountDetectedTitle;

  /// No description provided for @activationAccountDetectedMessage.
  ///
  /// In es, this message translates to:
  /// **'Parece que ya tienes una cuenta activa con el correo {email}.\n\nSi no recuerdas tu contraseña, pulsa el botón de abajo y te enviaremos un enlace.'**
  String activationAccountDetectedMessage(String email);

  /// No description provided for @activationLinkSentTo.
  ///
  /// In es, this message translates to:
  /// **'Enlace enviado a {email}'**
  String activationLinkSentTo(String email);

  /// No description provided for @activationLinkSendError.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar el enlace.'**
  String get activationLinkSendError;

  /// No description provided for @activationResetPassword.
  ///
  /// In es, this message translates to:
  /// **'RESTABLECER CONTRASEÑA'**
  String get activationResetPassword;

  /// No description provided for @termsValidationTitle.
  ///
  /// In es, this message translates to:
  /// **'VALIDACIÓN DE ACCESO'**
  String get termsValidationTitle;

  /// No description provided for @termsValidationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lee y acepta nuestras políticas oficiales para continuar.'**
  String get termsValidationSubtitle;

  /// No description provided for @termsMedicalDisclaimer.
  ///
  /// In es, this message translates to:
  /// **'AVISO MÉDICO: La información y evaluaciones de esta aplicación son complementarias a tu seguimiento en consulta. No sustituyen el diagnóstico, tratamiento o consejo de un profesional sanitario titulado. Ante cualquier síntoma grave consulta a tu médico.'**
  String get termsMedicalDisclaimer;

  /// No description provided for @termsReadTermsButton.
  ///
  /// In es, this message translates to:
  /// **'LEER TÉRMINOS Y CONDICIONES'**
  String get termsReadTermsButton;

  /// No description provided for @termsReadPrivacyButton.
  ///
  /// In es, this message translates to:
  /// **'LEER POLÍTICA DE PRIVACIDAD'**
  String get termsReadPrivacyButton;

  /// No description provided for @termsAcceptTermsCheckbox.
  ///
  /// In es, this message translates to:
  /// **'Acepto los Términos y Condiciones'**
  String get termsAcceptTermsCheckbox;

  /// No description provided for @termsAcceptPrivacyCheckbox.
  ///
  /// In es, this message translates to:
  /// **'Acepto la Política de Privacidad'**
  String get termsAcceptPrivacyCheckbox;

  /// No description provided for @termsReadFirstWarning.
  ///
  /// In es, this message translates to:
  /// **'Debes leer ambos documentos antes de poder aceptar.'**
  String get termsReadFirstWarning;

  /// No description provided for @termsRequiredBoth.
  ///
  /// In es, this message translates to:
  /// **'Es necesario aceptar ambas políticas para entrar.'**
  String get termsRequiredBoth;

  /// No description provided for @termsContactClinicLine.
  ///
  /// In es, this message translates to:
  /// **'Si no estás de acuerdo, contacta con la clínica:'**
  String get termsContactClinicLine;

  /// No description provided for @termsSupportLine.
  ///
  /// In es, this message translates to:
  /// **'Soporte Salufit: {phone}'**
  String termsSupportLine(String phone);

  /// No description provided for @termsConfirmAccess.
  ///
  /// In es, this message translates to:
  /// **'CONFIRMAR Y ACCEDER'**
  String get termsConfirmAccess;

  /// No description provided for @termsExit.
  ///
  /// In es, this message translates to:
  /// **'SALIR'**
  String get termsExit;

  /// No description provided for @termsErrorRetry.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error. Inténtalo de nuevo.'**
  String get termsErrorRetry;

  /// No description provided for @updateYourVersion.
  ///
  /// In es, this message translates to:
  /// **'Tu versión'**
  String get updateYourVersion;

  /// No description provided for @updateRequiredVersionLabel.
  ///
  /// In es, this message translates to:
  /// **'Requerida'**
  String get updateRequiredVersionLabel;

  /// No description provided for @updateContactSupport.
  ///
  /// In es, this message translates to:
  /// **'Contacta con administración si necesitas ayuda.'**
  String get updateContactSupport;

  /// No description provided for @updateMessageLong.
  ///
  /// In es, this message translates to:
  /// **'Hay una nueva versión de Salufit disponible. Debes actualizar para continuar usando la aplicación.'**
  String get updateMessageLong;

  /// No description provided for @chatWithUser.
  ///
  /// In es, this message translates to:
  /// **'Chat con {name}'**
  String chatWithUser(String name);

  /// No description provided for @chatEmptyFirst.
  ///
  /// In es, this message translates to:
  /// **'Sin mensajes aún. ¡Escribe el primero!'**
  String get chatEmptyFirst;

  /// No description provided for @chatMemberDefault.
  ///
  /// In es, this message translates to:
  /// **'Miembro'**
  String get chatMemberDefault;

  /// No description provided for @chatRoleAdminUpper.
  ///
  /// In es, this message translates to:
  /// **'ADMINISTRACIÓN'**
  String get chatRoleAdminUpper;

  /// No description provided for @chatRoleProfessionalUpper.
  ///
  /// In es, this message translates to:
  /// **'PROFESIONAL'**
  String get chatRoleProfessionalUpper;

  /// No description provided for @passwordMigrationDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualiza tu contraseña'**
  String get passwordMigrationDialogTitle;

  /// No description provided for @passwordMigrationDialogMessage.
  ///
  /// In es, this message translates to:
  /// **'Para proteger tus datos médicos hemos reforzado los requisitos de seguridad. Crea una nueva contraseña que cumpla los estándares actuales.'**
  String get passwordMigrationDialogMessage;

  /// No description provided for @passwordRequire12Chars.
  ///
  /// In es, this message translates to:
  /// **'Al menos 12 caracteres'**
  String get passwordRequire12Chars;

  /// No description provided for @passwordRequireUppercase.
  ///
  /// In es, this message translates to:
  /// **'Una mayúscula'**
  String get passwordRequireUppercase;

  /// No description provided for @passwordRequireLowercase.
  ///
  /// In es, this message translates to:
  /// **'Una minúscula'**
  String get passwordRequireLowercase;

  /// No description provided for @passwordRequireNumber.
  ///
  /// In es, this message translates to:
  /// **'Un número'**
  String get passwordRequireNumber;

  /// No description provided for @passwordShow.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get passwordShow;

  /// No description provided for @passwordHide.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get passwordHide;

  /// No description provided for @passwordConfirmLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirma la contraseña'**
  String get passwordConfirmLabel;

  /// No description provided for @passwordMigrationServerError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar la contraseña.'**
  String get passwordMigrationServerError;

  /// No description provided for @passwordUnexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado. Inténtalo de nuevo.'**
  String get passwordUnexpectedError;

  /// No description provided for @consentPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu privacidad'**
  String get consentPrivacyTitle;

  /// No description provided for @consentUpdatedMessage.
  ///
  /// In es, this message translates to:
  /// **'Hemos actualizado nuestra política de privacidad. Por favor revisa y selecciona qué permites que hagamos con tus datos. Puedes cambiar estas preferencias en cualquier momento desde tu perfil.'**
  String get consentUpdatedMessage;

  /// No description provided for @consentMedicalShort.
  ///
  /// In es, this message translates to:
  /// **'Datos médicos e historia clínica'**
  String get consentMedicalShort;

  /// No description provided for @consentMedicalLongDesc.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio. Necesario para ofrecerte el servicio médico y deportivo del centro.'**
  String get consentMedicalLongDesc;

  /// No description provided for @consentMarketingShort.
  ///
  /// In es, this message translates to:
  /// **'Comunicaciones comerciales'**
  String get consentMarketingShort;

  /// No description provided for @consentMarketingLongDesc.
  ///
  /// In es, this message translates to:
  /// **'Opcional. Recibir información sobre ofertas, eventos y novedades del centro por email.'**
  String get consentMarketingLongDesc;

  /// No description provided for @consentAnalyticsShort.
  ///
  /// In es, this message translates to:
  /// **'Analítica de uso de la app'**
  String get consentAnalyticsShort;

  /// No description provided for @consentAnalyticsLongDesc.
  ///
  /// In es, this message translates to:
  /// **'Opcional. Ayúdanos a mejorar la app analizando cómo la usas (no incluye datos médicos).'**
  String get consentAnalyticsLongDesc;

  /// No description provided for @consentFullPolicyLink.
  ///
  /// In es, this message translates to:
  /// **'Política completa en {url}'**
  String consentFullPolicyLink(String url);

  /// No description provided for @consentRequiredBadge.
  ///
  /// In es, this message translates to:
  /// **'OBLIGATORIO'**
  String get consentRequiredBadge;

  /// No description provided for @consentSubmitPreferences.
  ///
  /// In es, this message translates to:
  /// **'Guardar preferencias'**
  String get consentSubmitPreferences;

  /// No description provided for @consentMedicalRequired.
  ///
  /// In es, this message translates to:
  /// **'El tratamiento de datos médicos es necesario para usar la app.'**
  String get consentMedicalRequired;

  /// No description provided for @consentSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar. Revisa tu conexión.'**
  String get consentSaveError;

  /// No description provided for @consentSessionInvalid.
  ///
  /// In es, this message translates to:
  /// **'Sesión no válida'**
  String get consentSessionInvalid;

  /// No description provided for @dobConfirmAge.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu edad'**
  String get dobConfirmAge;

  /// No description provided for @dobSelectPrompt.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una fecha'**
  String get dobSelectPrompt;

  /// No description provided for @dobMinAgeError.
  ///
  /// In es, this message translates to:
  /// **'La edad mínima para usar la app es {age} años.'**
  String dobMinAgeError(int age);

  /// No description provided for @dobSelectHelp.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu fecha de nacimiento'**
  String get dobSelectHelp;

  /// No description provided for @dobParentalConsentRequired.
  ///
  /// In es, this message translates to:
  /// **'Como menor de edad, necesitas el consentimiento de un tutor para usar la app. Por favor, contacta con el centro.'**
  String get dobParentalConsentRequired;

  /// No description provided for @materialScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'TU MATERIAL'**
  String get materialScreenTitle;

  /// No description provided for @materialNoExercises.
  ///
  /// In es, this message translates to:
  /// **'No tienes ejercicios asignados todavía'**
  String get materialNoExercises;

  /// No description provided for @materialDailyGoal.
  ///
  /// In es, this message translates to:
  /// **'OBJETIVO DIARIO'**
  String get materialDailyGoal;

  /// No description provided for @materialExercisesCompleted.
  ///
  /// In es, this message translates to:
  /// **'ejercicios completados'**
  String get materialExercisesCompleted;

  /// No description provided for @materialLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar material'**
  String get materialLoadError;

  /// No description provided for @materialDefaultExercise.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio'**
  String get materialDefaultExercise;

  /// No description provided for @materialDefaultFamily.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get materialDefaultFamily;

  /// No description provided for @classListHeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'CLASES GRUPALES'**
  String get classListHeaderTitle;

  /// No description provided for @classListLoadErrorMsg.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar clases'**
  String get classListLoadErrorMsg;

  /// No description provided for @classListMonitorLabel.
  ///
  /// In es, this message translates to:
  /// **'MONITOR'**
  String get classListMonitorLabel;

  /// No description provided for @classListStaffDefault.
  ///
  /// In es, this message translates to:
  /// **'STAFF'**
  String get classListStaffDefault;

  /// No description provided for @classBookedUpper.
  ///
  /// In es, this message translates to:
  /// **'RESERVADO'**
  String get classBookedUpper;

  /// No description provided for @classFullUpper.
  ///
  /// In es, this message translates to:
  /// **'LLENO'**
  String get classFullUpper;

  /// No description provided for @classBookUpper.
  ///
  /// In es, this message translates to:
  /// **'RESERVAR'**
  String get classBookUpper;

  /// No description provided for @classBookConfirmShortTitle.
  ///
  /// In es, this message translates to:
  /// **'Menos de 24h'**
  String get classBookConfirmShortTitle;

  /// No description provided for @classBookConfirmShortMsg.
  ///
  /// In es, this message translates to:
  /// **'Si reservas, no podrás cancelar ni recuperar el token según nuestra política.'**
  String get classBookConfirmShortMsg;

  /// No description provided for @commonReturnUpper.
  ///
  /// In es, this message translates to:
  /// **'VOLVER'**
  String get commonReturnUpper;

  /// No description provided for @documentsScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'DOCUMENTOS'**
  String get documentsScreenTitle;

  /// No description provided for @documentsTabAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get documentsTabAll;

  /// No description provided for @documentsTabPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get documentsTabPending;

  /// No description provided for @documentsTabSigned.
  ///
  /// In es, this message translates to:
  /// **'Firmados'**
  String get documentsTabSigned;

  /// No description provided for @documentsLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar documentos'**
  String get documentsLoadError;

  /// No description provided for @documentsEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'No tienes documentos disponibles'**
  String get documentsEmptyAll;

  /// No description provided for @documentsEmptyPending.
  ///
  /// In es, this message translates to:
  /// **'No tienes documentos pendientes'**
  String get documentsEmptyPending;

  /// No description provided for @documentsEmptySigned.
  ///
  /// In es, this message translates to:
  /// **'Aún no has firmado documentos'**
  String get documentsEmptySigned;

  /// No description provided for @documentsCreatedOn.
  ///
  /// In es, this message translates to:
  /// **'Creado: {date}'**
  String documentsCreatedOn(String date);

  /// No description provided for @documentsSignedOn.
  ///
  /// In es, this message translates to:
  /// **'Firmado: {date}'**
  String documentsSignedOn(String date);

  /// No description provided for @documentsViewButton.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get documentsViewButton;

  /// No description provided for @documentsSignButton.
  ///
  /// In es, this message translates to:
  /// **'Firmar'**
  String get documentsSignButton;

  /// No description provided for @documentsTypeContract.
  ///
  /// In es, this message translates to:
  /// **'Contrato'**
  String get documentsTypeContract;

  /// No description provided for @documentsTypeInvoice.
  ///
  /// In es, this message translates to:
  /// **'Factura'**
  String get documentsTypeInvoice;

  /// No description provided for @documentsTypeReport.
  ///
  /// In es, this message translates to:
  /// **'Informe'**
  String get documentsTypeReport;

  /// No description provided for @documentsTypeReceipt.
  ///
  /// In es, this message translates to:
  /// **'Recibo'**
  String get documentsTypeReceipt;

  /// No description provided for @documentsTypeOther.
  ///
  /// In es, this message translates to:
  /// **'Documento'**
  String get documentsTypeOther;

  /// No description provided for @goalsCardTitle.
  ///
  /// In es, this message translates to:
  /// **'OBJETIVOS'**
  String get goalsCardTitle;

  /// No description provided for @goalsCardCurrentTitle.
  ///
  /// In es, this message translates to:
  /// **'TU OBJETIVO ACTUAL'**
  String get goalsCardCurrentTitle;

  /// No description provided for @goalsCardEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu profesional aún no ha definido objetivos para ti'**
  String get goalsCardEmpty;

  /// No description provided for @goalsCardSetByPro.
  ///
  /// In es, this message translates to:
  /// **'Definido por {name}'**
  String goalsCardSetByPro(String name);

  /// No description provided for @goalsCardProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso: {percent}%'**
  String goalsCardProgress(int percent);

  /// No description provided for @goalsCardDeadline.
  ///
  /// In es, this message translates to:
  /// **'Plazo: {date}'**
  String goalsCardDeadline(String date);

  /// No description provided for @goalsCardCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Objetivo conseguido!'**
  String get goalsCardCompleted;

  /// No description provided for @goalsCardOverdue.
  ///
  /// In es, this message translates to:
  /// **'Plazo superado'**
  String get goalsCardOverdue;

  /// No description provided for @goalsCardSeeHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver historial'**
  String get goalsCardSeeHistory;

  /// No description provided for @recordHeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'MI EXPEDIENTE'**
  String get recordHeaderTitle;

  /// No description provided for @recordTabMetrics.
  ///
  /// In es, this message translates to:
  /// **'MÉTRICAS'**
  String get recordTabMetrics;

  /// No description provided for @recordTabDocuments.
  ///
  /// In es, this message translates to:
  /// **'DOCUMENTOS'**
  String get recordTabDocuments;

  /// No description provided for @metricsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes métricas registradas'**
  String get metricsEmptyTitle;

  /// No description provided for @metricsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu profesional las irá registrando en consulta'**
  String get metricsEmptySubtitle;

  /// No description provided for @metricsDefaultLabel.
  ///
  /// In es, this message translates to:
  /// **'Métrica'**
  String get metricsDefaultLabel;

  /// No description provided for @metricsFirstRecord.
  ///
  /// In es, this message translates to:
  /// **'Primer registro'**
  String get metricsFirstRecord;

  /// No description provided for @consentsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay consentimientos firmados'**
  String get consentsEmptyTitle;

  /// No description provided for @consentsSignedAt.
  ///
  /// In es, this message translates to:
  /// **'Firmado: {date}'**
  String consentsSignedAt(String date);

  /// No description provided for @weeklyGoalLabel.
  ///
  /// In es, this message translates to:
  /// **'OBJETIVO SEMANAL'**
  String get weeklyGoalLabel;

  /// No description provided for @weeklyGoalRemaining.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 CLASE RESTANTE} other{{count} CLASES RESTANTES}}'**
  String weeklyGoalRemaining(int count);

  /// No description provided for @weeklyGoalCompleted.
  ///
  /// In es, this message translates to:
  /// **'OBJETIVO CUMPLIDO'**
  String get weeklyGoalCompleted;

  /// No description provided for @weeklyGoalEncouragement.
  ///
  /// In es, this message translates to:
  /// **'Ánimo, ¡a por tu meta!'**
  String get weeklyGoalEncouragement;

  /// No description provided for @weeklyGoalGreatWork.
  ///
  /// In es, this message translates to:
  /// **'¡Buen trabajo esta semana!'**
  String get weeklyGoalGreatWork;

  /// No description provided for @trialPromoExclusive.
  ///
  /// In es, this message translates to:
  /// **'EXCLUSIVO PARA TI'**
  String get trialPromoExclusive;

  /// No description provided for @trialPromoFreeFirstClass.
  ///
  /// In es, this message translates to:
  /// **'TU PRIMERA CLASE\nES GRATIS'**
  String get trialPromoFreeFirstClass;

  /// No description provided for @trialPromoTapToBook.
  ///
  /// In es, this message translates to:
  /// **'Toca para reservar ahora'**
  String get trialPromoTapToBook;

  /// No description provided for @trialPromoUsedBadge.
  ///
  /// In es, this message translates to:
  /// **'YA PROBASTE TU CLASE'**
  String get trialPromoUsedBadge;

  /// No description provided for @trialPromoBecomeMember.
  ///
  /// In es, this message translates to:
  /// **'¿TE GUSTÓ?\nHAZTE MIEMBRO'**
  String get trialPromoBecomeMember;

  /// No description provided for @trialPromoCheckPasses.
  ///
  /// In es, this message translates to:
  /// **'Consulta nuestros bonos mensuales'**
  String get trialPromoCheckPasses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
