import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationsDelegates` list, and the locales they support in the app's
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
/// Make sure to add the following packages to your pubspec.yaml:
///
/// ```yaml
/// dependencies:
///   flutter:
///     sdk: flutter
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
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn')
  ];

  // Common App Strings
  String get appTitle;
  String get appDescription;
  
  // Authentication
  String get signIn;
  String get signUp;
  String get signOut;
  String get email;
  String get password;
  String get confirmPassword;
  String get displayName;
  String get forgotPassword;
  String get resetPassword;
  String get createAccount;
  String get alreadyHaveAccount;
  String get dontHaveAccount;
  
  // Tasks
  String get tasks;
  String get addTask;
  String get editTask;
  String get deleteTask;
  String get taskTitle;
  String get taskDescription;
  String get dueDate;
  String get priority;
  String get category;
  String get completed;
  String get pending;
  String get overdue;
  String get today;
  String get tomorrow;
  String get thisWeek;
  String get high;
  String get medium;
  String get low;
  
  // Voice Commands
  String get voiceCommands;
  String get startListening;
  String get stopListening;
  String get voiceInputHint;
  String get sayHeyWhisp;
  String get listeningForCommands;
  String get voiceCommandProcessed;
  
  // Notifications
  String get notifications;
  String get reminder;
  String get taskReminder;
  String get dailyDigest;
  String get completionCelebration;
  
  // Settings
  String get settings;
  String get profile;
  String get preferences;
  String get language;
  String get theme;
  String get darkMode;
  String get lightMode;
  String get systemMode;
  
  // Premium
  String get premium;
  String get upgradeToPro;
  String get unlimitedTasks;
  String get advancedFeatures;
  String get premiumSupport;
  
  // Common Actions
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get add;
  String get search;
  String get filter;
  String get sort;
  String get refresh;
  String get loading;
  String get error;
  String get success;
  String get retry;
  
  // Additional UI strings
  String get rememberMe;
  String get welcomeBack;
  String get signInToContinue;
  String get enterEmailHint;
  String get enterPasswordHint;
  
  // Signup screen strings
  String get acceptTermsError;
  String get joinWhispTask;
  String get convertGuestAccount;
  String get startOrganizingTasks;
  String get fullName;
  String get enterFullNameHint;
  String get createPasswordHint;
  String get reenterPasswordHint;
  
  // Voice Input Screen strings
  String get voiceInput;
  String get pleaseProvideValidTask;
  String get taskCreatedSuccessfully;
  String get failedToSaveTask;
  String get listeningSpeak;
  String get tapToSpeak;
  String get initializing;
  String get youSaid;
  String get taskPreview;
  String get clear;
  String get saveTask;
  String get voiceCommandsExamples;
  String get voiceExample1;
  String get voiceExample2;
  String get voiceExample3;
  String get voiceExample4;
  String get voiceExample5;
  String get recurring;
  String get due;
  String get voiceInputHelp;
  String get howToUseVoiceInput;
  String get voiceStep1;
  String get voiceStep2;
  String get voiceStep3;
  String get voiceStep4;
  String get voiceFeatures;
  String get voiceFeatureTime;
  String get voiceFeaturePriority;
  String get voiceFeatureRecurring;
  String get voiceFeatureCategories;
  String get gotIt;
  
  // Add Task Screen strings (new keys only)
  String get taskTitleHint;
  String get pleaseEnterTaskTitle;
  String get titleTooLong;
  String get descriptionOptional;
  String get addMoreDetails;
  String get descriptionTooLong;
  String get initializingVoiceServices;
  String get taskProperties;
  String get taskColor;
  String get selected;
  
  // Account Settings Screen strings
  String get accountSettings;
  String get security;
  String get privacy;
  String get account;
  String get securityPreferences;
  String get biometricAuthentication;
  String get biometricAuthDescription;
  String get biometricEnabled;
  String get biometricDisabled;
  String get failedToUpdateBiometric;
  String get dataPrivacy;
  String get analyticsData;
  String get analyticsDescription;
  String get crashReports;
  String get crashReportsDescription;
  String get marketingEmails;
  String get marketingEmailsDescription;
  String get failedToUpdateSettings;
  String get pushNotifications;
  String get pushNotificationsDescription;
  String get dataManagement;
  String get exportData;
  String get exportDataDescription;
  String get importData;
  String get importDataDescription;
  String get clearCache;
  String get clearCacheDescription;
  String get exportingData;
  String get exportComplete;
  String get dataExportedSuccessfully;
  String get fileSize;
  String get syncing;
  String get synced;
  String get syncError;
  String get offline;
  String get tapToSync;
  
  // Task List Screen strings
  String get all;
  String get voiceCommandsReady;
  String get listeningForHeyWhisp;
  String get voiceError;
  String get stopVoiceCommands;
  String get startVoiceCommands;
  String get calendarView;
  String get logout;
  String get todaysProductivity;
  String get great;
  String get good;
  String get keepGoing;

  // Provider error messages
  String get userNotAuthenticated;
  String get dailyTaskLimitReached;
  String get failedToLoadTasks;
  String get failedToAddTask;
  String get failedToUpdateTask;
  String get failedToDeleteTask;
  String get failedToToggleTaskCompletion;
  String get failedToUpdateTasks;
  String get failedToDeleteAllTasks;
  String get failedToSnoozeReminder;
  String get failedToCancelReminder;
  String get failedToInitializeAuth;
  String get purchaseFailed;
  String get restoreFailed;
  String get pleaseEnterValidEmail;
  String get passwordMustBe6Characters;
  String get pleaseEnterYourName;
  String get failedToRegister;
  String get pleaseEnterYourPassword;
  String get failedToSignIn;
  String get currentUserNotAnonymous;
  String get failedToLinkAnonymousAccount;
  String get failedToResetPassword;
  String get nameCannotBeEmpty;
  String get failedToUpdateProfile;
  String get failedToUpdatePreferences;
  String get failedToUpdateNotificationSettings;
  String get failedToUpdateDisplaySettings;
  String get failedToUpdateVoiceSettings;
  String get failedToUpdatePrivacySettings;
  String get failedToResetPreferences;
  String get failedToSyncPreferences;
  String get failedToExportUserData;
  String get failedToImportUserData;
  String get failedToClearCache;
  String get failedToCreateBackup;
  String get failedToGetBackups;
  String get failedToRestoreFromBackup;
  String get failedToSyncUserData;
  String get failedToSyncAcrossDevices;
  String get failedToResolveSyncConflicts;
  String get failedToGetSyncStatistics;

  // Date filter labels
  String get onDate;
  String get fromDateToDate;
  String get afterDate;
  String get beforeDate;
  String get notSet;
  String get premiumFeaturesList;
  String get advertisementSpace;
  String get removeWithPro;
  String get activeFilters;
  String get clearAll;
  String get overdueReminder;
  String get overdueReminders;
  
  // Premium Purchase Screen strings
  String get upgradeToPremium;
  String get whispTaskPremium;
  String get unlockFullPotential;
  String get customVoicePacks;
  String get customVoicePacksDesc;
  String get offlineMode;
  String get offlineModeDesc;
  String get smartTags;
  String get smartTagsDesc;
  String get customThemes;
  String get customThemesDesc;
  String get advancedAnalytics;
  String get advancedAnalyticsDesc;
  String get noAds;
  String get noAdsDesc;
  String get choose;

  // Additional Task List Screen localization keys
  String get processing;
  String get listening;
  String get voiceServiceUnavailable;
  String get supportTheAppWithPremium;
  String get activeReminders;
  String get snooze5Min;
  String get reminderSnoozedFor5Minutes;
  String get taskDetails;
  String get status;
  String get markPending;
  String get markDone;
  String get snooze15m;
  String get reminderSnoozedFor15Minutes;
  String get taskHasActiveReminder;
  String get areYouSureDeleteTask;
  String get taskAndReminderDeletedSuccessfully;
  String get taskDeletedSuccessfully;
  String get copy;
  String get reminderNeedsAttention;
  String get reminderSet;
  String get reminders;
  String get cancelReminder;
  String get taskHasActiveReminderDeleteWarning;
  String get yes;
  String get no;
  String get cancelReminderButton;
  String get reminderNeedAttention;
  String get soon;
  String get updated;
  String get yesterday;
  String get justNow;
  String get ago;
  String get inTime;
  String get filterTasks;
  String get clearAllFilters;
  String get selectCategories;
  String get properties;
  String get dates;
  String get specialFilters;
  String get recurringTasksOnly;
  String get showOnlyTasksRepeat;
  String get tasksWithRemindersOnly;
  String get showOnlyTasksReminders;
  String get overdueTasksOnly;
  String get showOnlyTasksPastDue;
  String get dueDateRange;
  String get nextWeek;
  String get customDateRange;
  String get startDate;
  String get endDate;
  String get selectDate;
  String get categories;
  String get colors;
  String get thisMonth;
  String get taskMarkedIncomplete;
  String get taskCompletedNextOccurrence;
  String get taskDuplicatedSuccess;
  String get failedToDuplicateTask;
  String get reminderSnoozedMinutes;
  String get confirmDeleteTask;
  String get willCancelActiveReminder;
  String get willStopFutureRecurring;
  String get taskDeletedSuccess;
  String get selectTime;
  String get reminderSetFor;
  String get failedToSetReminder;
  String get passwordStrength;
  String get passwordRequirements;
  String get strong;
  String get user;
  String get minutes;
  String get chooseYourPlan;
  String get monthly;
  String get yearly;
  String get month;
  String get year;
  String get allPremiumFeatures;
  String get cancelAnytime;
  String get instantActivation;
  String get saveVsMonthly;
  String get prioritySupport;
  String get earlyAccess;
  String get restorePurchases;
  String get termsAndPrivacy;
  String get premiumActive;
  String get premiumActiveDesc;
  String get continue_;
  String get popular;
  String get monthlyPremiumActivated;
  String get yearlyPremiumActivated;
  String get purchasesRestored;
  String get failedToRestore;
  
  // Login Screen strings
  String get or;
  String get continueAsGuest;
  String get continueWithGoogle;
  String get signInWithGoogle;
  String get linkWithGoogle;
  String get byContingTermsPrivacy;
  String get forgotPasswordTitle;
  String get forgotPasswordDesc;
  String get emailAddress;
  String get enterEmailAddress;
  String get sendResetLink;
  String get backToSignIn;
  String get passwordResetSent;
  
  // Signup Screen strings
  String get iAgreeToTerms;
  String get termsOfService;
  String get and;
  String get privacyPolicy;
  String get atLeast8Characters;
  String get containsLowercase;
  String get containsUppercase;
  String get containsNumber;
  String get containsSpecialChar;
  
  // Profile Screen strings
  String get accountStatistics;
  String get totalTasks;
  String get completionRate;
  String get memberSince;
  String get profileInformation;
  String get saveChanges;
  String get accountActions;
  String get upgradeAccount;
  String get upgradeAccountDesc;
  String get changePassword;
  String get changePasswordDesc;
  String get accountSettingsDesc;
  String get signOutDesc;
  String get signOutTitle;
  String get signOutConfirm;
  String get profileUpdatedSuccess;
  
  // Change Password Screen strings
  String get changePasswordTitle;
  String get changePasswordSubtitle;
  String get passwordInformation;
  String get currentPassword;
  String get enterCurrentPassword;
  String get newPassword;
  String get enterNewPassword;
  String get confirmNewPassword;
  String get confirmNewPasswordHint;
  String get securityTips;
  String get tip1;
  String get tip2;
  String get tip3;
  String get tip4;
  String get tip5;
  String get passwordChangedSuccess;
  
  // Language Settings Screen strings
  String get selectLanguage;
  String get information;
  String get languageChangesApply;
  String get voiceCommandsWork;
  String get preferencesSaved;
  String get languageChangedSuccess;
  String get failedToChangeLanguage;
  String get errorChangingLanguage;
  
  // Splash Screen strings
  String get whispTask;
  String get voicePoweredTaskManagement;
  
  // Voice Input Screen strings
  String get testCommandsTitle;
  String get testCommandsHint;
  String get testCommand;
  
  // Task List Screen strings  
  String get listeningForWakeWord;
  String get processingVoiceCommand;
  String get premiumFeatures;
  
  // Add Task Screen strings
  String get taskAddedSuccessfully;
  String get taskUpdatedSuccessfully;
  String get withReminder;
  
  // Voice Notes Widget strings
  String get voiceNotes;
  String get recording;
  String get transcribing;
  String get liveTranscription;
  String get recordedNotes;
  String get duration;
  String get transcription;
  String get created;
  String get failedToStartRecording;
  String get transcriptionError;
  String get recordingPathNotFound;
  String get failedToSaveVoiceNote;
  String get failedToStartRecordingException;
  String get recordingFailed;
  String get voiceNoteSaved;
  String get failedToSave;
  
  // User Avatar Widget strings
  String get changeProfilePicture;
  String get camera;
  String get gallery;
  String get remove;
  String get photoTaken;
  String get failedToTakePhoto;
  String get imageSelected;
  String get failedToPickImage;
  String get photoRemoved;
  
  // Task Card Widget strings
  String get recurringLabel;
  
  // Ad service
  String get sampleAdBanner;
  String get upgradeToRemoveAds;
  
  // Premium helper
  String get premiumFeature;
  String get premiumFeatureAvailable;
  String get upgradeToProFor;
  String get maybeLater;
  String get upgradeNow;
  String get dailyLimitReached;
  String get dailyLimitMessage;
  String get upgradeForUnlimited;
  String get ok;
  String get upgrade;
  String get welcomeToPremium;
  String get purchaseError;
  String get pro;
  String get unlockUnlimitedFeatures;
  
  // Notification helper
  String get enableNotifications;
  String get notificationPermissionMessage;
  String get benefits;
  String get neverMissDeadlines;
  String get stayOrganized;
  String get customizableReminders;
  String get flexibleScheduling;
  String get notNow;
  String get enable;
  String get permissionRequired;
  String get notificationsDisabled;
  String get cancelNotification;
  String get openSettings;
  String get setReminder;
  String get reminderTime;
  
  // Task calendar
  String get taskCalendar;
  String get monthView;
  String get weekView;
  String get dayView;
  String get todaysTasks;
  String get tasksFor;
  String get noTasksForThisDay;
  
  // Task card actions
  String get duplicate;
  String get snooze5min;
  String get snooze30min;
  String get snooze1hour;
  String get reminderCancelled;
  String get deletingTask;
  String get setReminderFor;
  String get errorTaskIdMissing;
  String get upgradeToProLabel;
  String get addFileLabel;
  String get addPhotoLabel;
  String get clearDateFiltersLabel;
  String get applyFiltersLabel;
  
  // Additional notification helper strings
  String get snoozeReminder;
  String get selectTaskColor;
  String get noColor;
  String get deleteReminder;
  String get deleteReminderConfirm;
  String get smartReminders;
  
  
  // Messages
  String get taskCreated;
  String get taskUpdated;
  String get taskDeleted;
  String get taskCompleted;
  String get noTasksFound;
  String get internetRequired;
  String get somethingWentWrong;
  
  // Task list screen additional strings
  String get upgradeToProButton;
  String get errorPrefix;
  String get logoutConfirm;
  String get reminderSnoozed5min;
  String get reminderSnoozed15min;
  String get snooze15min;

  String get recurringTaskMessage;
  String get recurringTaskSubtitle;
  String get clearFilters;
  String get cancelReminderAction;
  String get setReminderTime;
  String get recurringTask;

  // Permission related strings
  String get requestingMicrophonePermission;
  String get requestingNotificationPermission;
  String get requestingStoragePermission;
  String get requestingCameraPermission;
  String get requestingPermissions;
  String get microphonePermissionRequired;
  String get microphonePermissionDescription;
  String get microphonePermissionDenied;
  String get microphonePermissionDeniedDescription;
  String get notificationPermissionRequired;
  String get notificationPermissionDescription;
  String get storagePermissionRequired;
  String get storagePermissionDescription;
  String get cameraPermissionRequired;
  String get cameraPermissionDescription;

  // Add Task Screen additional strings
  String get dueDateAndTime;
  String get saving;
  String get repeatEvery;
  String get pleaseEnterValidInterval;
  String get reminderTimeInPast;
  String get reminderIn;
  String get selectDueDateFirst;
  String get dueDateCannotBeInPast;
  String get reminderCannotBeInPast;
  String get fileAttachments;
  String get attachFilesAndPhotos;
  String get repeatEveryHelperText;
  String get pleaseSelectRecurringPattern;
  String get repeatEveryNumber;
  String get repeatEveryHelper;
  String get selectedColon;
  String get dangerZone;
  String get deleteAllTasksDescription;
  String get deleteAccountDescription;
  String get testCrash;
  String get testCrashDescription;
  String get contactSupport;
  String get accountSecurity;
  String get securityOptions;
  String get accountType;
  String get emailVerified;
  String get lastSignIn;
  String get loginAlerts;
  String get loginAlertsDescription;
  String get confirmAccountDeletion;
  String get enterPasswordToConfirm;
  String get needHelpContactUs;
  String get emailSupport;
  String get liveChat;
  String get availableHours;
  String get deleteAllTasksConfirmation;
  String get deleteAccountConfirmation;
  String get accountDeletedSuccessfully;
  String get exportCompleteDescription;
  String get exportFailed;
  String get failedToDeleteTasks;
  String get biometricUpdatedSuccessfully;

  String get biometricAuthenticationDescription;
  String get loginAlertsComingSoon;
  String get sentryTestCompleted;
  String get sentryTestFailed;
  String get downloadAccountData;
  String get downloadAccountDataDescription;
  String get getHelpDescription;
  String get analyticsDataDescription;
  String get analyticsSettingsUpdated;
  String get crashReportSettingsUpdated;
  String get enjoyingPremiumFeatures;
  String get unlockPremiumDescription;

  // New feature screens abstract getters
  String get features;
  String get achievements;
  String get habits;
  String get focus;
  String get yourProgress;
  String get achievementCategories;
  String get taskMaster;
  String get taskMasterDesc;
  String get streakWarrior;
  String get streakWarriorDesc;
  String get earlyBird;
  String get earlyBirdDesc;
  String get voiceChampion;
  String get voiceChampionDesc;
  String get recentAchievements;
  String get noAchievementsYet;
  String get completeTasksToEarn;
  String get unlocked;
  String get firstTaskComplete;
  String get firstTaskCompleteDesc;
  String get taskNovice;
  String get taskNoviceDesc;
  String get taskExplorer;
  String get taskExplorerDesc;
  String get addHabit;
  String get active;
  String get insights;
  String get templates;
  String get yourHabits;
  String get activeHabits;
  String get completedToday;
  String get currentStreak;
  String get days;
  String get frequency;
  String get weeklyProgress;
  String get noHabitsYet;
  String get createFirstHabit;
  String get habitInsights;
  String get weeklyOverview;
  String get weeklyOverviewDesc;
  String get bestPerformingHabits;
  String get bestPerformingHabitsDesc;
  String get improvementAreas;
  String get improvementAreasDesc;
  String get streakAnalysis;
  String get streakAnalysisDesc;
  String get habitTemplates;
  String get healthFitness;
  String get productivity;
  String get mindfulness;
  String get socialLife;
  String get useTemplate;
  String get addNewHabit;
  String get addHabitDesc;
  String get createHabit;
  String get templateWillCreate;
  String get createHabits;
  String get focusMode;
  String get pomodoro;
  String get pomodoroDesc;
  String get deepWork;
  String get deepWorkDesc;
  String get breakTime;
  String get breakTimeDesc;
  String get custom;
  String get customDesc;
  String get start;
  String get pause;
  String get resume;
  String get stop;
  String get todaysFocus;
  String get sessionsCompleted;
  String get totalFocusTime;
  String get averageSession;
  String get focusStreak;
  String get quickActions;
  String get quickFocus;
  String get focusHistory;
  String get focusGoals;
  String get distractionBlock;
  String get sessionComplete;
  String get sessionCompleteDesc;
  String get startAnother;
  String get focusSettings;
  String get focusSettingsDesc;
  String get close;
  String get focusHistoryDesc;
  String get focusGoalsDesc;
  String get distractionBlockDesc;
  String get daily;
  String get weekly;
  String get statistics;
  String get thisYear;
  String get overview;
  String get averagePerDay;
  String get productivityTrend;
  String get categoryBreakdown;
  String get timeAnalysis;
  String get mostProductiveHour;
  String get averageCompletionTime;
  String get longestStreak;
  String get exportStatistics;
  String get exportStatisticsDesc;
  String get export;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'kn': return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue on GitHub with a '
    'reproducible sample app and the gen-l10n configuration that was used.'
  );
}
