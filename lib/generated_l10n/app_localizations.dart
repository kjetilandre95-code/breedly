import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_no.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated_l10n/app_localizations.dart';
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
    Locale('da'),
    Locale('en'),
    Locale('fi'),
    Locale('no'),
    Locale('sv'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Breedly'**
  String get appTitle;

  /// Navigation label for home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Navigation label for dogs section
  ///
  /// In en, this message translates to:
  /// **'Dogs'**
  String get dogs;

  /// Navigation label for litters section
  ///
  /// In en, this message translates to:
  /// **'Litters'**
  String get litters;

  /// Navigation label for finance section
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// Navigation label for gallery section
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Navigation label for buyers section
  ///
  /// In en, this message translates to:
  /// **'Buyers'**
  String get buyers;

  /// Navigation label for settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Button label to add a new dog
  ///
  /// In en, this message translates to:
  /// **'Add dog'**
  String get addDog;

  /// Label for name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Label for breed field
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get breed;

  /// Label for color field
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// Label for gender field
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// Gender option for male
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// Gender option for female
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// Label for date of birth field
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// Label for age display
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// Label for registration number field
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get registrationNumber;

  /// Label for notes field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Label for heat cycles section
  ///
  /// In en, this message translates to:
  /// **'Heat cycles'**
  String get heatCycles;

  /// Button label to add a heat cycle
  ///
  /// In en, this message translates to:
  /// **'Add heat date'**
  String get addHeatCycle;

  /// Message when no heat cycles are registered
  ///
  /// In en, this message translates to:
  /// **'No heat dates registered'**
  String get noHeatCycles;

  /// Button label to save dog
  ///
  /// In en, this message translates to:
  /// **'Save dog'**
  String get saveDog;

  /// Button label for save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button label for delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Button label for edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Button label for cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button label for confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Confirmation message for delete action
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get confirmDelete;

  /// Title for delete heat cycle dialog
  ///
  /// In en, this message translates to:
  /// **'Delete heat date'**
  String get deleteHeatCycle;

  /// Confirmation message for deleting heat cycle
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this heat date?'**
  String get deleteHeatCycleConfirm;

  /// Success message when heat cycle is added
  ///
  /// In en, this message translates to:
  /// **'Heat date added'**
  String get heatCycleAdded;

  /// Success message when heat cycle is deleted
  ///
  /// In en, this message translates to:
  /// **'Heat date deleted'**
  String get heatCycleDeleted;

  /// Success message when dog is added
  ///
  /// In en, this message translates to:
  /// **'Dog added'**
  String get dogAdded;

  /// Label for basic information section
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get basic;

  /// Label for pedigree section
  ///
  /// In en, this message translates to:
  /// **'Pedigree'**
  String get pedigree;

  /// Label for mother/dam field
  ///
  /// In en, this message translates to:
  /// **'Dam (Female)'**
  String get mother;

  /// Label for father/sire field
  ///
  /// In en, this message translates to:
  /// **'Sire (Male)'**
  String get father;

  /// Status text for not registered
  ///
  /// In en, this message translates to:
  /// **'Not registered'**
  String get notRegistered;

  /// Text for unknown value
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Text suffix for days since
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysSince;

  /// Message when no dogs are added
  ///
  /// In en, this message translates to:
  /// **'No dogs added'**
  String get noDogsAdded;

  /// Instruction to add first dog
  ///
  /// In en, this message translates to:
  /// **'Add a new dog to get started'**
  String get addNewDog;

  /// Placeholder for breed selection
  ///
  /// In en, this message translates to:
  /// **'Select breed'**
  String get selectBreed;

  /// Title for breed selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select breed'**
  String get selectBreedTitle;

  /// Placeholder for breed search field
  ///
  /// In en, this message translates to:
  /// **'Search breed...'**
  String get searchBreed;

  /// Message when no breeds match search
  ///
  /// In en, this message translates to:
  /// **'No breeds found'**
  String get noBreeds;

  /// Text indicating field is optional
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// Button label to add a new litter
  ///
  /// In en, this message translates to:
  /// **'Add new litter'**
  String get addLitter;

  /// Welcome message title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Breedly!'**
  String get welcomeToBreedly;

  /// Welcome message subtitle
  ///
  /// In en, this message translates to:
  /// **'Your digital kennel assistant'**
  String get welcomeMessage;

  /// Label for quick actions section
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// Button label for new litter
  ///
  /// In en, this message translates to:
  /// **'New litter'**
  String get newLitter;

  /// Button label to set up kennel profile
  ///
  /// In en, this message translates to:
  /// **'Set up kennel profile'**
  String get setupKennelProfile;

  /// Description for kennel profile setup
  ///
  /// In en, this message translates to:
  /// **'Add information about your kennel'**
  String get setupKennelMessage;

  /// Status message during data sync
  ///
  /// In en, this message translates to:
  /// **'Syncing data...'**
  String get syncingData;

  /// Success message when data is synced
  ///
  /// In en, this message translates to:
  /// **'Data synced'**
  String get dataSynced;

  /// Error message when sync fails
  ///
  /// In en, this message translates to:
  /// **'Could not sync data'**
  String get syncFailed;

  /// Button to upload local data to cloud
  ///
  /// In en, this message translates to:
  /// **'Upload to cloud'**
  String get syncToCloud;

  /// Button to download data from cloud
  ///
  /// In en, this message translates to:
  /// **'Download from cloud'**
  String get syncFromCloud;

  /// Info text explaining sync buttons
  ///
  /// In en, this message translates to:
  /// **'Use \'Upload to cloud\' to sync local data to the cloud. \'Download from cloud\' retrieves data from other devices.'**
  String get syncInfo;

  /// Label for active litters section
  ///
  /// In en, this message translates to:
  /// **'Active litters'**
  String get activeLitters;

  /// Label for puppies
  ///
  /// In en, this message translates to:
  /// **'Puppies'**
  String get puppies;

  /// Label for overview tab
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// Label for statistics section
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Label for upcoming events section
  ///
  /// In en, this message translates to:
  /// **'Upcoming events'**
  String get upcomingEvents;

  /// Button label for adding new dog
  ///
  /// In en, this message translates to:
  /// **'New dog'**
  String get newDog;

  /// Label for kennel
  ///
  /// In en, this message translates to:
  /// **'Kennel'**
  String get kennel;

  /// Filter option for all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Filter option for active items
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Filter option for weaning phase
  ///
  /// In en, this message translates to:
  /// **'Weaning'**
  String get weaning;

  /// Filter option for older items
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get older;

  /// Message when no litters are registered
  ///
  /// In en, this message translates to:
  /// **'No litters registered'**
  String get noLittersRegistered;

  /// Instruction to register first litter
  ///
  /// In en, this message translates to:
  /// **'Register your first litter to get started'**
  String get registerFirstLitter;

  /// Message when no active litters
  ///
  /// In en, this message translates to:
  /// **'No active litters (0-8 weeks)'**
  String get noActiveLitters;

  /// Message when no weaning litters
  ///
  /// In en, this message translates to:
  /// **'No litters in weaning phase (8-12 weeks)'**
  String get noWeaningLitters;

  /// Message when no older litters
  ///
  /// In en, this message translates to:
  /// **'No older litters (12+ weeks)'**
  String get noOlderLitters;

  /// Message when no litters in selected category
  ///
  /// In en, this message translates to:
  /// **'No litters in this category'**
  String get noLittersInCategory;

  /// Suggestion to try another category
  ///
  /// In en, this message translates to:
  /// **'Try another category'**
  String get tryAnotherCategory;

  /// Label for app data section
  ///
  /// In en, this message translates to:
  /// **'App data'**
  String get dataInApp;

  /// Label for about app section
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get aboutApp;

  /// Label for version info
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Label for developer info
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// Label for sort options
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Label for birth date
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get birthDate;

  /// Label for puppy count
  ///
  /// In en, this message translates to:
  /// **'Puppy count'**
  String get puppyCount;

  /// Status label for available
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// Placeholder for dog search field
  ///
  /// In en, this message translates to:
  /// **'Search for dog...'**
  String get searchDog;

  /// Label for females filter
  ///
  /// In en, this message translates to:
  /// **'Females'**
  String get females;

  /// Label for males filter
  ///
  /// In en, this message translates to:
  /// **'Males'**
  String get males;

  /// Message when no search results
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// Suggestion to try different search
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// Message when no females registered
  ///
  /// In en, this message translates to:
  /// **'No females registered'**
  String get noFemalesRegistered;

  /// Instruction to add first female
  ///
  /// In en, this message translates to:
  /// **'Add your first female'**
  String get addFirstFemale;

  /// Message when no males registered
  ///
  /// In en, this message translates to:
  /// **'No males registered'**
  String get noMalesRegistered;

  /// Instruction to add first male
  ///
  /// In en, this message translates to:
  /// **'Add your first male'**
  String get addFirstMale;

  /// Message when no dogs registered
  ///
  /// In en, this message translates to:
  /// **'No dogs registered'**
  String get noDogsRegistered;

  /// Instruction to add first dog
  ///
  /// In en, this message translates to:
  /// **'Get started by adding your first dog'**
  String get getStartedAddDog;

  /// Text showing days until heat
  ///
  /// In en, this message translates to:
  /// **'Heat in {days} d'**
  String heatInDays(int days);

  /// Singular form of year
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// Plural form of years
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// Singular form of month
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// Plural form of months
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// Title for my dogs section
  ///
  /// In en, this message translates to:
  /// **'My dogs'**
  String get myDogs;

  /// Welcome message with kennel name
  ///
  /// In en, this message translates to:
  /// **'Welcome to {name}!'**
  String welcomeTo(String name);

  /// Label for expenses
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// Label for income
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// Label for balance
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Message when no transactions
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactions;

  /// Instruction to add first transaction
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction'**
  String get addFirstTransaction;

  /// Button label to add transaction
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// Label for amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Label for description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Label for category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Label for date field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Label for type field
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Label for expense type
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// Label for theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Title for theme selection
  ///
  /// In en, this message translates to:
  /// **'Select theme'**
  String get selectTheme;

  /// Label for color theme setting
  ///
  /// In en, this message translates to:
  /// **'Color theme'**
  String get colorTheme;

  /// Theme option for light mode
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// Label for dark mode section
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Theme option to follow system
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get systemMode;

  /// Message when no buyers registered
  ///
  /// In en, this message translates to:
  /// **'No buyers registered'**
  String get noBuyersRegistered;

  /// Instruction to add first buyer
  ///
  /// In en, this message translates to:
  /// **'Add your first buyer'**
  String get addFirstBuyer;

  /// Button label to add buyer
  ///
  /// In en, this message translates to:
  /// **'Add buyer'**
  String get addBuyer;

  /// Label for buyer name field
  ///
  /// In en, this message translates to:
  /// **'Buyer name'**
  String get buyerName;

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for phone field
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Label for address field
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Label for reserved puppy
  ///
  /// In en, this message translates to:
  /// **'Reserved puppy'**
  String get reservedPuppy;

  /// Status for no reservation
  ///
  /// In en, this message translates to:
  /// **'No reservation'**
  String get noReservation;

  /// Label for puppy
  ///
  /// In en, this message translates to:
  /// **'Puppy'**
  String get puppy;

  /// Label for contract
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// Button label to create contract
  ///
  /// In en, this message translates to:
  /// **'Create contract'**
  String get createContract;

  /// Button label to send contract
  ///
  /// In en, this message translates to:
  /// **'Send contract'**
  String get sendContract;

  /// Status when contract is sent
  ///
  /// In en, this message translates to:
  /// **'Contract sent'**
  String get contractSent;

  /// Status when contract is signed
  ///
  /// In en, this message translates to:
  /// **'Contract signed'**
  String get contractSigned;

  /// Label for price field
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Label for deposit field
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// Status when deposit is paid
  ///
  /// In en, this message translates to:
  /// **'Deposit paid'**
  String get depositPaid;

  /// Label for full payment
  ///
  /// In en, this message translates to:
  /// **'Full payment'**
  String get fullPayment;

  /// Status when payment is received
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived;

  /// Label for pickup date field
  ///
  /// In en, this message translates to:
  /// **'Pickup date'**
  String get pickupDate;

  /// Label for search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Label for filter
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// DNA test result - clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Button label to apply
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Loading status text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Label for error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Button label to retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Label for success
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Label for warning
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Label for info
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// Button label to close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Button label to go back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Button label for next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Button label for done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Button label for yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Button label for no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Button label for OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Button label to sync
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// Label for account
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Button label to log out
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// Confirmation message for log out
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logOutConfirm;

  /// Label for notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Label for manage reminders
  ///
  /// In en, this message translates to:
  /// **'Manage reminders'**
  String get manageReminders;

  /// Button label to update all reminders
  ///
  /// In en, this message translates to:
  /// **'Update all reminders'**
  String get updateAllReminders;

  /// Status message when updating reminders
  ///
  /// In en, this message translates to:
  /// **'Updating all reminders...'**
  String get updatingReminders;

  /// Success message when reminders updated
  ///
  /// In en, this message translates to:
  /// **'All reminders updated!'**
  String get remindersUpdated;

  /// Information about notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications are automatically scheduled for treatments, whelping, and delivery dates.'**
  String get notificationsInfo;

  /// Button label to turn off notifications
  ///
  /// In en, this message translates to:
  /// **'Turn off all notifications'**
  String get turnOffAllNotifications;

  /// Title for turn off notifications dialog
  ///
  /// In en, this message translates to:
  /// **'Turn off all notifications?'**
  String get turnOffNotificationsTitle;

  /// Message for turn off notifications dialog
  ///
  /// In en, this message translates to:
  /// **'This will remove all scheduled reminders. You can always enable them again.'**
  String get turnOffNotificationsMessage;

  /// Button label to turn off
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turnOff;

  /// Success message when notifications turned off
  ///
  /// In en, this message translates to:
  /// **'All notifications turned off'**
  String get allNotificationsTurnedOff;

  /// Button label to view statistics
  ///
  /// In en, this message translates to:
  /// **'View detailed statistics'**
  String get viewDetailedStatistics;

  /// Status for not logged in
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// Message when no upcoming events
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get noUpcomingEvents;

  /// Instruction to register heat or mating
  ///
  /// In en, this message translates to:
  /// **'Register heat cycle or mating to see events here'**
  String get registerHeatOrMating;

  /// Label for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Label for tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Text showing days ago
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// Text showing days remaining
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysRemaining(int days);

  /// Text showing weeks remaining
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks'**
  String weeksRemaining(int weeks);

  /// Label for urgent status
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgent;

  /// Event title for heat cycle
  ///
  /// In en, this message translates to:
  /// **'Heat: {dogName}'**
  String heatCycleEvent(String dogName);

  /// Label for estimated heat start
  ///
  /// In en, this message translates to:
  /// **'Estimated heat starts'**
  String get estimatedHeatStart;

  /// Event title for mating window
  ///
  /// In en, this message translates to:
  /// **'Mating window: {dogName}'**
  String matingWindow(String dogName);

  /// Event title for due date
  ///
  /// In en, this message translates to:
  /// **'Due date: {dogName}'**
  String dueDate(String dogName);

  /// Text showing days until birth
  ///
  /// In en, this message translates to:
  /// **'{days} days until expected birth'**
  String daysUntilBirth(int days);

  /// Event title for delivery
  ///
  /// In en, this message translates to:
  /// **'Delivery: {puppyName}'**
  String delivery(String puppyName);

  /// Text showing buyer name
  ///
  /// In en, this message translates to:
  /// **'To {buyerName}'**
  String toBuyer(String buyerName);

  /// Message when checklist is complete
  ///
  /// In en, this message translates to:
  /// **'Ready for delivery!'**
  String get readyForDelivery;

  /// Status for planned
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// Status for nursing
  ///
  /// In en, this message translates to:
  /// **'Nursing'**
  String get nursing;

  /// Label for archive
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// Theme color option
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get themeForestGreen;

  /// Theme color option
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get themeOceanBlue;

  /// Theme color option
  ///
  /// In en, this message translates to:
  /// **'Terracotta'**
  String get themeTerracotta;

  /// Theme color option
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get themePlum;

  /// Theme color option
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get themeSlate;

  /// Theme color option
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get themeRose;

  /// Theme color option
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get themeTeal;

  /// Theme color option
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get themeAmber;

  /// Title for kennel management
  ///
  /// In en, this message translates to:
  /// **'Kennel Management'**
  String get kennelManagement;

  /// Button label to create kennel
  ///
  /// In en, this message translates to:
  /// **'Create Kennel'**
  String get createKennel;

  /// Button label to join kennel
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinKennel;

  /// Button label to change role
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get changeRole;

  /// Button label to remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Success message when code copied
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get codeCopied;

  /// Button label to invite member
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get inviteMember;

  /// Button label to create invite code
  ///
  /// In en, this message translates to:
  /// **'Create invite code'**
  String get createInviteCode;

  /// Button label to create new kennel
  ///
  /// In en, this message translates to:
  /// **'Create new kennel'**
  String get createNewKennel;

  /// Button label to join with code
  ///
  /// In en, this message translates to:
  /// **'Use invite code'**
  String get joinWithCode;

  /// Button label to leave kennel
  ///
  /// In en, this message translates to:
  /// **'Leave kennel'**
  String get leaveKennel;

  /// Button label to delete kennel
  ///
  /// In en, this message translates to:
  /// **'Delete kennel'**
  String get deleteKennel;

  /// Validation message for required name
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// Message requiring login
  ///
  /// In en, this message translates to:
  /// **'You must be logged in'**
  String get mustBeLoggedIn;

  /// Success message when kennel created
  ///
  /// In en, this message translates to:
  /// **'Kennel created!'**
  String get kennelCreated;

  /// Button label to create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Error message for loading failure
  ///
  /// In en, this message translates to:
  /// **'Error loading: {error}'**
  String loadingError(String error);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericError(String error);

  /// Link for forgot password
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Title for reset password
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// Instructions for password reset
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you a link to reset your password.'**
  String get resetPasswordInstructions;

  /// Validation message for required email
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get emailRequired;

  /// Validation message for invalid email
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// Button label to send
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Success message for email sent
  ///
  /// In en, this message translates to:
  /// **'Email sent to {email}. Check your inbox.'**
  String emailSentTo(String email);

  /// Button label for log in
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// Button label for sign up
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// Button label for Google login
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Separator text for login options
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// Text for no account
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Text for existing account
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Label for password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Label for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// Validation message for required password
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get passwordRequired;

  /// Validation message for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Validation message for mismatched passwords
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Label for dog selection
  ///
  /// In en, this message translates to:
  /// **'Select dog'**
  String get selectDog;

  /// Title for show results section
  ///
  /// In en, this message translates to:
  /// **'Show Results'**
  String get showResults;

  /// Label for total income
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// Label for total expense
  ///
  /// In en, this message translates to:
  /// **'Total expense'**
  String get totalExpense;

  /// Label for net result
  ///
  /// In en, this message translates to:
  /// **'Net result'**
  String get netResult;

  /// Label for expense count
  ///
  /// In en, this message translates to:
  /// **'Number of expenses'**
  String get numberOfExpenses;

  /// Label for income count
  ///
  /// In en, this message translates to:
  /// **'Number of incomes'**
  String get numberOfIncomes;

  /// Message when no expenses
  ///
  /// In en, this message translates to:
  /// **'No expenses registered'**
  String get noExpensesRegistered;

  /// Instruction to add first expense
  ///
  /// In en, this message translates to:
  /// **'Add your first expense to get an overview'**
  String get addFirstExpense;

  /// Button label to add expense
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// Message when no incomes
  ///
  /// In en, this message translates to:
  /// **'No incomes registered'**
  String get noIncomesRegistered;

  /// Instruction to add first income
  ///
  /// In en, this message translates to:
  /// **'Add your first income to get an overview'**
  String get addFirstIncome;

  /// Button label to add income
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncome;

  /// Label for litter
  ///
  /// In en, this message translates to:
  /// **'Litter'**
  String get litter;

  /// Label for optional litter field
  ///
  /// In en, this message translates to:
  /// **'Litter (optional)'**
  String get litterOptional;

  /// Option for no litter
  ///
  /// In en, this message translates to:
  /// **'No litter'**
  String get noLitter;

  /// Success message when expense added
  ///
  /// In en, this message translates to:
  /// **'Expense added'**
  String get expenseAdded;

  /// Success message when income added
  ///
  /// In en, this message translates to:
  /// **'Income added'**
  String get incomeAdded;

  /// Title for delete expense dialog
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get deleteExpense;

  /// Title for delete income dialog
  ///
  /// In en, this message translates to:
  /// **'Delete income?'**
  String get deleteIncome;

  /// Label for buyer
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyer;

  /// Label for optional buyer field
  ///
  /// In en, this message translates to:
  /// **'Buyer (optional)'**
  String get buyerOptional;

  /// Title for statistics section
  ///
  /// In en, this message translates to:
  /// **'Statistics & Reports'**
  String get statisticsAndReports;

  /// Label for litter statistics
  ///
  /// In en, this message translates to:
  /// **'Litter statistics'**
  String get litterStatistics;

  /// Description for litter statistics
  ///
  /// In en, this message translates to:
  /// **'Average litter size, gender distribution and more.'**
  String get litterStatisticsDesc;

  /// Label for weight development
  ///
  /// In en, this message translates to:
  /// **'Weight development'**
  String get weightDevelopment;

  /// Description for weight development
  ///
  /// In en, this message translates to:
  /// **'Compare weight development between puppies and litters.'**
  String get weightDevelopmentDesc;

  /// Label for economy statistics
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get economyStats;

  /// Description for economy statistics
  ///
  /// In en, this message translates to:
  /// **'Income reports per year and breed.'**
  String get economyStatsDesc;

  /// Label for breeding statistics
  ///
  /// In en, this message translates to:
  /// **'Breeding statistics'**
  String get breedingStatistics;

  /// Description for breeding statistics
  ///
  /// In en, this message translates to:
  /// **'See which parent combinations give the best results.'**
  String get breedingStatisticsDesc;

  /// Tip about statistics updates
  ///
  /// In en, this message translates to:
  /// **'Statistics are automatically updated based on your registered data.'**
  String get statisticsTip;

  /// Title for litter overview
  ///
  /// In en, this message translates to:
  /// **'Litter overview'**
  String get litterOverview;

  /// Label for gender distribution
  ///
  /// In en, this message translates to:
  /// **'Gender distribution'**
  String get genderDistribution;

  /// Label for litter size by breed
  ///
  /// In en, this message translates to:
  /// **'Litter size by breed'**
  String get litterSizeByBreed;

  /// Label for litters per year
  ///
  /// In en, this message translates to:
  /// **'Litters per year'**
  String get littersPerYear;

  /// Label for total litters
  ///
  /// In en, this message translates to:
  /// **'Total litters'**
  String get totalLitters;

  /// Label for average litter size
  ///
  /// In en, this message translates to:
  /// **'Average litter size'**
  String get averageLitterSize;

  /// Label for total puppies
  ///
  /// In en, this message translates to:
  /// **'Total puppies'**
  String get totalPuppies;

  /// Label for largest litter
  ///
  /// In en, this message translates to:
  /// **'Largest litter'**
  String get largestLitter;

  /// Label for smallest litter
  ///
  /// In en, this message translates to:
  /// **'Smallest litter'**
  String get smallestLitter;

  /// Text showing puppy count
  ///
  /// In en, this message translates to:
  /// **'{count} puppies'**
  String puppiesCount(int count);

  /// Label for average
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// Title for weight comparison
  ///
  /// In en, this message translates to:
  /// **'Weight comparison between litters'**
  String get weightComparison;

  /// Message when no weight data
  ///
  /// In en, this message translates to:
  /// **'No weight data registered yet'**
  String get noWeightData;

  /// Instruction to register weight
  ///
  /// In en, this message translates to:
  /// **'Register weight on puppies to compare'**
  String get registerWeightForComparison;

  /// Label for average birth weight
  ///
  /// In en, this message translates to:
  /// **'Birth weight (avg)'**
  String get birthWeightAvg;

  /// Label for average latest weight
  ///
  /// In en, this message translates to:
  /// **'Latest weight (avg)'**
  String get latestWeightAvg;

  /// Title for weight development
  ///
  /// In en, this message translates to:
  /// **'Average weight development'**
  String get averageWeightDevelopment;

  /// Description for weight data
  ///
  /// In en, this message translates to:
  /// **'Based on all registered weight measurements'**
  String get basedOnAllWeightMeasurements;

  /// Label for week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// Unit label for grams
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get grams;

  /// Title for birth weight statistics
  ///
  /// In en, this message translates to:
  /// **'Birth weight statistics'**
  String get birthWeightStatistics;

  /// Label for average weight
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get avgWeight;

  /// Label for minimum weight
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minWeight;

  /// Label for maximum weight
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxWeight;

  /// Label for male average
  ///
  /// In en, this message translates to:
  /// **'Males (avg)'**
  String get malesAvg;

  /// Label for female average
  ///
  /// In en, this message translates to:
  /// **'Females (avg)'**
  String get femalesAvg;

  /// Message when no sales data
  ///
  /// In en, this message translates to:
  /// **'No sales data available'**
  String get noSalesData;

  /// Instruction to create contracts
  ///
  /// In en, this message translates to:
  /// **'Create purchase contracts to see economy statistics'**
  String get createContractsForStats;

  /// Tab label for overview
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get showResultsOverview;

  /// Tab label for statistics
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get showResultsStatistics;

  /// Title for exhibition results
  ///
  /// In en, this message translates to:
  /// **'Exhibition results'**
  String get exhibitionResults;

  /// Description for exhibition results
  ///
  /// In en, this message translates to:
  /// **'Here you can register and track all exhibition results for {dogName}.'**
  String exhibitionResultsDesc(String dogName);

  /// Button label to register results
  ///
  /// In en, this message translates to:
  /// **'Register results'**
  String get registerResults;

  /// Description for register results
  ///
  /// In en, this message translates to:
  /// **'Add results from exhibitions'**
  String get registerResultsDesc;

  /// Button label for statistics
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get showStatistics;

  /// Description for show statistics
  ///
  /// In en, this message translates to:
  /// **'See statistics on BIR, BIM, group and BIS results'**
  String get showStatisticsDesc;

  /// Label for critique
  ///
  /// In en, this message translates to:
  /// **'Critique'**
  String get critique;

  /// Description for critique
  ///
  /// In en, this message translates to:
  /// **'Save judge critique for each exhibition'**
  String get critiqueDesc;

  /// Tip for show results
  ///
  /// In en, this message translates to:
  /// **'If the dog wins BIR, you can add group result. If it wins the group (BIG1), you can add BIS result.'**
  String get showResultTip;

  /// Label for results
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// Message when no show results
  ///
  /// In en, this message translates to:
  /// **'No exhibition results yet'**
  String get noShowResults;

  /// Hint in empty tree card slot
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// Message when no statistics
  ///
  /// In en, this message translates to:
  /// **'No statistics available'**
  String get noStatisticsAvailable;

  /// Label for exhibitions
  ///
  /// In en, this message translates to:
  /// **'Exhibitions'**
  String get exhibitions;

  /// Quality grade excellent
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// Quality grade very good
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get veryGood;

  /// Quality grade good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// Quality grade sufficient
  ///
  /// In en, this message translates to:
  /// **'Sufficient'**
  String get sufficient;

  /// Status for disqualified
  ///
  /// In en, this message translates to:
  /// **'Disqualified'**
  String get disqualified;

  /// Status for cannot be judged
  ///
  /// In en, this message translates to:
  /// **'Cannot be judged'**
  String get cannotBeJudged;

  /// No description provided for @classPlacements.
  ///
  /// In en, this message translates to:
  /// **'Class placements'**
  String get classPlacements;

  /// No description provided for @bestMaleDog.
  ///
  /// In en, this message translates to:
  /// **'Best Male (BM)'**
  String get bestMaleDog;

  /// No description provided for @bestFemaleDog.
  ///
  /// In en, this message translates to:
  /// **'Best Female (BF)'**
  String get bestFemaleDog;

  /// Label for breed placements
  ///
  /// In en, this message translates to:
  /// **'BOB/BOS'**
  String get breedPlacements;

  /// Label for group and BIS
  ///
  /// In en, this message translates to:
  /// **'Group & BIS'**
  String get groupAndBIS;

  /// Label for group finals
  ///
  /// In en, this message translates to:
  /// **'Group finals'**
  String get groupFinals;

  /// Label for Best In Show
  ///
  /// In en, this message translates to:
  /// **'Best In Show'**
  String get bestInShow;

  /// Label for certificates count
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificates;

  /// No description provided for @juniorCertificates.
  ///
  /// In en, this message translates to:
  /// **'Junior certificates'**
  String get juniorCertificates;

  /// No description provided for @veteranCertificates.
  ///
  /// In en, this message translates to:
  /// **'Veteran certificates'**
  String get veteranCertificates;

  /// No description provided for @noCertificates.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet'**
  String get noCertificates;

  /// Label for judges
  ///
  /// In en, this message translates to:
  /// **'Judges'**
  String get judges;

  /// Text showing judge count
  ///
  /// In en, this message translates to:
  /// **'{count} judges'**
  String judgesCount(int count);

  /// Link to see all judges
  ///
  /// In en, this message translates to:
  /// **'See all {count} judges'**
  String seeAllJudges(int count);

  /// Singular exhibition count
  ///
  /// In en, this message translates to:
  /// **'{count} exhibition'**
  String exhibitionCount(int count);

  /// Plural exhibitions count
  ///
  /// In en, this message translates to:
  /// **'{count} exhibitions'**
  String exhibitionsCount(int count);

  /// Title for all judges
  ///
  /// In en, this message translates to:
  /// **'All judges'**
  String get allJudges;

  /// Button label to add result
  ///
  /// In en, this message translates to:
  /// **'Add result'**
  String get addResult;

  /// Button label to edit result
  ///
  /// In en, this message translates to:
  /// **'Edit result'**
  String get editResult;

  /// Button label to delete result
  ///
  /// In en, this message translates to:
  /// **'Delete result'**
  String get deleteResult;

  /// Confirmation for deleting result
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the result from {showName}?'**
  String confirmDeleteResult(String showName);

  /// Label for judge
  ///
  /// In en, this message translates to:
  /// **'Judge'**
  String get judge;

  /// Label for result field
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// Label for own notes
  ///
  /// In en, this message translates to:
  /// **'Own notes'**
  String get ownNotes;

  /// Label for judge critique
  ///
  /// In en, this message translates to:
  /// **'Judge critique'**
  String get judgeCritique;

  /// Label for show name
  ///
  /// In en, this message translates to:
  /// **'Show name'**
  String get showName;

  /// Hint for show name field
  ///
  /// In en, this message translates to:
  /// **'e.g. NKK Drammen'**
  String get showNameHint;

  /// Label for show type
  ///
  /// In en, this message translates to:
  /// **'Show type'**
  String get showType;

  /// Label for show class
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get showClass;

  /// Label for quality
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// Label for class placement
  ///
  /// In en, this message translates to:
  /// **'Class placement'**
  String get classPlacement;

  /// Status for unplaced
  ///
  /// In en, this message translates to:
  /// **'Unplaced'**
  String get unplaced;

  /// Label for best of sex
  ///
  /// In en, this message translates to:
  /// **'Best of sex'**
  String get bestOfSex;

  /// Label for group result
  ///
  /// In en, this message translates to:
  /// **'Group result'**
  String get groupResult;

  /// Status for no placement
  ///
  /// In en, this message translates to:
  /// **'No placement'**
  String get noPlacement;

  /// Status for did not participate
  ///
  /// In en, this message translates to:
  /// **'Did not participate / no placement'**
  String get didNotParticipate;

  /// Label for BIS result
  ///
  /// In en, this message translates to:
  /// **'BIS result'**
  String get bisResult;

  /// Validation label for required
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Button label to update
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Show type option
  ///
  /// In en, this message translates to:
  /// **'Puppy show'**
  String get puppyShow;

  /// Show type option
  ///
  /// In en, this message translates to:
  /// **'National'**
  String get national;

  /// Show type option
  ///
  /// In en, this message translates to:
  /// **'Nordic'**
  String get nordic;

  /// Show type option
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get international;

  /// Show type option
  ///
  /// In en, this message translates to:
  /// **'Breed special'**
  String get breedSpecial;

  /// Expense category
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// Expense category
  ///
  /// In en, this message translates to:
  /// **'Veterinary'**
  String get veterinary;

  /// Expense category
  ///
  /// In en, this message translates to:
  /// **'Registration (Kennel Club)'**
  String get registration;

  /// Category option for other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Message when no data
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// Instruction to register weight
  ///
  /// In en, this message translates to:
  /// **'Register weight on puppies to see statistics'**
  String get registerWeightToSeeStats;

  /// Message when no weight data
  ///
  /// In en, this message translates to:
  /// **'No weight data registered yet'**
  String get noWeightDataRegistered;

  /// Instruction to register weight
  ///
  /// In en, this message translates to:
  /// **'Register weight on puppies to compare'**
  String get registerWeightToCompare;

  /// Title for weight comparison
  ///
  /// In en, this message translates to:
  /// **'Weight comparison between litters'**
  String get weightComparisonBetweenLitters;

  /// Label for birth weight average
  ///
  /// In en, this message translates to:
  /// **'Birth weight (avg)'**
  String get birthWeightAverage;

  /// Label for latest weight average
  ///
  /// In en, this message translates to:
  /// **'Latest weight (avg)'**
  String get latestWeightAverage;

  /// Unit label for gram
  ///
  /// In en, this message translates to:
  /// **'Gram'**
  String get gram;

  /// Label for minimum
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// Label for maximum
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// Label for males average
  ///
  /// In en, this message translates to:
  /// **'Males (avg)'**
  String get malesAverage;

  /// Label for females average
  ///
  /// In en, this message translates to:
  /// **'Females (avg)'**
  String get femalesAverage;

  /// Message when no sales data
  ///
  /// In en, this message translates to:
  /// **'No sales data available'**
  String get noSalesDataAvailable;

  /// Instruction to create contracts
  ///
  /// In en, this message translates to:
  /// **'Create purchase contracts to see economy statistics'**
  String get createContractsToSeeStats;

  /// Title for revenue overview
  ///
  /// In en, this message translates to:
  /// **'Revenue overview'**
  String get revenueOverview;

  /// Label for total turnover
  ///
  /// In en, this message translates to:
  /// **'Total turnover'**
  String get totalTurnover;

  /// Status for paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// Status for outstanding
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// Label for total contracts
  ///
  /// In en, this message translates to:
  /// **'contracts total'**
  String get contractsTotal;

  /// Label for revenue per year
  ///
  /// In en, this message translates to:
  /// **'Revenue per year'**
  String get revenuePerYear;

  /// Label for revenue per breed
  ///
  /// In en, this message translates to:
  /// **'Revenue per breed'**
  String get revenuePerBreed;

  /// Title for price statistics
  ///
  /// In en, this message translates to:
  /// **'Price statistics'**
  String get priceStatistics;

  /// Label for average price
  ///
  /// In en, this message translates to:
  /// **'Average price'**
  String get averagePrice;

  /// Label for lowest
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get lowest;

  /// Label for highest
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get highest;

  /// Message when no breeding data
  ///
  /// In en, this message translates to:
  /// **'No breeding data available'**
  String get noBreedingDataAvailable;

  /// Instruction to register litters
  ///
  /// In en, this message translates to:
  /// **'Register litters to see breeding statistics'**
  String get registerLittersToSeeBreedingStats;

  /// Title for parent combinations
  ///
  /// In en, this message translates to:
  /// **'Best parent combinations'**
  String get bestParentCombinations;

  /// Description for sorting
  ///
  /// In en, this message translates to:
  /// **'Sorted by average litter size'**
  String get sortedByAverageLitterSize;

  /// Label for average litter size
  ///
  /// In en, this message translates to:
  /// **'Avg litter size'**
  String get avgLitterSize;

  /// Label for average birth weight
  ///
  /// In en, this message translates to:
  /// **'Avg birth weight'**
  String get avgBirthWeight;

  /// Title for most used breeding dogs
  ///
  /// In en, this message translates to:
  /// **'Most used breeding dogs'**
  String get mostUsedBreedingDogs;

  /// Label for placement rate
  ///
  /// In en, this message translates to:
  /// **'Placement rate'**
  String get placementRate;

  /// Status for sold
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// Status for reserved
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reserved;

  /// Label for CK certificate
  ///
  /// In en, this message translates to:
  /// **'CK (Certificate Quality)'**
  String get ckCertificateQuality;

  /// Label for best male placement
  ///
  /// In en, this message translates to:
  /// **'Best male placement'**
  String get bestMalePlacement;

  /// Label for best female placement
  ///
  /// In en, this message translates to:
  /// **'Best female placement'**
  String get bestFemalePlacement;

  /// Label for group final
  ///
  /// In en, this message translates to:
  /// **'Group final'**
  String get groupFinal;

  /// Title for delete measurement dialog
  ///
  /// In en, this message translates to:
  /// **'Delete measurement?'**
  String get deleteMeasurement;

  /// Confirmation for deleting measurement
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this measurement?'**
  String get confirmDeleteMeasurement;

  /// Title for delete vaccine dialog
  ///
  /// In en, this message translates to:
  /// **'Delete vaccine?'**
  String get deleteVaccine;

  /// Confirmation for deleting vaccine
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDeleteVaccine(String name);

  /// Title for delete vet visit dialog
  ///
  /// In en, this message translates to:
  /// **'Delete vet visit?'**
  String get deleteVetVisit;

  /// Confirmation for deleting vet visit
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this visit?'**
  String get confirmDeleteVetVisit;

  /// Title for delete treatment dialog
  ///
  /// In en, this message translates to:
  /// **'Delete treatment?'**
  String get deleteTreatment;

  /// Confirmation for deleting treatment
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDeleteTreatment(String name);

  /// Title for delete test dialog
  ///
  /// In en, this message translates to:
  /// **'Delete test?'**
  String get deleteTest;

  /// Confirmation for deleting test
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDeleteTest(String name);

  /// Text for reminder setting
  ///
  /// In en, this message translates to:
  /// **'Remind {days} days before'**
  String remindDaysBefore(int days);

  /// Label for follow-up date
  ///
  /// In en, this message translates to:
  /// **'Follow-up date'**
  String get followUpDate;

  /// Label for reminder
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// Text for days before
  ///
  /// In en, this message translates to:
  /// **'{days} days before'**
  String daysBefore(int days);

  /// Validation message for product name
  ///
  /// In en, this message translates to:
  /// **'Product name is required'**
  String get productNameRequired;

  /// Validation message for test name
  ///
  /// In en, this message translates to:
  /// **'Test name is required'**
  String get testNameRequired;

  /// Title for new buyer
  ///
  /// In en, this message translates to:
  /// **'New buyer'**
  String get newBuyer;

  /// Title for edit buyer
  ///
  /// In en, this message translates to:
  /// **'Edit buyer'**
  String get editBuyer;

  /// Title for delete buyer dialog
  ///
  /// In en, this message translates to:
  /// **'Delete buyer?'**
  String get deleteBuyer;

  /// Confirmation for deleting buyer
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDeleteBuyer(String name);

  /// Confirmation for removing reservation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the reservation for this buyer?'**
  String get confirmRemoveReservation;

  /// Instruction to select puppy
  ///
  /// In en, this message translates to:
  /// **'Select a puppy to reserve:'**
  String get selectPuppyToReserve;

  /// Confirmation message for delivery
  ///
  /// In en, this message translates to:
  /// **'Confirm that the puppy has been delivered to the buyer. This will mark the puppy as delivered.'**
  String get confirmDelivery;

  /// Success message when buyer added
  ///
  /// In en, this message translates to:
  /// **'Buyer added'**
  String get buyerAdded;

  /// Success message when buyer updated
  ///
  /// In en, this message translates to:
  /// **'Buyer updated'**
  String get buyerUpdated;

  /// Success message when buyer deleted
  ///
  /// In en, this message translates to:
  /// **'Buyer deleted'**
  String get buyerDeleted;

  /// Instruction to add dogs first
  ///
  /// In en, this message translates to:
  /// **'Add dogs first'**
  String get addDogsFirst;

  /// Instruction to tap for date
  ///
  /// In en, this message translates to:
  /// **'Tap to select date'**
  String get tapToSelectDate;

  /// Instruction to set mating date
  ///
  /// In en, this message translates to:
  /// **'Set mating date first'**
  String get setMatingDateFirst;

  /// Validation message for parents
  ///
  /// In en, this message translates to:
  /// **'Please select both dam and sire'**
  String get pleaseSelectBothParents;

  /// Validation message for mother
  ///
  /// In en, this message translates to:
  /// **'Dam must be a female'**
  String get motherMustBeFemale;

  /// Validation message for father
  ///
  /// In en, this message translates to:
  /// **'Sire must be a male'**
  String get fatherMustBeMale;

  /// Label for birth date field in edit dialog
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDateLabel;

  /// Button label to register birth
  ///
  /// In en, this message translates to:
  /// **'Register birth'**
  String get registerBirth;

  /// Confirmation for litter born
  ///
  /// In en, this message translates to:
  /// **'The litter is now born! Do you want to update the birth date to today?'**
  String get litterBornConfirm;

  /// Success message when birth registered
  ///
  /// In en, this message translates to:
  /// **'Birth registered! You can now add puppies.'**
  String get birthRegistered;

  /// Button label to open temperature log
  ///
  /// In en, this message translates to:
  /// **'Open temperature log'**
  String get openTemperatureLog;

  /// Button label to add measurement
  ///
  /// In en, this message translates to:
  /// **'Add measurement'**
  String get addMeasurement;

  /// Button label to add weight measurement
  ///
  /// In en, this message translates to:
  /// **'Add weight measurement'**
  String get addWeightMeasurement;

  /// Success message when weight added
  ///
  /// In en, this message translates to:
  /// **'Weight measurement added'**
  String get weightMeasurementAdded;

  /// Success message for weight measurements
  ///
  /// In en, this message translates to:
  /// **'{count} weight measurements saved'**
  String weightMeasurementsSaved(int count);

  /// Title for edit weight measurement
  ///
  /// In en, this message translates to:
  /// **'Edit weight measurement'**
  String get editWeightMeasurement;

  /// Success message when weight updated
  ///
  /// In en, this message translates to:
  /// **'Weight measurement updated'**
  String get weightMeasurementUpdated;

  /// Validation message for parents required
  ///
  /// In en, this message translates to:
  /// **'Dam and Sire are required'**
  String get motherAndFatherRequired;

  /// Label for buyer selection
  ///
  /// In en, this message translates to:
  /// **'Select a buyer'**
  String get selectBuyer;

  /// Label for standard terms option
  ///
  /// In en, this message translates to:
  /// **'Use standard terms'**
  String get useStandardTerms;

  /// Label for neutering requirement
  ///
  /// In en, this message translates to:
  /// **'Neutering/spaying required'**
  String get neuteringRequired;

  /// Validation message for export
  ///
  /// In en, this message translates to:
  /// **'Select buyer before export'**
  String get selectBuyerBeforeExport;

  /// Confirmation for deleting contract
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this contract?'**
  String get confirmDeleteContract;

  /// Error when buyer info not found
  ///
  /// In en, this message translates to:
  /// **'Buyer information not found'**
  String get buyerInfoNotFound;

  /// Validation for code length
  ///
  /// In en, this message translates to:
  /// **'Code must be 6 characters'**
  String get codeMustBe6Chars;

  /// Success message when joined kennel
  ///
  /// In en, this message translates to:
  /// **'You have joined the kennel!'**
  String get youJoinedKennel;

  /// Permission description
  ///
  /// In en, this message translates to:
  /// **'Can also invite members'**
  String get canAlsoInviteMembers;

  /// Error when email client fails
  ///
  /// In en, this message translates to:
  /// **'Could not open email client'**
  String get couldNotOpenEmailClient;

  /// Error message for email
  ///
  /// In en, this message translates to:
  /// **'Error opening email: {error}'**
  String errorOpeningEmail(String error);

  /// File size display
  ///
  /// In en, this message translates to:
  /// **'File size: {size} MB'**
  String fileSize(String size);

  /// Confirmation for deleting image
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this image?'**
  String get confirmDeleteImage;

  /// Confirmation for removing user
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this user?'**
  String get confirmRemoveUser;

  /// Success message for temperature
  ///
  /// In en, this message translates to:
  /// **'Temperature measurement registered'**
  String get temperatureMeasurementRegistered;

  /// Title for delete mating dialog
  ///
  /// In en, this message translates to:
  /// **'Delete mating'**
  String get deleteMating;

  /// Confirmation for deleting mating
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this mating?'**
  String get confirmDeleteMating;

  /// Suffix for age in years
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get yearsOld;

  /// Button label to add potential buyers
  ///
  /// In en, this message translates to:
  /// **'Add potential buyers'**
  String get addPotentialBuyers;

  /// Button label to remove reservation
  ///
  /// In en, this message translates to:
  /// **'Remove reservation'**
  String get removeReservation;

  /// Button label to add reservation
  ///
  /// In en, this message translates to:
  /// **'Add reservation'**
  String get addReservation;

  /// Message when no puppies available
  ///
  /// In en, this message translates to:
  /// **'No available puppies in this litter.'**
  String get noAvailablePuppiesInLitter;

  /// Label for puppy selection
  ///
  /// In en, this message translates to:
  /// **'Select puppy'**
  String get selectPuppy;

  /// Success message when reservation added
  ///
  /// In en, this message translates to:
  /// **'Reservation added'**
  String get reservationAdded;

  /// Button label to mark as delivered
  ///
  /// In en, this message translates to:
  /// **'Mark as delivered'**
  String get markAsDelivered;

  /// Success message when puppy delivered
  ///
  /// In en, this message translates to:
  /// **'Puppy marked as delivered!'**
  String get puppyMarkedAsDelivered;

  /// Button label to confirm delivery
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery'**
  String get confirmDeliveryButton;

  /// Label for preferences field
  ///
  /// In en, this message translates to:
  /// **'Preferences (gender/temperament)'**
  String get preferences;

  /// Section title for linking
  ///
  /// In en, this message translates to:
  /// **'Link to litter and puppy'**
  String get linkToLitterAndPuppy;

  /// Label for optional litter selection
  ///
  /// In en, this message translates to:
  /// **'Select litter (optional)'**
  String get selectLitterOptional;

  /// Label for optional puppy selection
  ///
  /// In en, this message translates to:
  /// **'Select puppy (optional)'**
  String get selectPuppyOptional;

  /// Option for none
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Validation message for mating date
  ///
  /// In en, this message translates to:
  /// **'Please enter mating date for planned litter'**
  String get enterMatingDateForPlannedLitter;

  /// Label for historical litter toggle
  ///
  /// In en, this message translates to:
  /// **'Historical litter'**
  String get historicalLitter;

  /// Subtitle when historical litter is enabled
  ///
  /// In en, this message translates to:
  /// **'Registering an older litter from before'**
  String get historicalLitterSubtitle;

  /// Subtitle when registering a new litter
  ///
  /// In en, this message translates to:
  /// **'New litter (last 75 days)'**
  String get newLitterSubtitle;

  /// Label for birth date of historical litter
  ///
  /// In en, this message translates to:
  /// **'Birth date (historical litter)'**
  String get birthDateHistorical;

  /// Section title for puppy identification
  ///
  /// In en, this message translates to:
  /// **'Identification (to distinguish puppies)'**
  String get puppyIdentification;

  /// Label for nickname field
  ///
  /// In en, this message translates to:
  /// **'Nickname / Display name'**
  String get nicknameDisplayName;

  /// Hint text for nickname field
  ///
  /// In en, this message translates to:
  /// **'e.g. \"Blue ribbon\", \"Little one\"'**
  String get nicknameHint;

  /// Label for color code selection
  ///
  /// In en, this message translates to:
  /// **'Color code (band/mark)'**
  String get colorCodeBandMark;

  /// Label when something is selected
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// Label for puppy name field
  ///
  /// In en, this message translates to:
  /// **'Puppy name'**
  String get puppyName;

  /// Validation message for name field
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// Label for country field
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// Helper text when CK system is available
  ///
  /// In en, this message translates to:
  /// **'The CK system is available'**
  String get ckSystemAvailable;

  /// Helper text when CK is not available
  ///
  /// In en, this message translates to:
  /// **'CK is only available in Nordic countries'**
  String get ckOnlyNordic;

  /// Helper text for BIR/BIM requirements
  ///
  /// In en, this message translates to:
  /// **'Requires 1st BHK or 1st BTK to select BIR/BIM'**
  String get requiresBHKBTK;

  /// Label for dam selection
  ///
  /// In en, this message translates to:
  /// **'Select dam'**
  String get selectDam;

  /// Label for sire selection
  ///
  /// In en, this message translates to:
  /// **'Select sire'**
  String get selectSire;

  /// Label for common DNA tests section
  ///
  /// In en, this message translates to:
  /// **'Common tests'**
  String get commonTests;

  /// Label for test name field
  ///
  /// In en, this message translates to:
  /// **'Test name'**
  String get testName;

  /// Label for test date field
  ///
  /// In en, this message translates to:
  /// **'Test date'**
  String get testDate;

  /// Label for laboratory field
  ///
  /// In en, this message translates to:
  /// **'Laboratory'**
  String get laboratory;

  /// Label for certificate number field
  ///
  /// In en, this message translates to:
  /// **'Certificate number'**
  String get certificateNumber;

  /// Status for pending DNA test result
  ///
  /// In en, this message translates to:
  /// **'Pending result'**
  String get pendingResult;

  /// DNA test result - carrier
  ///
  /// In en, this message translates to:
  /// **'Carrier'**
  String get carrier;

  /// DNA test result - affected
  ///
  /// In en, this message translates to:
  /// **'Affected'**
  String get affected;

  /// Placeholder text for search field
  ///
  /// In en, this message translates to:
  /// **'Search for dogs, litters, buyers...'**
  String get searchDogsLittersBuyers;

  /// Description for dark mode section
  ///
  /// In en, this message translates to:
  /// **'Adjust the appearance for your eyes'**
  String get darkModeDescription;

  /// Label for system theme toggle
  ///
  /// In en, this message translates to:
  /// **'Use System Theme'**
  String get useSystemTheme;

  /// Description for system theme toggle
  ///
  /// In en, this message translates to:
  /// **'App follows your device theme automatically'**
  String get useSystemThemeDescription;

  /// Label when dark mode is on
  ///
  /// In en, this message translates to:
  /// **'Dark mode enabled'**
  String get darkModeOn;

  /// Label when dark mode is off
  ///
  /// In en, this message translates to:
  /// **'Light mode enabled'**
  String get darkModeOff;

  /// Title for puppy delivery checklist
  ///
  /// In en, this message translates to:
  /// **'Delivery Checklist'**
  String get deliveryChecklist;

  /// Button to set delivery date
  ///
  /// In en, this message translates to:
  /// **'Set Delivery Date'**
  String get setDeliveryDate;

  /// Error message when checklist fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load checklist'**
  String get errorLoadingChecklist;

  /// Label for delivery date
  ///
  /// In en, this message translates to:
  /// **'Delivery Date'**
  String get deliveryDate;

  /// Label for progress indicator
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Button to add checklist item
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// Label for title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Message when delivery date is set
  ///
  /// In en, this message translates to:
  /// **'Delivery date set'**
  String get deliveryDateSet;

  /// Title for annual report
  ///
  /// In en, this message translates to:
  /// **'Annual Report'**
  String get annualReport;

  /// Label for year selector
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get selectYear;

  /// Title for annual summary section
  ///
  /// In en, this message translates to:
  /// **'Annual Summary'**
  String get annualSummary;

  /// Label for litters count
  ///
  /// In en, this message translates to:
  /// **'Litters Registered'**
  String get littersRegistered;

  /// Label for puppies born count
  ///
  /// In en, this message translates to:
  /// **'Puppies Born'**
  String get puppiesBorn;

  /// Label for male puppies count
  ///
  /// In en, this message translates to:
  /// **'Male Puppies'**
  String get malePuppies;

  /// Label for female puppies count
  ///
  /// In en, this message translates to:
  /// **'Female Puppies'**
  String get femalePuppies;

  /// Label for puppies sold count
  ///
  /// In en, this message translates to:
  /// **'Puppies Sold'**
  String get puppiesSold;

  /// Title for financial summary section
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get financialSummary;

  /// Label for total expenses
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// Label for shows count
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get shows;

  /// Button to generate PDF report
  ///
  /// In en, this message translates to:
  /// **'Generate PDF Report'**
  String get generatePdfReport;

  /// Loading text while generating
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// Information about the report contents
  ///
  /// In en, this message translates to:
  /// **'The report includes all litters, puppies, finances and show results for the selected year.'**
  String get reportInfo;

  /// No description provided for @contractTypes.
  ///
  /// In en, this message translates to:
  /// **'Contract Types'**
  String get contractTypes;

  /// No description provided for @selectContractType.
  ///
  /// In en, this message translates to:
  /// **'Select Contract Type'**
  String get selectContractType;

  /// No description provided for @purchaseContract.
  ///
  /// In en, this message translates to:
  /// **'Purchase Contract'**
  String get purchaseContract;

  /// No description provided for @purchaseContractDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard contract for puppy sales'**
  String get purchaseContractDesc;

  /// No description provided for @breedingContract.
  ///
  /// In en, this message translates to:
  /// **'Breeding Contract'**
  String get breedingContract;

  /// No description provided for @breedingContractDesc.
  ///
  /// In en, this message translates to:
  /// **'Agreement for mating between stud and dam'**
  String get breedingContractDesc;

  /// No description provided for @coOwnershipContract.
  ///
  /// In en, this message translates to:
  /// **'Co-Ownership Agreement'**
  String get coOwnershipContract;

  /// No description provided for @coOwnershipContractDesc.
  ///
  /// In en, this message translates to:
  /// **'Agreement for shared ownership of a dog'**
  String get coOwnershipContractDesc;

  /// No description provided for @fosterContract.
  ///
  /// In en, this message translates to:
  /// **'Foster Agreement'**
  String get fosterContract;

  /// No description provided for @fosterContractDesc.
  ///
  /// In en, this message translates to:
  /// **'Agreement for placing a dog with a foster family'**
  String get fosterContractDesc;

  /// No description provided for @reservationContract.
  ///
  /// In en, this message translates to:
  /// **'Reservation Agreement'**
  String get reservationContract;

  /// No description provided for @reservationContractDesc.
  ///
  /// In en, this message translates to:
  /// **'Agreement for reserving a puppy'**
  String get reservationContractDesc;

  /// No description provided for @studOwner.
  ///
  /// In en, this message translates to:
  /// **'Stud Owner'**
  String get studOwner;

  /// No description provided for @damOwner.
  ///
  /// In en, this message translates to:
  /// **'Dam Owner'**
  String get damOwner;

  /// No description provided for @studFee.
  ///
  /// In en, this message translates to:
  /// **'Stud Fee'**
  String get studFee;

  /// No description provided for @paymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms'**
  String get paymentTerms;

  /// No description provided for @owner1.
  ///
  /// In en, this message translates to:
  /// **'Owner 1'**
  String get owner1;

  /// No description provided for @owner2.
  ///
  /// In en, this message translates to:
  /// **'Owner 2'**
  String get owner2;

  /// No description provided for @ownershipPercentage.
  ///
  /// In en, this message translates to:
  /// **'Ownership Percentage (%)'**
  String get ownershipPercentage;

  /// No description provided for @primaryCaretaker.
  ///
  /// In en, this message translates to:
  /// **'Primary Caretaker'**
  String get primaryCaretaker;

  /// No description provided for @breedingRights.
  ///
  /// In en, this message translates to:
  /// **'Breeding Rights'**
  String get breedingRights;

  /// No description provided for @showRights.
  ///
  /// In en, this message translates to:
  /// **'Show Rights'**
  String get showRights;

  /// No description provided for @expenseSharing.
  ///
  /// In en, this message translates to:
  /// **'Expense Sharing'**
  String get expenseSharing;

  /// No description provided for @fosterParent.
  ///
  /// In en, this message translates to:
  /// **'Foster Parent'**
  String get fosterParent;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @returnConditions.
  ///
  /// In en, this message translates to:
  /// **'Return Conditions'**
  String get returnConditions;

  /// No description provided for @reservationFee.
  ///
  /// In en, this message translates to:
  /// **'Reservation Fee'**
  String get reservationFee;

  /// No description provided for @additionalTerms.
  ///
  /// In en, this message translates to:
  /// **'Additional Terms'**
  String get additionalTerms;

  /// No description provided for @waitlist.
  ///
  /// In en, this message translates to:
  /// **'Waitlist'**
  String get waitlist;

  /// No description provided for @waitlistPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get waitlistPosition;

  /// No description provided for @waitlistDate.
  ///
  /// In en, this message translates to:
  /// **'Date Registered'**
  String get waitlistDate;

  /// No description provided for @waitlistStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get waitlistStatus;

  /// No description provided for @preferredGender.
  ///
  /// In en, this message translates to:
  /// **'Preferred Gender'**
  String get preferredGender;

  /// No description provided for @preferredColor.
  ///
  /// In en, this message translates to:
  /// **'Preferred Color'**
  String get preferredColor;

  /// No description provided for @depositAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositAmount;

  /// No description provided for @noPreference.
  ///
  /// In en, this message translates to:
  /// **'No Preference'**
  String get noPreference;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @contacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get contacted;

  /// No description provided for @purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchased;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @addToWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Add to Waitlist'**
  String get addToWaitlist;

  /// No description provided for @removeFromWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from Waitlist'**
  String get removeFromWaitlist;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get moveDown;

  /// No description provided for @waitlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one on the waitlist'**
  String get waitlistEmpty;

  /// No description provided for @waitlistInfo.
  ///
  /// In en, this message translates to:
  /// **'Manage interested buyers and their position on the waitlist'**
  String get waitlistInfo;

  /// Waitlist position display
  ///
  /// In en, this message translates to:
  /// **'Position #{position}'**
  String position(Object position);

  /// No description provided for @addedToWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Added to waitlist'**
  String get addedToWaitlist;

  /// No description provided for @removedFromWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from waitlist'**
  String get removedFromWaitlist;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @expectedBirth.
  ///
  /// In en, this message translates to:
  /// **'Expected Birth'**
  String get expectedBirth;

  /// No description provided for @treatments.
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get treatments;

  /// No description provided for @birthdays.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get birthdays;

  /// Tag shown for planned litters
  ///
  /// In en, this message translates to:
  /// **'[Planned litter]'**
  String get plannedLitterTag;

  /// Snackbar when planned litter is saved
  ///
  /// In en, this message translates to:
  /// **'Planned litter created'**
  String get plannedLitterCreated;

  /// Snackbar when litter is added
  ///
  /// In en, this message translates to:
  /// **'Litter added'**
  String get litterAdded;

  /// Default puppy name for male
  ///
  /// In en, this message translates to:
  /// **'Male {number}'**
  String maleNumberTemplate(int number);

  /// Default puppy name for female
  ///
  /// In en, this message translates to:
  /// **'Female {number}'**
  String femaleNumberTemplate(int number);

  /// Title for planning litter mode
  ///
  /// In en, this message translates to:
  /// **'Plan litter'**
  String get planLitter;

  /// Subtitle for plan litter mode
  ///
  /// In en, this message translates to:
  /// **'Planning a future litter'**
  String get planningFutureLitter;

  /// Subtitle for registering born litter
  ///
  /// In en, this message translates to:
  /// **'Registering a born litter'**
  String get registeringBornLitter;

  /// Label for planning mode toggle
  ///
  /// In en, this message translates to:
  /// **'Planning mode'**
  String get planningMode;

  /// Description when planning mode is on
  ///
  /// In en, this message translates to:
  /// **'The litter is not born yet — you are planning ahead'**
  String get planningModeDescription;

  /// Description when planning mode is off
  ///
  /// In en, this message translates to:
  /// **'The litter is already born — you are registering data'**
  String get registeringModeDescription;

  /// Subtitle for historical litter
  ///
  /// In en, this message translates to:
  /// **'Register a previous litter'**
  String get registerPreviousLitter;

  /// Button to add a new female dog
  ///
  /// In en, this message translates to:
  /// **'Add new female'**
  String get addNewFemale;

  /// Button to add a new male dog
  ///
  /// In en, this message translates to:
  /// **'Add new male'**
  String get addNewMale;

  /// Validation message for dam
  ///
  /// In en, this message translates to:
  /// **'Please select a dam'**
  String get pleaseSelectDam;

  /// Validation message for sire
  ///
  /// In en, this message translates to:
  /// **'Please select a sire'**
  String get pleaseSelectSire;

  /// Info text about automatic date
  ///
  /// In en, this message translates to:
  /// **'Date will be set when first mating is completed'**
  String get dateSetWhenMatingCompleted;

  /// Label for mating date field
  ///
  /// In en, this message translates to:
  /// **'Mating date'**
  String get matingDate;

  /// Tooltip for removing mating date
  ///
  /// In en, this message translates to:
  /// **'Remove mating date'**
  String get removeMatingDate;

  /// Label for estimated due date
  ///
  /// In en, this message translates to:
  /// **'Estimated due date'**
  String get estimatedDueDate;

  /// Label for progesterone section
  ///
  /// In en, this message translates to:
  /// **'Progesterone measurements'**
  String get progesteroneMeasurements;

  /// Subtitle for progesterone section
  ///
  /// In en, this message translates to:
  /// **'View and record measurements for optimal mating'**
  String get progesteroneMeasurementsSubtitle;

  /// Subtitle for breeding contract section
  ///
  /// In en, this message translates to:
  /// **'Create contract between dam and sire owners'**
  String get breedingContractSubtitle;

  /// Label for expected puppy count
  ///
  /// In en, this message translates to:
  /// **'Number of puppies (expected)'**
  String get numberOfPuppiesExpected;

  /// Label for male puppy count
  ///
  /// In en, this message translates to:
  /// **'Number of males'**
  String get numberOfMales;

  /// Label for female puppy count
  ///
  /// In en, this message translates to:
  /// **'Number of females'**
  String get numberOfFemales;

  /// Button to save a planned litter
  ///
  /// In en, this message translates to:
  /// **'Save planned litter'**
  String get savePlannedLitter;

  /// Button to save a litter
  ///
  /// In en, this message translates to:
  /// **'Save litter'**
  String get saveLitter;

  /// Validation message for breed
  ///
  /// In en, this message translates to:
  /// **'Please select a breed'**
  String get pleaseSelectBreed;

  /// Toggle text when showing all breeds
  ///
  /// In en, this message translates to:
  /// **'Showing all breeds'**
  String get showingAllBreeds;

  /// Toggle text when showing kennel breeds
  ///
  /// In en, this message translates to:
  /// **'Showing kennel breeds'**
  String get showingKennelBreeds;

  /// Info tip for breed setup
  ///
  /// In en, this message translates to:
  /// **'Tip: Set up your breeds'**
  String get tipSetUpBreeds;

  /// Info body for breed setup
  ///
  /// In en, this message translates to:
  /// **'Add breeds to kennel profile for faster selection.'**
  String get addBreedsToKennelInfo;

  /// Button to navigate to kennel profile
  ///
  /// In en, this message translates to:
  /// **'Go to kennel profile'**
  String get goToKennelProfile;

  /// Toggle for kennel breeds
  ///
  /// In en, this message translates to:
  /// **'Show only kennel breeds'**
  String get showOnlyKennelBreeds;

  /// Toggle for all breeds
  ///
  /// In en, this message translates to:
  /// **'Show all breeds'**
  String get showAllBreeds;

  /// Empty state for breed search
  ///
  /// In en, this message translates to:
  /// **'No breeds found for \"{query}\"'**
  String noBreedsFoundForQuery(String query);

  /// Validation for temperature input
  ///
  /// In en, this message translates to:
  /// **'Please enter temperature'**
  String get pleaseEnterTemperature;

  /// Snackbar when temperature saved
  ///
  /// In en, this message translates to:
  /// **'Temperature recorded'**
  String get temperatureRecorded;

  /// Error for invalid temperature
  ///
  /// In en, this message translates to:
  /// **'Invalid temperature value'**
  String get invalidTemperatureValue;

  /// Title for temperature tracking screen
  ///
  /// In en, this message translates to:
  /// **'Temperature tracking'**
  String get temperatureTracking;

  /// Section for planning info
  ///
  /// In en, this message translates to:
  /// **'Planning information'**
  String get planningInformation;

  /// Label for whelping countdown
  ///
  /// In en, this message translates to:
  /// **'Days until whelping:'**
  String get daysUntilWhelping;

  /// Section for temp history
  ///
  /// In en, this message translates to:
  /// **'Temperature history'**
  String get temperatureHistory;

  /// Empty state for graph
  ///
  /// In en, this message translates to:
  /// **'No data to show graph'**
  String get noDataToShowGraph;

  /// Dialog title for adding temp
  ///
  /// In en, this message translates to:
  /// **'Add temperature reading'**
  String get addTemperatureReading;

  /// Label for date/time field
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// Label for temp in Celsius
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get temperatureCelsius;

  /// Label for optional notes
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// Empty state for temp list
  ///
  /// In en, this message translates to:
  /// **'No temperature readings recorded'**
  String get noTemperatureReadings;

  /// Section for measurements
  ///
  /// In en, this message translates to:
  /// **'Measurements overview'**
  String get measurementsOverview;

  /// Error loading users
  ///
  /// In en, this message translates to:
  /// **'Error loading shared users: {error}'**
  String errorLoadingSharedUsers(Object error);

  /// Email validation
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address'**
  String get pleaseEnterEmail;

  /// Share confirmation
  ///
  /// In en, this message translates to:
  /// **'Shared with {email}'**
  String sharedWithEmail(String email);

  /// User not found error
  ///
  /// In en, this message translates to:
  /// **'User with email {email} not found'**
  String userNotFoundByEmail(String email);

  /// Sharing error
  ///
  /// In en, this message translates to:
  /// **'Error sharing: {error}'**
  String errorSharing(Object error);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove user'**
  String get removeUser;

  /// Snackbar after removal
  ///
  /// In en, this message translates to:
  /// **'User removed'**
  String get userRemoved;

  /// Removal error
  ///
  /// In en, this message translates to:
  /// **'Error removing user: {error}'**
  String errorRemovingUser(Object error);

  /// Share screen title
  ///
  /// In en, this message translates to:
  /// **'Share {groupName}'**
  String shareGroupName(String groupName);

  /// Share subtitle
  ///
  /// In en, this message translates to:
  /// **'Share with collaborator'**
  String get shareWithCollaborator;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Shared with'**
  String get sharedWith;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'Not shared with anyone yet'**
  String get notSharedWithAnyone;

  /// Role label
  ///
  /// In en, this message translates to:
  /// **'Collaborator'**
  String get collaborator;

  /// COI requirement message
  ///
  /// In en, this message translates to:
  /// **'Select both dam and sire to calculate inbreeding coefficient'**
  String get selectBothForInbreeding;

  /// COI title
  ///
  /// In en, this message translates to:
  /// **'Inbreeding coefficient (COI)'**
  String get inbreedingCoefficientCoi;

  /// Common ancestors count
  ///
  /// In en, this message translates to:
  /// **'Common ancestors ({count})'**
  String commonAncestors(int count);

  /// Button to see all
  ///
  /// In en, this message translates to:
  /// **'See all {count} ancestors'**
  String seeAllAncestors(int count);

  /// Button for explanation
  ///
  /// In en, this message translates to:
  /// **'What does this mean?'**
  String get whatDoesThisMean;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'About inbreeding coefficient'**
  String get aboutInbreedingCoefficient;

  /// COI explanation
  ///
  /// In en, this message translates to:
  /// **'The inbreeding coefficient (COI) measures the probability that two alleles at the same locus are identical because they descend from the same ancestor.'**
  String get inbreedingDescription;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Recommended levels:'**
  String get recommendedLevels;

  /// Level label
  ///
  /// In en, this message translates to:
  /// **'Very low'**
  String get veryLow;

  /// Level label
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// Level label
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// Level label
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// Level label
  ///
  /// In en, this message translates to:
  /// **'Very high'**
  String get veryHigh;

  /// Consequences subtitle
  ///
  /// In en, this message translates to:
  /// **'High inbreeding can lead to:'**
  String get highInbreedingConsequences;

  /// Consequence
  ///
  /// In en, this message translates to:
  /// **'Reduced immune system'**
  String get reducedImmuneSystem;

  /// Consequence
  ///
  /// In en, this message translates to:
  /// **'Reduced fertility'**
  String get reducedFertility;

  /// Consequence
  ///
  /// In en, this message translates to:
  /// **'Increased risk of hereditary diseases'**
  String get increasedRiskOfDisease;

  /// Consequence
  ///
  /// In en, this message translates to:
  /// **'Shorter lifespan'**
  String get shorterLifespan;

  /// Tips section
  ///
  /// In en, this message translates to:
  /// **'Tips:'**
  String get tipsCoi;

  /// Tip
  ///
  /// In en, this message translates to:
  /// **'Register ancestors with registration numbers for accurate calculation'**
  String get tipRegisterAncestors;

  /// Tip
  ///
  /// In en, this message translates to:
  /// **'The system recognizes the same dog even if registered multiple times'**
  String get tipSystemRecognizes;

  /// Tip
  ///
  /// In en, this message translates to:
  /// **'COI is calculated over 5 generations'**
  String get tipCoiGenerations;

  /// Generation depth
  ///
  /// In en, this message translates to:
  /// **'{genMother} gen. from dam, {genFather} gen. from sire'**
  String generationsFromParents(int genMother, int genFather);

  /// Comparison title
  ///
  /// In en, this message translates to:
  /// **'Compare mating options'**
  String get compareMatingOptions;

  /// Label for female selection
  ///
  /// In en, this message translates to:
  /// **'Select female'**
  String get selectFemale;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Dog not found'**
  String get dogNotFound;

  /// Male gender display
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get maleDog;

  /// Born label
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get born;

  /// Visibility toggle
  ///
  /// In en, this message translates to:
  /// **'Pedigree only'**
  String get pedigreeOnly;

  /// Visibility toggle
  ///
  /// In en, this message translates to:
  /// **'Visible in dog list'**
  String get visibleInDogList;

  /// Pedigree-only description
  ///
  /// In en, this message translates to:
  /// **'This dog is only shown in pedigrees'**
  String get pedigreeOnlyDescription;

  /// Visible description
  ///
  /// In en, this message translates to:
  /// **'This dog is shown in your dog list'**
  String get visibleInDogListDescription;

  /// PDF filename
  ///
  /// In en, this message translates to:
  /// **'Pedigree_{name}.pdf'**
  String pedigreeFilename(String name);

  /// PDF error
  ///
  /// In en, this message translates to:
  /// **'Could not generate PDF: {error}'**
  String couldNotGeneratePdf(Object error);

  /// Pedigree title
  ///
  /// In en, this message translates to:
  /// **'Pedigree — {name}'**
  String pedigreeTitle(String name);

  /// Export button
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'About the pedigree'**
  String get aboutPedigree;

  /// Tip
  ///
  /// In en, this message translates to:
  /// **'Tap a dog for details'**
  String get pedigreeTipTapDetails;

  /// Legend
  ///
  /// In en, this message translates to:
  /// **'Pink = females'**
  String get pedigreeTipPinkFemales;

  /// Legend
  ///
  /// In en, this message translates to:
  /// **'Blue = males'**
  String get pedigreeTipBlueMales;

  /// Tip
  ///
  /// In en, this message translates to:
  /// **'Scroll to see all generations'**
  String get pedigreeTipScroll;

  /// Short add button
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get addNewMaleShort;

  /// Message when no image was selected for scanning
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// Error when pedigree scanning fails
  ///
  /// In en, this message translates to:
  /// **'Could not read the pedigree'**
  String get couldNotReadPedigree;

  /// Title for pedigree scanner section
  ///
  /// In en, this message translates to:
  /// **'Scan pedigree'**
  String get scanPedigree;

  /// Subtitle for pedigree scanner section
  ///
  /// In en, this message translates to:
  /// **'Take a photo or upload a pedigree for automatic data entry'**
  String get scanPedigreeSubtitle;

  /// Loading text while image is being processed
  ///
  /// In en, this message translates to:
  /// **'Processing image...'**
  String get processingImage;

  /// Button label for camera capture
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// Button label for gallery image selection
  ///
  /// In en, this message translates to:
  /// **'Select image'**
  String get selectImage;

  /// Title for scanning tips section
  ///
  /// In en, this message translates to:
  /// **'Tips for best results'**
  String get tipsForBestResults;

  /// Scanning tip
  ///
  /// In en, this message translates to:
  /// **'Ensure good lighting'**
  String get tipGoodLighting;

  /// Scanning tip
  ///
  /// In en, this message translates to:
  /// **'Hold the camera directly over the document'**
  String get tipHoldCameraOver;

  /// Scanning tip
  ///
  /// In en, this message translates to:
  /// **'Avoid shadows and reflections'**
  String get tipAvoidShadows;

  /// Scanning tip
  ///
  /// In en, this message translates to:
  /// **'The pedigree must be clear and readable'**
  String get tipPedigreeReadable;

  /// Scanning tip
  ///
  /// In en, this message translates to:
  /// **'You can always edit the data after scanning'**
  String get tipEditAfterScanning;

  /// AppBar title for scan review screen
  ///
  /// In en, this message translates to:
  /// **'Review scanned data'**
  String get reviewScannedData;

  /// Tooltip for list view toggle
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// Tooltip for tree view toggle
  ///
  /// In en, this message translates to:
  /// **'Tree view'**
  String get treeView;

  /// Title for scanner settings screen
  ///
  /// In en, this message translates to:
  /// **'Scanner settings'**
  String get scannerSettings;

  /// Tooltip for OCR text toggle
  ///
  /// In en, this message translates to:
  /// **'Show raw OCR text'**
  String get showRawOcrText;

  /// Tooltip for confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm data'**
  String get confirmData;

  /// Scan accuracy display
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {accuracy}'**
  String accuracyPercent(String accuracy);

  /// Summary of scanned dogs
  ///
  /// In en, this message translates to:
  /// **'{count} dogs found — tap ✏️ to edit'**
  String dogsFoundTapToEdit(int count);

  /// Title for raw OCR text section
  ///
  /// In en, this message translates to:
  /// **'Raw OCR text (what the scanner found)'**
  String get rawOcrTextTitle;

  /// Empty state for scan results
  ///
  /// In en, this message translates to:
  /// **'No dogs found in the scan'**
  String get noDogsFoundInScan;

  /// Hint when no dogs found
  ///
  /// In en, this message translates to:
  /// **'Tap + to add manually, or\ncheck raw OCR text to see what the scanner found'**
  String get tapToAddManually;

  /// Info banner in list view
  ///
  /// In en, this message translates to:
  /// **'All fields are editable. Tap ?? to change data.'**
  String get allFieldsEditable;

  /// Label for registration number with colon
  ///
  /// In en, this message translates to:
  /// **'Reg. no.:'**
  String get regNoLabel;

  /// Label for birth date with colon
  ///
  /// In en, this message translates to:
  /// **'Born:'**
  String get bornLabel;

  /// Confidence display for scanned dog
  ///
  /// In en, this message translates to:
  /// **'Confidence: {confidence}'**
  String confidencePercent(String confidence);

  /// Position label for main dog in pedigree
  ///
  /// In en, this message translates to:
  /// **'Main dog'**
  String get mainDog;

  /// Position label for father in pedigree
  ///
  /// In en, this message translates to:
  /// **'Sire'**
  String get sire;

  /// Position label for mother in pedigree
  ///
  /// In en, this message translates to:
  /// **'Dam'**
  String get dam;

  /// Position label
  ///
  /// In en, this message translates to:
  /// **'Paternal grandfather'**
  String get paternalGrandfather;

  /// Position label
  ///
  /// In en, this message translates to:
  /// **'Paternal grandmother'**
  String get paternalGrandmother;

  /// Position label
  ///
  /// In en, this message translates to:
  /// **'Maternal grandfather'**
  String get maternalGrandfather;

  /// Position label
  ///
  /// In en, this message translates to:
  /// **'Maternal grandmother'**
  String get maternalGrandmother;

  /// Position label for paternal grandfather's sire
  ///
  /// In en, this message translates to:
  /// **'Pat. great-grandsire'**
  String get greatGrandsirePP;

  /// Position label for paternal grandfather's dam
  ///
  /// In en, this message translates to:
  /// **'Pat. great-grandam'**
  String get greatGrandamPP;

  /// Position label for paternal grandmother's sire
  ///
  /// In en, this message translates to:
  /// **'Pat. great-grandsire (m)'**
  String get greatGrandsirePM;

  /// Position label for paternal grandmother's dam
  ///
  /// In en, this message translates to:
  /// **'Pat. great-grandam (m)'**
  String get greatGrandamPM;

  /// Position label for maternal grandfather's sire
  ///
  /// In en, this message translates to:
  /// **'Mat. great-grandsire'**
  String get greatGrandsireMP;

  /// Position label for maternal grandfather's dam
  ///
  /// In en, this message translates to:
  /// **'Mat. great-grandam'**
  String get greatGrandamMP;

  /// Position label for maternal grandmother's sire
  ///
  /// In en, this message translates to:
  /// **'Mat. great-grandsire (m)'**
  String get greatGrandsireMM;

  /// Position label for maternal grandmother's dam
  ///
  /// In en, this message translates to:
  /// **'Mat. great-grandam (m)'**
  String get greatGrandamMM;

  /// Title for edit dog dialog
  ///
  /// In en, this message translates to:
  /// **'Edit dog'**
  String get editDog;

  /// Label for registration number field
  ///
  /// In en, this message translates to:
  /// **'Reg. no.'**
  String get regNo;

  /// Hint text for registration number
  ///
  /// In en, this message translates to:
  /// **'e.g. NO12345/2020'**
  String get regNoHint;

  /// Hint for date format
  ///
  /// In en, this message translates to:
  /// **'dd.mm.yyyy'**
  String get dateFormatHint;

  /// Label for position dropdown
  ///
  /// In en, this message translates to:
  /// **'Position in pedigree'**
  String get positionInPedigree;

  /// Snackbar message when settings are saved
  ///
  /// In en, this message translates to:
  /// **'Settings saved!'**
  String get settingsSaved;

  /// Scanner engine name
  ///
  /// In en, this message translates to:
  /// **'Gemini AI Vision'**
  String get geminiAiVision;

  /// Badge label for cloud scanner
  ///
  /// In en, this message translates to:
  /// **'Cloud-powered'**
  String get cloudPowered;

  /// Description of Gemini AI scanner
  ///
  /// In en, this message translates to:
  /// **'The scanner uses Gemini AI Vision via a secure cloud service. No API key is needed — just sign in and scan!'**
  String get scannerGeminiDescription;

  /// Title for scanner customization section
  ///
  /// In en, this message translates to:
  /// **'Customize scanner'**
  String get customizeScanner;

  /// Description for keyword customization
  ///
  /// In en, this message translates to:
  /// **'Add keywords for the scanner to look for in pedigree documents. The scanner uses these words to identify which dog is the main dog, sire, and dam.\n\nExample: If your pedigree has \"Object:\" before the main dog, add \"object:\" as a keyword for the main dog.'**
  String get addKeywordsDescription;

  /// Title for main dog keyword section
  ///
  /// In en, this message translates to:
  /// **'Main dog keywords'**
  String get mainDogKeywords;

  /// Subtitle for main dog keywords
  ///
  /// In en, this message translates to:
  /// **'Words that identify the main dog in the pedigree'**
  String get wordsIdentifyMainDog;

  /// Title for sire keyword section
  ///
  /// In en, this message translates to:
  /// **'Sire keywords'**
  String get sireKeywords;

  /// Subtitle for sire keywords
  ///
  /// In en, this message translates to:
  /// **'Words that identify the sire/male'**
  String get wordsIdentifySire;

  /// Title for dam keyword section
  ///
  /// In en, this message translates to:
  /// **'Dam keywords'**
  String get damKeywords;

  /// Subtitle for dam keywords
  ///
  /// In en, this message translates to:
  /// **'Words that identify the dam/female'**
  String get wordsIdentifyDam;

  /// Title for automatic learning section
  ///
  /// In en, this message translates to:
  /// **'Automatic learning'**
  String get automaticLearning;

  /// Description of automatic learning feature
  ///
  /// In en, this message translates to:
  /// **'The scanner learns automatically when you correct data:\n• If you change position (e.g. Sire → Main dog), it remembers\n• Next time similar patterns are recognized\n• The scanner also uses position in the image (top = main dog)'**
  String get automaticLearningDescription;

  /// Button label to reset learning data
  ///
  /// In en, this message translates to:
  /// **'Reset learning data'**
  String get resetLearningData;

  /// Label for custom keywords section
  ///
  /// In en, this message translates to:
  /// **'Your custom keywords:'**
  String get yourCustomKeywords;

  /// Dialog title for reset confirmation
  ///
  /// In en, this message translates to:
  /// **'Reset learning data?'**
  String get resetLearningDataTitle;

  /// Dialog body for reset confirmation
  ///
  /// In en, this message translates to:
  /// **'This will delete all saved corrections. The scanner will start fresh without previous learning.'**
  String get resetLearningDataBody;

  /// Button label for reset action
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAction;

  /// Snackbar message after learning data reset
  ///
  /// In en, this message translates to:
  /// **'Learning data reset'**
  String get learningDataReset;

  /// Hint text for keyword input field
  ///
  /// In en, this message translates to:
  /// **'New keyword...'**
  String get newKeywordHint;

  /// FAB label for adding a dog
  ///
  /// In en, this message translates to:
  /// **'Add dog'**
  String get addDogLabel;
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
      <String>['da', 'en', 'fi', 'no', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
    case 'fi':
      return AppLocalizationsFi();
    case 'no':
      return AppLocalizationsNo();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
