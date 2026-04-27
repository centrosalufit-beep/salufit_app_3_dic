// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Salufit';

  @override
  String get appSlogan => 'Votre santé entre des mains PROFESSIONNELLES';

  @override
  String get loginEmailLabel => 'Adresse e-mail';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginInvalidEmail => 'Adresse e-mail invalide';

  @override
  String get loginEmptyPassword => 'Saisissez votre mot de passe';

  @override
  String get loginSubmit => 'SE CONNECTER';

  @override
  String get loginFirstTime => 'Première fois';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginGenericError =>
      'Connexion impossible. Vérifiez vos identifiants.';

  @override
  String get languagePickerTitle => 'Langue';

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
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonError => 'Erreur';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonSearch => 'Rechercher';

  @override
  String get commonRequired => 'Champ obligatoire';

  @override
  String get commonNoData => 'Aucune donnée';

  @override
  String get errorGeneric =>
      'Une erreur s\'est produite.\nVeuillez redémarrer l\'application.';

  @override
  String get errorNoConnection => 'Pas de connexion Internet';

  @override
  String get errorTryAgain => 'Réessayer';

  @override
  String get logoutConfirmTitle => 'Se déconnecter';

  @override
  String get logoutConfirmMessage =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get logoutAction => 'Se déconnecter';

  @override
  String get navHome => 'Accueil';

  @override
  String get navClasses => 'Cours';

  @override
  String get navProfile => 'Profil';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navMaterial => 'Matériel';

  @override
  String get navChat => 'Messages';

  @override
  String get navBookings => 'Réservations';

  @override
  String get navSettings => 'Paramètres';

  @override
  String dashboardWelcome(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get dashboardYourPasses => 'Vos forfaits';

  @override
  String get dashboardYourClasses => 'Vos cours';

  @override
  String get dashboardUpcomingClass => 'Prochain cours';

  @override
  String get dashboardNoUpcoming => 'Vous n\'avez pas de cours programmé';

  @override
  String get dashboardSeeAll => 'Tout voir';

  @override
  String passesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count forfaits disponibles',
      one: '1 forfait disponible',
      zero: 'Aucun forfait',
    );
    return '$_temp0';
  }

  @override
  String passesExpiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String get classBookSubmit => 'Réserver une place';

  @override
  String get classBookSuccess => 'Place réservée';

  @override
  String get classBookError => 'Impossible de réserver la place';

  @override
  String get classCancelSubmit => 'Annuler la réservation';

  @override
  String get classCancelConfirm => 'Annuler votre réservation ?';

  @override
  String get classFull => 'Cours complet';

  @override
  String get classMyReservation => 'Votre réservation';

  @override
  String classCapacity(int occupied, int capacity) {
    return '$occupied/$capacity places';
  }

  @override
  String get classWaitlist => 'Liste d\'attente';

  @override
  String get classWaitlistJoin => 'Rejoindre la liste d\'attente';

  @override
  String classWaitlistPosition(int position) {
    return 'Position dans la liste : $position';
  }

  @override
  String get profileTitle => 'Mon profil';

  @override
  String get profileFullName => 'Nom complet';

  @override
  String get profilePhone => 'Téléphone';

  @override
  String get profileBirthdate => 'Date de naissance';

  @override
  String get profileGender => 'Genre';

  @override
  String get profileEditTitle => 'Modifier le profil';

  @override
  String get profileSaved => 'Profil enregistré';

  @override
  String get profileLanguage => 'Langue de l\'application';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsEmpty => 'Vous n\'avez aucun document disponible';

  @override
  String get documentsView => 'Voir le document';

  @override
  String get documentsSign => 'Signer';

  @override
  String get documentsSigned => 'Signé';

  @override
  String get materialTitle => 'Matériel';

  @override
  String get materialEmpty => 'Vous n\'avez aucun matériel attribué';

  @override
  String get materialView => 'Voir le matériel';

  @override
  String get chatTitle => 'Messages';

  @override
  String get chatEmpty => 'Vous n\'avez aucune conversation active';

  @override
  String get chatTypeMessage => 'Écrire un message…';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get chatNew => 'Nouvelle conversation';

  @override
  String get chatYou => 'Vous';

  @override
  String get termsTitle => 'Conditions générales';

  @override
  String get termsAcceptButton => 'J\'accepte les conditions';

  @override
  String get termsReadFirst =>
      'Vous devez lire et accepter les conditions pour continuer';

  @override
  String get privacyTitle => 'Politique de confidentialité';

  @override
  String get privacyAcceptButton =>
      'J\'accepte la politique de confidentialité';

  @override
  String get activationTitle => 'Activer le compte';

  @override
  String get activationCodePrompt =>
      'Saisissez le code d\'activation que nous vous avons envoyé';

  @override
  String get activationCodeLabel => 'Code';

  @override
  String get activationSubmit => 'Activer';

  @override
  String get activationInvalidCode => 'Code invalide';

  @override
  String get activationSendAgain => 'Renvoyer le code';

  @override
  String get activationFirstTime => 'C\'est ma première fois chez Salufit';

  @override
  String get forgotTitle => 'Récupérer le mot de passe';

  @override
  String get forgotInstructions =>
      'Saisissez votre adresse e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe';

  @override
  String get forgotSubmit => 'Envoyer le lien';

  @override
  String get forgotSuccess =>
      'Nous vous avons envoyé un e-mail. Vérifiez votre boîte de réception.';

  @override
  String get forgotErrorEmail => 'Vérifiez l\'adresse e-mail saisie';

  @override
  String get passwordMigrationTitle => 'Définissez un nouveau mot de passe';

  @override
  String get passwordMigrationMessage =>
      'Pour des raisons de sécurité, nous vous demandons de créer un nouveau mot de passe.';

  @override
  String get passwordMigrationLabel => 'Nouveau mot de passe';

  @override
  String get passwordMigrationConfirm => 'Confirmer le mot de passe';

  @override
  String get passwordMigrationMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get passwordMigrationMinLength =>
      'Doit contenir au moins 8 caractères';

  @override
  String get passwordMigrationSubmit => 'Enregistrer le mot de passe';

  @override
  String get consentGranularTitle => 'Vos préférences de confidentialité';

  @override
  String get consentMarketing => 'Communications commerciales';

  @override
  String get consentAnalytics => 'Amélioration du service (analytique)';

  @override
  String get consentMedical => 'Traitement des données cliniques';

  @override
  String get consentSubmit => 'Enregistrer les préférences';

  @override
  String get birthDateDialogTitle => 'Date de naissance';

  @override
  String get birthDateDialogPrompt =>
      'Confirmez votre date de naissance pour continuer';

  @override
  String get birthDateDialogSubmit => 'Confirmer';

  @override
  String get updateRequiredTitle => 'Mise à jour requise';

  @override
  String get updateRequiredMessage =>
      'Une nouvelle version est disponible. Veuillez mettre à jour l\'application pour continuer.';

  @override
  String get updateRequiredAction => 'Mettre à jour';

  @override
  String get qrWalkInTitle => 'Accès par QR';

  @override
  String get qrWalkInPrompt =>
      'Scannez le code QR du centre pour enregistrer votre entrée';

  @override
  String get qrWalkInSuccess => 'Accès enregistré';

  @override
  String get scheduleEmpty => 'Aucun cours ce jour-là';

  @override
  String get scheduleToday => 'Aujourd\'hui';

  @override
  String get scheduleTomorrow => 'Demain';

  @override
  String get scheduleYesterday => 'Hier';

  @override
  String get errorPassesEmpty =>
      'Vous n\'avez aucun forfait disponible pour ce cours';

  @override
  String get errorClassFull => 'Le cours est complet';

  @override
  String get errorAlreadyBooked =>
      'Vous avez déjà une réservation pour ce cours';

  @override
  String get errorBookingClosed =>
      'Les réservations pour ce cours sont fermées';

  @override
  String get appOfflineBanner =>
      'Hors ligne. Certaines données peuvent ne pas être à jour.';

  @override
  String get syncingData => 'Synchronisation des données…';

  @override
  String get commonGotIt => 'Compris';

  @override
  String get commonAccept => 'Accepter';

  @override
  String get commonDecline => 'Refuser';

  @override
  String get commonGoBack => 'Retour';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get activationLinkPrompt =>
      'Saisissez vos informations pour lier votre dossier médical à l\'application.';

  @override
  String get activationHistoryNumber => 'N° Dossier';

  @override
  String get activationVerifyIdentity => 'VÉRIFIER MON IDENTITÉ';

  @override
  String get activationVerifiedTitle => 'Identité vérifiée !';

  @override
  String activationVerifiedMessage(String email) {
    return 'Nous avons envoyé un lien à $email pour créer votre mot de passe.';
  }

  @override
  String get activationServerError =>
      'Erreur de communication avec le serveur.';

  @override
  String get activationDataMismatch =>
      'Les données ne correspondent pas à notre base de données.';

  @override
  String get activationAlreadyRegisteredTitle => 'Vous êtes déjà inscrit';

  @override
  String get activationAlreadyRegisteredMessage =>
      'Ce dossier a déjà un compte actif. Si vous avez oublié votre mot de passe, nous vous enverrons un lien pour le récupérer.';

  @override
  String get activationAlreadyRegisteredAction => 'Envoyer le lien';

  @override
  String get termsAcceptanceTitle => 'Conditions et confidentialité';

  @override
  String get termsAcceptancePrompt =>
      'Pour continuer, veuillez lire et accepter les documents suivants :';

  @override
  String get termsAcceptanceTerms =>
      'J\'ai lu et j\'accepte les Conditions Générales';

  @override
  String get termsAcceptancePrivacy =>
      'J\'ai lu et j\'accepte la Politique de Confidentialité';

  @override
  String get termsAcceptanceContinue => 'Continuer';

  @override
  String get termsAcceptanceRequired =>
      'Vous devez accepter les deux documents pour continuer';

  @override
  String get termsViewLink => 'Voir le document';

  @override
  String get consentMarketingDescription =>
      'Recevoir des informations commerciales et des promotions du centre.';

  @override
  String get consentAnalyticsDescription =>
      'Autoriser les analyses anonymes pour améliorer l\'application.';

  @override
  String get consentMedicalDescription =>
      'Traitement de vos données cliniques conformément au RGPD/HIPAA.';

  @override
  String get consentRequiredMedical =>
      'Le traitement des données cliniques est nécessaire pour utiliser le service.';

  @override
  String get updateRequiredAppStore => 'Ouvrir l\'App Store';

  @override
  String get updateRequiredPlayStore => 'Ouvrir le Play Store';

  @override
  String get permissionDeniedTitle => 'Autorisation refusée';

  @override
  String get permissionDeniedMessage =>
      'Accordez l\'autorisation depuis les paramètres système pour continuer.';

  @override
  String get permissionOpenSettings => 'Ouvrir les paramètres';

  @override
  String homeWelcome(String name) {
    return 'Bienvenue, $name';
  }

  @override
  String get homeFitTrack => 'Votre suivi';

  @override
  String get homeQuickActions => 'Actions rapides';

  @override
  String get homeBookClass => 'Réserver un cours';

  @override
  String get homeMyDocuments => 'Mes documents';

  @override
  String get homeMyMaterial => 'Mon matériel';

  @override
  String get homeContactPro => 'Contacter mon professionnel';

  @override
  String get classListTitle => 'Cours du centre';

  @override
  String get classListEmptyDay => 'Aucun cours programmé';

  @override
  String get classListLoading => 'Chargement des cours…';

  @override
  String classDetailsDuration(int minutes) {
    return 'Durée : $minutes min';
  }

  @override
  String classDetailsCoach(String name) {
    return 'Professionnel : $name';
  }

  @override
  String classDetailsLocation(String room) {
    return 'Salle : $room';
  }

  @override
  String classDetailsTime(String time) {
    return 'Horaire : $time';
  }

  @override
  String get tokenSyncing => 'Mise à jour des forfaits…';

  @override
  String get tokenError => 'Impossible de charger vos forfaits';

  @override
  String get documentsSignPrompt =>
      'Nous avons besoin de votre signature sur ce document';

  @override
  String get documentsSignSuccess => 'Document signé avec succès';

  @override
  String get qrAccessTitle => 'Accès par QR';

  @override
  String get qrAccessRetry => 'Scanner à nouveau';

  @override
  String get chatNoMessages => 'Aucun message pour le moment';

  @override
  String get chatComposeHint => 'Écrivez votre message…';

  @override
  String get chatSendError => 'Impossible d\'envoyer le message';

  @override
  String get chatProfessional => 'Professionnel';

  @override
  String get chatStaff => 'Équipe Salufit';

  @override
  String get profileLogoutAction => 'Se déconnecter';

  @override
  String get profileSection => 'Section';

  @override
  String get profileSectionAccount => 'Compte';

  @override
  String get profileSectionApp => 'Application';

  @override
  String get profileSectionPrivacy => 'Confidentialité et données';

  @override
  String get profileVersionLabel => 'Version';

  @override
  String get settingsLanguageSubtitle =>
      'Sélectionnez la langue de l\'application';

  @override
  String get settingsLanguageChanged => 'Langue mise à jour';

  @override
  String get validationFieldRequired => 'Ce champ est obligatoire';

  @override
  String get validationEmailInvalid => 'Adresse e-mail invalide';

  @override
  String get validationPasswordWeak =>
      'Le mot de passe n\'est pas assez sécurisé';

  @override
  String get activationAccountDetectedTitle => 'Compte détecté';

  @override
  String activationAccountDetectedMessage(String email) {
    return 'Il semble que vous ayez déjà un compte actif avec l\'adresse $email.\n\nSi vous ne vous souvenez pas de votre mot de passe, appuyez sur le bouton ci-dessous et nous vous enverrons un lien.';
  }

  @override
  String activationLinkSentTo(String email) {
    return 'Lien envoyé à $email';
  }

  @override
  String get activationLinkSendError => 'Erreur lors de l\'envoi du lien.';

  @override
  String get activationResetPassword => 'RÉINITIALISER LE MOT DE PASSE';

  @override
  String get termsValidationTitle => 'VALIDATION D\'ACCÈS';

  @override
  String get termsValidationSubtitle =>
      'Veuillez lire et accepter nos politiques officielles pour continuer.';

  @override
  String get termsMedicalDisclaimer =>
      'AVIS MÉDICAL : Les informations et évaluations de cette application sont complémentaires à votre suivi en consultation. Elles ne remplacent pas le diagnostic, le traitement ou les conseils d\'un professionnel de santé qualifié. En cas de symptômes graves, consultez votre médecin.';

  @override
  String get termsReadTermsButton => 'LIRE LES CONDITIONS GÉNÉRALES';

  @override
  String get termsReadPrivacyButton => 'LIRE LA POLITIQUE DE CONFIDENTIALITÉ';

  @override
  String get termsAcceptTermsCheckbox => 'J\'accepte les Conditions Générales';

  @override
  String get termsAcceptPrivacyCheckbox =>
      'J\'accepte la Politique de Confidentialité';

  @override
  String get termsReadFirstWarning =>
      'Vous devez lire les deux documents avant de pouvoir accepter.';

  @override
  String get termsRequiredBoth =>
      'Vous devez accepter les deux politiques pour entrer.';

  @override
  String get termsContactClinicLine =>
      'Si vous n\'êtes pas d\'accord, contactez la clinique :';

  @override
  String termsSupportLine(String phone) {
    return 'Support Salufit : $phone';
  }

  @override
  String get termsConfirmAccess => 'CONFIRMER ET ACCÉDER';

  @override
  String get termsExit => 'QUITTER';

  @override
  String get termsErrorRetry =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get updateYourVersion => 'Votre version';

  @override
  String get updateRequiredVersionLabel => 'Requise';

  @override
  String get updateContactSupport =>
      'Contactez l\'administration si vous avez besoin d\'aide.';

  @override
  String get updateMessageLong =>
      'Une nouvelle version de Salufit est disponible. Vous devez mettre à jour pour continuer à utiliser l\'application.';

  @override
  String chatWithUser(String name) {
    return 'Discussion avec $name';
  }

  @override
  String get chatEmptyFirst => 'Aucun message. Écrivez le premier !';

  @override
  String get chatMemberDefault => 'Membre';

  @override
  String get chatRoleAdminUpper => 'ADMINISTRATION';

  @override
  String get chatRoleProfessionalUpper => 'PROFESSIONNEL';

  @override
  String get passwordMigrationDialogTitle => 'Mettez à jour votre mot de passe';

  @override
  String get passwordMigrationDialogMessage =>
      'Pour protéger vos données médicales, nous avons renforcé nos exigences de sécurité. Créez un nouveau mot de passe conforme aux standards actuels.';

  @override
  String get passwordRequire12Chars => 'Au moins 12 caractères';

  @override
  String get passwordRequireUppercase => 'Une lettre majuscule';

  @override
  String get passwordRequireLowercase => 'Une lettre minuscule';

  @override
  String get passwordRequireNumber => 'Un chiffre';

  @override
  String get passwordShow => 'Afficher le mot de passe';

  @override
  String get passwordHide => 'Masquer le mot de passe';

  @override
  String get passwordConfirmLabel => 'Confirmer le mot de passe';

  @override
  String get passwordMigrationServerError =>
      'Impossible de mettre à jour le mot de passe.';

  @override
  String get passwordUnexpectedError =>
      'Erreur inattendue. Veuillez réessayer.';

  @override
  String get consentPrivacyTitle => 'Votre confidentialité';

  @override
  String get consentUpdatedMessage =>
      'Nous avons mis à jour notre politique de confidentialité. Veuillez vérifier et sélectionner ce que vous nous autorisez à faire avec vos données. Vous pouvez modifier ces préférences à tout moment depuis votre profil.';

  @override
  String get consentMedicalShort => 'Données médicales et dossier clinique';

  @override
  String get consentMedicalLongDesc =>
      'Obligatoire. Nécessaire pour vous fournir le service médical et sportif du centre.';

  @override
  String get consentMarketingShort => 'Communications commerciales';

  @override
  String get consentMarketingLongDesc =>
      'Facultatif. Recevoir des informations sur les offres, événements et actualités du centre par e-mail.';

  @override
  String get consentAnalyticsShort => 'Analyse de l\'utilisation de l\'app';

  @override
  String get consentAnalyticsLongDesc =>
      'Facultatif. Aidez-nous à améliorer l\'app en analysant comment vous l\'utilisez (n\'inclut pas de données médicales).';

  @override
  String consentFullPolicyLink(String url) {
    return 'Politique complète sur $url';
  }

  @override
  String get consentRequiredBadge => 'OBLIGATOIRE';

  @override
  String get consentSubmitPreferences => 'Enregistrer les préférences';

  @override
  String get consentMedicalRequired =>
      'Le traitement des données médicales est nécessaire pour utiliser l\'app.';

  @override
  String get consentSaveError =>
      'Impossible d\'enregistrer. Vérifiez votre connexion.';

  @override
  String get consentSessionInvalid => 'Session invalide';

  @override
  String get dobConfirmAge => 'Confirmez votre âge';

  @override
  String get dobSelectPrompt => 'Sélectionnez une date';

  @override
  String dobMinAgeError(int age) {
    return 'L\'âge minimum pour utiliser l\'app est de $age ans.';
  }

  @override
  String get dobSelectHelp => 'Sélectionnez votre date de naissance';

  @override
  String get dobParentalConsentRequired =>
      'En tant que mineur, vous avez besoin du consentement d\'un tuteur pour utiliser l\'app. Veuillez contacter le centre.';

  @override
  String get materialScreenTitle => 'VOTRE MATÉRIEL';

  @override
  String get materialNoExercises =>
      'Vous n\'avez pas encore d\'exercices assignés';

  @override
  String get materialDailyGoal => 'OBJECTIF QUOTIDIEN';

  @override
  String get materialExercisesCompleted => 'exercices terminés';

  @override
  String get materialLoadError => 'Erreur lors du chargement du matériel';

  @override
  String get materialDefaultExercise => 'Exercice';

  @override
  String get materialDefaultFamily => 'Entraînement';
}
