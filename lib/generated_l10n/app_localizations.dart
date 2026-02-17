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

  /// Hint for breed search field
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

  /// Label for action cards section on dashboard
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get attentionNeeded;

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

  /// Filter label for mating window events
  ///
  /// In en, this message translates to:
  /// **'Mating windows'**
  String get matingWindows;

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

  /// Button to change member role
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

  /// Button to invite a member
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get inviteMember;

  /// Button label to create invite code
  ///
  /// In en, this message translates to:
  /// **'Create invite code'**
  String get createInviteCode;

  /// Button to create a new kennel
  ///
  /// In en, this message translates to:
  /// **'Create new kennel'**
  String get createNewKennel;

  /// Button label to join with code
  ///
  /// In en, this message translates to:
  /// **'Use invite code'**
  String get joinWithCode;

  /// Button to leave a kennel
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

  /// Error message when not logged in
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

  /// Confirmation for deleting measurement
  ///
  /// In en, this message translates to:
  /// **'Delete measurement?'**
  String get deleteMeasurement;

  /// Confirmation for deleting measurement
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this measurement?'**
  String get confirmDeleteMeasurement;

  /// Confirmation for deleting vaccine
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

  /// Validation for test name
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

  /// Label for birth date
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
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

  /// Button to add measurement
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

  /// Validation for invitation code length
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

  /// Error when opening email
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

  /// Button to delete mating
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

  /// Label for common tests
  ///
  /// In en, this message translates to:
  /// **'Common tests:'**
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

  /// Section title for progesterone
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

  /// Label for date and time
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// Label for temp in Celsius
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get temperatureCelsius;

  /// Optional notes field
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

  /// Error when sharing
  ///
  /// In en, this message translates to:
  /// **'Error sharing: {error}'**
  String errorSharing(String error);

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

  /// Label for main dog
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

  /// Sign up page title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Sign up header text
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerYourself;

  /// Sign up subtitle
  ///
  /// In en, this message translates to:
  /// **'Create an account to get started'**
  String get createAccountSubtitle;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// Full name field hint
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fullNameHint;

  /// Email address label
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddressLabel;

  /// Email field hint
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordHintText;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// Confirm password hint
  ///
  /// In en, this message translates to:
  /// **'Repeat the password'**
  String get repeatPasswordHint;

  /// Terms checkbox prefix
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// Terms link text
  ///
  /// In en, this message translates to:
  /// **'terms of use'**
  String get termsOfUse;

  /// Create account button
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// Login link prefix
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccountQuestion;

  /// Login link text
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterNameValidation;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address'**
  String get pleaseEnterEmailValidation;

  /// Invalid email error
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmailValidation;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPasswordValidation;

  /// Password too short error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMin6Chars;

  /// Password mismatch error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchValidation;

  /// Terms not accepted error
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms of use'**
  String get mustAcceptTerms;

  /// Gen 4: paternal grandfather's father's sire
  ///
  /// In en, this message translates to:
  /// **'P.GF\'s sire'**
  String get gen4PGFSire;

  /// Gen 4: paternal grandfather's father's dam
  ///
  /// In en, this message translates to:
  /// **'P.GF\'s dam'**
  String get gen4PGFDam;

  /// Gen 4: paternal grandfather's mother's sire
  ///
  /// In en, this message translates to:
  /// **'P.GM\'s sire'**
  String get gen4PGMSire;

  /// Gen 4: paternal grandfather's mother's dam
  ///
  /// In en, this message translates to:
  /// **'P.GM\'s dam'**
  String get gen4PGMDam;

  /// Gen 4: paternal grandmother's father's sire
  ///
  /// In en, this message translates to:
  /// **'P.MF\'s sire'**
  String get gen4PMFSire;

  /// Gen 4: paternal grandmother's father's dam
  ///
  /// In en, this message translates to:
  /// **'P.MF\'s dam'**
  String get gen4PMFDam;

  /// Gen 4: paternal grandmother's mother's sire
  ///
  /// In en, this message translates to:
  /// **'P.MM\'s sire'**
  String get gen4PMMSire;

  /// Gen 4: paternal grandmother's mother's dam
  ///
  /// In en, this message translates to:
  /// **'P.MM\'s dam'**
  String get gen4PMMDam;

  /// Gen 4: maternal grandfather's father's sire
  ///
  /// In en, this message translates to:
  /// **'M.GF\'s sire'**
  String get gen4MGFSire;

  /// Gen 4: maternal grandfather's father's dam
  ///
  /// In en, this message translates to:
  /// **'M.GF\'s dam'**
  String get gen4MGFDam;

  /// Gen 4: maternal grandfather's mother's sire
  ///
  /// In en, this message translates to:
  /// **'M.GM\'s sire'**
  String get gen4MGMSire;

  /// Gen 4: maternal grandfather's mother's dam
  ///
  /// In en, this message translates to:
  /// **'M.GM\'s dam'**
  String get gen4MGMDam;

  /// Gen 4: maternal grandmother's father's sire
  ///
  /// In en, this message translates to:
  /// **'M.MF\'s sire'**
  String get gen4MMFSire;

  /// Gen 4: maternal grandmother's father's dam
  ///
  /// In en, this message translates to:
  /// **'M.MF\'s dam'**
  String get gen4MMFDam;

  /// Gen 4: maternal grandmother's mother's sire
  ///
  /// In en, this message translates to:
  /// **'M.MM\'s sire'**
  String get gen4MMMSire;

  /// Gen 4: maternal grandmother's mother's dam
  ///
  /// In en, this message translates to:
  /// **'M.MM\'s dam'**
  String get gen4MMMDam;

  /// Title for pedigree scanner test screen
  ///
  /// In en, this message translates to:
  /// **'Test Pedigree Scanner'**
  String get testPedigreeScanner;

  /// Title for scan result section
  ///
  /// In en, this message translates to:
  /// **'Scan Result'**
  String get scanResult;

  /// Total dogs found count
  ///
  /// In en, this message translates to:
  /// **'Total found: {count} dogs'**
  String totalDogsFound(int count);

  /// Scan successful status
  ///
  /// In en, this message translates to:
  /// **'Successful: {value}'**
  String scanSuccessful(String value);

  /// Label for scan confidence
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get scanConfidence;

  /// Label for test instructions section
  ///
  /// In en, this message translates to:
  /// **'Test instructions'**
  String get testInstructions;

  /// Info about testing pedigree scanner
  ///
  /// In en, this message translates to:
  /// **'Testing pedigree scanner'**
  String get testingScannerInfo;

  /// Info about what scanner uses
  ///
  /// In en, this message translates to:
  /// **'This function uses Google ML Kit for:'**
  String get scannerUsesInfo;

  /// Scanner capability: OCR
  ///
  /// In en, this message translates to:
  /// **'Read text from images (OCR)'**
  String get readTextFromImages;

  /// Scanner capability: registration numbers
  ///
  /// In en, this message translates to:
  /// **'Find registration numbers'**
  String get findRegistrationNumbers;

  /// Scanner capability: dog names
  ///
  /// In en, this message translates to:
  /// **'Identify dog names'**
  String get identifyDogNames;

  /// Scanner capability: parents
  ///
  /// In en, this message translates to:
  /// **'Recognize parents (Sire/Dam)'**
  String get recognizeParents;

  /// Scanner capability: birth dates
  ///
  /// In en, this message translates to:
  /// **'Extract birth dates'**
  String get extractBirthDates;

  /// Tip for using scanner
  ///
  /// In en, this message translates to:
  /// **'Tip: Use a clear image of a pedigree for best results.'**
  String get tipClearImage;

  /// Step 1 instruction
  ///
  /// In en, this message translates to:
  /// **'Take a photo of a pedigree'**
  String get step1TakePhoto;

  /// Step 2 instruction
  ///
  /// In en, this message translates to:
  /// **'Wait while ML Kit processes the image'**
  String get step2WaitProcessing;

  /// Step 3 instruction
  ///
  /// In en, this message translates to:
  /// **'See results and accuracy'**
  String get step3SeeResults;

  /// Step 4 instruction
  ///
  /// In en, this message translates to:
  /// **'Edit data if necessary'**
  String get step4EditData;

  /// Step 5 instruction
  ///
  /// In en, this message translates to:
  /// **'Save dog(s) to the database'**
  String get step5SaveDogs;

  /// Label for example data section
  ///
  /// In en, this message translates to:
  /// **'Example data that can be recognized'**
  String get exampleDataRecognized;

  /// Label for keywords section
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get keywords;

  /// Label for debug information section
  ///
  /// In en, this message translates to:
  /// **'Debug information'**
  String get debugInfo;

  /// Label for parents section
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parents;

  /// Label for grandparents section
  ///
  /// In en, this message translates to:
  /// **'Grandparents'**
  String get grandparents;

  /// Number of dogs found
  ///
  /// In en, this message translates to:
  /// **'{count} dogs found'**
  String dogsFound(int count);

  /// Message when dog already exists
  ///
  /// In en, this message translates to:
  /// **'Dog already exists'**
  String get dogAlreadyExists;

  /// Prompt for user action
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get whatDoYouWantToDo;

  /// Option to create new entry
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get createNew;

  /// Option to use existing entry
  ///
  /// In en, this message translates to:
  /// **'Use existing'**
  String get useExisting;

  /// Option to update data
  ///
  /// In en, this message translates to:
  /// **'Update data'**
  String get updateData;

  /// Dog added with pedigree message
  ///
  /// In en, this message translates to:
  /// **'{name} added with pedigree ({count} dogs total)'**
  String dogAddedWithPedigree(String name, int count);

  /// Message when dog is updated
  ///
  /// In en, this message translates to:
  /// **'Dog updated'**
  String get dogUpdated;

  /// Label for optional date of death field
  ///
  /// In en, this message translates to:
  /// **'Date of death (optional)'**
  String get dateOfDeathOptional;

  /// Placeholder when nothing is selected
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get noneSelected;

  /// Message when puppy is added
  ///
  /// In en, this message translates to:
  /// **'Puppy added'**
  String get puppyAdded;

  /// Label for puppy name field
  ///
  /// In en, this message translates to:
  /// **'Puppy name'**
  String get puppyNameLabel;

  /// Label for birth weight in grams
  ///
  /// In en, this message translates to:
  /// **'Birth weight (grams)'**
  String get birthWeightGrams;

  /// Label for birth notes field
  ///
  /// In en, this message translates to:
  /// **'Birth notes (e.g. assistance required)'**
  String get birthNotes;

  /// Label for status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Section label for health and documentation
  ///
  /// In en, this message translates to:
  /// **'Health & documentation'**
  String get healthAndDocumentation;

  /// Label for vaccinated status
  ///
  /// In en, this message translates to:
  /// **'Vaccinated'**
  String get vaccinated;

  /// Label for dewormed status
  ///
  /// In en, this message translates to:
  /// **'Dewormed'**
  String get dewormed;

  /// Label for microchipped status
  ///
  /// In en, this message translates to:
  /// **'Microchipped'**
  String get microchipped;

  /// Button label to save puppy
  ///
  /// In en, this message translates to:
  /// **'Save puppy'**
  String get savePuppy;

  /// Title for contracts screen
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// Label for purchase contracts
  ///
  /// In en, this message translates to:
  /// **'Purchase Contracts'**
  String get purchaseContracts;

  /// Label for reservations
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// Label for breeding contracts
  ///
  /// In en, this message translates to:
  /// **'Breeding Contracts'**
  String get breedingContracts;

  /// Label for co-ownership
  ///
  /// In en, this message translates to:
  /// **'Co-Ownership'**
  String get coOwnership;

  /// Label for foster contracts
  ///
  /// In en, this message translates to:
  /// **'Foster Contracts'**
  String get fosterContracts;

  /// Message when purchase contract is deleted
  ///
  /// In en, this message translates to:
  /// **'Purchase contract deleted'**
  String get purchaseContractDeleted;

  /// Message when reservation contract is deleted
  ///
  /// In en, this message translates to:
  /// **'Reservation contract deleted'**
  String get reservationContractDeleted;

  /// Message when breeding contract is deleted
  ///
  /// In en, this message translates to:
  /// **'Breeding contract deleted'**
  String get breedingContractDeleted;

  /// Message when co-ownership contract is deleted
  ///
  /// In en, this message translates to:
  /// **'Co-ownership contract deleted'**
  String get coOwnershipContractDeleted;

  /// Message when foster contract is deleted
  ///
  /// In en, this message translates to:
  /// **'Foster contract deleted'**
  String get fosterContractDeleted;

  /// Prompt to select sire and dam
  ///
  /// In en, this message translates to:
  /// **'Select sire and dam'**
  String get selectSireAndDam;

  /// Prompt to enter stud fee
  ///
  /// In en, this message translates to:
  /// **'Enter stud fee'**
  String get enterStudFee;

  /// Error message during generation
  ///
  /// In en, this message translates to:
  /// **'Error generating: {error}'**
  String errorGenerating(String error);

  /// Message when contract is generated
  ///
  /// In en, this message translates to:
  /// **'Contract generated!'**
  String get contractGenerated;

  /// Prompt to select stud dog
  ///
  /// In en, this message translates to:
  /// **'Select stud dog'**
  String get selectStud;

  /// Label for stud owner name
  ///
  /// In en, this message translates to:
  /// **'Stud owner (name)'**
  String get studOwnerName;

  /// Prompt to select dam for contract
  ///
  /// In en, this message translates to:
  /// **'Select dam'**
  String get selectDamForContract;

  /// Label for dam owner name
  ///
  /// In en, this message translates to:
  /// **'Dam owner (name)'**
  String get damOwnerName;

  /// Label for amount in NOK
  ///
  /// In en, this message translates to:
  /// **'Amount (NOK)'**
  String get amountNok;

  /// Hint for payment terms field
  ///
  /// In en, this message translates to:
  /// **'E.g. \"Payment at mating\"'**
  String get paymentTermsHint;

  /// Hint for additional terms field
  ///
  /// In en, this message translates to:
  /// **'Add special terms...'**
  String get additionalTermsHint;

  /// Placeholder for buyer search field
  ///
  /// In en, this message translates to:
  /// **'Search buyer...'**
  String get searchBuyer;

  /// Button to remove filter
  ///
  /// In en, this message translates to:
  /// **'Remove filter'**
  String get removeFilter;

  /// Label for all litters option
  ///
  /// In en, this message translates to:
  /// **'All litters'**
  String get allLitters;

  /// Message when reservation is removed
  ///
  /// In en, this message translates to:
  /// **'Reservation removed'**
  String get reservationRemoved;

  /// Prompt to select a puppy
  ///
  /// In en, this message translates to:
  /// **'Please select a puppy'**
  String get pleaseSelectPuppy;

  /// Button label to delete a dog
  ///
  /// In en, this message translates to:
  /// **'Delete dog'**
  String get deleteDog;

  /// Button label to add heat date
  ///
  /// In en, this message translates to:
  /// **'Add heat date'**
  String get addHeatDate;

  /// Button label to create breeding contract
  ///
  /// In en, this message translates to:
  /// **'Create contract for mating services'**
  String get createBreedingContract;

  /// Label for co-ownership agreement
  ///
  /// In en, this message translates to:
  /// **'Co-ownership agreement'**
  String get coOwnershipAgreement;

  /// Button to create co-ownership agreement
  ///
  /// In en, this message translates to:
  /// **'Create agreement for shared ownership'**
  String get createCoOwnershipAgreement;

  /// Label for foster agreement
  ///
  /// In en, this message translates to:
  /// **'Foster agreement'**
  String get fosterAgreement;

  /// Button to create foster agreement
  ///
  /// In en, this message translates to:
  /// **'Create agreement for foster care'**
  String get createFosterAgreement;

  /// Message when heat date is added
  ///
  /// In en, this message translates to:
  /// **'Heat date added'**
  String get heatDateAdded;

  /// Confirmation for deleting heat date
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this heat date?'**
  String get confirmDeleteHeatDate;

  /// Message when heat date is deleted
  ///
  /// In en, this message translates to:
  /// **'Heat date deleted'**
  String get heatDateDeleted;

  /// Button to add championship
  ///
  /// In en, this message translates to:
  /// **'Add championship'**
  String get addChampionship;

  /// Prompt to enter other title
  ///
  /// In en, this message translates to:
  /// **'Enter other title'**
  String get enterOtherTitle;

  /// Option to select from list
  ///
  /// In en, this message translates to:
  /// **'Select from list'**
  String get selectFromList;

  /// Message when title already exists
  ///
  /// In en, this message translates to:
  /// **'This title is already registered'**
  String get titleAlreadyRegistered;

  /// Button to remove championship
  ///
  /// In en, this message translates to:
  /// **'Remove championship'**
  String get removeChampionship;

  /// Confirm remove championship dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{title}\"?'**
  String confirmRemoveChampionship(String title);

  /// Button to add mating
  ///
  /// In en, this message translates to:
  /// **'Add mating'**
  String get addMating;

  /// Label for external dam
  ///
  /// In en, this message translates to:
  /// **'External dam'**
  String get externalDam;

  /// Message when mating is added
  ///
  /// In en, this message translates to:
  /// **'Mating added'**
  String get matingAdded;

  /// Button to edit mating
  ///
  /// In en, this message translates to:
  /// **'Edit mating'**
  String get editMating;

  /// Message when mating is updated
  ///
  /// In en, this message translates to:
  /// **'Mating updated'**
  String get matingUpdated;

  /// Message when mating is deleted
  ///
  /// In en, this message translates to:
  /// **'Mating deleted'**
  String get matingDeleted;

  /// Health screen title with dog name
  ///
  /// In en, this message translates to:
  /// **'Health - {name}'**
  String healthTitle(String name);

  /// Tab label for health status
  ///
  /// In en, this message translates to:
  /// **'Health Status'**
  String get healthStatusTab;

  /// Tab label for vaccines
  ///
  /// In en, this message translates to:
  /// **'Vaccines'**
  String get vaccinesTab;

  /// Tab label for veterinary
  ///
  /// In en, this message translates to:
  /// **'Veterinary'**
  String get vetTab;

  /// Tab label for treatments
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get treatmentsTab;

  /// Tab label for DNA tests
  ///
  /// In en, this message translates to:
  /// **'DNA Tests'**
  String get dnaTestsTab;

  /// Tab label for weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightTab;

  /// Tab label for hormones
  ///
  /// In en, this message translates to:
  /// **'Hormones'**
  String get hormonesTab;

  /// Button to add health information
  ///
  /// In en, this message translates to:
  /// **'Add health information'**
  String get addHealthInfo;

  /// Message when health info is not found
  ///
  /// In en, this message translates to:
  /// **'Health information not found'**
  String get healthInfoNotFound;

  /// Button to add vaccine
  ///
  /// In en, this message translates to:
  /// **'Add vaccine'**
  String get addVaccine;

  /// Confirmation for deleting health info
  ///
  /// In en, this message translates to:
  /// **'Delete health information?'**
  String get deleteHealthInfo;

  /// Message when changes are saved locally offline
  ///
  /// In en, this message translates to:
  /// **'Offline - changes saved locally'**
  String get offlineChangesLocal;

  /// Label for registration number with colon
  ///
  /// In en, this message translates to:
  /// **'Registration number:'**
  String get registrationNumberColon;

  /// Optional registration number field
  ///
  /// In en, this message translates to:
  /// **'Registration number (optional)'**
  String get registrationNumberOptional;

  /// Title for add puppy screen
  ///
  /// In en, this message translates to:
  /// **'Add puppy'**
  String get addPuppy;

  /// Label for birth time
  ///
  /// In en, this message translates to:
  /// **'Birth time'**
  String get birthTimeLabel;

  /// Label for optional birth time
  ///
  /// In en, this message translates to:
  /// **'Birth time (optional)'**
  String get birthTimeOptional;

  /// Validation for color field
  ///
  /// In en, this message translates to:
  /// **'Please enter a color'**
  String get pleaseEnterColor;

  /// Message when dog is deleted
  ///
  /// In en, this message translates to:
  /// **'«{name}» was deleted'**
  String dogWasDeleted(String name);

  /// Error message when delete fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String couldNotDelete(String error);

  /// Confirmation message for deleting a dog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete «{name}»?\n\nThis removes the dog and all associated data. This action cannot be undone.'**
  String confirmDeleteDogMessage(String name);

  /// Section title for health information
  ///
  /// In en, this message translates to:
  /// **'Health information'**
  String get healthInformation;

  /// Empty state message for health info
  ///
  /// In en, this message translates to:
  /// **'No health information registered'**
  String get noHealthInfoRegistered;

  /// Subtitle for adding health info
  ///
  /// In en, this message translates to:
  /// **'Add health information for {name}'**
  String addHealthInfoFor(String name);

  /// Card title for health status
  ///
  /// In en, this message translates to:
  /// **'Health status'**
  String get healthStatus;

  /// Label for remarks section
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// Date label with value
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateWithValue(String date);

  /// Empty state for vaccines
  ///
  /// In en, this message translates to:
  /// **'No vaccines registered'**
  String get noVaccinesRegistered;

  /// Subtitle for adding vaccines
  ///
  /// In en, this message translates to:
  /// **'Add vaccines for {name}'**
  String addVaccinesFor(String name);

  /// Vaccine taken date
  ///
  /// In en, this message translates to:
  /// **'Taken: {value}'**
  String takenWithDate(String value);

  /// Badge label for overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueLabel;

  /// Badge label for alert
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alertLabel;

  /// Next dose date
  ///
  /// In en, this message translates to:
  /// **'Next dose: {value}'**
  String nextDoseWithDate(String value);

  /// Veterinarian with name
  ///
  /// In en, this message translates to:
  /// **'Veterinarian: {value}'**
  String veterinarianWithName(String value);

  /// Empty state for progesterone
  ///
  /// In en, this message translates to:
  /// **'No progesterone measurements registered'**
  String get noProgesteroneMeasurements;

  /// Subtitle for progesterone tracking
  ///
  /// In en, this message translates to:
  /// **'Add progesterone measurements to track {name}\'s cycle'**
  String addProgesteroneTracking(String name);

  /// Confirm delete progesterone
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this progesterone measurement?'**
  String get confirmDeleteProgesterone;

  /// Section title for vet visits
  ///
  /// In en, this message translates to:
  /// **'Veterinary visits'**
  String get vetVisits;

  /// Tooltip for add visit
  ///
  /// In en, this message translates to:
  /// **'Add visit'**
  String get addVisit;

  /// Empty state for vet visits
  ///
  /// In en, this message translates to:
  /// **'No veterinary visits registered'**
  String get noVetVisitsRegistered;

  /// Subtitle for vet visits
  ///
  /// In en, this message translates to:
  /// **'Add veterinary visits for {name}'**
  String addVetVisitsFor(String name);

  /// Visit type routine
  ///
  /// In en, this message translates to:
  /// **'Routine check'**
  String get visitTypeRoutine;

  /// Visit type emergency
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get visitTypeEmergency;

  /// Visit type surgery
  ///
  /// In en, this message translates to:
  /// **'Surgery'**
  String get visitTypeSurgery;

  /// Visit type vaccination
  ///
  /// In en, this message translates to:
  /// **'Vaccination'**
  String get visitTypeVaccination;

  /// Visit type follow-up
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get visitTypeFollowup;

  /// Visit type other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get visitTypeOther;

  /// Reason with value
  ///
  /// In en, this message translates to:
  /// **'Reason: {value}'**
  String reasonWithValue(String value);

  /// Diagnosis with value
  ///
  /// In en, this message translates to:
  /// **'Diagnosis: {value}'**
  String diagnosisWithValue(String value);

  /// Treatment with value
  ///
  /// In en, this message translates to:
  /// **'Treatment: {value}'**
  String treatmentWithValue(String value);

  /// Cost with value
  ///
  /// In en, this message translates to:
  /// **'Cost: {value} kr'**
  String costWithValue(String value);

  /// Follow-up date with value
  ///
  /// In en, this message translates to:
  /// **'Follow-up: {value}'**
  String followUpWithDate(String value);

  /// Tooltip for add treatment
  ///
  /// In en, this message translates to:
  /// **'Add treatment'**
  String get addTreatment;

  /// Empty state for treatments
  ///
  /// In en, this message translates to:
  /// **'No treatments registered'**
  String get noTreatmentsRegistered;

  /// Subtitle for treatments
  ///
  /// In en, this message translates to:
  /// **'Add deworming, flea/tick treatments, etc.'**
  String get addTreatmentsSubtitle;

  /// Treatment type deworming
  ///
  /// In en, this message translates to:
  /// **'Deworming'**
  String get treatmentTypeDeworming;

  /// Treatment type flea
  ///
  /// In en, this message translates to:
  /// **'Flea treatment'**
  String get treatmentTypeFlea;

  /// Treatment type tick
  ///
  /// In en, this message translates to:
  /// **'Tick treatment'**
  String get treatmentTypeTick;

  /// Treatment type medication
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get treatmentTypeMedication;

  /// Treatment type supplement
  ///
  /// In en, this message translates to:
  /// **'Supplement'**
  String get treatmentTypeSupplement;

  /// Treatment type other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get treatmentTypeOther;

  /// Menu item register new dose
  ///
  /// In en, this message translates to:
  /// **'Register new dose'**
  String get registerNewDose;

  /// Last given date
  ///
  /// In en, this message translates to:
  /// **'Last given: {value}'**
  String lastGivenWithDate(String value);

  /// Dosage with value
  ///
  /// In en, this message translates to:
  /// **'Dosage: {value}'**
  String dosageWithValue(String value);

  /// Manufacturer with value
  ///
  /// In en, this message translates to:
  /// **'Manufacturer: {value}'**
  String manufacturerWithValue(String value);

  /// Next date
  ///
  /// In en, this message translates to:
  /// **'Next: {value}'**
  String nextWithDate(String value);

  /// Snackbar for new dose
  ///
  /// In en, this message translates to:
  /// **'New dose of {name} registered'**
  String newDoseRegistered(String name);

  /// Empty state for DNA tests
  ///
  /// In en, this message translates to:
  /// **'No DNA tests registered'**
  String get noDnaTestsRegistered;

  /// Tooltip for add DNA test
  ///
  /// In en, this message translates to:
  /// **'Add DNA test'**
  String get addDnaTest;

  /// Subtitle for DNA tests
  ///
  /// In en, this message translates to:
  /// **'Add genetic tests for {name}'**
  String addGeneticTestsFor(String name);

  /// Tested date
  ///
  /// In en, this message translates to:
  /// **'Tested: {value}'**
  String testedWithDate(String value);

  /// Laboratory with name
  ///
  /// In en, this message translates to:
  /// **'Laboratory: {value}'**
  String laboratoryWithValue(String value);

  /// Certificate number
  ///
  /// In en, this message translates to:
  /// **'Certificate no: {value}'**
  String certificateNoWithValue(String value);

  /// Section title for weight history
  ///
  /// In en, this message translates to:
  /// **'Weight history'**
  String get weightHistory;

  /// Tooltip for add weight
  ///
  /// In en, this message translates to:
  /// **'Add weight'**
  String get addWeight;

  /// Empty state for weight
  ///
  /// In en, this message translates to:
  /// **'No weight records'**
  String get noWeightRecords;

  /// Subtitle for weight tracking
  ///
  /// In en, this message translates to:
  /// **'Track {name}\'s weight development'**
  String trackWeightFor(String name);

  /// Label for current weight
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get currentWeight;

  /// Button label for change
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLabel;

  /// Delete weight record title
  ///
  /// In en, this message translates to:
  /// **'Delete weight record?'**
  String get deleteWeightRecord;

  /// Confirm delete weight record
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record?'**
  String get confirmDeleteWeightRecord;

  /// Confirm delete health info
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this health information?'**
  String get confirmDeleteHealthInfo;

  /// Label for HD date
  ///
  /// In en, this message translates to:
  /// **'HD date'**
  String get hdDateLabel;

  /// AD status grade 0
  ///
  /// In en, this message translates to:
  /// **'Grade 0 (Clear)'**
  String get adGrade0;

  /// AD status grade 1
  ///
  /// In en, this message translates to:
  /// **'Grade 1 (Mild)'**
  String get adGrade1;

  /// AD status grade 2
  ///
  /// In en, this message translates to:
  /// **'Grade 2 (Moderate)'**
  String get adGrade2;

  /// AD status grade 3
  ///
  /// In en, this message translates to:
  /// **'Grade 3 (Severe)'**
  String get adGrade3;

  /// Hint for AD status dropdown
  ///
  /// In en, this message translates to:
  /// **'Select AD Status'**
  String get selectAdStatus;

  /// Dropdown option to remove selection
  ///
  /// In en, this message translates to:
  /// **'None (remove selection)'**
  String get noneRemoveSelection;

  /// Label for AD date
  ///
  /// In en, this message translates to:
  /// **'AD date'**
  String get adDateLabel;

  /// Patella grade 0
  ///
  /// In en, this message translates to:
  /// **'Grade 0 (Normal)'**
  String get patellaGrade0;

  /// Patella grade 1
  ///
  /// In en, this message translates to:
  /// **'Grade 1'**
  String get patellaGrade1;

  /// Patella grade 2
  ///
  /// In en, this message translates to:
  /// **'Grade 2'**
  String get patellaGrade2;

  /// Patella grade 3
  ///
  /// In en, this message translates to:
  /// **'Grade 3'**
  String get patellaGrade3;

  /// Hint for Patella dropdown
  ///
  /// In en, this message translates to:
  /// **'Select Patella Status'**
  String get selectPatellaStatus;

  /// Label for Patella date
  ///
  /// In en, this message translates to:
  /// **'Patella date'**
  String get patellaDateLabel;

  /// Generic select hint
  ///
  /// In en, this message translates to:
  /// **'Select {label}'**
  String selectStatus(String label);

  /// Dialog title for vaccine
  ///
  /// In en, this message translates to:
  /// **'Vaccine'**
  String get vaccineDialogTitle;

  /// Hint for vaccine name
  ///
  /// In en, this message translates to:
  /// **'Vaccine name (e.g. DHPPL, Rabies)'**
  String get vaccineNameHint;

  /// Taken date
  ///
  /// In en, this message translates to:
  /// **'Taken date: {value}'**
  String takenDateWithValue(String value);

  /// Next date
  ///
  /// In en, this message translates to:
  /// **'Next date: {value}'**
  String nextDateWithValue(String value);

  /// When date is not set
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// Label for enable reminder
  ///
  /// In en, this message translates to:
  /// **'Enable reminder'**
  String get enableReminder;

  /// Label for optional vet field
  ///
  /// In en, this message translates to:
  /// **'Veterinarian (optional)'**
  String get veterinarianOptional;

  /// Label for optional remarks
  ///
  /// In en, this message translates to:
  /// **'Remarks (optional)'**
  String get remarksOptional;

  /// Validation for vaccine name
  ///
  /// In en, this message translates to:
  /// **'Please enter vaccine name'**
  String get pleaseEnterVaccineName;

  /// Dialog title add progesterone
  ///
  /// In en, this message translates to:
  /// **'Add progesterone measurement'**
  String get addProgesteroneMeasurement;

  /// Dialog title edit measurement
  ///
  /// In en, this message translates to:
  /// **'Edit measurement'**
  String get editMeasurementTitle;

  /// Label for progesterone input
  ///
  /// In en, this message translates to:
  /// **'Progesterone value (ng/mL) *'**
  String get progesteroneValueLabel;

  /// Hint for progesterone value
  ///
  /// In en, this message translates to:
  /// **'e.g. 5.2'**
  String get progesteroneHint;

  /// Validation for progesterone
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid progesterone value'**
  String get invalidProgesteroneValue;

  /// Dialog title new vet visit
  ///
  /// In en, this message translates to:
  /// **'New veterinary visit'**
  String get newVetVisit;

  /// Dialog title edit visit
  ///
  /// In en, this message translates to:
  /// **'Edit visit'**
  String get editVisit;

  /// Label for visit type
  ///
  /// In en, this message translates to:
  /// **'Visit type'**
  String get visitTypeLabel;

  /// Label for reason field
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// Label for diagnosis field
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosisLabel;

  /// Label for treatment field
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatmentFieldLabel;

  /// Label for prescription field
  ///
  /// In en, this message translates to:
  /// **'Prescription/medication'**
  String get prescriptionLabel;

  /// Label for veterinarian field
  ///
  /// In en, this message translates to:
  /// **'Veterinarian'**
  String get veterinarianFieldLabel;

  /// Label for clinic
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get clinicLabel;

  /// Label for cost field
  ///
  /// In en, this message translates to:
  /// **'Cost (kr)'**
  String get costKrLabel;

  /// Dialog title new treatment
  ///
  /// In en, this message translates to:
  /// **'New treatment'**
  String get newTreatment;

  /// Dialog title edit treatment
  ///
  /// In en, this message translates to:
  /// **'Edit treatment'**
  String get editTreatment;

  /// Label for product name
  ///
  /// In en, this message translates to:
  /// **'Product name*'**
  String get productNameLabel;

  /// Label for date given
  ///
  /// In en, this message translates to:
  /// **'Date given'**
  String get dateGivenLabel;

  /// Label for dosage field
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosageLabel;

  /// Label for manufacturer field
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get manufacturerLabel;

  /// Label for batch number
  ///
  /// In en, this message translates to:
  /// **'Batch number'**
  String get batchNumberLabel;

  /// Label for interval
  ///
  /// In en, this message translates to:
  /// **'Interval (days)'**
  String get intervalDaysLabel;

  /// Dialog title new DNA test
  ///
  /// In en, this message translates to:
  /// **'New DNA test'**
  String get newDnaTest;

  /// Dialog title edit DNA test
  ///
  /// In en, this message translates to:
  /// **'Edit DNA test'**
  String get editDnaTest;

  /// Label for test name
  ///
  /// In en, this message translates to:
  /// **'Test name*'**
  String get testNameLabel;

  /// Label for test date
  ///
  /// In en, this message translates to:
  /// **'Test date'**
  String get testDateLabel;

  /// Dialog title register weight
  ///
  /// In en, this message translates to:
  /// **'Register weight'**
  String get registerWeight;

  /// Dialog title edit weight
  ///
  /// In en, this message translates to:
  /// **'Edit weight'**
  String get editWeight;

  /// Label for weight input
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)*'**
  String get weightKgLabel;

  /// Validation for weight
  ///
  /// In en, this message translates to:
  /// **'Invalid weight'**
  String get invalidWeight;

  /// Message when search has no matches
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String noMatchesForQuery(String query);

  /// Message when no buyers for selected litter
  ///
  /// In en, this message translates to:
  /// **'No buyers for this litter'**
  String get noBuyersForLitter;

  /// Placeholder for litter filter dropdown
  ///
  /// In en, this message translates to:
  /// **'Filter by litter'**
  String get filterByLitter;

  /// Status label for delivered
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveredStatus;

  /// Section header for buyers with reservation
  ///
  /// In en, this message translates to:
  /// **'With reservation'**
  String get withReservationSection;

  /// Section header for interested buyers without reservation
  ///
  /// In en, this message translates to:
  /// **'Interested parties'**
  String get interestedParties;

  /// Label showing puppy name
  ///
  /// In en, this message translates to:
  /// **'Puppy: {name}'**
  String puppyLabelWithName(String name);

  /// Label for subscription section
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// Subtitle for subscription section
  ///
  /// In en, this message translates to:
  /// **'Manage your Breedly subscription'**
  String get manageSubscription;

  /// Label for promo code source
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// Label for lifetime subscription
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetimeAccess;

  /// Subscription source and expiry info
  ///
  /// In en, this message translates to:
  /// **'{source} • Expires: {expiry}'**
  String subscriptionExpiresInfo(String source, String expiry);

  /// Status badge for active subscription
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// SnackBar message when purchases restored
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get purchasesRestored;

  /// Button label to restore purchases
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// Message when user is on free plan
  ///
  /// In en, this message translates to:
  /// **'You are using the free version'**
  String get usingFreeVersion;

  /// Upgrade prompt description
  ///
  /// In en, this message translates to:
  /// **'Upgrade for unlimited access to all features.'**
  String get upgradeForUnlimited;

  /// Button label to upgrade
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// SnackBar message when premium restored
  ///
  /// In en, this message translates to:
  /// **'Premium restored!'**
  String get premiumRestored;

  /// SnackBar message when no purchases found
  ///
  /// In en, this message translates to:
  /// **'No previous purchases found.'**
  String get noPreviousPurchases;

  /// Title for developer section
  ///
  /// In en, this message translates to:
  /// **'Developer & Testing'**
  String get developerAndTesting;

  /// Subtitle for developer section
  ///
  /// In en, this message translates to:
  /// **'Test new features'**
  String get testNewFeatures;

  /// Subtitle for pedigree scanner in settings
  ///
  /// In en, this message translates to:
  /// **'Google ML Kit OCR - Scan pedigrees with AI'**
  String get pedigreeScannerSubtitleSettings;

  /// Badge label for new features
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// Empty state for certificates
  ///
  /// In en, this message translates to:
  /// **'No Cert/Cacib yet'**
  String get noCertCacibYet;

  /// Judge statistics summary line
  ///
  /// In en, this message translates to:
  /// **'{showCount} exhibitions • {excellentCount} Excellent • {ckCount} CK'**
  String judgeStatsSummary(int showCount, int excellentCount, int ckCount);

  /// Tooltip/button to share result card
  ///
  /// In en, this message translates to:
  /// **'Share result card'**
  String get shareResultCard;

  /// Chip label for group judge
  ///
  /// In en, this message translates to:
  /// **'Group judge: {name}'**
  String groupJudgeWithName(String name);

  /// Chip label for BIS judge
  ///
  /// In en, this message translates to:
  /// **'BIS judge: {name}'**
  String bisJudgeWithName(String name);

  /// Helper text when quality locks placements
  ///
  /// In en, this message translates to:
  /// **'No placement or certificates available with this quality grade'**
  String get noPlacementWithQuality;

  /// Helper text for HP requirement
  ///
  /// In en, this message translates to:
  /// **'Requires Highly promising'**
  String get requiresHighlyPromising;

  /// Helper text when HP qualifies
  ///
  /// In en, this message translates to:
  /// **'Qualifies for best male puppy/female puppy'**
  String get qualifiesForBestPuppy;

  /// Helper text for CK requirement
  ///
  /// In en, this message translates to:
  /// **'Requires Excellent'**
  String get requiresExcellent;

  /// Label for best male puppy placement
  ///
  /// In en, this message translates to:
  /// **'Best male puppy'**
  String get bestMalePuppy;

  /// Label for best female puppy placement
  ///
  /// In en, this message translates to:
  /// **'Best female puppy'**
  String get bestFemalePuppy;

  /// Helper text when qualified
  ///
  /// In en, this message translates to:
  /// **'Qualified for BIR/BIM Puppy'**
  String get qualifiedForBIRBIMPuppy;

  /// Helper text for puppy BIR requirement
  ///
  /// In en, this message translates to:
  /// **'Requires 1st place with HP to participate'**
  String get requiresFirstWithHP;

  /// Helper text for puppy BIR/BIM
  ///
  /// In en, this message translates to:
  /// **'Requires being best male/female puppy'**
  String get requiresBestPuppy;

  /// Helper text for Nordic BIR/BIM rules
  ///
  /// In en, this message translates to:
  /// **'BHK/BTK 1st required for BIR/BIM in Nordic countries'**
  String get requiresBHKBTKFirstNordic;

  /// Dropdown option for winning best puppy
  ///
  /// In en, this message translates to:
  /// **'Yes - Won'**
  String get yesWon;

  /// Label for group judge field
  ///
  /// In en, this message translates to:
  /// **'Group judge'**
  String get groupJudge;

  /// Label for BIS judge field
  ///
  /// In en, this message translates to:
  /// **'BIS judge'**
  String get bisJudge;

  /// SnackBar message when result saved
  ///
  /// In en, this message translates to:
  /// **'Result saved!'**
  String get resultSaved;

  /// Label for HP checkbox
  ///
  /// In en, this message translates to:
  /// **'HP (Hopeful Puppy)'**
  String get hpAward;

  /// Label for puppy BIR/BIM dropdown
  ///
  /// In en, this message translates to:
  /// **'BIR/BIM Puppy'**
  String get birBimPuppy;

  /// Abbreviation for class in chips
  ///
  /// In en, this message translates to:
  /// **'Cl'**
  String get classAbbrev;

  /// Abbreviation for best male
  ///
  /// In en, this message translates to:
  /// **'BM'**
  String get bestMaleAbbrev;

  /// Abbreviation for best female
  ///
  /// In en, this message translates to:
  /// **'BF'**
  String get bestFemaleAbbrev;

  /// Abbreviation for best of sex
  ///
  /// In en, this message translates to:
  /// **'BOS'**
  String get bestOfSexAbbrev;

  /// Validation message for price
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get enterPrice;

  /// Success message for contract save
  ///
  /// In en, this message translates to:
  /// **'Contract saved'**
  String get contractSaved;

  /// Error message for save
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSaving(String error);

  /// Section header for buyer info
  ///
  /// In en, this message translates to:
  /// **'Buyer information'**
  String get buyerInformation;

  /// Section header for contract details
  ///
  /// In en, this message translates to:
  /// **'Contract details'**
  String get contractDetails;

  /// Label for optional deposit field
  ///
  /// In en, this message translates to:
  /// **'Deposit (optional)'**
  String get depositOptional;

  /// Hint for deposit field
  ///
  /// In en, this message translates to:
  /// **'Amount already paid as advance'**
  String get amountAlreadyPaidAsAdvance;

  /// Label for optional contract number
  ///
  /// In en, this message translates to:
  /// **'Contract number (optional)'**
  String get contractNumberOptional;

  /// Hint for payment terms
  ///
  /// In en, this message translates to:
  /// **'E.g. Full payment at pickup'**
  String get paymentTermsExampleHint;

  /// Label for optional delivery location
  ///
  /// In en, this message translates to:
  /// **'Delivery location (optional)'**
  String get deliveryLocationOptional;

  /// Hint for delivery location
  ///
  /// In en, this message translates to:
  /// **'E.g. Breeder\'s address'**
  String get deliveryLocationHint;

  /// Section header for contract terms
  ///
  /// In en, this message translates to:
  /// **'Contract terms'**
  String get contractTerms;

  /// Instruction for selecting terms
  ///
  /// In en, this message translates to:
  /// **'Select which terms to include in the contract'**
  String get selectTermsToInclude;

  /// Contract term: general
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get termGeneral;

  /// Subtitle for general terms
  ///
  /// In en, this message translates to:
  /// **'Basic purchase and sale terms'**
  String get termGeneralSubtitle;

  /// Contract term: health
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get termHealth;

  /// Subtitle for health terms
  ///
  /// In en, this message translates to:
  /// **'Guarantee of healthy puppy and vet check'**
  String get termHealthSubtitle;

  /// Contract term: vaccinations
  ///
  /// In en, this message translates to:
  /// **'Vaccinations and treatments'**
  String get termVaccinations;

  /// Subtitle for vaccination terms
  ///
  /// In en, this message translates to:
  /// **'Vaccinated and dewormed per guidelines'**
  String get termVaccinationsSubtitle;

  /// Contract term: return
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get termReturn;

  /// Subtitle for return terms
  ///
  /// In en, this message translates to:
  /// **'Seller contacted first for rehoming'**
  String get termReturnSubtitle;

  /// Contract term: responsibility
  ///
  /// In en, this message translates to:
  /// **'Responsibility'**
  String get termResponsibility;

  /// Subtitle for responsibility terms
  ///
  /// In en, this message translates to:
  /// **'Buyer takes over responsibility from handover'**
  String get termResponsibilitySubtitle;

  /// Contract term: registration
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get termRegistration;

  /// Subtitle for registration terms
  ///
  /// In en, this message translates to:
  /// **'Puppy registered to new owner'**
  String get termRegistrationSubtitle;

  /// Contract term for return clause
  ///
  /// In en, this message translates to:
  /// **'Return clause included'**
  String get returnClauseIncluded;

  /// Section header for documentation
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentation;

  /// Checkbox for pedigree delivery
  ///
  /// In en, this message translates to:
  /// **'Pedigree delivered'**
  String get pedigreeDeliveredLabel;

  /// Subtitle for pedigree delivery
  ///
  /// In en, this message translates to:
  /// **'Pedigree included at handover'**
  String get pedigreeDeliveredSubtitle;

  /// Checkbox for vet certificate
  ///
  /// In en, this message translates to:
  /// **'Vet certificate attached'**
  String get vetCertificateAttached;

  /// Subtitle for vet certificate
  ///
  /// In en, this message translates to:
  /// **'Veterinary certificate on health status'**
  String get vetCertificateAttachedSubtitle;

  /// Checkbox for insurance transfer
  ///
  /// In en, this message translates to:
  /// **'Insurance transferred'**
  String get insuranceTransferred;

  /// Subtitle for insurance transfer
  ///
  /// In en, this message translates to:
  /// **'Puppy insurance transferred to buyer'**
  String get insuranceTransferredSubtitle;

  /// Label for special terms
  ///
  /// In en, this message translates to:
  /// **'Special terms (optional)'**
  String get specialTermsOptional;

  /// Hint for special terms
  ///
  /// In en, this message translates to:
  /// **'Any special agreements between the parties...'**
  String get specialTermsHint;

  /// Button to save contract
  ///
  /// In en, this message translates to:
  /// **'Save contract'**
  String get saveContract;

  /// Button to download PDF
  ///
  /// In en, this message translates to:
  /// **'Download as PDF'**
  String get downloadAsPdf;

  /// Success message for PDF save with path
  ///
  /// In en, this message translates to:
  /// **'PDF saved:\n{path}'**
  String pdfSavedAt(String path);

  /// Error message for export
  ///
  /// In en, this message translates to:
  /// **'Error exporting: {error}'**
  String errorExporting(String error);

  /// Gender label for male puppy
  ///
  /// In en, this message translates to:
  /// **'Male puppy'**
  String get malePuppy;

  /// Gender label for female puppy
  ///
  /// In en, this message translates to:
  /// **'Female puppy'**
  String get femalePuppy;

  /// Success message for co-ownership
  ///
  /// In en, this message translates to:
  /// **'Co-ownership agreement created!'**
  String get coOwnershipContractCreated;

  /// Label for dog
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get dog;

  /// Section header for ownership
  ///
  /// In en, this message translates to:
  /// **'Ownership share'**
  String get ownershipShare;

  /// Option for shared care
  ///
  /// In en, this message translates to:
  /// **'Shared responsibility'**
  String get sharedResponsibility;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Rights and responsibilities'**
  String get rightsAndResponsibilities;

  /// Label for optional additional terms
  ///
  /// In en, this message translates to:
  /// **'Additional terms (optional)'**
  String get additionalTermsOptional;

  /// Hint for additional terms
  ///
  /// In en, this message translates to:
  /// **'Enter any additional terms...'**
  String get additionalTermsHintText;

  /// Button to generate co-ownership PDF
  ///
  /// In en, this message translates to:
  /// **'Generate co-ownership agreement'**
  String get generateCoOwnershipContract;

  /// Success message for foster contract
  ///
  /// In en, this message translates to:
  /// **'Foster agreement created!'**
  String get fosterContractCreated;

  /// Section header for period
  ///
  /// In en, this message translates to:
  /// **'Contract period'**
  String get contractPeriod;

  /// Checkbox for end date
  ///
  /// In en, this message translates to:
  /// **'Has definite end date'**
  String get hasDefiniteEndDate;

  /// Prompt to select date
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// Section header for terms
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get contractTermsSection;

  /// Label for breeding terms
  ///
  /// In en, this message translates to:
  /// **'Breeding terms'**
  String get breedingTerms;

  /// Button to generate foster PDF
  ///
  /// In en, this message translates to:
  /// **'Generate foster agreement'**
  String get generateFosterContract;

  /// Success for reservation creation
  ///
  /// In en, this message translates to:
  /// **'Reservation agreement created!'**
  String get reservationContractCreated;

  /// Success for reservation update
  ///
  /// In en, this message translates to:
  /// **'Reservation agreement updated!'**
  String get reservationContractUpdated;

  /// Section header for prices
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get prices;

  /// Label for reservation fee
  ///
  /// In en, this message translates to:
  /// **'Reservation fee (kr)'**
  String get reservationFeeLabel;

  /// Label for total puppy price
  ///
  /// In en, this message translates to:
  /// **'Total price for puppy (kr)'**
  String get totalPriceForPuppy;

  /// Validation for invalid amount
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// Display remaining amount
  ///
  /// In en, this message translates to:
  /// **'Remaining: kr {amount},-'**
  String remainingAmount(String amount);

  /// Hint for remarks field
  ///
  /// In en, this message translates to:
  /// **'Enter any remarks...'**
  String get remarksHint;

  /// Button to generate reservation PDF
  ///
  /// In en, this message translates to:
  /// **'Generate reservation agreement'**
  String get generateReservationContract;

  /// Notification title for PDF download
  ///
  /// In en, this message translates to:
  /// **'PDF downloaded'**
  String get pdfDownloaded;

  /// Calendar event for dog heat cycle
  ///
  /// In en, this message translates to:
  /// **'{dogName} - Heat cycle'**
  String dogHeatCycle(String dogName);

  /// Calendar event for expected heat cycle
  ///
  /// In en, this message translates to:
  /// **'{dogName} - Expected heat'**
  String dogExpectedHeat(String dogName);

  /// Calendar event for dog giving birth
  ///
  /// In en, this message translates to:
  /// **'{dogName} gave birth'**
  String dogGaveBirth(String dogName);

  /// Calendar event for litter delivery
  ///
  /// In en, this message translates to:
  /// **'Delivery: {damName} litter'**
  String litterDeliveryEvent(String damName);

  /// Label for 8 weeks old puppies
  ///
  /// In en, this message translates to:
  /// **'8 weeks old'**
  String get eightWeeksOld;

  /// Placeholder for unknown dog name
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownDog;

  /// Calendar event for puppy vaccination
  ///
  /// In en, this message translates to:
  /// **'{puppyName} - Vaccination {number}'**
  String puppyVaccination(String puppyName, String number);

  /// Calendar event for puppy deworming
  ///
  /// In en, this message translates to:
  /// **'{puppyName} - Deworming {number}'**
  String puppyDeworming(String puppyName, String number);

  /// Calendar event for puppy microchipping
  ///
  /// In en, this message translates to:
  /// **'{puppyName} - Microchipping'**
  String puppyMicrochip(String puppyName);

  /// Calendar event for dog birthday
  ///
  /// In en, this message translates to:
  /// **'{dogName} turns {age} years'**
  String dogBirthdayAge(String dogName, String age);

  /// Filter label for expected heat cycles
  ///
  /// In en, this message translates to:
  /// **'Heat cycles (expected)'**
  String get expectedHeatCycles;

  /// Filter label for estimated birth date
  ///
  /// In en, this message translates to:
  /// **'Estimated birth date'**
  String get estimatedBirthDate;

  /// Label for kennel selector
  ///
  /// In en, this message translates to:
  /// **'Select kennel'**
  String get selectKennel;

  /// Singular form of member
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get memberSingular;

  /// Plural form of members
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get membersPlural;

  /// Section header for members
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersSection;

  /// Label indicating current user
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// Owner role label
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerRole;

  /// Administrator role label
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administratorRole;

  /// Member role label
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberRole;

  /// Button to remove member
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// Section header for pending invitations
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get pendingInvitations;

  /// Invitation expiration info
  ///
  /// In en, this message translates to:
  /// **'Open invitation • Expires in {days} days'**
  String openInvitationExpires(String days);

  /// Snackbar message when code copied
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get codeCopiedToClipboard;

  /// Section header for actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsSection;

  /// Subtitle for invite member button
  ///
  /// In en, this message translates to:
  /// **'Create invitation code'**
  String get createInvitationCode;

  /// Button to join a kennel
  ///
  /// In en, this message translates to:
  /// **'Join kennel'**
  String get joinKennelLabel;

  /// Subtitle for join kennel button
  ///
  /// In en, this message translates to:
  /// **'Use invitation code'**
  String get useInvitationCode;

  /// Button to delete a kennel
  ///
  /// In en, this message translates to:
  /// **'Delete kennel'**
  String get deleteKennelLabel;

  /// Required kennel name field label
  ///
  /// In en, this message translates to:
  /// **'Kennel name *'**
  String get kennelNameRequired;

  /// Validation message for required name
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// Create button label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// Instruction for entering invitation code
  ///
  /// In en, this message translates to:
  /// **'Enter the invitation code you received:'**
  String get enterInvitationCodeMessage;

  /// Label for invitation code field
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get invitationCode;

  /// Hint for invitation code field
  ///
  /// In en, this message translates to:
  /// **'E.g. ABC123'**
  String get invitationCodeHint;

  /// Success message when joining kennel
  ///
  /// In en, this message translates to:
  /// **'You have joined the kennel!'**
  String get joinedKennelSuccess;

  /// Join button label
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// Dialog title for editing kennel
  ///
  /// In en, this message translates to:
  /// **'Edit kennel'**
  String get editKennel;

  /// Label for kennel name field
  ///
  /// In en, this message translates to:
  /// **'Kennel name'**
  String get kennelNameLabel;

  /// Success message when kennel updated
  ///
  /// In en, this message translates to:
  /// **'Kennel updated!'**
  String get kennelUpdated;

  /// Dialog title for changing role
  ///
  /// In en, this message translates to:
  /// **'Change role for {name}'**
  String changeRoleFor(String name);

  /// Dialog title for removing member
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get removeMemberQuestion;

  /// Confirmation for removing member
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from the kennel?'**
  String confirmRemoveMember(String name);

  /// Success message when member removed
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// Dialog title for leaving kennel
  ///
  /// In en, this message translates to:
  /// **'Leave kennel?'**
  String get leaveKennelQuestion;

  /// Confirmation for leaving kennel
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave {name}? You will lose access to all data.'**
  String confirmLeaveKennel(String name);

  /// Success message when left kennel
  ///
  /// In en, this message translates to:
  /// **'You have left the kennel'**
  String get leftKennel;

  /// Leave button label
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveButton;

  /// Dialog title for deleting kennel
  ///
  /// In en, this message translates to:
  /// **'Delete kennel?'**
  String get deleteKennelQuestion;

  /// Confirmation for deleting kennel
  ///
  /// In en, this message translates to:
  /// **'Are you ABSOLUTELY sure you want to delete {name}? This cannot be undone!'**
  String confirmDeleteKennel(String name);

  /// Success message when kennel deleted
  ///
  /// In en, this message translates to:
  /// **'Kennel deleted'**
  String get kennelDeleted;

  /// Description for invitation creation
  ///
  /// In en, this message translates to:
  /// **'You can create an invitation code that others can use to join the kennel.'**
  String get invitationCodeDescription;

  /// Label for optional email field
  ///
  /// In en, this message translates to:
  /// **'Email address (optional)'**
  String get emailOptional;

  /// Placeholder for email field
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get emailPlaceholder;

  /// Helper text for email field
  ///
  /// In en, this message translates to:
  /// **'Leave empty for open invitation'**
  String get leaveEmptyForOpen;

  /// Label for role selection
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// Description for member role
  ///
  /// In en, this message translates to:
  /// **'Can view and edit data'**
  String get canViewAndEdit;

  /// Description for admin role
  ///
  /// In en, this message translates to:
  /// **'Can also invite members'**
  String get canAlsoInvite;

  /// Button to create invitation
  ///
  /// In en, this message translates to:
  /// **'Create invitation'**
  String get createInvitation;

  /// Success message when invitation created
  ///
  /// In en, this message translates to:
  /// **'Invitation created!'**
  String get invitationCreated;

  /// Instruction for sharing invitation code
  ///
  /// In en, this message translates to:
  /// **'Share this code with the person you want to invite:'**
  String get shareCodeMessage;

  /// Invitation validity period
  ///
  /// In en, this message translates to:
  /// **'Valid for 7 days'**
  String get validFor7Days;

  /// Label for share options
  ///
  /// In en, this message translates to:
  /// **'Share the invitation:'**
  String get shareInvitationLabel;

  /// Copy button label
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// Email button label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailButtonLabel;

  /// Share button label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButtonLabel;

  /// Done/Finished button label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get finishedButton;

  /// Email subject for invitation
  ///
  /// In en, this message translates to:
  /// **'Invitation to {kennelName} on Breedly'**
  String invitationEmailSubject(String kennelName);

  /// Email body for invitation
  ///
  /// In en, this message translates to:
  /// **'Hi!\n\nYou have been invited to join {kennelName} on the Breedly app.\n\nYour invitation code is: {code}\n\nHow to join:\n1. Download the Breedly app if you don\'t have it\n2. Log in or create an account\n3. Go to Settings → Kennel Management\n4. Tap \"Join kennel\"\n5. Enter the code: {code}\n\nThe code is valid for 7 days.\n\nWelcome!\n'**
  String invitationEmailBody(String kennelName, String code);

  /// Error when email client cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open email client'**
  String get couldNotOpenEmail;

  /// Share message for invitation
  ///
  /// In en, this message translates to:
  /// **'You have been invited to {kennelName} on Breedly!\n\n🐕 Invitation code: {code}\n\nOpen the Breedly app, go to Settings → Kennel Management → \"Join kennel\" and enter the code.\n\nThe code is valid for 7 days.'**
  String invitationShareMessage(String kennelName, String code);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// Success message when kennel created
  ///
  /// In en, this message translates to:
  /// **'Kennel created!'**
  String get kennelCreatedSuccess;

  /// Title for kennel profile screen
  ///
  /// In en, this message translates to:
  /// **'Kennel Profile'**
  String get kennelProfile;

  /// Success message when kennel profile saved
  ///
  /// In en, this message translates to:
  /// **'Kennel profile saved'**
  String get kennelProfileSaved;

  /// Section header for kennel info
  ///
  /// In en, this message translates to:
  /// **'Kennel Information'**
  String get kennelInfo;

  /// Label for kennel name input field
  ///
  /// In en, this message translates to:
  /// **'Kennel name'**
  String get kennelNameFieldLabel;

  /// Hint for kennel name field
  ///
  /// In en, this message translates to:
  /// **'E.g. \"Nordlys Kennel\"'**
  String get kennelNameHint;

  /// Label for optional description field
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// Hint for kennel description field
  ///
  /// In en, this message translates to:
  /// **'Tell a little about your kennel...'**
  String get kennelDescriptionHint;

  /// Section header for breeds
  ///
  /// In en, this message translates to:
  /// **'Breeds'**
  String get breedsSection;

  /// Instruction for selecting breeds
  ///
  /// In en, this message translates to:
  /// **'Select the breeds you breed'**
  String get selectBreedsForBreeding;

  /// Placeholder for breed selection
  ///
  /// In en, this message translates to:
  /// **'Tap to select breeds...'**
  String get tapToSelectBreeds;

  /// Singular breed selected count
  ///
  /// In en, this message translates to:
  /// **'breed selected'**
  String get breedSelectedSingular;

  /// Plural breeds selected count
  ///
  /// In en, this message translates to:
  /// **'breeds selected'**
  String get breedsSelectedPlural;

  /// Section header for contact info
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// Label for optional phone field
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// Label for optional address field
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// Label for optional website field
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get websiteOptional;

  /// Button to save kennel profile
  ///
  /// In en, this message translates to:
  /// **'Save kennel profile'**
  String get saveKennelProfile;

  /// Dialog title for breed selection
  ///
  /// In en, this message translates to:
  /// **'Select breeds'**
  String get selectBreeds;

  /// Count of selected items
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String nSelected(String count);

  /// Message when no breeds match search
  ///
  /// In en, this message translates to:
  /// **'No breeds found for \"{query}\"'**
  String noBreedsFoundFor(String query);

  /// Empty state for gallery
  ///
  /// In en, this message translates to:
  /// **'No images yet'**
  String get noImagesYet;

  /// Instruction to add photos
  ///
  /// In en, this message translates to:
  /// **'Tap + to add photos'**
  String get tapToAddPhotos;

  /// Dialog title for image details
  ///
  /// In en, this message translates to:
  /// **'Image details'**
  String get imageDetails;

  /// File size display
  ///
  /// In en, this message translates to:
  /// **'File size: {size} MB'**
  String fileSizeLabel(String size);

  /// Description label with value
  ///
  /// In en, this message translates to:
  /// **'Description: {value}'**
  String descriptionWithValue(String value);

  /// Dialog title for editing image notes
  ///
  /// In en, this message translates to:
  /// **'Edit image notes'**
  String get editImageNotes;

  /// Label for description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// Success message when image notes updated
  ///
  /// In en, this message translates to:
  /// **'Image notes updated'**
  String get imageNotesUpdated;

  /// Dialog title for deleting image
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get deleteImage;

  /// Success message when image deleted
  ///
  /// In en, this message translates to:
  /// **'Image deleted'**
  String get imageDeleted;

  /// Prompt text for global search
  ///
  /// In en, this message translates to:
  /// **'Search for dogs, litters, puppies or buyers'**
  String get searchPrompt;

  /// Title for export screen
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// Loading text during export
  ///
  /// In en, this message translates to:
  /// **'Exporting {item}...'**
  String exportingItem(String item);

  /// Success message when export completed
  ///
  /// In en, this message translates to:
  /// **'Export completed!'**
  String get exportCompleted;

  /// Error message during export
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportError(String error);

  /// Success message when item exported
  ///
  /// In en, this message translates to:
  /// **'{item} exported!'**
  String itemExported(String item);

  /// Info card title for export
  ///
  /// In en, this message translates to:
  /// **'About export'**
  String get aboutExport;

  /// Description of export format
  ///
  /// In en, this message translates to:
  /// **'Data is exported as CSV files that can be opened in Excel, Google Sheets or other spreadsheet programs. Files use UTF-8 with BOM to support special characters.'**
  String get exportDescription;

  /// Button to export all data
  ///
  /// In en, this message translates to:
  /// **'Export all'**
  String get exportAll;

  /// Label for individual export section
  ///
  /// In en, this message translates to:
  /// **'Or export individually'**
  String get orExportIndividually;

  /// Description for dogs export
  ///
  /// In en, this message translates to:
  /// **'All registered dogs with pedigree info'**
  String get exportDogsDesc;

  /// Description for litters export
  ///
  /// In en, this message translates to:
  /// **'All litters with parents and puppy status'**
  String get exportLittersDesc;

  /// Description for puppies export
  ///
  /// In en, this message translates to:
  /// **'All puppies with details and sales status'**
  String get exportPuppiesDesc;

  /// Description for expenses export
  ///
  /// In en, this message translates to:
  /// **'All expenses sorted by date'**
  String get exportExpensesDesc;

  /// Description for income export
  ///
  /// In en, this message translates to:
  /// **'All income sorted by date'**
  String get exportIncomeDesc;

  /// Description for financial summary export
  ///
  /// In en, this message translates to:
  /// **'Annual overview of results'**
  String get exportFinancialSummaryDesc;

  /// Description for litter statistics export
  ///
  /// In en, this message translates to:
  /// **'Statistics per breed'**
  String get exportLitterStatsDesc;

  /// Label for all data in export
  ///
  /// In en, this message translates to:
  /// **'all data'**
  String get allData;

  /// Empty state for contracts
  ///
  /// In en, this message translates to:
  /// **'No contracts'**
  String get noContracts;

  /// Instruction to create contract
  ///
  /// In en, this message translates to:
  /// **'Create a purchase contract for this puppy'**
  String get createPurchaseContractForPuppy;

  /// Contract number display
  ///
  /// In en, this message translates to:
  /// **'Contract no. {number}'**
  String contractNumberLabel(String number);

  /// Draft status label
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// Active status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// Completed status label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Cancelled status label
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Dialog title for deleting contract
  ///
  /// In en, this message translates to:
  /// **'Delete contract'**
  String get deleteContract;

  /// Success message when contract deleted
  ///
  /// In en, this message translates to:
  /// **'Contract deleted'**
  String get contractDeleted;

  /// Label for creation date
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdDate;

  /// Label for purchase date
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchasedDate;

  /// Label for terms section
  ///
  /// In en, this message translates to:
  /// **'Terms:'**
  String get termsLabel;

  /// Contract term for spay/neuter requirement
  ///
  /// In en, this message translates to:
  /// **'Spay/neuter required'**
  String get spayNeuterRequired;

  /// Button to create new contract
  ///
  /// In en, this message translates to:
  /// **'New contract'**
  String get newContract;

  /// Description for purchase contract option
  ///
  /// In en, this message translates to:
  /// **'Full sales contract for the puppy'**
  String get fullSalesContract;

  /// Description for reservation contract option
  ///
  /// In en, this message translates to:
  /// **'Reserve the puppy with a deposit'**
  String get reserveWithDeposit;

  /// Title for reservation contract option
  ///
  /// In en, this message translates to:
  /// **'Reservation agreement'**
  String get reservationAgreement;

  /// Generic export error message
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportErrorGeneric(String error);

  /// Title for photo gallery screen
  ///
  /// In en, this message translates to:
  /// **'{damName} - Photo Gallery'**
  String photoGalleryTitle(String damName);

  /// Menu item for edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editMenu;

  /// Menu item to delete litter
  ///
  /// In en, this message translates to:
  /// **'Delete litter'**
  String get deleteLitterMenu;

  /// Tab label for puppies
  ///
  /// In en, this message translates to:
  /// **'Puppies'**
  String get tabPuppies;

  /// Tab label for registration
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get tabRegistration;

  /// Label for planned litter
  ///
  /// In en, this message translates to:
  /// **'Planned litter'**
  String get plannedLitterLabel;

  /// Label for litter info
  ///
  /// In en, this message translates to:
  /// **'Litter info'**
  String get litterInfoLabel;

  /// Label for dam/mother
  ///
  /// In en, this message translates to:
  /// **'Dam'**
  String get damLabel;

  /// Label for sire/father
  ///
  /// In en, this message translates to:
  /// **'Sire'**
  String get sireLabel;

  /// Label for breed
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get breedLabel;

  /// Label for age
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// Label for total puppies count
  ///
  /// In en, this message translates to:
  /// **'Total puppies'**
  String get totalPuppiesLabel;

  /// Label for males
  ///
  /// In en, this message translates to:
  /// **'Males'**
  String get malesLabel;

  /// Label for females
  ///
  /// In en, this message translates to:
  /// **'Females'**
  String get femalesLabel;

  /// Label for mating date
  ///
  /// In en, this message translates to:
  /// **'Mating date'**
  String get matingDateLabel;

  /// Label for estimated due date
  ///
  /// In en, this message translates to:
  /// **'Estimated due date'**
  String get estimatedDueDateLabel;

  /// Label for days until whelping
  ///
  /// In en, this message translates to:
  /// **'Days until whelping'**
  String get daysUntilWhelpingLabel;

  /// Days to estimated birth
  ///
  /// In en, this message translates to:
  /// **'{days} days to estimated birth'**
  String daysToEstimatedBirth(int days);

  /// When estimated date is in the past
  ///
  /// In en, this message translates to:
  /// **'Estimated due date has passed'**
  String get estimatedDatePassed;

  /// When no mating date is set
  ///
  /// In en, this message translates to:
  /// **'Set mating date to calculate due date'**
  String get setMatingDateToCalculate;

  /// Button to register birth
  ///
  /// In en, this message translates to:
  /// **'Register birth'**
  String get registerBirthButton;

  /// Label for planning tools section
  ///
  /// In en, this message translates to:
  /// **'Planning tools'**
  String get planningToolsLabel;

  /// Label for temperature
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// Label for progesterone
  ///
  /// In en, this message translates to:
  /// **'Progesterone'**
  String get progesteroneLabel;

  /// Label for edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// Label for birth
  ///
  /// In en, this message translates to:
  /// **'Birth'**
  String get birthLabel;

  /// Mating date with value
  ///
  /// In en, this message translates to:
  /// **'Mating date: {date}'**
  String matingDateColon(String date);

  /// When no mating date is set
  ///
  /// In en, this message translates to:
  /// **'No mating date set'**
  String get noMatingDateSet;

  /// Button label for set date
  ///
  /// In en, this message translates to:
  /// **'Set date'**
  String get setDateLabel;

  /// Estimated birth with date
  ///
  /// In en, this message translates to:
  /// **'Estimated birth: {date}'**
  String estimatedBirthColon(String date);

  /// Days remaining
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysLeft(int days);

  /// Help text for mating date picker
  ///
  /// In en, this message translates to:
  /// **'Select mating date'**
  String get selectMatingDateLabel;

  /// Snackbar after setting mating date
  ///
  /// In en, this message translates to:
  /// **'Mating date set to {matingDate}. Estimated birth: {dueDate}'**
  String matingDateSetSnackbar(String matingDate, String dueDate);

  /// Error when dam not found
  ///
  /// In en, this message translates to:
  /// **'Could not find the dam'**
  String get couldNotFindDam;

  /// Dialog title for register birth
  ///
  /// In en, this message translates to:
  /// **'Register birth'**
  String get registerBirthTitle;

  /// Birth confirmation text
  ///
  /// In en, this message translates to:
  /// **'The litter is now born! Do you want to update the birth date to today?'**
  String get litterBornConfirmText;

  /// Info text after birth registration
  ///
  /// In en, this message translates to:
  /// **'You can then add puppies manually.'**
  String get canThenAddPuppies;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// Register button label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLabel;

  /// Snackbar after birth registered
  ///
  /// In en, this message translates to:
  /// **'Birth registered! You can now add puppies.'**
  String get birthRegisteredSnackbar;

  /// When no puppies in litter
  ///
  /// In en, this message translates to:
  /// **'No puppies yet'**
  String get noPuppiesYet;

  /// Hint to add puppies
  ///
  /// In en, this message translates to:
  /// **'Go to the Puppies tab to add puppies'**
  String get goToPuppiesTabHint;

  /// Puppies with count
  ///
  /// In en, this message translates to:
  /// **'Puppies ({count})'**
  String puppiesCount2(int count);

  /// Label for available status
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// Label for reserved status
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reservedLabel;

  /// Label for sold status
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get soldLabel;

  /// Section label for quick actions
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActionsLabel;

  /// Label for weighing
  ///
  /// In en, this message translates to:
  /// **'Weighing'**
  String get weighingLabel;

  /// Label for adding new puppy
  ///
  /// In en, this message translates to:
  /// **'New puppy'**
  String get newPuppyLabel;

  /// Label for treatment overview
  ///
  /// In en, this message translates to:
  /// **'Treatment overview'**
  String get treatmentOverviewLabel;

  /// Label for vaccinated
  ///
  /// In en, this message translates to:
  /// **'Vaccinated'**
  String get vaccinatedLabel;

  /// Label for dewormed
  ///
  /// In en, this message translates to:
  /// **'Dewormed'**
  String get dewormedLabel;

  /// Label for microchipped
  ///
  /// In en, this message translates to:
  /// **'Microchipped'**
  String get microchippedLabel;

  /// Day/days unit
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String dayUnit(int count);

  /// Week/weeks unit
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{week} other{weeks}}'**
  String weekUnit(int count);

  /// Weeks and days format
  ///
  /// In en, this message translates to:
  /// **'{weeks} {weekLabel} and {days} {dayLabel}'**
  String weeksAndDays(int weeks, String weekLabel, int days, String dayLabel);

  /// Today in parentheses
  ///
  /// In en, this message translates to:
  /// **'(today)'**
  String get todayParens;

  /// Tomorrow in parentheses
  ///
  /// In en, this message translates to:
  /// **'(tomorrow)'**
  String get tomorrowParens;

  /// Yesterday in parentheses
  ///
  /// In en, this message translates to:
  /// **'(yesterday)'**
  String get yesterdayParens;

  /// Label for summary
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryLabel;

  /// Button label for adding puppy
  ///
  /// In en, this message translates to:
  /// **'Add puppy'**
  String get addPuppyLabel;

  /// Label for total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// Label for puppy list
  ///
  /// In en, this message translates to:
  /// **'Puppy list'**
  String get puppyListLabel;

  /// Empty state for puppy list
  ///
  /// In en, this message translates to:
  /// **'No puppies registered yet'**
  String get noPuppiesRegisteredYet;

  /// Puppy color and age
  ///
  /// In en, this message translates to:
  /// **'Color: {color} • Age: {weeks} weeks'**
  String colorAge(String color, int weeks);

  /// Section label for basic info
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get basicInfoLabel;

  /// Label for gender
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// Label for birth weight
  ///
  /// In en, this message translates to:
  /// **'Birth weight'**
  String get birthWeightLabel;

  /// Section label for treatments
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get treatmentsLabel;

  /// Yes label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// Section label for buyer
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyerLabel;

  /// Label for name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Label for contact
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactLabel;

  /// Section label for notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// Button label for weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightButton;

  /// Button label for plan
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planButton;

  /// Button label for contract
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contractButton;

  /// Button label for health certificate
  ///
  /// In en, this message translates to:
  /// **'Health cert.'**
  String get healthCertificateButton;

  /// Button label for share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// Label for temperature registration section
  ///
  /// In en, this message translates to:
  /// **'Temperature registration'**
  String get temperatureRegistrationLabel;

  /// Description for temp registration
  ///
  /// In en, this message translates to:
  /// **'Register temperature on the dam before estimated birth'**
  String get registerTempBeforeBirth;

  /// Button to open temperature log
  ///
  /// In en, this message translates to:
  /// **'Open temperature log'**
  String get openTemperatureLogButton;

  /// Label for puppy weight section
  ///
  /// In en, this message translates to:
  /// **'Puppy weight'**
  String get puppyWeightLabel;

  /// Button to register weight for all
  ///
  /// In en, this message translates to:
  /// **'Register weight for all puppies'**
  String get registerWeightForAll;

  /// Short empty state for puppies
  ///
  /// In en, this message translates to:
  /// **'No puppies registered'**
  String get noPuppiesRegisteredShort;

  /// Dialog title for editing puppy
  ///
  /// In en, this message translates to:
  /// **'Edit puppy'**
  String get editPuppyTitle;

  /// Label for status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// Label for birth weight in grams
  ///
  /// In en, this message translates to:
  /// **'Birth weight (grams)'**
  String get birthWeightGramsLabel;

  /// Label for birth note
  ///
  /// In en, this message translates to:
  /// **'Birth note'**
  String get birthNoteLabel;

  /// Label for buyer name
  ///
  /// In en, this message translates to:
  /// **'Buyer name'**
  String get buyerNameLabel;

  /// Label for buyer contact
  ///
  /// In en, this message translates to:
  /// **'Buyer contact'**
  String get buyerContactLabel;

  /// Label for notes field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesFieldLabel;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// Snackbar after puppy update
  ///
  /// In en, this message translates to:
  /// **'Puppy updated'**
  String get puppyUpdatedSnackbar;

  /// Weight curve dialog title
  ///
  /// In en, this message translates to:
  /// **'{name} - Weight curve'**
  String weightCurveTitle(String name);

  /// Note for birth weight entry
  ///
  /// In en, this message translates to:
  /// **'Birth weight'**
  String get birthWeightNote;

  /// X-axis label for weight chart
  ///
  /// In en, this message translates to:
  /// **'Days since birth'**
  String get daysSinceBirthAxis;

  /// Y-axis label for weight chart
  ///
  /// In en, this message translates to:
  /// **'Gram'**
  String get gramAxis;

  /// Empty state for weight chart
  ///
  /// In en, this message translates to:
  /// **'No weight measurements or birth weight registered'**
  String get noWeightOrBirthWeight;

  /// Label for measurement list
  ///
  /// In en, this message translates to:
  /// **'Registered measurements:'**
  String get registeredMeasurements;

  /// Weight in grams
  ///
  /// In en, this message translates to:
  /// **'{weight} gram'**
  String gramUnit(String weight);

  /// Day and date label
  ///
  /// In en, this message translates to:
  /// **'Day {day} - {date}'**
  String dayDateLabel(int day, String date);

  /// Snackbar after weight deletion
  ///
  /// In en, this message translates to:
  /// **'Weight measurement deleted'**
  String get weightMeasurementDeleted;

  /// Button to add measurement
  ///
  /// In en, this message translates to:
  /// **'Add measurement'**
  String get addMeasurementButton;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// Dialog title for adding weight
  ///
  /// In en, this message translates to:
  /// **'Add weight measurement'**
  String get addWeightMeasurementTitle;

  /// Label for date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// Label for time/clock
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get clockLabel;

  /// Label for weight in grams
  ///
  /// In en, this message translates to:
  /// **'Weight (grams)'**
  String get weightGramsLabel;

  /// Snackbar after weight added
  ///
  /// In en, this message translates to:
  /// **'Weight measurement added'**
  String get weightMeasurementAddedSnackbar;

  /// Dialog title for bulk weight
  ///
  /// In en, this message translates to:
  /// **'Register weight for all puppies'**
  String get registerWeightForAllTitle;

  /// Label for optional notes
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptionalLabel;

  /// Button label for save all
  ///
  /// In en, this message translates to:
  /// **'Save all'**
  String get saveAllLabel;

  /// Snackbar after bulk weight save
  ///
  /// In en, this message translates to:
  /// **'{count} weight measurements saved'**
  String weightMeasurementsSavedSnackbar(int count);

  /// Dialog title for editing weight
  ///
  /// In en, this message translates to:
  /// **'Edit weight measurement'**
  String get editWeightMeasurementTitle;

  /// Snackbar after weight update
  ///
  /// In en, this message translates to:
  /// **'Weight measurement updated'**
  String get weightMeasurementUpdatedSnackbar;

  /// Treatment plan dialog title
  ///
  /// In en, this message translates to:
  /// **'{name} - Treatment plan'**
  String treatmentPlanTitle(String name);

  /// Section label for deworming
  ///
  /// In en, this message translates to:
  /// **'Deworming:'**
  String get dewormingLabel;

  /// First deworming label
  ///
  /// In en, this message translates to:
  /// **'1st deworming (approx. 2 weeks)'**
  String get deworming1;

  /// Second deworming label
  ///
  /// In en, this message translates to:
  /// **'2nd deworming (approx. 4 weeks)'**
  String get deworming2;

  /// Third deworming label
  ///
  /// In en, this message translates to:
  /// **'3rd deworming (approx. 6 weeks)'**
  String get deworming3;

  /// Section label for vaccines
  ///
  /// In en, this message translates to:
  /// **'Vaccines:'**
  String get vaccinesLabel;

  /// First vaccination label
  ///
  /// In en, this message translates to:
  /// **'1st vaccination (8 weeks)'**
  String get vaccine1;

  /// Second vaccination label
  ///
  /// In en, this message translates to:
  /// **'2nd vaccination (12 weeks)'**
  String get vaccine2;

  /// Third vaccination label
  ///
  /// In en, this message translates to:
  /// **'3rd vaccination (16 weeks)'**
  String get vaccine3;

  /// Section label for other
  ///
  /// In en, this message translates to:
  /// **'Other:'**
  String get otherLabel;

  /// Label for ID marking
  ///
  /// In en, this message translates to:
  /// **'ID marking'**
  String get idMarkingLabel;

  /// Label for ID marking number
  ///
  /// In en, this message translates to:
  /// **'ID marking number'**
  String get idMarkingNumberLabel;

  /// Placeholder for date selection
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDateLabel;

  /// Snackbar after treatment plan saved
  ///
  /// In en, this message translates to:
  /// **'Treatment plan updated and reminders scheduled'**
  String get treatmentPlanUpdatedSnackbar;

  /// Notification title for PDF download
  ///
  /// In en, this message translates to:
  /// **'PDF downloaded'**
  String get pdfDownloadedTitle;

  /// Snackbar for PDF save
  ///
  /// In en, this message translates to:
  /// **'PDF saved:\n{path}'**
  String pdfSavedSnackbar(String path);

  /// Error for PDF generation
  ///
  /// In en, this message translates to:
  /// **'Error generating PDF: {error}'**
  String errorGeneratingPdf(String error);

  /// Title for health certificate dialog
  ///
  /// In en, this message translates to:
  /// **'Health certificate'**
  String get healthCertificateTitle;

  /// Subtitle for health cert
  ///
  /// In en, this message translates to:
  /// **'Generate health certificate for {name}'**
  String generateHealthCertFor(String name);

  /// Section label for health exam
  ///
  /// In en, this message translates to:
  /// **'Health examination'**
  String get healthExaminationLabel;

  /// Hint for adding notes
  ///
  /// In en, this message translates to:
  /// **'Tap an item to add a note'**
  String get tapToAddNote;

  /// Health check: general condition
  ///
  /// In en, this message translates to:
  /// **'General condition'**
  String get generalConditionLabel;

  /// Health check: eyes
  ///
  /// In en, this message translates to:
  /// **'Eyes'**
  String get eyesLabel;

  /// Health check: ears
  ///
  /// In en, this message translates to:
  /// **'Ears'**
  String get earsLabel;

  /// Health check: heart
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get heartLabel;

  /// Health check: lungs
  ///
  /// In en, this message translates to:
  /// **'Lungs'**
  String get lungsLabel;

  /// Health check: skin/coat
  ///
  /// In en, this message translates to:
  /// **'Skin/coat'**
  String get skinCoatLabel;

  /// Health check: teeth/mouth
  ///
  /// In en, this message translates to:
  /// **'Teeth/mouth'**
  String get teethMouthLabel;

  /// Health check: abdomen
  ///
  /// In en, this message translates to:
  /// **'Abdomen'**
  String get abdomenLabel;

  /// Health check: limbs/joints
  ///
  /// In en, this message translates to:
  /// **'Limbs/joints'**
  String get limbsJointsLabel;

  /// Label for vet info section
  ///
  /// In en, this message translates to:
  /// **'Veterinary information (optional):'**
  String get vetInfoOptional;

  /// Label for vet name
  ///
  /// In en, this message translates to:
  /// **'Veterinarian name'**
  String get vetNameLabel;

  /// Label for phone
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// Label for general notes
  ///
  /// In en, this message translates to:
  /// **'General notes'**
  String get generalNotesLabel;

  /// Button to generate PDF
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get generatePdfButton;

  /// Hint for adding note
  ///
  /// In en, this message translates to:
  /// **'Add note for {label}...'**
  String addNoteFor(String label);

  /// Notification for health cert download
  ///
  /// In en, this message translates to:
  /// **'Health certificate downloaded'**
  String get healthCertificateDownloaded;

  /// Snackbar for health cert save
  ///
  /// In en, this message translates to:
  /// **'Health certificate saved:\n{path}'**
  String healthCertSavedSnackbar(String path);

  /// Error for health cert generation
  ///
  /// In en, this message translates to:
  /// **'Error generating health certificate: {error}'**
  String errorGeneratingHealthCert(String error);

  /// Dialog title for sharing update
  ///
  /// In en, this message translates to:
  /// **'Share update'**
  String get shareUpdateTitle;

  /// Subtitle for share dialog
  ///
  /// In en, this message translates to:
  /// **'Share update about {name} with buyer'**
  String shareUpdateAbout(String name);

  /// Label for message inclusions
  ///
  /// In en, this message translates to:
  /// **'Include in message:'**
  String get includeInMessage;

  /// Checkbox label for age
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageCheckbox;

  /// Checkbox label for weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightCheckbox;

  /// Checkbox label for treatments
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get treatmentsCheckbox;

  /// Label for custom message
  ///
  /// In en, this message translates to:
  /// **'Custom message (optional)'**
  String get customMessageOptional;

  /// Hint for greeting field
  ///
  /// In en, this message translates to:
  /// **'Write a personal greeting...'**
  String get personalGreetingHint;

  /// Subject for update message
  ///
  /// In en, this message translates to:
  /// **'Update about {name}'**
  String updateAbout(String name);

  /// Dialog title for editing litter
  ///
  /// In en, this message translates to:
  /// **'Edit litter'**
  String get editLitterTitle;

  /// Label for dam field
  ///
  /// In en, this message translates to:
  /// **'Dam (Female) *'**
  String get damFemaleLabel;

  /// Label for sire field
  ///
  /// In en, this message translates to:
  /// **'Sire (Male) *'**
  String get sireMaleLabel;

  /// Label for puppy count section
  ///
  /// In en, this message translates to:
  /// **'Puppy count (based on registered puppies):'**
  String get puppyCountBasedOnRegistered;

  /// Info about automatic count update
  ///
  /// In en, this message translates to:
  /// **'These numbers update automatically when you add or delete puppies.'**
  String get updatesAutomatically;

  /// Validation for dam/sire fields
  ///
  /// In en, this message translates to:
  /// **'Dam and Sire are required'**
  String get damAndSireRequired;

  /// Snackbar after litter update
  ///
  /// In en, this message translates to:
  /// **'Litter updated'**
  String get litterUpdatedSnackbar;

  /// Dialog title for deleting litter
  ///
  /// In en, this message translates to:
  /// **'Delete litter?'**
  String get deleteLitterTitle;

  /// Confirmation for litter deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the litter from {damName} x {sireName}?\n\nNote: This will also delete all puppies in the litter!'**
  String confirmDeleteLitterText(String damName, String sireName);

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// Snackbar after litter deletion
  ///
  /// In en, this message translates to:
  /// **'Litter deleted'**
  String get litterDeletedSnackbar;

  /// Label for placed percentage
  ///
  /// In en, this message translates to:
  /// **'placed'**
  String get placedLabel;

  /// Role label for owner
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerRoleLabel;

  /// Button to skip onboarding
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// Button to get started
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStartedButton;

  /// Onboarding page 1 title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Breedly'**
  String get onboardingWelcomeTitle;

  /// Onboarding page 1 description
  ///
  /// In en, this message translates to:
  /// **'Your complete solution for breeding management. Keep track of dogs, litters, buyers and much more.'**
  String get onboardingWelcomeDesc;

  /// Onboarding page 2 title
  ///
  /// In en, this message translates to:
  /// **'Manage your dogs'**
  String get onboardingDogsTitle;

  /// Onboarding page 2 description
  ///
  /// In en, this message translates to:
  /// **'Add dogs with pedigree, health information, show results and photos. All in one place.'**
  String get onboardingDogsDesc;

  /// Onboarding page 3 title
  ///
  /// In en, this message translates to:
  /// **'Track litters and puppies'**
  String get onboardingLittersTitle;

  /// Onboarding page 3 description
  ///
  /// In en, this message translates to:
  /// **'Register litters, follow puppy development with weight logs, and generate contracts for buyers.'**
  String get onboardingLittersDesc;

  /// Onboarding page 4 title
  ///
  /// In en, this message translates to:
  /// **'Calendar and reminders'**
  String get onboardingCalendarTitle;

  /// Onboarding page 4 description
  ///
  /// In en, this message translates to:
  /// **'Never forget important dates. Get notifications for vaccinations, vet visits and other events.'**
  String get onboardingCalendarDesc;

  /// Onboarding page 5 title
  ///
  /// In en, this message translates to:
  /// **'Statistics and reports'**
  String get onboardingStatsTitle;

  /// Onboarding page 5 description
  ///
  /// In en, this message translates to:
  /// **'Get insights into your breeding with detailed statistics, financial overview and annual reports.'**
  String get onboardingStatsDesc;

  /// Tab label for info
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get tabInfo;

  /// Label for optional vet info section
  ///
  /// In en, this message translates to:
  /// **'Veterinary information (optional):'**
  String get veterinaryInfoOptional;

  /// Confirmation message for deleting litter
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the litter from {damName} x {sireName}?\n\nNOTE: This will also delete all puppies in the litter!'**
  String deleteLitterConfirmMessage(String damName, String sireName);

  /// Error when image generation fails
  ///
  /// In en, this message translates to:
  /// **'Could not generate image'**
  String get couldNotGenerateImage;

  /// Section header for content toggles
  ///
  /// In en, this message translates to:
  /// **'CONTENT'**
  String get contentSection;

  /// Toggle label for details section
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsToggle;

  /// Section header for background themes
  ///
  /// In en, this message translates to:
  /// **'BACKGROUND'**
  String get backgroundSection;

  /// Auto-detect theme option
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get autoTheme;

  /// Theme name
  ///
  /// In en, this message translates to:
  /// **'Gold & Black'**
  String get themeGoldBlack;

  /// Theme name
  ///
  /// In en, this message translates to:
  /// **'Navy & Gold'**
  String get themeNavyGold;

  /// Theme name
  ///
  /// In en, this message translates to:
  /// **'Teal & Amber'**
  String get themeTealAmber;

  /// Theme name
  ///
  /// In en, this message translates to:
  /// **'Slate & Silver'**
  String get themeSlateSilver;

  /// Theme name
  ///
  /// In en, this message translates to:
  /// **'Forest & Jade'**
  String get themeForestJade;

  /// Theme name
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get themeIndigo;

  /// Theme name
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get themeClassic;

  /// Section header for pattern selection
  ///
  /// In en, this message translates to:
  /// **'PATTERN'**
  String get patternSection;

  /// No pattern option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get patternNone;

  /// Geometric pattern
  ///
  /// In en, this message translates to:
  /// **'Geometric'**
  String get patternGeometric;

  /// Circles pattern
  ///
  /// In en, this message translates to:
  /// **'Circles'**
  String get patternCircles;

  /// Lines pattern
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get patternLines;

  /// Dots pattern
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get patternDots;

  /// Waves pattern
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get patternWaves;

  /// Elegant pattern
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get patternElegant;

  /// Section header for font type selection
  ///
  /// In en, this message translates to:
  /// **'FONT TYPE'**
  String get fontTypeSection;

  /// Standard font
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get fontStandard;

  /// Serif font
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get fontSerif;

  /// Elegant font
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get fontElegant;

  /// Modern font
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get fontModern;

  /// Classic font
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get fontClassic;

  /// Handwriting font
  ///
  /// In en, this message translates to:
  /// **'Handwriting'**
  String get fontHandwritten;

  /// Section header for font size
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get fontSizeSection;

  /// Title for result card screen
  ///
  /// In en, this message translates to:
  /// **'Result card'**
  String get resultCardTitle;

  /// Tooltip to remove photo
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// Tooltip to add photo
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// Option to select from gallery
  ///
  /// In en, this message translates to:
  /// **'Select from gallery'**
  String get selectFromGallery;

  /// Breed judge label with name
  ///
  /// In en, this message translates to:
  /// **'Breed judge: {name}'**
  String breedJudgeWithName(String name);

  /// Abbreviated class placement
  ///
  /// In en, this message translates to:
  /// **'Cl. {placement}'**
  String classPlacementAbbr(String placement);

  /// Privacy policy title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Privacy policy description
  ///
  /// In en, this message translates to:
  /// **'Read about how we handle your data'**
  String get privacyPolicyDescription;

  /// Label for SMS share option
  ///
  /// In en, this message translates to:
  /// **'Send SMS'**
  String get sendSmsLabel;

  /// Label for email share option
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get sendEmailLabel;

  /// Label for sharing via other apps
  ///
  /// In en, this message translates to:
  /// **'Share via other apps'**
  String get shareViaOtherApps;

  /// Subtitle for other apps share option
  ///
  /// In en, this message translates to:
  /// **'Messenger, WhatsApp, etc.'**
  String get messengerWhatsappEtc;

  /// Label for copy to clipboard option
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyTextLabel;

  /// Snackbar message when text is copied
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard'**
  String get textCopiedToClipboard;

  /// Error when SMS app cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open SMS app'**
  String get couldNotOpenSms;

  /// Default subject for puppy update email
  ///
  /// In en, this message translates to:
  /// **'Puppy update'**
  String get puppyUpdateSubject;

  /// Header for puppy update message
  ///
  /// In en, this message translates to:
  /// **'Update from {kennelName}'**
  String msgUpdateFromKennel(String kennelName);

  /// Fallback kennel name when none is set
  ///
  /// In en, this message translates to:
  /// **'The kennel'**
  String get msgDefaultKennelName;

  /// Puppy name line in message
  ///
  /// In en, this message translates to:
  /// **'Puppy: {name}'**
  String msgPuppy(String name);

  /// Breed line in message
  ///
  /// In en, this message translates to:
  /// **'Breed: {breed}'**
  String msgBreed(String breed);

  /// Age with weeks and days
  ///
  /// In en, this message translates to:
  /// **'Age: {weeks} weeks and {days} days'**
  String msgAgeWeeksAndDays(int weeks, int days);

  /// Age with weeks only
  ///
  /// In en, this message translates to:
  /// **'Age: {weeks} weeks'**
  String msgAgeWeeks(int weeks);

  /// Birth weight line in message
  ///
  /// In en, this message translates to:
  /// **'Birth weight: {weight} g'**
  String msgBirthWeight(String weight);

  /// Status section header
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get msgStatusHeader;

  /// Vaccination status line
  ///
  /// In en, this message translates to:
  /// **'Vaccinated: {status}'**
  String msgVaccinated(String status);

  /// Deworming status line
  ///
  /// In en, this message translates to:
  /// **'Dewormed: {status}'**
  String msgDewormed(String status);

  /// ID tagging status line
  ///
  /// In en, this message translates to:
  /// **'ID tagged: {status}'**
  String msgIdTagged(String status);

  /// Message section header
  ///
  /// In en, this message translates to:
  /// **'Message:'**
  String get msgMessageHeader;

  /// Closing salutation
  ///
  /// In en, this message translates to:
  /// **'Best regards,'**
  String get msgBestRegards;

  /// Contact phone line
  ///
  /// In en, this message translates to:
  /// **'Contact: {phone}'**
  String msgContact(String phone);

  /// Header for litter update message
  ///
  /// In en, this message translates to:
  /// **'Litter update from {kennelName}'**
  String msgLitterUpdateFromKennel(String kennelName);

  /// Litter parents line
  ///
  /// In en, this message translates to:
  /// **'Litter: {damName} × {sireName}'**
  String msgLitter(String damName, String sireName);

  /// Puppy count line
  ///
  /// In en, this message translates to:
  /// **'Number of puppies: {count}'**
  String msgPuppyCount(int count);

  /// Treatment status section header
  ///
  /// In en, this message translates to:
  /// **'Treatment status:'**
  String get msgTreatmentStatus;

  /// Header for delivery reminder message
  ///
  /// In en, this message translates to:
  /// **'Delivery reminder from {kennelName}'**
  String msgDeliveryReminder(String kennelName);

  /// Puppy ready to move home
  ///
  /// In en, this message translates to:
  /// **'{puppyName} is ready to move home to you!'**
  String msgReadyToMoveHome(String puppyName);

  /// Delivery date line
  ///
  /// In en, this message translates to:
  /// **'Delivery date: {date}'**
  String msgDeliveryDate(String date);

  /// Countdown line
  ///
  /// In en, this message translates to:
  /// **'In {count} {dayWord}'**
  String msgInDays(int count, String dayWord);

  /// Singular form of day
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get msgDaySingular;

  /// Plural form of day
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get msgDayPlural;

  /// Delivery is today
  ///
  /// In en, this message translates to:
  /// **'Today!'**
  String get msgToday;

  /// Checklist header
  ///
  /// In en, this message translates to:
  /// **'Remember to bring:'**
  String get msgRememberToBring;

  /// Checklist item
  ///
  /// In en, this message translates to:
  /// **'Transport crate/carrier'**
  String get msgTransportCrate;

  /// Checklist item
  ///
  /// In en, this message translates to:
  /// **'Blanket with home scent'**
  String get msgBlanketWithHomeScent;

  /// Checklist item
  ///
  /// In en, this message translates to:
  /// **'Water for the trip'**
  String get msgWaterForTrip;

  /// Address line
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String msgAddress(String address);

  /// Closing line for delivery reminder
  ///
  /// In en, this message translates to:
  /// **'We look forward to seeing you!'**
  String get msgLookingForward;

  /// Feed screen title
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get feedTitle;

  /// Feed tab for followed kennels
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedFollowing;

  /// Feed tab for all posts
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedAll;

  /// Empty state for following feed
  ///
  /// In en, this message translates to:
  /// **'No news from kennels you follow yet'**
  String get feedNoFollowing;

  /// Empty state for all feed
  ///
  /// In en, this message translates to:
  /// **'No news yet'**
  String get feedNoNews;

  /// Hint for kennel search
  ///
  /// In en, this message translates to:
  /// **'Search for kennels to follow'**
  String get feedSearchKennels;

  /// Delete feed post confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get feedDeleteConfirm;

  /// Filter option for show results
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get feedShowResults;

  /// Filter option for champion titles
  ///
  /// In en, this message translates to:
  /// **'Champion titles'**
  String get feedChampionTitles;

  /// Filter option for litter announcements
  ///
  /// In en, this message translates to:
  /// **'Litter announcements'**
  String get feedLitterAnnouncements;

  /// Filter option for available puppies
  ///
  /// In en, this message translates to:
  /// **'Puppies available'**
  String get feedPuppiesAvailable;

  /// Time ago in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String feedMinutesAgo(int minutes);

  /// Time ago in hours
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String feedHoursAgo(int hours);

  /// Time ago in days
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String feedDaysAgo(int days);

  /// Visibility label for followers-only posts
  ///
  /// In en, this message translates to:
  /// **'Followers only'**
  String get feedFollowersOnly;

  /// Kennel search sheet title
  ///
  /// In en, this message translates to:
  /// **'Find kennels'**
  String get feedSearchKennelsTitle;

  /// Kennel search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search kennel name...'**
  String get feedSearchKennelsHint;

  /// Prompt before searching
  ///
  /// In en, this message translates to:
  /// **'Search for kennels by name'**
  String get feedSearchKennelsPrompt;

  /// Followers count label
  ///
  /// In en, this message translates to:
  /// **'followers'**
  String get feedFollowers;

  /// Follow button text
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get feedFollow;

  /// Unfollow button text
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get feedUnfollow;

  /// Share to feed dialog title
  ///
  /// In en, this message translates to:
  /// **'Share on Breedly?'**
  String get feedShareTitle;

  /// Success message after sharing
  ///
  /// In en, this message translates to:
  /// **'Shared on Breedly!'**
  String get feedPostPublished;

  /// Visibility selector label
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get feedVisibility;

  /// Public visibility option
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get feedPublic;

  /// Skip sharing button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get feedSkip;

  /// Publish to feed button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get feedPublish;

  /// See all link text
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;
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
