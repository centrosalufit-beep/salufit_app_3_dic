// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Salufit';

  @override
  String get appSlogan => 'Ihre Gesundheit in PROFESSIONELLEN Händen';

  @override
  String get loginEmailLabel => 'E-Mail';

  @override
  String get loginPasswordLabel => 'Passwort';

  @override
  String get loginInvalidEmail => 'Ungültige E-Mail';

  @override
  String get loginEmptyPassword => 'Passwort eingeben';

  @override
  String get loginSubmit => 'ANMELDEN';

  @override
  String get loginFirstTime => 'Erstes Mal';

  @override
  String get loginForgotPassword => 'Passwort vergessen?';

  @override
  String get loginGenericError =>
      'Anmeldung nicht möglich. Bitte überprüfen Sie Ihre Zugangsdaten.';

  @override
  String get languagePickerTitle => 'Sprache';

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
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonError => 'Fehler';

  @override
  String get commonLoading => 'Wird geladen…';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nein';

  @override
  String get commonNext => 'Weiter';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonSearch => 'Suchen';

  @override
  String get commonRequired => 'Pflichtfeld';

  @override
  String get commonNoData => 'Keine Daten';

  @override
  String get errorGeneric =>
      'Ein Fehler ist aufgetreten.\nBitte starten Sie die App neu.';

  @override
  String get errorNoConnection => 'Keine Internetverbindung';

  @override
  String get errorTryAgain => 'Erneut versuchen';

  @override
  String get logoutConfirmTitle => 'Abmelden';

  @override
  String get logoutConfirmMessage => 'Möchten Sie sich wirklich abmelden?';

  @override
  String get logoutAction => 'Abmelden';

  @override
  String get navHome => 'Startseite';

  @override
  String get navClasses => 'Kurse';

  @override
  String get navProfile => 'Profil';

  @override
  String get navDocuments => 'Dokumente';

  @override
  String get navMaterial => 'Material';

  @override
  String get navChat => 'Nachrichten';

  @override
  String get navBookings => 'Buchungen';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String dashboardWelcome(String name) {
    return 'Hallo, $name';
  }

  @override
  String get dashboardYourPasses => 'Ihre Pässe';

  @override
  String get dashboardYourClasses => 'Ihre Kurse';

  @override
  String get dashboardUpcomingClass => 'Nächster Kurs';

  @override
  String get dashboardNoUpcoming => 'Sie haben keine geplanten Kurse';

  @override
  String get dashboardSeeAll => 'Alle anzeigen';

  @override
  String passesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pässe verfügbar',
      one: '1 Pass verfügbar',
      zero: 'Keine Pässe',
    );
    return '$_temp0';
  }

  @override
  String passesExpiresOn(String date) {
    return 'Läuft ab am $date';
  }

  @override
  String get classBookSubmit => 'Platz buchen';

  @override
  String get classBookSuccess => 'Platz gebucht';

  @override
  String get classBookError => 'Platz konnte nicht gebucht werden';

  @override
  String get classCancelSubmit => 'Buchung stornieren';

  @override
  String get classCancelConfirm => 'Buchung stornieren?';

  @override
  String get classFull => 'Kurs ausgebucht';

  @override
  String get classMyReservation => 'Ihre Buchung';

  @override
  String classCapacity(int occupied, int capacity) {
    return '$occupied/$capacity Plätze';
  }

  @override
  String get classWaitlist => 'Warteliste';

  @override
  String get classWaitlistJoin => 'Auf die Warteliste setzen';

  @override
  String classWaitlistPosition(int position) {
    return 'Wartelistenposition: $position';
  }

  @override
  String get profileTitle => 'Mein Profil';

  @override
  String get profileFullName => 'Vollständiger Name';

  @override
  String get profilePhone => 'Telefon';

  @override
  String get profileBirthdate => 'Geburtsdatum';

  @override
  String get profileGender => 'Geschlecht';

  @override
  String get profileEditTitle => 'Profil bearbeiten';

  @override
  String get profileSaved => 'Profil gespeichert';

  @override
  String get profileLanguage => 'App-Sprache';

  @override
  String get documentsTitle => 'Dokumente';

  @override
  String get documentsEmpty => 'Sie haben keine verfügbaren Dokumente';

  @override
  String get documentsView => 'Dokument anzeigen';

  @override
  String get documentsSign => 'Unterzeichnen';

  @override
  String get documentsSigned => 'Unterzeichnet';

  @override
  String get materialTitle => 'Material';

  @override
  String get materialEmpty => 'Ihnen ist kein Material zugewiesen';

  @override
  String get materialView => 'Material anzeigen';

  @override
  String get chatTitle => 'Nachrichten';

  @override
  String get chatEmpty => 'Sie haben keine aktiven Konversationen';

  @override
  String get chatTypeMessage => 'Nachricht schreiben…';

  @override
  String get chatSend => 'Senden';

  @override
  String get chatNew => 'Neue Konversation';

  @override
  String get chatYou => 'Sie';

  @override
  String get termsTitle => 'Allgemeine Geschäftsbedingungen';

  @override
  String get termsAcceptButton => 'Ich akzeptiere die Bedingungen';

  @override
  String get termsReadFirst =>
      'Sie müssen die Bedingungen lesen und akzeptieren, um fortzufahren';

  @override
  String get privacyTitle => 'Datenschutzerklärung';

  @override
  String get privacyAcceptButton => 'Ich akzeptiere die Datenschutzerklärung';

  @override
  String get activationTitle => 'Konto aktivieren';

  @override
  String get activationCodePrompt =>
      'Geben Sie den zugesandten Aktivierungscode ein';

  @override
  String get activationCodeLabel => 'Code';

  @override
  String get activationSubmit => 'Aktivieren';

  @override
  String get activationInvalidCode => 'Ungültiger Code';

  @override
  String get activationSendAgain => 'Code erneut senden';

  @override
  String get activationFirstTime => 'Es ist mein erstes Mal bei Salufit';

  @override
  String get forgotTitle => 'Passwort zurücksetzen';

  @override
  String get forgotInstructions =>
      'Geben Sie Ihre E-Mail ein und wir senden Ihnen einen Link zum Zurücksetzen des Passworts';

  @override
  String get forgotSubmit => 'Link senden';

  @override
  String get forgotSuccess =>
      'Wir haben Ihnen eine E-Mail gesendet. Bitte prüfen Sie Ihren Posteingang.';

  @override
  String get forgotErrorEmail => 'Bitte überprüfen Sie die eingegebene E-Mail';

  @override
  String get passwordMigrationTitle => 'Neues Passwort festlegen';

  @override
  String get passwordMigrationMessage =>
      'Aus Sicherheitsgründen bitten wir Sie, ein neues Passwort zu erstellen.';

  @override
  String get passwordMigrationLabel => 'Neues Passwort';

  @override
  String get passwordMigrationConfirm => 'Passwort bestätigen';

  @override
  String get passwordMigrationMismatch =>
      'Die Passwörter stimmen nicht überein';

  @override
  String get passwordMigrationMinLength =>
      'Muss mindestens 8 Zeichen enthalten';

  @override
  String get passwordMigrationSubmit => 'Passwort speichern';

  @override
  String get consentGranularTitle => 'Ihre Datenschutzeinstellungen';

  @override
  String get consentMarketing => 'Werbliche Mitteilungen';

  @override
  String get consentAnalytics => 'Servicequalität (Analytik)';

  @override
  String get consentMedical => 'Verarbeitung klinischer Daten';

  @override
  String get consentSubmit => 'Einstellungen speichern';

  @override
  String get birthDateDialogTitle => 'Geburtsdatum';

  @override
  String get birthDateDialogPrompt =>
      'Bestätigen Sie Ihr Geburtsdatum, um fortzufahren';

  @override
  String get birthDateDialogSubmit => 'Bestätigen';

  @override
  String get updateRequiredTitle => 'Aktualisierung erforderlich';

  @override
  String get updateRequiredMessage =>
      'Eine neue Version ist verfügbar. Bitte aktualisieren Sie die App, um fortzufahren.';

  @override
  String get updateRequiredAction => 'Aktualisieren';

  @override
  String get qrWalkInTitle => 'QR-Zugang';

  @override
  String get qrWalkInPrompt =>
      'Scannen Sie den QR-Code des Zentrums, um Ihren Eintritt zu registrieren';

  @override
  String get qrWalkInSuccess => 'Zugang registriert';

  @override
  String get scheduleEmpty => 'An diesem Tag keine Kurse';

  @override
  String get scheduleToday => 'Heute';

  @override
  String get scheduleTomorrow => 'Morgen';

  @override
  String get scheduleYesterday => 'Gestern';

  @override
  String get errorPassesEmpty =>
      'Sie haben keine verfügbaren Pässe für diesen Kurs';

  @override
  String get errorClassFull => 'Der Kurs ist ausgebucht';

  @override
  String get errorAlreadyBooked =>
      'Sie haben bereits eine Buchung für diesen Kurs';

  @override
  String get errorBookingClosed => 'Buchungen für diesen Kurs sind geschlossen';

  @override
  String get appOfflineBanner =>
      'Offline. Einige Daten sind möglicherweise nicht aktuell.';

  @override
  String get syncingData => 'Daten werden synchronisiert…';

  @override
  String get commonGotIt => 'Verstanden';

  @override
  String get commonAccept => 'Akzeptieren';

  @override
  String get commonDecline => 'Ablehnen';

  @override
  String get commonGoBack => 'Zurück';

  @override
  String get commonConfirm => 'Bestätigen';

  @override
  String get activationLinkPrompt =>
      'Geben Sie Ihre Daten ein, um Ihre Krankenakte mit der App zu verknüpfen.';

  @override
  String get activationHistoryNumber => 'Akten-Nr.';

  @override
  String get activationVerifyIdentity => 'MEINE IDENTITÄT BESTÄTIGEN';

  @override
  String get activationVerifiedTitle => 'Identität bestätigt!';

  @override
  String activationVerifiedMessage(String email) {
    return 'Wir haben einen Link an $email gesendet, um Ihr Passwort zu erstellen.';
  }

  @override
  String get activationServerError => 'Kommunikationsfehler mit dem Server.';

  @override
  String get activationDataMismatch =>
      'Die Daten stimmen nicht mit unserer Datenbank überein.';

  @override
  String get activationAlreadyRegisteredTitle => 'Sie sind bereits registriert';

  @override
  String get activationAlreadyRegisteredMessage =>
      'Diese Akte hat bereits ein aktives Konto. Wenn Sie Ihr Passwort vergessen haben, senden wir Ihnen einen Link zur Wiederherstellung.';

  @override
  String get activationAlreadyRegisteredAction => 'Link senden';

  @override
  String get termsAcceptanceTitle => 'Bedingungen und Datenschutz';

  @override
  String get termsAcceptancePrompt =>
      'Um fortzufahren, lesen und akzeptieren Sie bitte die folgenden Dokumente:';

  @override
  String get termsAcceptanceTerms =>
      'Ich habe die Allgemeinen Geschäftsbedingungen gelesen und akzeptiert';

  @override
  String get termsAcceptancePrivacy =>
      'Ich habe die Datenschutzerklärung gelesen und akzeptiert';

  @override
  String get termsAcceptanceContinue => 'Weiter';

  @override
  String get termsAcceptanceRequired =>
      'Sie müssen beide Dokumente akzeptieren, um fortzufahren';

  @override
  String get termsViewLink => 'Dokument anzeigen';

  @override
  String get consentMarketingDescription =>
      'Werbeinformationen und Aktionen des Zentrums erhalten.';

  @override
  String get consentAnalyticsDescription =>
      'Anonyme Analysen zur Verbesserung der App zulassen.';

  @override
  String get consentMedicalDescription =>
      'Verarbeitung Ihrer klinischen Daten gemäß DSGVO/HIPAA.';

  @override
  String get consentRequiredMedical =>
      'Die Verarbeitung klinischer Daten ist für die Nutzung des Dienstes erforderlich.';

  @override
  String get updateRequiredAppStore => 'App Store öffnen';

  @override
  String get updateRequiredPlayStore => 'Play Store öffnen';

  @override
  String get permissionDeniedTitle => 'Berechtigung verweigert';

  @override
  String get permissionDeniedMessage =>
      'Erteilen Sie die Berechtigung in den Systemeinstellungen, um fortzufahren.';

  @override
  String get permissionOpenSettings => 'Einstellungen öffnen';

  @override
  String homeWelcome(String name) {
    return 'Willkommen, $name';
  }

  @override
  String get homeFitTrack => 'Ihr Fortschritt';

  @override
  String get homeQuickActions => 'Schnellzugriff';

  @override
  String get homeBookClass => 'Kurs buchen';

  @override
  String get homeMyDocuments => 'Meine Dokumente';

  @override
  String get homeMyMaterial => 'Mein Material';

  @override
  String get homeContactPro => 'Mein Spezialist kontaktieren';

  @override
  String get classListTitle => 'Kurse des Zentrums';

  @override
  String get classListEmptyDay => 'Keine Kurse geplant';

  @override
  String get classListLoading => 'Kurse werden geladen…';

  @override
  String classDetailsDuration(int minutes) {
    return 'Dauer: $minutes Min.';
  }

  @override
  String classDetailsCoach(String name) {
    return 'Profi: $name';
  }

  @override
  String classDetailsLocation(String room) {
    return 'Raum: $room';
  }

  @override
  String classDetailsTime(String time) {
    return 'Zeit: $time';
  }

  @override
  String get tokenSyncing => 'Pässe werden aktualisiert…';

  @override
  String get tokenError => 'Ihre Pässe konnten nicht geladen werden';

  @override
  String get documentsSignPrompt =>
      'Wir benötigen Ihre Unterschrift auf diesem Dokument';

  @override
  String get documentsSignSuccess => 'Dokument erfolgreich unterzeichnet';

  @override
  String get qrAccessTitle => 'QR-Zugang';

  @override
  String get qrAccessRetry => 'Erneut scannen';

  @override
  String get chatNoMessages => 'Noch keine Nachrichten';

  @override
  String get chatComposeHint => 'Schreiben Sie Ihre Nachricht…';

  @override
  String get chatSendError => 'Nachricht konnte nicht gesendet werden';

  @override
  String get chatProfessional => 'Profi';

  @override
  String get chatStaff => 'Salufit-Team';

  @override
  String get profileLogoutAction => 'Abmelden';

  @override
  String get profileSection => 'Bereich';

  @override
  String get profileSectionAccount => 'Konto';

  @override
  String get profileSectionApp => 'Anwendung';

  @override
  String get profileSectionPrivacy => 'Datenschutz und Daten';

  @override
  String get profileVersionLabel => 'Version';

  @override
  String get settingsLanguageSubtitle => 'Wählen Sie die Sprache der Anwendung';

  @override
  String get settingsLanguageChanged => 'Sprache aktualisiert';

  @override
  String get validationFieldRequired => 'Dieses Feld ist erforderlich';

  @override
  String get validationEmailInvalid => 'Ungültige E-Mail-Adresse';

  @override
  String get validationPasswordWeak => 'Das Passwort ist nicht sicher genug';

  @override
  String get activationAccountDetectedTitle => 'Konto erkannt';

  @override
  String activationAccountDetectedMessage(String email) {
    return 'Es scheint, Sie haben bereits ein aktives Konto mit der E-Mail $email.\n\nWenn Sie Ihr Passwort nicht mehr wissen, tippen Sie unten auf die Schaltfläche und wir senden Ihnen einen Link.';
  }

  @override
  String activationLinkSentTo(String email) {
    return 'Link gesendet an $email';
  }

  @override
  String get activationLinkSendError => 'Fehler beim Senden des Links.';

  @override
  String get activationResetPassword => 'PASSWORT ZURÜCKSETZEN';

  @override
  String get termsValidationTitle => 'ZUGANGSPRÜFUNG';

  @override
  String get termsValidationSubtitle =>
      'Bitte lesen und akzeptieren Sie unsere offiziellen Richtlinien, um fortzufahren.';

  @override
  String get termsMedicalDisclaimer =>
      'MEDIZINISCHER HINWEIS: Die Informationen und Bewertungen in dieser App sind eine Ergänzung zu Ihrer ärztlichen Betreuung. Sie ersetzen weder die Diagnose, Behandlung noch den Rat eines qualifizierten medizinischen Fachpersonals. Bei schwerwiegenden Symptomen konsultieren Sie bitte Ihren Arzt.';

  @override
  String get termsReadTermsButton => 'ALLGEMEINE GESCHÄFTSBEDINGUNGEN LESEN';

  @override
  String get termsReadPrivacyButton => 'DATENSCHUTZERKLÄRUNG LESEN';

  @override
  String get termsAcceptTermsCheckbox =>
      'Ich akzeptiere die Allgemeinen Geschäftsbedingungen';

  @override
  String get termsAcceptPrivacyCheckbox =>
      'Ich akzeptiere die Datenschutzerklärung';

  @override
  String get termsReadFirstWarning =>
      'Sie müssen beide Dokumente lesen, bevor Sie akzeptieren können.';

  @override
  String get termsRequiredBoth =>
      'Sie müssen beide Richtlinien akzeptieren, um fortzufahren.';

  @override
  String get termsContactClinicLine =>
      'Wenn Sie nicht einverstanden sind, kontaktieren Sie die Klinik:';

  @override
  String termsSupportLine(String phone) {
    return 'Salufit-Support: $phone';
  }

  @override
  String get termsConfirmAccess => 'BESTÄTIGEN UND ZUGREIFEN';

  @override
  String get termsExit => 'BEENDEN';

  @override
  String get termsErrorRetry =>
      'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get updateYourVersion => 'Ihre Version';

  @override
  String get updateRequiredVersionLabel => 'Erforderlich';

  @override
  String get updateContactSupport =>
      'Kontaktieren Sie die Verwaltung, wenn Sie Hilfe benötigen.';

  @override
  String get updateMessageLong =>
      'Eine neue Version von Salufit ist verfügbar. Sie müssen aktualisieren, um die App weiter nutzen zu können.';

  @override
  String chatWithUser(String name) {
    return 'Chat mit $name';
  }

  @override
  String get chatEmptyFirst =>
      'Noch keine Nachrichten. Schreiben Sie die erste!';

  @override
  String get chatMemberDefault => 'Mitglied';

  @override
  String get chatRoleAdminUpper => 'VERWALTUNG';

  @override
  String get chatRoleProfessionalUpper => 'FACHKRAFT';

  @override
  String get passwordMigrationDialogTitle => 'Aktualisieren Sie Ihr Passwort';

  @override
  String get passwordMigrationDialogMessage =>
      'Zum Schutz Ihrer medizinischen Daten haben wir unsere Sicherheitsanforderungen verschärft. Erstellen Sie ein neues Passwort, das den aktuellen Standards entspricht.';

  @override
  String get passwordRequire12Chars => 'Mindestens 12 Zeichen';

  @override
  String get passwordRequireUppercase => 'Ein Großbuchstabe';

  @override
  String get passwordRequireLowercase => 'Ein Kleinbuchstabe';

  @override
  String get passwordRequireNumber => 'Eine Zahl';

  @override
  String get passwordShow => 'Passwort anzeigen';

  @override
  String get passwordHide => 'Passwort ausblenden';

  @override
  String get passwordConfirmLabel => 'Passwort bestätigen';

  @override
  String get passwordMigrationServerError =>
      'Passwort konnte nicht aktualisiert werden.';

  @override
  String get passwordUnexpectedError =>
      'Unerwarteter Fehler. Bitte versuchen Sie es erneut.';

  @override
  String get consentPrivacyTitle => 'Ihre Privatsphäre';

  @override
  String get consentUpdatedMessage =>
      'Wir haben unsere Datenschutzerklärung aktualisiert. Bitte überprüfen Sie und wählen Sie aus, was Sie uns mit Ihren Daten erlauben. Sie können diese Einstellungen jederzeit in Ihrem Profil ändern.';

  @override
  String get consentMedicalShort => 'Medizinische Daten und Krankenakte';

  @override
  String get consentMedicalLongDesc =>
      'Obligatorisch. Notwendig, um Ihnen den medizinischen und sportlichen Service des Zentrums anzubieten.';

  @override
  String get consentMarketingShort => 'Werbliche Mitteilungen';

  @override
  String get consentMarketingLongDesc =>
      'Optional. Informationen über Angebote, Veranstaltungen und Neuigkeiten des Zentrums per E-Mail erhalten.';

  @override
  String get consentAnalyticsShort => 'Nutzungsanalyse der App';

  @override
  String get consentAnalyticsLongDesc =>
      'Optional. Helfen Sie uns, die App zu verbessern, indem wir analysieren, wie Sie sie nutzen (keine medizinischen Daten).';

  @override
  String consentFullPolicyLink(String url) {
    return 'Vollständige Richtlinie unter $url';
  }

  @override
  String get consentRequiredBadge => 'OBLIGATORISCH';

  @override
  String get consentSubmitPreferences => 'Einstellungen speichern';

  @override
  String get consentMedicalRequired =>
      'Die Verarbeitung medizinischer Daten ist für die Nutzung der App erforderlich.';

  @override
  String get consentSaveError =>
      'Speichern nicht möglich. Überprüfen Sie Ihre Verbindung.';

  @override
  String get consentSessionInvalid => 'Ungültige Sitzung';

  @override
  String get dobConfirmAge => 'Bestätigen Sie Ihr Alter';

  @override
  String get dobSelectPrompt => 'Wählen Sie ein Datum';

  @override
  String dobMinAgeError(int age) {
    return 'Das Mindestalter zur Nutzung der App beträgt $age Jahre.';
  }

  @override
  String get dobSelectHelp => 'Wählen Sie Ihr Geburtsdatum';

  @override
  String get dobParentalConsentRequired =>
      'Als Minderjähriger benötigen Sie die Zustimmung eines Erziehungsberechtigten, um die App zu nutzen. Bitte kontaktieren Sie das Zentrum.';

  @override
  String get materialScreenTitle => 'IHR MATERIAL';

  @override
  String get materialNoExercises => 'Sie haben noch keine zugewiesenen Übungen';

  @override
  String get materialDailyGoal => 'TAGESZIEL';

  @override
  String get materialExercisesCompleted => 'Übungen abgeschlossen';

  @override
  String get materialLoadError => 'Fehler beim Laden des Materials';

  @override
  String get materialDefaultExercise => 'Übung';

  @override
  String get materialDefaultFamily => 'Training';
}
