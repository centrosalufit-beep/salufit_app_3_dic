// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Salufit';

  @override
  String get appSlogan => 'Your health in PROFESSIONAL hands';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginInvalidEmail => 'Invalid email';

  @override
  String get loginEmptyPassword => 'Enter your password';

  @override
  String get loginSubmit => 'SIGN IN';

  @override
  String get loginFirstTime => 'First time';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginGenericError => 'Could not sign in. Check your credentials.';

  @override
  String get languagePickerTitle => 'Language';

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
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonError => 'Error';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonRequired => 'Required field';

  @override
  String get commonNoData => 'No data';

  @override
  String get errorGeneric => 'An error has occurred.\nPlease restart the app.';

  @override
  String get errorNoConnection => 'No internet connection';

  @override
  String get errorTryAgain => 'Try again';

  @override
  String get logoutConfirmTitle => 'Sign out';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to sign out?';

  @override
  String get logoutAction => 'Sign out';

  @override
  String get navHome => 'Home';

  @override
  String get navClasses => 'Classes';

  @override
  String get navProfile => 'Profile';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navMaterial => 'Material';

  @override
  String get navChat => 'Chat';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navSettings => 'Settings';

  @override
  String dashboardWelcome(String name) {
    return 'Hello, $name';
  }

  @override
  String get dashboardYourPasses => 'Your passes';

  @override
  String get dashboardYourClasses => 'Your classes';

  @override
  String get dashboardUpcomingClass => 'Upcoming class';

  @override
  String get dashboardNoUpcoming => 'You have no scheduled classes';

  @override
  String get dashboardSeeAll => 'See all';

  @override
  String passesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passes available',
      one: '1 pass available',
      zero: 'No passes',
    );
    return '$_temp0';
  }

  @override
  String passesExpiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String get classBookSubmit => 'Book a spot';

  @override
  String get classBookSuccess => 'Spot booked';

  @override
  String get classBookError => 'Could not book the spot';

  @override
  String get classCancelSubmit => 'Cancel booking';

  @override
  String get classCancelConfirm => 'Cancel your booking?';

  @override
  String get classFull => 'Class full';

  @override
  String get classMyReservation => 'Your booking';

  @override
  String classCapacity(int occupied, int capacity) {
    return '$occupied/$capacity spots';
  }

  @override
  String get classWaitlist => 'Waitlist';

  @override
  String get classWaitlistJoin => 'Join the waitlist';

  @override
  String classWaitlistPosition(int position) {
    return 'Waitlist position: $position';
  }

  @override
  String get profileTitle => 'My profile';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileBirthdate => 'Date of birth';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileLanguage => 'App language';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsEmpty => 'You have no documents available';

  @override
  String get documentsView => 'View document';

  @override
  String get documentsSign => 'Sign';

  @override
  String get documentsSigned => 'Signed';

  @override
  String get materialTitle => 'Material';

  @override
  String get materialEmpty => 'You have no assigned material';

  @override
  String get materialView => 'View material';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatEmpty => 'You have no active conversations';

  @override
  String get chatTypeMessage => 'Type a message…';

  @override
  String get chatSend => 'Send';

  @override
  String get chatNew => 'New conversation';

  @override
  String get chatYou => 'You';

  @override
  String get termsTitle => 'Terms and conditions';

  @override
  String get termsAcceptButton => 'I accept the terms';

  @override
  String get termsReadFirst => 'You must read and accept the terms to continue';

  @override
  String get privacyTitle => 'Privacy policy';

  @override
  String get privacyAcceptButton => 'I accept the privacy policy';

  @override
  String get activationTitle => 'Activate account';

  @override
  String get activationCodePrompt => 'Enter the activation code we sent you';

  @override
  String get activationCodeLabel => 'Code';

  @override
  String get activationSubmit => 'Activate';

  @override
  String get activationInvalidCode => 'Invalid code';

  @override
  String get activationSendAgain => 'Resend code';

  @override
  String get activationFirstTime => 'It\'s my first time at Salufit';

  @override
  String get forgotTitle => 'Reset password';

  @override
  String get forgotInstructions =>
      'Enter your email and we\'ll send you a link to reset your password';

  @override
  String get forgotSubmit => 'Send link';

  @override
  String get forgotSuccess => 'We\'ve sent you an email. Check your inbox.';

  @override
  String get forgotErrorEmail => 'Check the email entered';

  @override
  String get passwordMigrationTitle => 'Set a new password';

  @override
  String get passwordMigrationMessage =>
      'For security reasons, we ask you to create a new password.';

  @override
  String get passwordMigrationLabel => 'New password';

  @override
  String get passwordMigrationConfirm => 'Confirm password';

  @override
  String get passwordMigrationMismatch => 'Passwords do not match';

  @override
  String get passwordMigrationMinLength => 'Must be at least 8 characters';

  @override
  String get passwordMigrationSubmit => 'Save password';

  @override
  String get consentGranularTitle => 'Your privacy preferences';

  @override
  String get consentMarketing => 'Marketing communications';

  @override
  String get consentAnalytics => 'Service improvement (analytics)';

  @override
  String get consentMedical => 'Processing of clinical data';

  @override
  String get consentSubmit => 'Save preferences';

  @override
  String get birthDateDialogTitle => 'Date of birth';

  @override
  String get birthDateDialogPrompt => 'Confirm your date of birth to continue';

  @override
  String get birthDateDialogSubmit => 'Confirm';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredMessage =>
      'A new version is available. Please update the app to continue.';

  @override
  String get updateRequiredAction => 'Update';

  @override
  String get qrWalkInTitle => 'QR access';

  @override
  String get qrWalkInPrompt =>
      'Scan the centre\'s QR code to register your entry';

  @override
  String get qrWalkInSuccess => 'Access registered';

  @override
  String get scheduleEmpty => 'No classes on this day';

  @override
  String get scheduleToday => 'Today';

  @override
  String get scheduleTomorrow => 'Tomorrow';

  @override
  String get scheduleYesterday => 'Yesterday';

  @override
  String get errorPassesEmpty => 'You have no available passes for this class';

  @override
  String get errorClassFull => 'The class is full';

  @override
  String get errorAlreadyBooked => 'You already have a booking for this class';

  @override
  String get errorBookingClosed => 'Bookings for this class are closed';

  @override
  String get appOfflineBanner => 'Offline. Some data may not be up to date.';

  @override
  String get syncingData => 'Syncing data…';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonAccept => 'Accept';

  @override
  String get commonDecline => 'Decline';

  @override
  String get commonGoBack => 'Go back';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get activationLinkPrompt =>
      'Enter your details to link your medical record with the App.';

  @override
  String get activationHistoryNumber => 'Record No.';

  @override
  String get activationVerifyIdentity => 'VERIFY MY IDENTITY';

  @override
  String get activationVerifiedTitle => 'Identity verified!';

  @override
  String activationVerifiedMessage(String email) {
    return 'We\'ve sent a link to $email to create your password.';
  }

  @override
  String get activationServerError => 'Server communication error.';

  @override
  String get activationDataMismatch => 'The data does not match our database.';

  @override
  String get activationAlreadyRegisteredTitle => 'You\'re already registered';

  @override
  String get activationAlreadyRegisteredMessage =>
      'This record already has an active account. If you\'ve forgotten your password, we\'ll send you a link to recover it.';

  @override
  String get activationAlreadyRegisteredAction => 'Send link';

  @override
  String get termsAcceptanceTitle => 'Terms and privacy';

  @override
  String get termsAcceptancePrompt =>
      'To continue, please read and accept the following documents:';

  @override
  String get termsAcceptanceTerms =>
      'I have read and accept the Terms and Conditions';

  @override
  String get termsAcceptancePrivacy =>
      'I have read and accept the Privacy Policy';

  @override
  String get termsAcceptanceContinue => 'Continue';

  @override
  String get termsAcceptanceRequired =>
      'You must accept both documents to continue';

  @override
  String get termsViewLink => 'View document';

  @override
  String get consentMarketingDescription =>
      'Receive commercial information and centre promotions.';

  @override
  String get consentAnalyticsDescription =>
      'Allow anonymous analytics to improve the app.';

  @override
  String get consentMedicalDescription =>
      'Processing of your clinical data under GDPR/HIPAA.';

  @override
  String get consentRequiredMedical =>
      'Processing of clinical data is required to use the service.';

  @override
  String get updateRequiredAppStore => 'Open App Store';

  @override
  String get updateRequiredPlayStore => 'Open Play Store';

  @override
  String get permissionDeniedTitle => 'Permission denied';

  @override
  String get permissionDeniedMessage =>
      'Grant the permission from system settings to continue.';

  @override
  String get permissionOpenSettings => 'Open settings';

  @override
  String homeWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeFitTrack => 'Your tracking';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeBookClass => 'Book a class';

  @override
  String get homeMyDocuments => 'My documents';

  @override
  String get homeMyMaterial => 'My material';

  @override
  String get homeContactPro => 'Contact my professional';

  @override
  String get classListTitle => 'Centre classes';

  @override
  String get classListEmptyDay => 'No classes scheduled';

  @override
  String get classListLoading => 'Loading classes…';

  @override
  String classDetailsDuration(int minutes) {
    return 'Duration: $minutes min';
  }

  @override
  String classDetailsCoach(String name) {
    return 'Professional: $name';
  }

  @override
  String classDetailsLocation(String room) {
    return 'Room: $room';
  }

  @override
  String classDetailsTime(String time) {
    return 'Time: $time';
  }

  @override
  String get tokenSyncing => 'Updating passes…';

  @override
  String get tokenError => 'Could not load your passes';

  @override
  String get documentsSignPrompt => 'We need your signature on this document';

  @override
  String get documentsSignSuccess => 'Document signed successfully';

  @override
  String get qrAccessTitle => 'QR access';

  @override
  String get qrAccessRetry => 'Scan again';

  @override
  String get chatNoMessages => 'No messages yet';

  @override
  String get chatComposeHint => 'Write your message…';

  @override
  String get chatSendError => 'Could not send the message';

  @override
  String get chatProfessional => 'Professional';

  @override
  String get chatStaff => 'Salufit team';

  @override
  String get profileLogoutAction => 'Sign out';

  @override
  String get profileSection => 'Section';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionApp => 'Application';

  @override
  String get profileSectionPrivacy => 'Privacy and data';

  @override
  String get profileVersionLabel => 'Version';

  @override
  String get settingsLanguageSubtitle => 'Select the application language';

  @override
  String get settingsLanguageChanged => 'Language updated';

  @override
  String get validationFieldRequired => 'This field is required';

  @override
  String get validationEmailInvalid => 'Invalid email address';

  @override
  String get validationPasswordWeak => 'The password is not strong enough';
}
