// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Salufit';

  @override
  String get appSlogan => 'Uw gezondheid in PROFESSIONELE handen';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginPasswordLabel => 'Wachtwoord';

  @override
  String get loginInvalidEmail => 'Ongeldig e-mailadres';

  @override
  String get loginEmptyPassword => 'Voer uw wachtwoord in';

  @override
  String get loginSubmit => 'INLOGGEN';

  @override
  String get loginFirstTime => 'Eerste keer';

  @override
  String get loginForgotPassword => 'Wachtwoord vergeten?';

  @override
  String get loginGenericError => 'Inloggen mislukt. Controleer uw gegevens.';

  @override
  String get languagePickerTitle => 'Taal';

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
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Annuleren';

  @override
  String get commonSave => 'Opslaan';

  @override
  String get commonClose => 'Sluiten';

  @override
  String get commonContinue => 'Doorgaan';

  @override
  String get commonRetry => 'Opnieuw proberen';

  @override
  String get commonError => 'Fout';

  @override
  String get commonLoading => 'Laden…';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nee';

  @override
  String get commonNext => 'Volgende';

  @override
  String get commonBack => 'Terug';

  @override
  String get commonDelete => 'Verwijderen';

  @override
  String get commonEdit => 'Bewerken';

  @override
  String get commonAdd => 'Toevoegen';

  @override
  String get commonSearch => 'Zoeken';

  @override
  String get commonRequired => 'Verplicht veld';

  @override
  String get commonNoData => 'Geen gegevens';

  @override
  String get errorGeneric =>
      'Er is een fout opgetreden.\nStart de app opnieuw op.';

  @override
  String get errorNoConnection => 'Geen internetverbinding';

  @override
  String get errorTryAgain => 'Probeer opnieuw';

  @override
  String get logoutConfirmTitle => 'Uitloggen';

  @override
  String get logoutConfirmMessage => 'Weet u zeker dat u wilt uitloggen?';

  @override
  String get logoutAction => 'Uitloggen';

  @override
  String get navHome => 'Start';

  @override
  String get navClasses => 'Lessen';

  @override
  String get navProfile => 'Profiel';

  @override
  String get navDocuments => 'Documenten';

  @override
  String get navMaterial => 'Materiaal';

  @override
  String get navChat => 'Berichten';

  @override
  String get navBookings => 'Reserveringen';

  @override
  String get navSettings => 'Instellingen';

  @override
  String dashboardWelcome(String name) {
    return 'Hallo, $name';
  }

  @override
  String get dashboardYourPasses => 'Uw passen';

  @override
  String get dashboardYourClasses => 'Uw lessen';

  @override
  String get dashboardUpcomingClass => 'Volgende les';

  @override
  String get dashboardNoUpcoming => 'U heeft geen geplande lessen';

  @override
  String get dashboardSeeAll => 'Alles bekijken';

  @override
  String passesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passen beschikbaar',
      one: '1 pas beschikbaar',
      zero: 'Geen passen',
    );
    return '$_temp0';
  }

  @override
  String passesExpiresOn(String date) {
    return 'Verloopt op $date';
  }

  @override
  String get classBookSubmit => 'Plaats reserveren';

  @override
  String get classBookSuccess => 'Plaats gereserveerd';

  @override
  String get classBookError => 'Plaats kon niet gereserveerd worden';

  @override
  String get classCancelSubmit => 'Reservering annuleren';

  @override
  String get classCancelConfirm => 'Uw reservering annuleren?';

  @override
  String get classFull => 'Les vol';

  @override
  String get classMyReservation => 'Uw reservering';

  @override
  String classCapacity(int occupied, int capacity) {
    return '$occupied/$capacity plaatsen';
  }

  @override
  String get classWaitlist => 'Wachtlijst';

  @override
  String get classWaitlistJoin => 'Op de wachtlijst zetten';

  @override
  String classWaitlistPosition(int position) {
    return 'Positie op wachtlijst: $position';
  }

  @override
  String get profileTitle => 'Mijn profiel';

  @override
  String get profileFullName => 'Volledige naam';

  @override
  String get profilePhone => 'Telefoon';

  @override
  String get profileBirthdate => 'Geboortedatum';

  @override
  String get profileGender => 'Geslacht';

  @override
  String get profileEditTitle => 'Profiel bewerken';

  @override
  String get profileSaved => 'Profiel opgeslagen';

  @override
  String get profileLanguage => 'App-taal';

  @override
  String get documentsTitle => 'Documenten';

  @override
  String get documentsEmpty => 'U heeft geen documenten beschikbaar';

  @override
  String get documentsView => 'Document bekijken';

  @override
  String get documentsSign => 'Ondertekenen';

  @override
  String get documentsSigned => 'Ondertekend';

  @override
  String get materialTitle => 'Materiaal';

  @override
  String get materialEmpty => 'U heeft geen toegewezen materiaal';

  @override
  String get materialView => 'Materiaal bekijken';

  @override
  String get chatTitle => 'Berichten';

  @override
  String get chatEmpty => 'U heeft geen actieve gesprekken';

  @override
  String get chatTypeMessage => 'Bericht schrijven…';

  @override
  String get chatSend => 'Verzenden';

  @override
  String get chatNew => 'Nieuw gesprek';

  @override
  String get chatYou => 'U';

  @override
  String get termsTitle => 'Algemene voorwaarden';

  @override
  String get termsAcceptButton => 'Ik accepteer de voorwaarden';

  @override
  String get termsReadFirst =>
      'U moet de voorwaarden lezen en accepteren om door te gaan';

  @override
  String get privacyTitle => 'Privacybeleid';

  @override
  String get privacyAcceptButton => 'Ik accepteer het privacybeleid';

  @override
  String get activationTitle => 'Account activeren';

  @override
  String get activationCodePrompt =>
      'Voer de activeringscode in die we u hebben gestuurd';

  @override
  String get activationCodeLabel => 'Code';

  @override
  String get activationSubmit => 'Activeren';

  @override
  String get activationInvalidCode => 'Ongeldige code';

  @override
  String get activationSendAgain => 'Code opnieuw verzenden';

  @override
  String get activationFirstTime => 'Het is mijn eerste keer bij Salufit';

  @override
  String get forgotTitle => 'Wachtwoord herstellen';

  @override
  String get forgotInstructions =>
      'Voer uw e-mailadres in en we sturen u een link om uw wachtwoord te herstellen';

  @override
  String get forgotSubmit => 'Link verzenden';

  @override
  String get forgotSuccess =>
      'We hebben u een e-mail gestuurd. Controleer uw inbox.';

  @override
  String get forgotErrorEmail => 'Controleer het ingevoerde e-mailadres';

  @override
  String get passwordMigrationTitle => 'Stel een nieuw wachtwoord in';

  @override
  String get passwordMigrationMessage =>
      'Om veiligheidsredenen vragen we u een nieuw wachtwoord aan te maken.';

  @override
  String get passwordMigrationLabel => 'Nieuw wachtwoord';

  @override
  String get passwordMigrationConfirm => 'Wachtwoord bevestigen';

  @override
  String get passwordMigrationMismatch => 'Wachtwoorden komen niet overeen';

  @override
  String get passwordMigrationMinLength => 'Moet minstens 8 tekens bevatten';

  @override
  String get passwordMigrationSubmit => 'Wachtwoord opslaan';

  @override
  String get consentGranularTitle => 'Uw privacy-voorkeuren';

  @override
  String get consentMarketing => 'Commerciële communicatie';

  @override
  String get consentAnalytics => 'Verbetering van de service (analyse)';

  @override
  String get consentMedical => 'Verwerking van klinische gegevens';

  @override
  String get consentSubmit => 'Voorkeuren opslaan';

  @override
  String get birthDateDialogTitle => 'Geboortedatum';

  @override
  String get birthDateDialogPrompt =>
      'Bevestig uw geboortedatum om door te gaan';

  @override
  String get birthDateDialogSubmit => 'Bevestigen';

  @override
  String get updateRequiredTitle => 'Update vereist';

  @override
  String get updateRequiredMessage =>
      'Er is een nieuwe versie beschikbaar. Werk de app bij om door te gaan.';

  @override
  String get updateRequiredAction => 'Bijwerken';

  @override
  String get qrWalkInTitle => 'QR-toegang';

  @override
  String get qrWalkInPrompt =>
      'Scan de QR-code van het centrum om uw bezoek te registreren';

  @override
  String get qrWalkInSuccess => 'Toegang geregistreerd';

  @override
  String get scheduleEmpty => 'Geen lessen op deze dag';

  @override
  String get scheduleToday => 'Vandaag';

  @override
  String get scheduleTomorrow => 'Morgen';

  @override
  String get scheduleYesterday => 'Gisteren';

  @override
  String get errorPassesEmpty =>
      'U heeft geen beschikbare passen voor deze les';

  @override
  String get errorClassFull => 'De les is vol';

  @override
  String get errorAlreadyBooked => 'U heeft al een reservering voor deze les';

  @override
  String get errorBookingClosed => 'Reserveringen voor deze les zijn gesloten';

  @override
  String get appOfflineBanner =>
      'Offline. Sommige gegevens zijn mogelijk niet bijgewerkt.';

  @override
  String get syncingData => 'Gegevens synchroniseren…';

  @override
  String get commonGotIt => 'Begrepen';

  @override
  String get commonAccept => 'Accepteren';

  @override
  String get commonDecline => 'Weigeren';

  @override
  String get commonGoBack => 'Terug';

  @override
  String get commonConfirm => 'Bevestigen';

  @override
  String get activationLinkPrompt =>
      'Voer uw gegevens in om uw medisch dossier te koppelen aan de app.';

  @override
  String get activationHistoryNumber => 'Dossiernr.';

  @override
  String get activationVerifyIdentity => 'MIJN IDENTITEIT VERIFIËREN';

  @override
  String get activationVerifiedTitle => 'Identiteit geverifieerd!';

  @override
  String activationVerifiedMessage(String email) {
    return 'We hebben een link naar $email gestuurd om uw wachtwoord aan te maken.';
  }

  @override
  String get activationServerError => 'Communicatiefout met de server.';

  @override
  String get activationDataMismatch =>
      'De gegevens komen niet overeen met onze database.';

  @override
  String get activationAlreadyRegisteredTitle => 'U bent al geregistreerd';

  @override
  String get activationAlreadyRegisteredMessage =>
      'Dit dossier heeft al een actief account. Als u uw wachtwoord bent vergeten, sturen we u een link om het te herstellen.';

  @override
  String get activationAlreadyRegisteredAction => 'Link verzenden';

  @override
  String get termsAcceptanceTitle => 'Voorwaarden en privacy';

  @override
  String get termsAcceptancePrompt =>
      'Lees en accepteer de volgende documenten om door te gaan:';

  @override
  String get termsAcceptanceTerms =>
      'Ik heb de Algemene Voorwaarden gelezen en accepteer ze';

  @override
  String get termsAcceptancePrivacy =>
      'Ik heb het Privacybeleid gelezen en accepteer het';

  @override
  String get termsAcceptanceContinue => 'Doorgaan';

  @override
  String get termsAcceptanceRequired =>
      'U moet beide documenten accepteren om door te gaan';

  @override
  String get termsViewLink => 'Document bekijken';

  @override
  String get consentMarketingDescription =>
      'Commerciële informatie en promoties van het centrum ontvangen.';

  @override
  String get consentAnalyticsDescription =>
      'Anonieme analyses toestaan om de app te verbeteren.';

  @override
  String get consentMedicalDescription =>
      'Verwerking van uw klinische gegevens onder AVG/HIPAA.';

  @override
  String get consentRequiredMedical =>
      'Verwerking van klinische gegevens is vereist om de service te gebruiken.';

  @override
  String get updateRequiredAppStore => 'App Store openen';

  @override
  String get updateRequiredPlayStore => 'Play Store openen';

  @override
  String get permissionDeniedTitle => 'Toestemming geweigerd';

  @override
  String get permissionDeniedMessage =>
      'Verleen de toestemming in de systeeminstellingen om door te gaan.';

  @override
  String get permissionOpenSettings => 'Instellingen openen';

  @override
  String homeWelcome(String name) {
    return 'Welkom, $name';
  }

  @override
  String get homeFitTrack => 'Uw voortgang';

  @override
  String get homeQuickActions => 'Snelle acties';

  @override
  String get homeBookClass => 'Les reserveren';

  @override
  String get homeMyDocuments => 'Mijn documenten';

  @override
  String get homeMyMaterial => 'Mijn materiaal';

  @override
  String get homeContactPro => 'Contact met mijn professional';

  @override
  String get classListTitle => 'Lessen van het centrum';

  @override
  String get classListEmptyDay => 'Geen lessen gepland';

  @override
  String get classListLoading => 'Lessen laden…';

  @override
  String classDetailsDuration(int minutes) {
    return 'Duur: $minutes min';
  }

  @override
  String classDetailsCoach(String name) {
    return 'Professional: $name';
  }

  @override
  String classDetailsLocation(String room) {
    return 'Zaal: $room';
  }

  @override
  String classDetailsTime(String time) {
    return 'Tijd: $time';
  }

  @override
  String get tokenSyncing => 'Passen bijwerken…';

  @override
  String get tokenError => 'Uw passen konden niet worden geladen';

  @override
  String get documentsSignPrompt =>
      'We hebben uw handtekening nodig op dit document';

  @override
  String get documentsSignSuccess => 'Document succesvol ondertekend';

  @override
  String get qrAccessTitle => 'QR-toegang';

  @override
  String get qrAccessRetry => 'Opnieuw scannen';

  @override
  String get chatNoMessages => 'Nog geen berichten';

  @override
  String get chatComposeHint => 'Schrijf uw bericht…';

  @override
  String get chatSendError => 'Bericht kon niet worden verzonden';

  @override
  String get chatProfessional => 'Professional';

  @override
  String get chatStaff => 'Salufit-team';

  @override
  String get profileLogoutAction => 'Uitloggen';

  @override
  String get profileSection => 'Sectie';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionApp => 'Applicatie';

  @override
  String get profileSectionPrivacy => 'Privacy en gegevens';

  @override
  String get profileVersionLabel => 'Versie';

  @override
  String get settingsLanguageSubtitle => 'Selecteer de taal van de applicatie';

  @override
  String get settingsLanguageChanged => 'Taal bijgewerkt';

  @override
  String get validationFieldRequired => 'Dit veld is verplicht';

  @override
  String get validationEmailInvalid => 'Ongeldig e-mailadres';

  @override
  String get validationPasswordWeak => 'Het wachtwoord is niet sterk genoeg';
}
