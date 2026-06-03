import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authRegisterButton;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccountButton;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginTitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterTitle;

  /// No description provided for @authGiveInStyleTagline.
  ///
  /// In en, this message translates to:
  /// **'Give in style'**
  String get authGiveInStyleTagline;

  /// No description provided for @authContinueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get authContinueWithEmail;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameLabel;

  /// No description provided for @authUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get authUsernameHint;

  /// No description provided for @authFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get authFirstNameLabel;

  /// No description provided for @authFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get authFirstNameHint;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get authPhoneHint;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authLoginSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get authLoginSuccessToast;

  /// No description provided for @authRegisterSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful'**
  String get authRegisterSuccessToast;

  /// No description provided for @authAlreadyHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authAlreadyHaveAccountPrompt;

  /// No description provided for @authVerifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Check your email inbox for a Verification email'**
  String get authVerifyEmailBody;

  /// No description provided for @authResendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get authResendVerificationEmail;

  /// No description provided for @authForgotPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please type your email and we\'ll get in touch'**
  String get authForgotPasswordInstruction;

  /// No description provided for @authSendEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get authSendEmailButton;

  /// No description provided for @authNotYouLink.
  ///
  /// In en, this message translates to:
  /// **'Not you'**
  String get authNotYouLink;

  /// No description provided for @authUsernameSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is this?'**
  String get authUsernameSetupTitle;

  /// No description provided for @authUsernameSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the name you will like to go by.'**
  String get authUsernameSetupSubtitle;

  /// No description provided for @authUsernameSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameSetupHint;

  /// No description provided for @authUsernameTakenError.
  ///
  /// In en, this message translates to:
  /// **'Username is already taken.'**
  String get authUsernameTakenError;

  /// No description provided for @authUsernameSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save username. Please try again.'**
  String get authUsernameSaveFailed;

  /// No description provided for @authConfirmSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sign out'**
  String get authConfirmSignOutTitle;

  /// No description provided for @authConfirmSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get authConfirmSignOutBody;

  /// No description provided for @authSignOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOutButton;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navGive.
  ///
  /// In en, this message translates to:
  /// **'Give'**
  String get navGive;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscoverTitle;

  /// No description provided for @navPopularSegment.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get navPopularSegment;

  /// No description provided for @navSmallerCharitiesSegment.
  ///
  /// In en, this message translates to:
  /// **'Smaller Charities'**
  String get navSmallerCharitiesSegment;

  /// No description provided for @navLocalToYouSegment.
  ///
  /// In en, this message translates to:
  /// **'Local to you'**
  String get navLocalToYouSegment;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get commonOk;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @productDescriptionHeading.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get productDescriptionHeading;

  /// No description provided for @productMakeOfferButton.
  ///
  /// In en, this message translates to:
  /// **'Make Offer'**
  String get productMakeOfferButton;

  /// No description provided for @productBuyNowButton.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get productBuyNowButton;

  /// No description provided for @productAskSellerButton.
  ///
  /// In en, this message translates to:
  /// **'Ask seller'**
  String get productAskSellerButton;

  /// No description provided for @productNoProductSelected.
  ///
  /// In en, this message translates to:
  /// **'No product selected'**
  String get productNoProductSelected;

  /// No description provided for @checkoutPayButton.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get checkoutPayButton;

  /// No description provided for @checkoutSomethingWentWrongToast.
  ///
  /// In en, this message translates to:
  /// **'oops! Something went wrong'**
  String get checkoutSomethingWentWrongToast;

  /// No description provided for @checkoutPaymentSuccessfulToast.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get checkoutPaymentSuccessfulToast;

  /// No description provided for @checkoutPostcodeRequiredToast.
  ///
  /// In en, this message translates to:
  /// **'Postcode required'**
  String get checkoutPostcodeRequiredToast;

  /// No description provided for @checkoutChangePickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Change pickup point'**
  String get checkoutChangePickupPoint;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
