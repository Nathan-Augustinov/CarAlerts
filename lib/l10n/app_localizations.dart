import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('ro')
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save language. Please try again.'**
  String get languageSaveError;

  /// No description provided for @makeItYours.
  ///
  /// In en, this message translates to:
  /// **'MAKE IT YOURS'**
  String get makeItYours;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your account and preferences, in one place.'**
  String get settingsDescription;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'YOUR ACCOUNT'**
  String get yourAccount;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email available'**
  String get noEmail;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @preferencesDescription.
  ///
  /// In en, this message translates to:
  /// **'Personal touches to make CarAlerts yours.'**
  String get preferencesDescription;

  /// No description provided for @helpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get helpFeedback;

  /// No description provided for @helpDescription.
  ///
  /// In en, this message translates to:
  /// **'Help shape what comes next.'**
  String get helpDescription;

  /// No description provided for @shareFeedback.
  ///
  /// In en, this message translates to:
  /// **'Share feedback'**
  String get shareFeedback;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Suggest an improvement or report a problem.'**
  String get feedbackDescription;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your session on this device.'**
  String get accountDescription;

  /// No description provided for @signingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get signingOut;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @carsStaySaved.
  ///
  /// In en, this message translates to:
  /// **'Your cars stay saved to your account.'**
  String get carsStaySaved;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and saved data.'**
  String get deleteDescription;

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @signOutError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Please try again.'**
  String get signOutError;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get statusUnavailable;

  /// No description provided for @reminderRetry.
  ///
  /// In en, this message translates to:
  /// **'Reminders will retry automatically'**
  String get reminderRetry;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @notEnabled.
  ///
  /// In en, this message translates to:
  /// **'Not enabled'**
  String get notEnabled;

  /// No description provided for @allowReminders.
  ///
  /// In en, this message translates to:
  /// **'Tap to allow expiry reminders.'**
  String get allowReminders;

  /// No description provided for @enableInSettings.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable in phone settings.'**
  String get enableInSettings;

  /// No description provided for @permissionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to check. Tap to retry.'**
  String get permissionError;

  /// No description provided for @notificationSettingsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open notification settings. Please try again.'**
  String get notificationSettingsError;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @followDevice.
  ///
  /// In en, this message translates to:
  /// **'Follow your device settings'**
  String get followDevice;

  /// No description provided for @alwaysLight.
  ///
  /// In en, this message translates to:
  /// **'Always use light appearance'**
  String get alwaysLight;

  /// No description provided for @alwaysDark.
  ///
  /// In en, this message translates to:
  /// **'Always use dark appearance'**
  String get alwaysDark;

  /// No description provided for @appearanceSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save appearance. Please try again.'**
  String get appearanceSaveError;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @yourCars.
  ///
  /// In en, this message translates to:
  /// **'Your cars'**
  String get yourCars;

  /// No description provided for @noEmailAppIsAvailableInstallOrSetUpAnEmailAppThenTryAgainYourMessageIsStillHere.
  ///
  /// In en, this message translates to:
  /// **'No email app is available. Install or set up an email app, then try again. Your message is still here.'**
  String
      get noEmailAppIsAvailableInstallOrSetUpAnEmailAppThenTryAgainYourMessageIsStillHere;

  /// No description provided for @couldNotPrepareYourEmailPleaseTryAgainYourMessageIsStillHere.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare your email. Please try again. Your message is still here.'**
  String get couldNotPrepareYourEmailPleaseTryAgainYourMessageIsStillHere;

  /// No description provided for @makeCaralertsBetter.
  ///
  /// In en, this message translates to:
  /// **'Make CarAlerts better'**
  String get makeCaralertsBetter;

  /// No description provided for @haveAnIdeaOrSpottedAProblemWeDLoveToHearFromYou.
  ///
  /// In en, this message translates to:
  /// **'Have an idea or spotted a problem? We’d love to hear from you.'**
  String get haveAnIdeaOrSpottedAProblemWeDLoveToHearFromYou;

  /// No description provided for @whatWouldYouLikeToShare.
  ///
  /// In en, this message translates to:
  /// **'What would you like to share?'**
  String get whatWouldYouLikeToShare;

  /// No description provided for @tellUsWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened'**
  String get tellUsWhatHappened;

  /// No description provided for @tellUsAboutYourIdea.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your idea'**
  String get tellUsAboutYourIdea;

  /// No description provided for @whatWentWrongWhatWereYouDoingAndWhatDidYouExpectToHappen.
  ///
  /// In en, this message translates to:
  /// **'What went wrong? What were you doing, and what did you expect to happen?'**
  String get whatWentWrongWhatWereYouDoingAndWhatDidYouExpectToHappen;

  /// No description provided for @whatCouldWeImproveAndHowWouldItHelpYou.
  ///
  /// In en, this message translates to:
  /// **'What could we improve, and how would it help you?'**
  String get whatCouldWeImproveAndHowWouldItHelpYou;

  /// No description provided for @pleaseWriteAMessageBeforeContinuing.
  ///
  /// In en, this message translates to:
  /// **'Please write a message before continuing.'**
  String get pleaseWriteAMessageBeforeContinuing;

  /// No description provided for @toHelpUsUnderstandYourFeedbackYourPhoneModelOsVersionAndAppVersionAreAutomaticallyAddedAtTheEndOfTheEmail.
  ///
  /// In en, this message translates to:
  /// **'To help us understand your feedback, your phone model, OS version, and app version are automatically added at the end of the email.'**
  String
      get toHelpUsUnderstandYourFeedbackYourPhoneModelOsVersionAndAppVersionAreAutomaticallyAddedAtTheEndOfTheEmail;

  /// No description provided for @preparingEmail.
  ///
  /// In en, this message translates to:
  /// **'Preparing email…'**
  String get preparingEmail;

  /// No description provided for @continueToEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue to email'**
  String get continueToEmail;

  /// No description provided for @reviewAndSendFromYourEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Review and send from your email app.'**
  String get reviewAndSendFromYourEmailApp;

  /// No description provided for @enterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get enterAValidEmailAddress;

  /// No description provided for @emailOrPasswordIsIncorrectTryAgainOrResetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect. Try again or reset your password.'**
  String get emailOrPasswordIsIncorrectTryAgainOrResetYourPassword;

  /// No description provided for @thisEmailAlreadyHasAnAccountSignInOrResetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Sign in or reset your password.'**
  String get thisEmailAlreadyHasAnAccountSignInOrResetYourPassword;

  /// No description provided for @chooseAStrongerPasswordThatMeetsTheAccountPasswordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password that meets the account password requirements.'**
  String get chooseAStrongerPasswordThatMeetsTheAccountPasswordRequirements;

  /// No description provided for @thisAccountHasBeenDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get thisAccountHasBeenDisabled;

  /// No description provided for @tooManyAttemptsPleaseWaitAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get tooManyAttemptsPleaseWaitAndTryAgain;

  /// No description provided for @checkYourConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkYourConnectionAndTryAgain;

  /// No description provided for @thisSignInMethodIsNotAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not available right now.'**
  String get thisSignInMethodIsNotAvailableRightNow;

  /// No description provided for @unableToCompleteYourRequestPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete your request. Please try again.'**
  String get unableToCompleteYourRequestPleaseTryAgain;

  /// No description provided for @ifAnAccountExistsForThisEmailYouLlReceiveAPasswordResetLink.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, you’ll receive a password reset link.'**
  String get ifAnAccountExistsForThisEmailYouLlReceiveAPasswordResetLink;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @atLeastCharacters.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeastCharacters;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterYourPassword;

  /// No description provided for @useAtLeastCharacters.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get useAtLeastCharacters;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password.'**
  String get confirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @sendingResetLink.
  ///
  /// In en, this message translates to:
  /// **'Sending reset link…'**
  String get sendingResetLink;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @alreadyHaveAnAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAnAccountSignIn;

  /// No description provided for @newHereCreateAnAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newHereCreateAnAccount;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @aLittlePeaceOfMind.
  ///
  /// In en, this message translates to:
  /// **'A LITTLE PEACE OF MIND'**
  String get aLittlePeaceOfMind;

  /// No description provided for @lessToRememberMoreRoadAhead.
  ///
  /// In en, this message translates to:
  /// **'Less to remember.\nMore road ahead.'**
  String get lessToRememberMoreRoadAhead;

  /// No description provided for @insuranceInspectionsVignettes.
  ///
  /// In en, this message translates to:
  /// **'Insurance · Inspections · Vignettes'**
  String get insuranceInspectionsVignettes;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @thisCarAndItsSavedExpiryDatesWillBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'This car and its saved expiry dates will be removed.'**
  String get thisCarAndItsSavedExpiryDatesWillBeRemoved;

  /// No description provided for @keepCar.
  ///
  /// In en, this message translates to:
  /// **'Keep car'**
  String get keepCar;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @couldNotRemoveTheCarPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the car. Please try again.'**
  String get couldNotRemoveTheCarPleaseTryAgain;

  /// No description provided for @yourGarage.
  ///
  /// In en, this message translates to:
  /// **'YOUR GARAGE'**
  String get yourGarage;

  /// No description provided for @everyCarEveryDeadlineInOnePlace.
  ///
  /// In en, this message translates to:
  /// **'Every car. Every deadline. In one place.'**
  String get everyCarEveryDeadlineInOnePlace;

  /// No description provided for @noUpcomingDeadlines.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deadlines'**
  String get noUpcomingDeadlines;

  /// No description provided for @expiredOrDueWithinTheNextDays.
  ///
  /// In en, this message translates to:
  /// **'Expired or due within the next 30 days'**
  String get expiredOrDueWithinTheNextDays;

  /// No description provided for @unableToLoadYourCars.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your cars'**
  String get unableToLoadYourCars;

  /// No description provided for @checkYourConnectionAndReopenThisPage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and reopen this page.'**
  String get checkYourConnectionAndReopenThisPage;

  /// No description provided for @yourGarageStartsHere.
  ///
  /// In en, this message translates to:
  /// **'Your garage starts here'**
  String get yourGarageStartsHere;

  /// No description provided for @nothingNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs attention'**
  String get nothingNeedsAttention;

  /// No description provided for @addYourFirstCarToKeepInsuranceInspectionsAndVignettesTogether.
  ///
  /// In en, this message translates to:
  /// **'Add your first car to keep insurance, inspections and vignettes together.'**
  String get addYourFirstCarToKeepInsuranceInspectionsAndVignettesTogether;

  /// No description provided for @noSavedDatesAreExpiredOrDueInTheNextDays.
  ///
  /// In en, this message translates to:
  /// **'No saved dates are expired or due in the next 30 days.'**
  String get noSavedDatesAreExpiredOrDueInTheNextDays;

  /// No description provided for @addCar.
  ///
  /// In en, this message translates to:
  /// **'Add car'**
  String get addCar;

  /// No description provided for @addExpiryDatesToStartTrackingThisCar.
  ///
  /// In en, this message translates to:
  /// **'Add expiry dates to start tracking this car.'**
  String get addExpiryDatesToStartTrackingThisCar;

  /// No description provided for @checkDate.
  ///
  /// In en, this message translates to:
  /// **'Check date'**
  String get checkDate;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// No description provided for @updateThisExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Update this expiry date'**
  String get updateThisExpiryDate;

  /// No description provided for @removeCar.
  ///
  /// In en, this message translates to:
  /// **'Remove car'**
  String get removeCar;

  /// No description provided for @manageCar.
  ///
  /// In en, this message translates to:
  /// **'Manage car'**
  String get manageCar;

  /// No description provided for @atAGlance.
  ///
  /// In en, this message translates to:
  /// **'AT A GLANCE'**
  String get atAGlance;

  /// No description provided for @helloThere.
  ///
  /// In en, this message translates to:
  /// **'Hello there'**
  String get helloThere;

  /// No description provided for @aLittlePlanningASmootherJourney.
  ///
  /// In en, this message translates to:
  /// **'A little planning. A smoother journey.'**
  String get aLittlePlanningASmootherJourney;

  /// No description provided for @makeRoomForPeaceOfMind.
  ///
  /// In en, this message translates to:
  /// **'Make room for peace of mind'**
  String get makeRoomForPeaceOfMind;

  /// No description provided for @youReAheadOfYourDeadlines.
  ///
  /// In en, this message translates to:
  /// **'You’re ahead of your deadlines'**
  String get youReAheadOfYourDeadlines;

  /// No description provided for @keepTrackOfInsuranceInspectionsAndVignettesForEveryCar.
  ///
  /// In en, this message translates to:
  /// **'Keep track of insurance, inspections and vignettes for every car.'**
  String get keepTrackOfInsuranceInspectionsAndVignettesForEveryCar;

  /// No description provided for @addYourFirstCar.
  ///
  /// In en, this message translates to:
  /// **'Add your first car'**
  String get addYourFirstCar;

  /// No description provided for @viewYourGarage.
  ///
  /// In en, this message translates to:
  /// **'View your garage'**
  String get viewYourGarage;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {count}d'**
  String dueInDays(int count);

  /// No description provided for @carTracked.
  ///
  /// In en, this message translates to:
  /// **'Car tracked'**
  String get carTracked;

  /// No description provided for @carsTracked.
  ///
  /// In en, this message translates to:
  /// **'Cars tracked'**
  String get carsTracked;

  /// No description provided for @yourDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Your deadlines'**
  String get yourDeadlines;

  /// No description provided for @theMostUrgentDatesComeFirstTapToManage.
  ///
  /// In en, this message translates to:
  /// **'The most urgent dates come first. Tap to manage.'**
  String get theMostUrgentDatesComeFirstTapToManage;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @unableToLoadYourDashboard.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your dashboard'**
  String get unableToLoadYourDashboard;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noDeadlinesYet.
  ///
  /// In en, this message translates to:
  /// **'No deadlines yet'**
  String get noDeadlinesYet;

  /// No description provided for @yourSavedExpiryDatesWillAppearHereOnceYouAddACar.
  ///
  /// In en, this message translates to:
  /// **'Your saved expiry dates will appear here once you add a car.'**
  String get yourSavedExpiryDatesWillAppearHereOnceYouAddACar;

  /// No description provided for @openYourGarageAndAddExpiryDatesToYourCars.
  ///
  /// In en, this message translates to:
  /// **'Open your garage and add expiry dates to your cars.'**
  String get openYourGarageAndAddExpiryDatesToYourCars;

  /// No description provided for @takeALookAtUpcomingToPlanYourNextRenewal.
  ///
  /// In en, this message translates to:
  /// **'Take a look at Upcoming to plan your next renewal.'**
  String get takeALookAtUpcomingToPlanYourNextRenewal;

  /// No description provided for @yourSavedDatesAreInThePastUpdateThemAfterRenewing.
  ///
  /// In en, this message translates to:
  /// **'Your saved dates are in the past. Update them after renewing.'**
  String get yourSavedDatesAreInThePastUpdateThemAfterRenewing;

  /// No description provided for @deleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteYourAccount;

  /// No description provided for @keepAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep account'**
  String get keepAccount;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @verifyWithGoogleDelete.
  ///
  /// In en, this message translates to:
  /// **'Verify with Google & delete'**
  String get verifyWithGoogleDelete;

  /// No description provided for @verificationCancelledYourAccountHasNotBeenDeleted.
  ///
  /// In en, this message translates to:
  /// **'Verification cancelled. Your account has not been deleted.'**
  String get verificationCancelledYourAccountHasNotBeenDeleted;

  /// No description provided for @couldNotVerifyYourGoogleAccountPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your Google account. Please try again.'**
  String get couldNotVerifyYourGoogleAccountPleaseTryAgain;

  /// No description provided for @couldNotDeleteYourAccountCheckYourConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Check your connection and try again.'**
  String get couldNotDeleteYourAccountCheckYourConnectionAndTryAgain;

  /// No description provided for @yourPasswordWasNotAcceptedPleaseCheckItAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Your password was not accepted. Please check it and try again.'**
  String get yourPasswordWasNotAcceptedPleaseCheckItAndTryAgain;

  /// No description provided for @pleaseSignInAgainThenReturnHereToDeleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then return here to delete your account.'**
  String get pleaseSignInAgainThenReturnHereToDeleteYourAccount;

  /// No description provided for @thisSignInMethodCannotBeVerifiedHerePleaseContactSupport.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method cannot be verified here. Please contact support.'**
  String get thisSignInMethodCannotBeVerifiedHerePleaseContactSupport;

  /// No description provided for @couldNotVerifyYourAccountPleaseSignInAgainAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your account. Please sign in again and retry.'**
  String get couldNotVerifyYourAccountPleaseSignInAgainAndRetry;

  /// No description provided for @permanentlyDeleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get permanentlyDeleteYourAccount;

  /// No description provided for @thisCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get thisCannotBeUndone;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @verifyYourIdentityToDeleteThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to delete this account.'**
  String get verifyYourIdentityToDeleteThisAccount;

  /// No description provided for @enterYourCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get enterYourCurrentPassword;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get deletingAccount;

  /// No description provided for @keepTheAppOpenWhileDeletionFinishes.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open while deletion finishes.'**
  String get keepTheAppOpenWhileDeletionFinishes;

  /// No description provided for @addACar.
  ///
  /// In en, this message translates to:
  /// **'Add a car'**
  String get addACar;

  /// No description provided for @editCar.
  ///
  /// In en, this message translates to:
  /// **'Edit car'**
  String get editCar;

  /// No description provided for @aFewDetailsNowFewerSurprisesLater.
  ///
  /// In en, this message translates to:
  /// **'A few details now. Fewer surprises later.'**
  String get aFewDetailsNowFewerSurprisesLater;

  /// No description provided for @keepYourCarSDetailsAndDeadlinesUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Keep your car’s details and deadlines up to date.'**
  String get keepYourCarSDetailsAndDeadlinesUpToDate;

  /// No description provided for @yourCarCovered.
  ///
  /// In en, this message translates to:
  /// **'Your car, covered'**
  String get yourCarCovered;

  /// No description provided for @carDetails.
  ///
  /// In en, this message translates to:
  /// **'Car details'**
  String get carDetails;

  /// No description provided for @registrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get registrationNumber;

  /// No description provided for @eGArXyz.
  ///
  /// In en, this message translates to:
  /// **'e.g. AR00XYZ'**
  String get eGArXyz;

  /// No description provided for @useTheNumberOnYourLicencePlate.
  ///
  /// In en, this message translates to:
  /// **'Use the number on your licence plate.'**
  String get useTheNumberOnYourLicencePlate;

  /// No description provided for @enterYourRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your registration number.'**
  String get enterYourRegistrationNumber;

  /// No description provided for @useARegistrationNumberWithoutSlashes.
  ///
  /// In en, this message translates to:
  /// **'Use a registration number without slashes.'**
  String get useARegistrationNumberWithoutSlashes;

  /// No description provided for @documentsExpiryDates.
  ///
  /// In en, this message translates to:
  /// **'Documents & expiry dates'**
  String get documentsExpiryDates;

  /// No description provided for @chooseWhatToTrackThenAddEachExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Choose what to track, then add each expiry date.'**
  String get chooseWhatToTrackThenAddEachExpiryDate;

  /// No description provided for @carInsurance.
  ///
  /// In en, this message translates to:
  /// **'Car insurance'**
  String get carInsurance;

  /// No description provided for @insuranceCover.
  ///
  /// In en, this message translates to:
  /// **'Insurance cover'**
  String get insuranceCover;

  /// No description provided for @carInspection.
  ///
  /// In en, this message translates to:
  /// **'Car inspection'**
  String get carInspection;

  /// No description provided for @roadworthinessCheck.
  ///
  /// In en, this message translates to:
  /// **'Roadworthiness check'**
  String get roadworthinessCheck;

  /// No description provided for @roadVignettes.
  ///
  /// In en, this message translates to:
  /// **'ROAD VIGNETTES'**
  String get roadVignettes;

  /// No description provided for @romanianVignette.
  ///
  /// In en, this message translates to:
  /// **'Romanian vignette'**
  String get romanianVignette;

  /// No description provided for @romania.
  ///
  /// In en, this message translates to:
  /// **'Romania'**
  String get romania;

  /// No description provided for @hungarianVignette.
  ///
  /// In en, this message translates to:
  /// **'Hungarian vignette'**
  String get hungarianVignette;

  /// No description provided for @hungary.
  ///
  /// In en, this message translates to:
  /// **'Hungary'**
  String get hungary;

  /// No description provided for @austrianVignette.
  ///
  /// In en, this message translates to:
  /// **'Austrian vignette'**
  String get austrianVignette;

  /// No description provided for @austria.
  ///
  /// In en, this message translates to:
  /// **'Austria'**
  String get austria;

  /// No description provided for @otherExpiryDates.
  ///
  /// In en, this message translates to:
  /// **'Other expiry dates'**
  String get otherExpiryDates;

  /// No description provided for @trackParkingPermitsWarrantiesAndMoreUpToPerCar.
  ///
  /// In en, this message translates to:
  /// **'Track parking permits, warranties and more. Up to 10 per car.'**
  String get trackParkingPermitsWarrantiesAndMoreUpToPerCar;

  /// No description provided for @youCanAddOrUpdateExpiryDatesAtAnyTime.
  ///
  /// In en, this message translates to:
  /// **'You can add or update expiry dates at any time.'**
  String get youCanAddOrUpdateExpiryDatesAtAnyTime;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveCar.
  ///
  /// In en, this message translates to:
  /// **'Save car'**
  String get saveCar;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'EXPIRY DATE'**
  String get expiryDate;

  /// No description provided for @chooseADate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseADate;

  /// No description provided for @expiryName.
  ///
  /// In en, this message translates to:
  /// **'Expiry name'**
  String get expiryName;

  /// No description provided for @eGParkingPermit.
  ///
  /// In en, this message translates to:
  /// **'e.g. Parking permit'**
  String get eGParkingPermit;

  /// No description provided for @enterAnExpiryName.
  ///
  /// In en, this message translates to:
  /// **'Enter an expiry name.'**
  String get enterAnExpiryName;

  /// No description provided for @useCharactersOrFewer.
  ///
  /// In en, this message translates to:
  /// **'Use 50 characters or fewer.'**
  String get useCharactersOrFewer;

  /// No description provided for @useADifferentExpiryName.
  ///
  /// In en, this message translates to:
  /// **'Use a different expiry name.'**
  String get useADifferentExpiryName;

  /// No description provided for @removeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Remove expiry'**
  String get removeExpiry;

  /// No description provided for @expiryDateText.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDateText;

  /// No description provided for @chooseExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Choose expiry date'**
  String get chooseExpiryDate;

  /// No description provided for @pleaseEnterTheRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter the registration number!'**
  String get pleaseEnterTheRegistrationNumber;

  /// No description provided for @pleaseSelectTheInsuranceExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'Please select the insurance expiration date!'**
  String get pleaseSelectTheInsuranceExpirationDate;

  /// No description provided for @pleaseSelectTheInspectionExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'Please select the inspection expiration date!'**
  String get pleaseSelectTheInspectionExpirationDate;

  /// No description provided for @pleaseSelectTheRomanianVignetteExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'Please select the romanian vignette expiration date!'**
  String get pleaseSelectTheRomanianVignetteExpirationDate;

  /// No description provided for @pleaseSelectTheHungarianVignetteExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'Please select the hungarian vignette expiration date!'**
  String get pleaseSelectTheHungarianVignetteExpirationDate;

  /// No description provided for @pleaseSelectTheAustrianVignetteExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'Please select the austrian vignette expiration date!'**
  String get pleaseSelectTheAustrianVignetteExpirationDate;

  /// No description provided for @couldNotSaveYourCarPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Could not save your car. Please try again.'**
  String get couldNotSaveYourCarPleaseTryAgain;

  /// No description provided for @carSavedRemindersWillRetryAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Car saved. Reminders will retry automatically.'**
  String get carSavedRemindersWillRetryAutomatically;

  /// No description provided for @carSavedNotificationsAreDisabled.
  ///
  /// In en, this message translates to:
  /// **'Car saved. Notifications are disabled.'**
  String get carSavedNotificationsAreDisabled;

  /// No description provided for @carSaved.
  ///
  /// In en, this message translates to:
  /// **'Car saved.'**
  String get carSaved;

  /// No description provided for @couldNotOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not open Settings.'**
  String get couldNotOpenSettings;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @signInToTheReminderSAccountToViewThisCar.
  ///
  /// In en, this message translates to:
  /// **'Sign in to the reminder’s account to view this car.'**
  String get signInToTheReminderSAccountToViewThisCar;

  /// No description provided for @thisCarHasBeenRemoved.
  ///
  /// In en, this message translates to:
  /// **'This car has been removed.'**
  String get thisCarHasBeenRemoved;

  /// No description provided for @couldNotOpenThisCarPleaseCheckYourCars.
  ///
  /// In en, this message translates to:
  /// **'Could not open this car. Please check Your cars.'**
  String get couldNotOpenThisCarPleaseCheckYourCars;

  /// No description provided for @chooseAnExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Choose an expiry date.'**
  String get chooseAnExpiryDate;

  /// No description provided for @chooseTodayOrAFutureDate.
  ///
  /// In en, this message translates to:
  /// **'Choose today or a future date.'**
  String get chooseTodayOrAFutureDate;

  /// No description provided for @suggestAnImprovement.
  ///
  /// In en, this message translates to:
  /// **'Suggest an improvement'**
  String get suggestAnImprovement;

  /// No description provided for @reportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportAProblem;

  /// No description provided for @removeNamedCar.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeNamedCar(String name);

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(String name);

  /// No description provided for @carsNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 car needs attention} other{{count} cars need attention}}'**
  String carsNeedAttention(int count);

  /// No description provided for @deadlinesNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 deadline needs attention} other{{count} deadlines need attention}}'**
  String deadlinesNeedAttention(int count);

  /// No description provided for @documentsTracked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 document tracked} other{{count} documents tracked}}'**
  String documentsTracked(int count);

  /// No description provided for @itemsTracked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item tracked} other{{count} items tracked}}'**
  String itemsTracked(int count);

  /// No description provided for @allCarsCount.
  ///
  /// In en, this message translates to:
  /// **'All cars · {count}'**
  String allCarsCount(int count);

  /// No description provided for @attentionCount.
  ///
  /// In en, this message translates to:
  /// **'Needs attention · {count}'**
  String attentionCount(int count);

  /// No description provided for @daysOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count}d overdue'**
  String daysOverdue(int count);

  /// No description provided for @addExpiryCount.
  ///
  /// In en, this message translates to:
  /// **'Add expiry ({count}/10)'**
  String addExpiryCount(int count);

  /// No description provided for @documentExpiry.
  ///
  /// In en, this message translates to:
  /// **'{title} expiry'**
  String documentExpiry(String title);

  /// No description provided for @reviewDates.
  ///
  /// In en, this message translates to:
  /// **'Review expired documents and dates due in the next 30 days.'**
  String get reviewDates;

  /// No description provided for @invalidDates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{} one{ 1 saved date also needs checking.} other{ {count} saved dates also need checking.}}'**
  String invalidDates(int count);

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Your account, all saved cars, and their expiry dates will be permanently deleted. This cannot be undone.'**
  String get deleteConfirmation;

  /// No description provided for @deletionDetails.
  ///
  /// In en, this message translates to:
  /// **'This removes your CarAlerts account, saved cars, expiry dates, and saved account settings. Reminders on this device will be cancelled.'**
  String get deletionDetails;

  /// No description provided for @googleDeletion.
  ///
  /// In en, this message translates to:
  /// **'Google will ask you to choose an account to confirm it’s you. Select {email}. After verification, your CarAlerts account will be permanently deleted. Your Google account will not be deleted.'**
  String googleDeletion(String email);

  /// No description provided for @googleAccountAbove.
  ///
  /// In en, this message translates to:
  /// **'the Google account shown above'**
  String get googleAccountAbove;

  /// No description provided for @accountBeingDeleted.
  ///
  /// In en, this message translates to:
  /// **'the account you are deleting'**
  String get accountBeingDeleted;

  /// No description provided for @differentAccount.
  ///
  /// In en, this message translates to:
  /// **'That is a different account. Select {email} to continue. Nothing has been deleted.'**
  String differentAccount(String email);

  /// No description provided for @emailSubject.
  ///
  /// In en, this message translates to:
  /// **'Email subject: {subject}'**
  String emailSubject(String subject);

  /// No description provided for @expiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiry;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid Date'**
  String get invalidDate;

  /// No description provided for @expiresTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Expires tomorrow.'**
  String get expiresTomorrow;

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {count} days.'**
  String expiresInDays(int count);

  /// No description provided for @expiryNotifications.
  ///
  /// In en, this message translates to:
  /// **'Expiry Notifications'**
  String get expiryNotifications;

  /// No description provided for @remindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders for car expiry dates'**
  String get remindersDescription;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Every car. Every deadline.'**
  String get splashTagline;

  /// No description provided for @dueInThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'Due in 30 days'**
  String get dueInThirtyDays;

  /// No description provided for @deviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Device details'**
  String get deviceDetails;

  /// No description provided for @phoneModel.
  ///
  /// In en, this message translates to:
  /// **'Phone model'**
  String get phoneModel;

  /// No description provided for @osVersion.
  ///
  /// In en, this message translates to:
  /// **'OS version'**
  String get osVersion;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRomanian.
  ///
  /// In en, this message translates to:
  /// **'Romanian'**
  String get languageRomanian;
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
      <String>['en', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
