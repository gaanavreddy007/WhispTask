// ignore_for_file: use_super_parameters

import 'app_localizations.dart';

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appTitle => 'ವಿಸ್ಪ್‌ಟಾಸ್ಕ್';

  @override
  String get appDescription => 'ಧ್ವನಿ-ಸಕ್ರಿಯ ಕಾರ್ಯ ನಿರ್ವಹಣೆ';

  @override
  String get signIn => 'ಸೈನ್ ಇನ್ ಮಾಡಿ';

  @override
  String get signUp => 'ಸೈನ್ ಅಪ್ ಮಾಡಿ';

  @override
  String get signOut => 'ಸೈನ್ ಔಟ್ ಮಾಡಿ';

  @override
  String get email => 'ಇಮೇಲ್';

  @override
  String get password => 'ಪಾಸ್‌ವರ್ಡ್';

  @override
  String get confirmPassword => 'ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ';

  @override
  String get displayName => 'ಪ್ರದರ್ಶನ ಹೆಸರು';

  @override
  String get forgotPassword => 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿದ್ದೀರಾ?';

  @override
  String get resetPassword => 'ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸಿ';

  @override
  String get createAccount => 'ಖಾತೆ ರಚಿಸಿ';

  @override
  String get alreadyHaveAccount => 'ಈಗಾಗಲೇ ಖಾತೆ ಇದೆಯೇ?';

  @override
  String get dontHaveAccount => 'ಖಾತೆ ಇಲ್ಲವೇ?';

  // Permission related strings
  @override
  String get requestingMicrophonePermission => 'ಮೈಕ್ರೋಫೋನ್ ಅನುಮತಿಯನ್ದ ಅನುರೋಧ ಮಾಡುತ್ತಿದ್ದೇವೆ...';

  @override
  String get requestingNotificationPermission => 'ಸೂಚನೆ ಅನುಮತಿಯನ್ದ ಅನುರೋಧ ಮಾಡುತ್ತಿದ್ದೇವೆ...';

  @override
  String get requestingStoragePermission => 'ಸ್ಟೋರೇಜ್ ಅನುಮತಿಯನ್ದ ಅನುರೋಧ ಮಾಡುತ್ತಿದ್ದೇವೆ...';

  @override
  String get requestingCameraPermission => 'ಕ್ಯಾಮೆರಾ ಅನುಮತಿಯನ್ದ ಅನುರೋಧ ಮಾಡುತ್ತಿದ್ದೇವೆ...';

  @override
  String get requestingPermissions => 'ಅನುಮತಿಗಳನ್ದ ಅನುರೋಧ ಮಾಡುತ್ತಿದ್ದೇವೆ...';

  @override
  String get microphonePermissionRequired => 'ಮೈಕ್ರೋಫೋನ್ ಅನುಮತಿ ಆವಶ್ಯಕ';

  @override
  String get microphonePermissionDescription => 'ವಿಸ್ಪ್‌ಟಾಸ್ಕ್‌ಗೆ ವಾಯಿಸ್ ಕಮಾಂಡ್ ಮತ್ತು ಕಾರ್ಯ ಸೃಷ್ಟಿಸಲು ಮೈಕ್ರೋಫೋನ್ ಅಕ್ಸೆಸ್ ಆವಶ್ಯಕ. ದಯವಿಟ್ಟು ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿ ಅನುಮತಿ ಕೊಡಿ.';

  @override
  String get microphonePermissionDenied => 'ಮೈಕ್ರೋಫೋನ್ ಅನುಮತಿ ನಕಾರಿಸಲಾಗಿದೆ';

  @override
  String get microphonePermissionDeniedDescription => 'ಮೈಕ್ರೋಫೋನ್ ಅನುಮತಿ ಇಲ್ಲದೆ ವಾಯಿಸ್ ಫೀಚರ್ಗಳು ಕೆಲಸ ಮಾಡಲ್ಲ. ನೀವು ಇದನ್ನ ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿ ಸಕ್ರಿಯಗೊಳಿಸಬಹುದು.';

  @override
  String get notificationPermissionRequired => 'ಸೂಚನೆ ಅನುಮತಿ ಆವಶ್ಯಕ';

  @override
  String get notificationPermissionDescription => 'ವಿಸ್ಪ್‌ಟಾಸ್ಕ್‌ಗೆ ಕಾರ್ಯಗಳ ಗುರಿಸಲು ಸೂಚನೆ ಅಕ್ಸೆಸ್ ಆವಶ್ಯಕ. ದಯವಿಟ್ಟು ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿ ಅನುಮತಿ ಕೊಡಿ.';

  @override
  String get storagePermissionRequired => 'ಸ್ಟೋರೇಜ್ ಅನುಮತಿ ಆವಶ್ಯಕ';

  @override
  String get storagePermissionDescription => 'ವಿಸ್ಪ್‌ಟಾಸ್ಕ್‌ಗೆ ವಾಯಿಸ್ ರಿಕಾರ್ಡಿಂಗ್ ಮತ್ತು ಕಾರ್ಯ ಅಟ್ಯಾಚ್ಮೆಂಟ್ ಸೇವ್ ಮಾಡಲು ಸ್ಟೋರೇಜ್ ಅಕ್ಸೆಸ್ ಆವಶ್ಯಕ. ದಯವಿಟ್ಟು ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿ ಅನುಮತಿ ಕೊಡಿ.';

  @override
  String get cameraPermissionRequired => 'ಕ್ಯಾಮೆರಾ ಅನುಮತಿ ಆವಶ್ಯಕ';

  @override
  String get cameraPermissionDescription => 'ವಿಸ್ಪ್‌ಟಾಸ್ಕ್‌ಗೆ ಕಾರ್ಯಗಳಿಗೆ ಫೋಟೋ ಸೇರಿಸಲು ಕ್ಯಾಮೆರಾ ಅಕ್ಸೆಸ್ ಆವಶ್ಯಕ. ದಯವಿಟ್ಟು ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿ ಅನುಮತಿ ಕೊಡಿ.';

  @override
  String get tasks => 'ಕಾರ್ಯಗಳು';

  @override
  String get addTask => 'ಕಾರ್ಯ ಸೇರಿಸಿ';

  @override
  String get editTask => 'ಕಾರ್ಯ ಸಂಪಾದಿಸಿ';

  @override
  String get deleteTask => 'ಕಾರ್ಯ ಅಳಿಸಿ';

  @override
  String get taskTitle => 'ಕಾರ್ಯದ ಶೀರ್ಷಿಕೆ';

  @override
  String get taskDescription => 'ಕಾರ್ಯದ ವಿವರಣೆ';

  @override
  String get dueDate => 'ಅಂತಿಮ ದಿನಾಂಕ';

  @override
  String get priority => 'ಆದ್ಯತೆ';

  @override
  String get category => 'ವರ್ಗ';

  @override
  String get completed => 'ಪೂರ್ಣಗೊಂಡಿದೆ';

  @override
  String get pending => 'ಬಾಕಿ ಇದೆ';

  @override
  String get overdue => 'ವಿಳಂಬವಾಗಿದೆ';

  @override
  String get today => 'ಇಂದು';

  @override
  String get tomorrow => 'ನಾಳೆ';

  @override
  String get thisWeek => 'ಈ ವಾರ';

  @override
  String get high => 'ಹೆಚ್ಚು';

  @override
  String get medium => 'ಮಧ್ಯಮ';

  @override
  String get low => 'ಕಡಿಮೆ';

  @override
  String get voiceCommands => 'ಧ್ವನಿ ಆದೇಶಗಳು';

  @override
  String get startListening => 'ಕೇಳಲು ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get stopListening => 'ಕೇಳುವುದನ್ನು ನಿಲ್ಲಿಸಿ';

  @override
  String get voiceInputHint => 'ಧ್ವನಿ ಆದೇಶಗಳನ್ನು ಪ್ರಾರಂಭಿಸಲು "ಹೇ ವಿಸ್ಪ್" ಎಂದು ಹೇಳಿ';

  @override
  String get sayHeyWhisp => '"ಹೇ ವಿಸ್ಪ್" ಎಂದು ಹೇಳಿ';

  @override
  String get listeningForCommands => 'ಆದೇಶಗಳನ್ನು ಕೇಳುತ್ತಿದೆ...';

  @override
  String get voiceCommandProcessed => 'ಧ್ವನಿ ಆದೇಶ ಪ್ರಕ್ರಿಯೆಗೊಂಡಿದೆ';

  @override
  String get notifications => 'ಅಧಿಸೂಚನೆಗಳು';

  @override
  String get reminder => 'ಜ್ಞಾಪನೆ';

  @override
  String get taskReminder => 'ಕಾರ್ಯ ಜ್ಞಾಪನೆ';

  @override
  String get dailyDigest => 'ದೈನಂದಿನ ಸಾರಾಂಶ';

  @override
  String get completionCelebration => 'ಪೂರ್ಣಗೊಳಿಸುವಿಕೆಯ ಆಚರಣೆ';

  @override
  String get settings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get profile => 'ಪ್ರೊಫೈಲ್';

  @override
  String get preferences => 'ಆದ್ಯತೆಗಳು';

  @override
  String get language => 'ಭಾಷೆ';

  @override
  String get theme => 'ಥೀಮ್';

  @override
  String get darkMode => 'ಡಾರ್ಕ್ ಮೋಡ್';

  @override
  String get lightMode => 'ಲೈಟ್ ಮೋಡ್';

  @override
  String get systemMode => 'ಸಿಸ್ಟಂ ಮೋಡ್';

  @override
  String get premium => 'ಪ್ರೀಮಿಯಂ';

  @override
  String get upgradeToPro => 'ಪ್ರೋಗೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ';

  @override
  String get unlimitedTasks => 'ಅಪರಿಮಿತ ಕಾರ್ಯಗಳು';

  @override
  String get advancedFeatures => 'ಸುಧಾರಿತ ವೈಶಿಷ್ಟ್ಯಗಳು';

  @override
  String get premiumSupport => 'ಪ್ರೀಮಿಯಂ ಬೆಂಬಲ';

  @override
  String get save => 'ಉಳಿಸಿ';

  @override
  String get cancel => 'ರದ್ದುಮಾಡಿ';

  @override
  String get delete => 'ಅಳಿಸಿ';

  @override
  String get edit => 'ಸಂಪಾದಿಸಿ';

  @override
  String get add => 'ಸೇರಿಸಿ';

  @override
  String get search => 'ಹುಡುಕಿ';

  @override
  String get filter => 'ಫಿಲ್ಟರ್';

  @override
  String get sort => 'ವಿಂಗಡಿಸಿ';

  @override
  String get refresh => 'ರಿಫ್ರೆಶ್ ಮಾಡಿ';

  @override
  String get loading => 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...';

  @override
  String get error => 'ದೋಷ';

  @override
  String get success => 'ಯಶಸ್ಸು';

  @override
  String get retry => 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ';

  @override
  String get taskCreated => 'ಕಾರ್ಯ ಯಶಸ್ವಿಯಾಗಿ ರಚಿಸಲಾಗಿದೆ';

  @override
  String get taskUpdated => 'ಕಾರ್ಯ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ';

  @override
  String get taskDeleted => 'ಕಾರ್ಯ ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ';

  @override
  String get taskCompleted => 'ಕಾರ್ಯ ಪೂರ್ಣಗೊಂಡಿದೆ!';

  @override
  String get noTasksFound => 'ಯಾವುದೇ ಕಾರ್ಯಗಳು ಕಂಡುಬಂದಿಲ್ಲ';

  @override
  String get internetRequired => 'ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಅಗತ್ಯವಿದೆ';

  @override
  String get somethingWentWrong => 'ಏದೋ ತಪ್ಪಾಗಿದೆ';

  @override
  String get rememberMe => 'ನನ್ನ ಗೆಂಬಿಸಿ';

  @override
  String get welcomeBack => 'ಪುನಃ ಸ್ವಾಗತ';

  @override
  String get signInToContinue => 'ನಿಮ್ಮ ಕಾರ್ಯಗಳ ನಿರ್ವಹಣೆಯನ್ನು ಮುಂದುವರಿಸಲು ಸೈನ್ ಇನ್ ಮಾಡಿ';

  @override
  String get enterEmailHint => 'ನಿಮ್ಮ ಇ-ಮೇಲ್ ವಿಲಾಸವನ್ನು ನಮೂದಿಸಿ';

  @override
  String get enterPasswordHint => 'ನಿಮ್ಮ ಗುಪ್ತಪದವನ್ನು ನಮೂದಿಸಿ';

  @override
  String get acceptTermsError => 'ದಯವಿಟ್ಟು ಸೇವೆಯ ನಿಯಮಗಳನ್ನು ಒಪ್ಪಿಕೊಳ್ಳಿ';

  @override
  String get joinWhispTask => 'ವಿಸ್ಪ್‌ಟಾಸ್ಕ್‌ಗೆ ಸೇರಿ';

  @override
  String get convertGuestAccount => 'ನಿಮ್ಮ ಅತಿಥಿ ಖಾತೆಯನ್ನು ಶಾಶ್ವತ ಖಾತೆಗೆ ಪರಿವರ್ತಿಸಿ';

  @override
  String get startOrganizingTasks => 'ಧ್ವನಿ ಆಜ್ಞೆಗಳೊಂದಿಗೆ ನಿಮ್ಮ ಕಾರ್ಯಗಳನ್ನು ಆಯೋಜಿಸಲು ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get fullName => 'ಪೂರ್ಣ ಹೆಸರು';

  @override
  String get enterFullNameHint => 'ನಿಮ್ಮ ಪೂರ್ಣ ಹೆಸರನ್ನು ನಮೂದಿಸಿ';

  @override
  String get createPasswordHint => 'ಬಲವಾದ ಗುಪ್ತಪದವನ್ನು ರಚಿಸಿ';

  @override
  String get reenterPasswordHint => 'ನಿಮ್ಮ ಗುಪ್ತಪದವನ್ನು ಮತ್ತೆ ನಮೂದಿಸಿ';

  @override
  String get voiceInput => 'ಧ್ವನಿ ಇನ್‌ಪುಟ್';

  @override
  String get pleaseProvideValidTask => 'ದಯವಿಟ್ಟು ಮಾನ್ಯವಾದ ಕಾರ್ಯ ವಿವರಣೆಯನ್ನು ಒದಗಿಸಿ';

  @override
  String get taskCreatedSuccessfully => 'ಕಾರ್ಯವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ರಚಿಸಲಾಗಿದೆ!';

  @override
  String get failedToSaveTask => 'ಕಾರ್ಯವನ್ನು ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ';

  @override
  String get listeningSpeak => 'ಆಲಿಸುತ್ತಿದ್ದೇವೆ... ಈಗ ಮಾತನಾಡಿ!';

  @override
  String get tapToSpeak => 'ಮಾತನಾಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ';

  @override
  String get initializing => 'ಪ್ರಾರಂಭಿಸುತ್ತಿದೆ...';

  @override
  String get youSaid => 'ನೀವು ಹೇಳಿದ್ದು:';

  @override
  String get taskPreview => 'ಕಾರ್ಯ ಪೂರ್ವವೀಕ್ಷಣೆ:';

  @override
  String get clear => 'ತೆರವುಗೊಳಿಸಿ';

  @override
  String get saveTask => 'ಕಾರ್ಯವನ್ನು ಉಳಿಸಿ';

  @override
  String get voiceCommandsExamples => 'ಧ್ವನಿ ಆಜ್ಞೆಗಳ ಉದಾಹರಣೆಗಳು:';

  @override
  String get voiceExample1 => '• "ಕಿರಾಣಿ ವಸ್ತುಗಳನ್ನು ಖರೀದಿಸಲು ನನಗೆ ನೆನಪಿಸಿ"';

  @override
  String get voiceExample2 => '• "ಸಂಜೆ 6 ಗಂಟೆಗೆ ಅಮ್ಮನಿಗೆ ಕರೆ ಮಾಡಿ"';

  @override
  String get voiceExample3 => '• "ಮುಖ್ಯ: ನಾಳೆ ಪ್ರಾಜೆಕ್ಟ್ ಸಲ್ಲಿಸಿ"';

  @override
  String get voiceExample4 => '• "ಪ್ರತಿದಿನ ಜಿಮ್‌ನಲ್ಲಿ ವ್ಯಾಯಾಮ ಮಾಡಿ"';

  @override
  String get voiceExample5 => '• "ಬಿಲ್‌ಗಳನ್ನು ಪಾವತಿಸಿ ಹೆಚ್ಚಿನ ಆದ್ಯತೆ"';

  @override
  String get recurring => 'ಪುನರಾವರ್ತಿತ';

  @override
  String get due => 'ಬಾಕಿ';

  @override
  String get voiceInputHelp => 'ಧ್ವನಿ ಇನ್‌ಪುಟ್ ಸಹಾಯ';

  @override
  String get howToUseVoiceInput => 'ಧ್ವನಿ ಇನ್‌ಪುಟ್ ಅನ್ನು ಹೇಗೆ ಬಳಸುವುದು:';

  @override
  String get voiceStep1 => '1. ಆಲಿಸಲು ಪ್ರಾರಂಭಿಸಲು ಮೈಕ್ರೊಫೋನ್ ಬಟನ್ ಅನ್ನು ಟ್ಯಾಪ್ ಮಾಡಿ';

  @override
  String get voiceStep2 => '2. ನಿಮ್ಮ ಕಾರ್ಯವನ್ನು ಸ್ಪಷ್ಟವಾಗಿ ಹೇಳಿ';

  @override
  String get voiceStep3 => '3. ಪಾರ್ಸ್ ಮಾಡಿದ ಕಾರ್ಯವನ್ನು ಪರಿಶೀಲಿಸಿ';

  @override
  String get voiceStep4 => '4. ಅದನ್ನು ನಿಮ್ಮ ಪಟ್ಟಿಗೆ ಸೇರಿಸಲು "ಕಾರ್ಯವನ್ನು ಉಳಿಸಿ" ಅನ್ನು ಟ್ಯಾಪ್ ಮಾಡಿ';

  @override
  String get voiceFeatures => 'ಧ್ವನಿ ವೈಶಿಷ್ಟ್ಯಗಳು:';

  @override
  String get voiceFeatureTime => '• ಸಮಯ: "ಸಂಜೆ 6 ಗಂಟೆಗೆ", "ನಾಳೆ"';

  @override
  String get voiceFeaturePriority => '• ಆದ್ಯತೆ: "ತುರ್ತು", "ಮುಖ್ಯ", "ಕಡಿಮೆ ಆದ್ಯತೆ"';

  @override
  String get voiceFeatureRecurring => '• ಪುನರಾವರ್ತಿತ: "ದೈನಿಕ", "ಸಾಪ್ತಾಹಿಕ", "ಮಾಸಿಕ"';

  @override
  String get voiceFeatureCategories => '• ವರ್ಗಗಳು: ಕೀವರ್ಡ್‌ಗಳಿಂದ ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಪತ್ತೆ ಮಾಡಲಾಗುತ್ತದೆ';

  @override
  String get gotIt => 'ಅರ್ಥವಾಯಿತು!';

  @override
  String get taskTitleHint => 'ನಿಮ್ಮ ಕೆಲಸವನ್ನು ನಮೂದಿಸಿ...';

  @override
  String get pleaseEnterTaskTitle => 'ದಯವಿಟ್ಟು ಕೆಲಸದ ಶೀರ್ಷಿಕೆಯನ್ನು ನಮೂದಿಸಿ';

  @override
  String get titleTooLong => 'ಶೀರ್ಷಿಕೆಯು 100 ಅಕ್ಷರಗಳಿಗಿಂತ ಕಡಿಮೆ ಇರಬೇಕು';

  @override
  String get descriptionOptional => 'ವಿವರಣೆ (ಐಚ್ಛಿಕ)';

  @override
  String get addMoreDetails => 'ಹೆಚ್ಚಿನ ವಿವರಗಳನ್ನು ಸೇರಿಸಿ...';

  @override
  String get descriptionTooLong => 'ವಿವರಣೆಯು 500 ಅಕ್ಷರಗಳಿಗಿಂತ ಕಡಿಮೆ ಇರಬೇಕು';

  @override
  String get initializingVoiceServices => 'ಧ್ವನಿ ಸೇವೆಗಳನ್ನು ಪ್ರಾರಂಭಿಸಲಾಗುತ್ತಿದೆ...';

  @override
  String get taskProperties => 'ಕೆಲಸದ ಗುಣಲಕ್ಷಣಗಳು';

  @override
  String get taskColor => 'ಕೆಲಸದ ಬಣ್ಣ';

  @override
  String get selected => 'ಆಯ್ಕೆಮಾಡಲಾಗಿದೆ';
  
  // Account Settings Screen strings
  @override
  String get accountSettings => 'ಖಾತೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳು';
  
  @override
  String get security => 'ಭದ್ರತೆ';
  
  @override
  String get privacy => 'ಗೌಪ್ಯತೆ';
  
  @override
  String get account => 'ಖಾತೆ';
  
  @override
  String get securityPreferences => 'ಭದ್ರತೆ ಆದ್ಯತೆಗಳು';
  
  @override
  String get biometricAuthentication => 'ಬಯೋಮೆಟ್ರಿಕ್ ದೃಢೀಕರಣ';
  
  @override
  String get biometricAuthDescription => 'ಅಪ್ಲಿಕೇಶನ್ ಅನ್ಲಾಕ್ ಮಾಡಲು ಫಿಂಗರ್‌ಪ್ರಿಂಟ್ ಅಥವಾ ಮುಖ ಗುರುತಿಸುವಿಕೆಯನ್ನು ಬಳಸಿ';
  
  @override
  String get biometricEnabled => 'ಬಯೋಮೆಟ್ರಿಕ್ ದೃಢೀಕರಣ ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ!';
  
  @override
  String get biometricDisabled => 'ಬಯೋಮೆಟ್ರಿಕ್ ದೃಢೀಕರಣ ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ';
  
  @override
  String get failedToUpdateBiometric => 'ಬಯೋಮೆಟ್ರಿಕ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಅಪ್‌ಡೇಟ್ ಮಾಡುವಲ್ಲಿ ವಿಫಲವಾಗಿದೆ';
  
  @override
  String get dataPrivacy => 'ಡೇಟಾ ಗೌಪ್ಯತೆ';
  
  @override
  String get analyticsData => 'ವಿಶ್ಲೇಷಣೆ ಡೇಟಾ';
  
  @override
  String get analyticsDescription => 'ಬಳಕೆ ವಿಶ್ಲೇಷಣೆಯನ್ನು ಹಂಚಿಕೊಳ್ಳುವ ಮೂಲಕ ಅಪ್ಲಿಕೇಶನ್ ಸುಧಾರಿಸಲು ಸಹಾಯ ಮಾಡಿ';
  
  @override
  String get crashReports => 'ಕ್ರ್ಯಾಶ್ ವರದಿಗಳು';
  
  @override
  String get crashReportsDescription => 'ಸಮಸ್ಯೆಗಳನ್ನು ಪರಿಹರಿಸಲು ಸಹಾಯ ಮಾಡಲು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಕ್ರ್ಯಾಶ್ ವರದಿಗಳನ್ನು ಕಳುಹಿಸಿ';
  
  @override
  String get marketingEmails => 'ಮಾರ್ಕೆಟಿಂಗ್ ಇಮೇಲ್‌ಗಳು';
  
  @override
  String get marketingEmailsDescription => 'ಸಲಹೆಗಳು, ಅಪ್‌ಡೇಟ್‌ಗಳು ಮತ್ತು ಪ್ರಚಾರದ ವಿಷಯವನ್ನು ಸ್ವೀಕರಿಸಿ';
  
  @override
  String get failedToUpdateSettings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಅಪ್‌ಡೇಟ್ ಮಾಡುವಲ್ಲಿ ವಿಫಲವಾಗಿದೆ';
  
  @override
  String get pushNotifications => 'ಪುಶ್ ಅಧಿಸೂಚನೆಗಳು';
  
  @override
  String get pushNotificationsDescription => 'ಕೆಲಸದ ಜ್ಞಾಪನೆಗಳು ಮತ್ತು ಅಪ್ಲಿಕೇಶನ್ ಅಪ್‌ಡೇಟ್‌ಗಳನ್ನು ಸ್ವೀಕರಿಸಿ';
  
  @override
  String get dataManagement => 'ಡೇಟಾ ನಿರ್ವಹಣೆ';
  
  @override
  String get exportData => 'ಡೇಟಾ ರಫ್ತು ಮಾಡಿ';
  
  @override
  String get exportDataDescription => 'ನಿಮ್ಮ ಕೆಲಸಗಳು ಮತ್ತು ಖಾತೆ ಡೇಟಾದ ಪ್ರತಿಯನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ';
  
  @override
  String get importData => 'ಡೇಟಾ ಆಮದು ಮಾಡಿ';
  
  @override
  String get importDataDescription => 'ಹಿಂದಿನ ರಫ್ತಿನಿಂದ ಡೇಟಾವನ್ನು ಪುನಃಸ್ಥಾಪಿಸಿ';
  
  @override
  String get clearCache => 'ಕ್ಯಾಶ್ ತೆರವುಗೊಳಿಸಿ';
  
  @override
  String get clearCacheDescription => 'ಸ್ಥಳೀಯವಾಗಿ ಸಂಗ್ರಹಿಸಲಾದ ಅಪ್ಲಿಕೇಶನ್ ಡೇಟಾ ಮತ್ತು ಆದ್ಯತೆಗಳನ್ನು ತೆರವುಗೊಳಿಸಿ';
  
  @override
  String get exportingData => 'ಡೇಟಾ ರಫ್ತು ಮಾಡಲಾಗುತ್ತಿದೆ...';
  
  @override
  String get exportComplete => 'ರಫ್ತು ಪೂರ್ಣಗೊಂಡಿದೆ';
  
  @override
  String get dataExportedSuccessfully => 'ನಿಮ್ಮ ಡೇಟಾವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ರಫ್ತು ಮಾಡಲಾಗಿದೆ!';
  
  @override
  String get fileSize => 'ಫೈಲ್ ಗಾತ್ರ';
  
  @override
  String get syncing => 'ಸಿಂಕ್ ಮಾಡಲಾಗುತ್ತಿದೆ...';
  
  @override
  String get synced => 'ಸಿಂಕ್ ಮಾಡಲಾಗಿದೆ';
  
  @override
  String get syncError => 'ಸಿಂಕ್ ದೋಷ - ಮರುಪ್ರಯತ್ನಿಸಲು ಟ್ಯಾಪ್ ಮಾಡಿ';
  
  @override
  String get offline => 'ಆಫ್‌ಲೈನ್ - ಆನ್‌ಲೈನ್ ಆದಾಗ ಸಿಂಕ್ ಆಗುತ್ತದೆ';
  
  @override
  String get tapToSync => 'ಸಿಂಕ್ ಮಾಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ';
  
  // Task List Screen strings
  @override
  String get all => 'ಎಲ್ಲಾ';
  
  @override
  String get voiceCommandsReady => 'ಧ್ವನಿ ಆಜ್ಞೆಗಳು ಸಿದ್ಧ - ಪ್ರಾರಂಭಿಸಲು ಮೈಕ್ ಟ್ಯಾಪ್ ಮಾಡಿ';
  
  @override
  String get listeningForHeyWhisp => '"ಹೇ ವಿಸ್ಪ್" ಕೇಳುತ್ತಿದೆ...';
  
  @override
  String get voiceError => 'ಧ್ವನಿ ದೋಷ - ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ';
  
  @override
  String get stopVoiceCommands => 'ಧ್ವನಿ ಆಜ್ಞೆಗಳನ್ನು ನಿಲ್ಲಿಸಿ';
  
  @override
  String get startVoiceCommands => 'ಧ್ವನಿ ಆಜ್ಞೆಗಳನ್ನು ಪ್ರಾರಂಭಿಸಿ';
  
  @override
  String get calendarView => 'ಕ್ಯಾಲೆಂಡರ್ ವೀಕ್ಷಣೆ';
  
  @override
  String get logout => 'ಲಾಗ್ ಔಟ್';
  
  @override
  String get todaysProductivity => 'ಇಂದಿನ ಉತ್ಪಾದಕತೆ';
  
  @override
  String get great => 'ಅದ್ಭುತ!';
  
  @override
  String get good => 'ಒಳ್ಳೆಯದು';
  
  @override
  String get keepGoing => 'ಮುಂದುವರಿಸಿ!';

  // Provider error messages
  @override
  String get userNotAuthenticated => 'ಬೇರೆರು ಪ್ರಮಾಣಿತವಾಗಿಲ್ಲ';
  
  @override
  String get dailyTaskLimitReached => 'ದೈನಂದಿನ ಕಾರ್ಯ ಸೀಮೆ ಸೇರಿದೆ (20 ಕಾರ್ಯಗಳು)। ಅಸೀಮಿತ ಕಾರ್ಯಗಳಿಗಾಗಿ ಪ್ರೋಗೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ!';
  
  @override
  String get failedToLoadTasks => 'ಕಾರ್ಯಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToAddTask => 'ಕಾರ್ಯ ಸೇರಿಸಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToUpdateTask => 'ಕಾರ್ಯ ಅಪ್ಡೇಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToDeleteTask => 'ಕಾರ್ಯ ತೆರೆಯಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToToggleTaskCompletion => 'ಕಾರ್ಯ ಪೂರ್ಣಗೊಳಿಸುವಿಕೆಯನ್ನು ಟಾಗಲ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToUpdateTasks => 'ಕಾರ್ಯಗಳನ್ನು ಅಪ್ಡೇಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToDeleteAllTasks => 'ಎಲ್ಲಾ ಕಾರ್ಯಗಳನ್ನು ತೆರೆಯಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToSnoozeReminder => 'ಸ್ಮರಣೆ ಸ್ನೂಜ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToCancelReminder => 'ಸ್ಮರಣೆ ರದ್ದು ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToInitializeAuth => 'ಪ್ರಮಾಣೀಕರಣ ಪ್ರಾರಂಭಿಸಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get purchaseFailed => 'ಖರೀದಿ ವಿಫಲವಾಯಿತು';
  
  @override
  String get restoreFailed => 'ಪುನರುದ್ಧಾರ ವಿಫಲವಾಯಿತು';
  
  @override
  String get pleaseEnterValidEmail => 'ದಯವಿಟ್ಟು ಬರೆಯದ ಇ-ಮೇಲ್ ವಿಲಾಸ ನಮೂದಿಸಿ';
  
  @override
  String get passwordMustBe6Characters => 'ಪಾಸ್‌ವರ್ಡ್ ಕನಿಷ್ಟ 6 ಅಕ್ಷರಗಳ ಲಂಬವಿರಬೇಕು';
  
  @override
  String get pleaseEnterYourName => 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಹೆಸರು ನಮೂದಿಸಿ';
  
  @override
  String get failedToRegister => 'ನೋಂದಣಿ ವಿಫಲವಾಯಿತು';
  
  @override
  String get pleaseEnterYourPassword => 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ';
  
  @override
  String get failedToSignIn => 'ಸೈನ್ ಇನ್ ವಿಫಲವಾಯಿತು';
  
  @override
  String get currentUserNotAnonymous => 'ಸದ್ಯದ ಬೇರೆರು ಅನಾಮಿಕವಲ್ಲ';
  
  @override
  String get failedToLinkAnonymousAccount => 'ಅನಾಮಿಕ ಖಾತೆ ಲಿಂಕ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToResetPassword => 'ಪಾಸ್‌ವರ್ಡ್ ರೀಸೆಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get nameCannotBeEmpty => 'ಹೆಸರು ಖಾಲಿ ಇರಬಾರದು';
  
  @override
  String get failedToUpdateProfile => 'ಪ್ರೋಫೈಲ್ ಅಪ್ಡೇಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToUpdatePreferences => 'ಪ್ರಾಥಮಿಕತೆಗಳನ್ನು ಅಪ್ಡೇಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToUpdateNotificationSettings => 'ಅಧಿಸೂಚನೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಅಪ್ಡೇಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToUpdateDisplaySettings => 'ದಿಸ್ಪ್ಲೇ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಅಪ್ಡೇಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToUpdateVoiceSettings => 'ಸ್ವರ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಅಪ್ಡೇಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToUpdatePrivacySettings => 'ಗೌಪ್ಯತೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಅಪ್ಡೇಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToResetPreferences => 'ಪ್ರಾಥಮಿಕತೆಗಳನ್ನು ರೀಸೆಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToSyncPreferences => 'ಪ್ರಾಥಮಿಕತೆಗಳನ್ನು ಸಿಂಕ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToExportUserData => 'ಬೇರೆರ ಡೇಟಾ ನಿರ್ಯಾತ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToImportUserData => 'ಬೇರೆರ ಡೇಟಾ ಆಯಾತ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToClearCache => 'ಕ್ಯಾಶ್ ಸಾಫ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToCreateBackup => 'ಬ್ಯಾಕ್ಅಪ್ ತಯಾರಿಸಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToGetBackups => 'ಬ್ಯಾಕ್ಅಪ್‌ಗಳನ್ನು ಸಿಗಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToRestoreFromBackup => 'ಬ್ಯಾಕ್ಅಪ್‌ನಿಂದ ಪುನರುದ್ಧರಿಸಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToSyncUserData => 'ಬೇರೆರ ಡೇಟಾ ಸಿಂಕ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToSyncAcrossDevices => 'ಉಪಕರಣಗಳಲ್ಲಿ ಸಿಂಕ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToResolveSyncConflicts => 'ಸಿಂಕ್ ಸಂಘರ್ಷಗಳನ್ನು ಹಲ್ಲಿಸಲು ವಿಫಲವಾಯಿತು';
  
  @override
  String get failedToGetSyncStatistics => 'ಸಿಂಕ್ ಅಂಕಿಯಗಳನ್ನು ಸಿಗಲು ವಿಫಲವಾಯಿತು';

  // Date filter labels
  @override
  String get onDate => 'ರಂದು';
  
  @override
  String get fromDateToDate => 'ನಿಂದ';
  
  @override
  String get afterDate => 'ನಂತರ';
  
  @override
  String get beforeDate => 'ಮುಂದೆ';
  
  @override
  String get notSet => 'ಸೆಟ್ ಮಾಡಿಲ್ಲ';
  
  @override
  String get premiumFeaturesList => '• ಕಸ್ಟಮ್ ವಾಯ್ಸ್ ಪ್ಯಾಕ್‌ಗಳು\n• ಆಫ್‌ಲೈನ್ ಮೋಡ್\n• ಸ್ಮಾರ್ಟ್ ಟ್ಯಾಗ್‌ಗಳು\n• ಕಸ್ಟಮ್ ಥೀಮ್‌ಗಳು\n• ಸುಧಾರಿತ ವಿಶ್ಲೇಷಣೆ\n• ಜಾಹೀರಾತುಗಳಿಲ್ಲ';
  
  @override
  String get advertisementSpace => 'ಜಾಹೀರಾತು ಸ್ಥಳ';
  
  @override
  String get removeWithPro => 'ಪ್ರೋ ಜೊತೆ ತೆಗೆದುಹಾಕಿ';
  
  @override
  String get activeFilters => 'ಸಕ್ರಿಯ ಫಿಲ್ಟರ್‌ಗಳು:';
  
  @override
  String get clearAll => 'ಎಲ್ಲವನ್ನೂ ತೆರವುಗೊಳಿಸಿ';
  
  @override
  String get overdueReminder => 'ಮಿತಿ ಮೀರಿದ ಜ್ಞಾಪನೆ';
  
  @override
  String get overdueReminders => 'ಬಾಕಿ ಇರುವ ಜ್ಞಾಪನೆಗಳು';
  
  // Premium Purchase Screen strings
  @override
  String get upgradeToPremium => 'ಪ್ರೀಮಿಯಂಗೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ';
  
  @override
  String get whispTaskPremium => 'ವಿಸ್ಪ್‌ಟಾಸ್ಕ್ ಪ್ರೀಮಿಯಂ';
  
  @override
  String get unlockFullPotential => 'ಧ್ವನಿ-ಚಾಲಿತ ಉತ್ಪಾದಕತೆಯ ಸಂಪೂರ್ಣ ಸಾಮರ್ಥ್ಯವನ್ನು ಅನ್‌ಲಾಕ್ ಮಾಡಿ';
  
  @override
  String get customVoicePacks => 'ಕಸ್ಟಮ್ ಧ್ವನಿ ಪ್ಯಾಕ್‌ಗಳು';
  
  @override
  String get customVoicePacksDesc => 'ಅನೇಕ ಧ್ವನಿ ವ್ಯಕ್ತಿತ್ವಗಳು ಮತ್ತು ಉಚ್ಚಾರಣೆಗಳಿಂದ ಆಯ್ಕೆ ಮಾಡಿ';
  
  @override
  String get offlineMode => 'ಆಫ್‌ಲೈನ್ ಮೋಡ್';
  
  @override
  String get offlineModeDesc => 'ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವಿಲ್ಲದೆ ಧ್ವನಿ ಆಜ್ಞೆಗಳನ್ನು ಬಳಸಿ';
  
  @override
  String get smartTags => 'ಸ್ಮಾರ್ಟ್ ಟ್ಯಾಗ್‌ಗಳು';
  
  @override
  String get smartTagsDesc => 'AI-ಚಾಲಿತ ಸ್ವಯಂಚಾಲಿತ ಕಾರ್ಯ ವರ್ಗೀಕರಣ';
  
  @override
  String get customThemes => 'ಕಸ್ಟಮ್ ಥೀಮ್‌ಗಳು';
  
  @override
  String get customThemesDesc => 'ಸುಂದರ ಥೀಮ್‌ಗಳೊಂದಿಗೆ ನಿಮ್ಮ ಅಪ್ಲಿಕೇಶನ್ ಅನ್ನು ವೈಯಕ್ತೀಕರಿಸಿ';
  
  @override
  String get advancedAnalytics => 'ಸುಧಾರಿತ ವಿಶ್ಲೇಷಣೆ';
  
  @override
  String get advancedAnalyticsDesc => 'ವಿವರವಾದ ಉತ್ಪಾದಕತೆ ಒಳನೋಟಗಳು ಮತ್ತು ವರದಿಗಳು';
  
  @override
  String get noAds => 'ಜಾಹೀರಾತುಗಳಿಲ್ಲ';
  
  @override
  String get noAdsDesc => 'ಜಾಹೀರಾತು-ಮುಕ್ತ ಅನುಭವವನ್ನು ಆನಂದಿಸಿ';
  
  @override
  String get choose => 'ಆಯ್ಕೆಮಾಡಿ';

  // Additional Task List Screen localization keys
  @override
  String get processing => 'ಪ್ರಕ್ರಿಯೆಗೊಳಿಸಲಾಗಿದೆ';

  @override
  String get listening => 'ಕೇಳುತ್ತಿದೆ';

  @override
  String get voiceServiceUnavailable => 'ವಾಯಿಸ್ ಸೇವೆ ಉಪಲಬ್ಧವಿಲ್ಲ';

  @override
  String get supportTheAppWithPremium => 'ಪ್ರೀಮಿಯಂದಿಂದ ಅಪ್ಲಿಕೇಶನ್ನು ಸಹಾಯ ಮಾಡಿ';

  @override
  String get activeReminders => 'ಸಕ್ರಿಯ ಸ್ಮರಣೆಗಳು';

  @override
  String get snooze5Min => '5 ನಿಮಿಷ ಸ್ನೂಜ್';

  @override
  String get reminderSnoozedFor5Minutes => '5 ನಿಮಿಷಗಳಿಗೆ ಸ್ಮರಣೆ ಸ್ನೂಜ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get taskDetails => 'ಕಾರ್ಯದ ವಿವರಗಳು';

  @override
  String get status => 'ಸ್ಥಿತಿ';

  @override
  String get markPending => 'ಬಾಕಿ ಇದೆ ಎಂದು ಗುರುತು ಹಾಕಿ';

  @override
  String get markDone => 'ಪೂರ್ಣಗೊಂಡ ಎಂದು ಗುರುತು ಹಾಕಿ';

  @override
  String get snooze15m => '15 ನಿಮಿಷ ಸ್ನೂಜ್';

  @override
  String get reminderSnoozedFor15Minutes => '15 ನಿಮಿಷಗಳಿಗೆ ಸ್ಮರಣೆ ಸ್ನೂಜ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get taskHasActiveReminder => 'ಈ ಕಾರ್ಯದಲ್ಲಿ ಸಕ್ರಿಯ ಸ್ಮರಣೆ ಇದೆ। ಇದನ್ನು ಅಳಿಸಲು ಸ್ಮರಣೆಯನ್ನೂ ರದ್ದು ಮಾಡಲಾಗುತ್ತದೆ।';

  @override
  String get areYouSureDeleteTask => 'ನೀವು ಈ ಕಾರ್ಯವನ್ನು ಅಳಿಸಲು ಬಯಸುತ್ತೀರಾ?';

  @override
  String get taskAndReminderDeletedSuccessfully => 'ಕಾರ್ಯ ಮತ್ತು ಸ್ಮರಣೆ ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ';

  @override
  String get taskDeletedSuccessfully => 'ಕಾರ್ಯ ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ';

  @override
  String get copy => 'ನಕಲು';

  @override
  String get reminderNeedsAttention => 'ಗಮನ ಬೇಕು';

  @override
  String get reminderSet => 'ಸೆಟ್';

  @override
  String get reminders => 'ಸ್ಮರಣೆಗಳು';

  @override
  String get cancelReminder => 'ಸ್ಮರಣೆ ರದ್ದುಮಾಡಿ';

  @override
  String get taskHasActiveReminderDeleteWarning => 'ಈ ಕಾರ್ಯದಲ್ಲಿ ಸಕ್ರಿಯ ಸ್ಮರಣೆ ಇದೆ. ಇದನ್ನು ಅಳಿಸುವುದರಿಂದ ಸ್ಮರಣೆಯೂ ರದ್ದಾಗುತ್ತದೆ.';

  @override
  String get yes => 'ಹೌದು';

  @override
  String get cancelReminderButton => 'ಸ್ಮರಣೆ ರದ್ದುಮಾಡಿ';

  @override
  String get no => 'ಇಲ್ಲ';

  @override
  String get reminderNeedAttention => 'ನಿಮ್ಮ ಗಮನ ಬೇಕು';

  @override
  String get soon => 'ಬೇಗ';

  @override
  String get updated => 'ಅಪ್‌ಡೇಟ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get yesterday => 'ನಿನ್ನೆ';

  @override
  String get justNow => 'ಈಗಷ್ಟೇ';

  @override
  String get ago => 'ಹಿಂದೆ';

  @override
  String get inTime => 'ನಲ್ಲಿ';

  @override
  String get filterTasks => 'ಕಾರ್ಯಗಳನ್ನು ಫಿಲ್ಟರ್ ಮಾಡಿ';

  @override
  String get clearAllFilters => 'ಎಲ್ಲಾ ಫಿಲ್ಟರ್‌ಗಳನ್ನು ಕ್ಲಿಯರ್ ಮಾಡಿ';

  @override
  String get selectCategories => 'ವರ್ಗಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get properties => 'ಗುಣಗಳು';

  @override
  String get dates => 'ದಿನಾಂಕಗಳು';

  @override
  String get specialFilters => 'ವಿಶೇಷ ಫಿಲ್ಟರ್‌ಗಳು';

  @override
  String get recurringTasksOnly => 'ಕೇವಲ ಪುನರಾವರ್ತನೆ ಕಾರ್ಯಗಳು';

  @override
  String get showOnlyTasksRepeat => 'ಕೇವಲ ಪುನರಾವರ್ತನೆಯಾಗುವ ಕಾರ್ಯಗಳನ್ನು ತೋರಿಸಿ';

  @override
  String get tasksWithRemindersOnly => 'ಕೇವಲ ಸ್ಮರಣೆ ಇರುವ ಕಾರ್ಯಗಳು';

  @override
  String get showOnlyTasksReminders => 'ಕೇವಲ ಸಕ್ರಿಯ ಸ್ಮರಣೆ ಇರುವ ಕಾರ್ಯಗಳನ್ನು ತೋರಿಸಿ';

  @override
  String get overdueTasksOnly => 'ಕೇವಲ ಕಾಲಾವಧಿ ವೆಂಚಿದ ಕಾರ್ಯಗಳು';

  @override
  String get showOnlyTasksPastDue => 'ಕೇವಲ ನಿರ್ಧಾರಿತ ದಿನಾಂಕ ಕಡೆ ಹೋದ ಕಾರ್ಯಗಳನ್ನು ತೋರಿಸಿ';

  @override
  String get dueDateRange => 'ನಿಯತ ದಿನಾಂಕ ವ್ಯಾಪ್ತಿ';

  @override
  String get nextWeek => 'ಮುಂದಿನ ವಾರ';

  @override
  String get customDateRange => 'ಕಸ್ಟಮ್ ದಿನಾಂಕ ವ್ಯಾಪ್ತಿ';

  @override
  String get startDate => 'ಪ್ರಾರಂಭ ದಿನಾಂಕ';

  @override
  String get endDate => 'ಅಂತ್ಯ ದಿನಾಂಕ';

  @override
  String get selectDate => 'ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get categories => 'ವರ್ಗಗಳು';

  @override
  String get colors => 'ರಂಗಗಳು';

  @override
  String get thisMonth => 'ಈ ತಿಂಗಳು';

  @override
  String get taskMarkedIncomplete => 'ಕಾರ್ಯವನ್ನು ಅಪೂರ್ಣ ಎಂದು ಗುರುತಿಸಲಾಗಿದೆ';

  @override
  String get taskCompletedNextOccurrence => 'ಕಾರ್ಯ ಪೂರ್ಣಗೊಂಡಿದೆ! ಮುಂದಿನ ಘಟನೆ ಸೃಷ್ಟಿಸಲಾಗಿದೆ';

  @override
  String get taskDuplicatedSuccess => 'ಕಾರ್ಯ ಯಶಸ್ವಿಯಾಗಿ ಡುಪ್ಲಿಕೇಟ್ ಮಾಡಲಾಗಿದೆ!';

  @override
  String get failedToDuplicateTask => 'ಕಾರ್ಯ ಡುಪ್ಲಿಕೇಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';

  @override
  String get reminderSnoozedMinutes => 'ಸ್ಮರಣೆಯನ್ನು ಸ್ನೂಜ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get confirmDeleteTask => 'ನೀವು ನಿಜವಾಗಿಯೂ ಅಳಿಸಲು ಬಯಸುತ್ತೀರಾ';

  @override
  String get willCancelActiveReminder => 'ಇದು ಸಕ್ರಿಯ ಸ್ಮರಣೆಯನ್ನೂ ರದ್ದುಮಾಡುತ್ತದೆ.';

  @override
  String get willStopFutureRecurring => 'ಇದು ಎಲ್ಲಾ ಭವಿಷ್ಯದ ಪುನರಾವರ್ತನೆ ಘಟನೆಗಳನ್ನು ನಿಲಿಸುತ್ತದೆ.';

  @override
  String get taskDeletedSuccess => 'ಕಾರ್ಯ ಯಶಸ್ವಿಯಾಗಿ ಡಿಲಿಟ್ ಮಾಡಲಾಗಿದೆ!';

  @override
  String get selectTime => 'ಸಮಯ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get reminderSetFor => 'ಸ್ಮರಣೆ ಸೆಟ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get failedToSetReminder => 'ಸ್ಮರಣೆ ಸೆಟ್ ಮಾಡಲು ವಿಫಲವಾಯಿತು';

  @override
  String get passwordStrength => 'ಪಾಸ್‌ವರ್ಡ್ ಬಲ';

  @override
  String get passwordRequirements => 'ಪಾಸ್‌ವರ್ಡ್ ಅವಶ್ಯಕತೆಗಳು';

  @override
  String get strong => 'ಬಲವಾದ';

  @override
  String get user => 'ಬಳಕೆದಾರ';

  @override
  String get minutes => 'ನಿಮಿಷಗಳು';

  @override
  String get chooseYourPlan => 'ನಿಮ್ಮ ಯೋಜನೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get monthly => 'ಮಾಸಿಕ';

  @override
  String get yearly => 'ವಾರ್ಷಿಕ';

  @override
  String get month => 'ತಿಂಗಳು';

  @override
  String get year => 'ವರ್ಷ';

  @override
  String get allPremiumFeatures => 'ಎಲ್ಲಾ ಪ್ರೀಮಿಯಂ ವೈಶಿಷ್ಟ್ಯಗಳು';

  @override
  String get cancelAnytime => 'ಯಾವಾಗ ಬೇಕಾದರೂ ರದ್ದುಮಾಡಿ';

  @override
  String get instantActivation => 'ತ್ವರಿತ ಸಕ್ರಿಯಗೊಳಿಸುವಿಕೆ';

  @override
  String get saveVsMonthly => 'ಮಾಸಿಕಕ್ಕಿಂತ ಉಳಿಸಿ';

  @override
  String get prioritySupport => 'ಆದ್ಯತೆ ಬೆಂಬಲ';

  @override
  String get earlyAccess => 'ಮುಂಚಿನ ಪ್ರವೇಶ';

  @override
  String get restorePurchases => 'ಖರೀದಿಗಳನ್ನು ಮರುಸ್ಥಾಪಿಸಿ';

  @override
  String get termsAndPrivacy => 'ನಿಯಮಗಳು ಮತ್ತು ಗೌಪ್ಯತೆ';

  @override
  String get premiumActive => 'ಪ್ರೀಮಿಯಂ ಸಕ್ರಿಯ';

  @override
  String get premiumActiveDesc => 'ನಿಮ್ಮ ಪ್ರೀಮಿಯಂ ಸದಸ್ಯತ್ವ ಸಕ್ರಿಯವಾಗಿದೆ';

  @override
  String get continue_ => 'ಮುಂದುವರಿಸಿ';

  @override
  String get popular => 'ಜನಪ್ರಿಯ';

  @override
  String get monthlyPremiumActivated => 'ಮಾಸಿಕ ಪ್ರೀಮಿಯಂ ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ! 🎉';
  
  @override
  String get yearlyPremiumActivated => 'ವಾರ್ಷಿಕ ಪ್ರೀಮಿಯಂ ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ! ';
  
  @override
  String get purchasesRestored => 'ಖರೀದಿಗಳನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ!';
  
  @override
  String get failedToRestore => 'ಖರೀದಿಗಳನ್ನು ಪುನಃಸ್ಥಾಪಿಸಲು ವಿಫಲವಾಗಿದೆ';
  
  // Login Screen strings
  @override
  String get or => 'ಅಥವಾ';
  
  @override
  String get continueAsGuest => 'ಅತಿಥಿಯಾಗಿ ಮುಂದುವರಿಸಿ';
  
  @override
  String get continueWithGoogle => 'Google ನೊಂದಿಗೆ ಮುಂದುವರಿಸಿ';

  @override
  String get signInWithGoogle => 'Google ನೊಂದಿಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ';

  @override
  String get linkWithGoogle => 'Google ನೊಂದಿಗೆ ಲಿಂಕ್ ಮಾಡಿ';

  @override
  String get byContingTermsPrivacy => 'ಮುಂದುವರಿಸುವ ಮೂಲಕ, ನೀವು ನಮ್ಮ ಸೇವಾ ನಿಯಮಗಳು ಮತ್ತು ಗೌಪ್ಯತಾ ನೀತಿಗೆ ಒಪ್ಪುತ್ತೀರಿ';
  
  @override
  String get forgotPasswordTitle => 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿದ್ದೀರಾ?';
  
  @override
  String get forgotPasswordDesc => 'ನಿಮ್ಮ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ ಮತ್ತು ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸಲು ನಾವು ನಿಮಗೆ ಲಿಂಕ್ ಕಳುಹಿಸುತ್ತೇವೆ.';
  
  @override
  String get emailAddress => 'ಇಮೇಲ್ ವಿಳಾಸ';
  
  @override
  String get enterEmailAddress => 'ನಿಮ್ಮ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ';
  
  @override
  String get sendResetLink => 'ಮರುಹೊಂದಿಸುವ ಲಿಂಕ್ ಕಳುಹಿಸಿ';
  
  @override
  String get backToSignIn => 'ಸೈನ್ ಇನ್‌ಗೆ ಹಿಂತಿರುಗಿ';
  
  @override
  String get passwordResetSent => 'ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸುವ ಲಿಂಕ್ ನಿಮ್ಮ ಇಮೇಲ್‌ಗೆ ಕಳುಹಿಸಲಾಗಿದೆ';
  
  // Signup Screen strings
  @override
  String get iAgreeToTerms => 'ನಾನು ಒಪ್ಪುತ್ತೇನೆ ';
  
  @override
  String get termsOfService => 'ಸೇವಾ ನಿಯಮಗಳು';
  
  @override
  String get and => ' ಮತ್ತು ';
  
  @override
  String get privacyPolicy => 'ಗೌಪ್ಯತಾ ನೀತಿ';
  
  @override
  String get atLeast8Characters => 'ಕನಿಷ್ಠ 8 ಅಕ್ಷರಗಳು';
  
  @override
  String get containsLowercase => 'ಸಣ್ಣ ಅಕ್ಷರಗಳನ್ನು ಒಳಗೊಂಡಿದೆ';
  
  @override
  String get containsUppercase => 'ದೊಡ್ಡ ಅಕ್ಷರಗಳನ್ನು ಒಳಗೊಂಡಿದೆ';
  
  @override
  String get containsNumber => 'ಸಂಖ್ಯೆಯನ್ನು ಒಳಗೊಂಡಿದೆ';
  
  @override
  String get containsSpecialChar => 'ವಿಶೇಷ ಅಕ್ಷರವನ್ನು ಒಳಗೊಂಡಿದೆ';
  
  // Profile Screen strings
  @override
  String get accountStatistics => 'ಖಾತೆ ಅಂಕಿಅಂಶಗಳು';
  
  @override
  String get totalTasks => 'ಒಟ್ಟು ಕಾರ್ಯಗಳು';
  
  @override
  String get completionRate => 'ಪೂರ್ಣಗೊಳಿಸುವ ದರ';
  
  @override
  String get memberSince => 'ಸದಸ್ಯರಾದ ದಿನಾಂಕ';
  
  @override
  String get profileInformation => 'ಪ್ರೊಫೈಲ್ ಮಾಹಿತಿ';
  
  @override
  String get saveChanges => 'ಬದಲಾವಣೆಗಳನ್ನು ಉಳಿಸಿ';
  
  @override
  String get accountActions => 'ಖಾತೆ ಕ್ರಿಯೆಗಳು';
  
  @override
  String get upgradeAccount => 'ಖಾತೆಯನ್ನು ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ';
  
  @override
  String get upgradeAccountDesc => 'ಸಾಧನಗಳಲ್ಲಿ ಸಿಂಕ್ ಮಾಡಲು ಶಾಶ್ವತ ಖಾತೆಯನ್ನು ರಚಿಸಿ';
  
  @override
  String get changePassword => 'ಪಾಸ್‌ವರ್ಡ್ ಬದಲಾಯಿಸಿ';
  
  @override
  String get changePasswordDesc => 'ನಿಮ್ಮ ಖಾತೆ ಪಾಸ್‌ವರ್ಡ್ ಅನ್ನು ಅಪ್‌ಡೇಟ್ ಮಾಡಿ';
  
  @override
  String get accountSettingsDesc => 'ಗೌಪ್ಯತೆ ಮತ್ತು ಸುರಕ್ಷತೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ನಿರ್ವಹಿಸಿ';
  
  @override
  String get signOutDesc => 'ನಿಮ್ಮ ಖಾತೆಯಿಂದ ಸೈನ್ ಔಟ್ ಮಾಡಿ';
  
  @override
  String get signOutTitle => 'ಸೈನ್ ಔಟ್';
  
  @override
  String get signOutConfirm => 'ನೀವು ನಿಜವಾಗಿಯೂ ನಿಮ್ಮ ಖಾತೆಯಿಂದ ಸೈನ್ ಔಟ್ ಮಾಡಲು ಬಯಸುವಿರಾ?';
  
  @override
  String get profileUpdatedSuccess => 'ಪ್ರೊಫೈಲ್ ಯಶಸ್ವಿಯಾಗಿ ಅಪ್‌ಡೇಟ್ ಮಾಡಲಾಗಿದೆ!';
  
  // Change Password Screen strings
  @override
  String get changePasswordTitle => 'ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ಬದಲಾಯಿಸಿ';
  
  @override
  String get changePasswordSubtitle => 'ಬಲವಾದ, ಅನನ್ಯ ಪಾಸ್‌ವರ್ಡ್ ಬಳಸಿ ನಿಮ್ಮ ಖಾತೆಯನ್ನು ಸುರಕ್ಷಿತವಾಗಿ ಇರಿಸಿ';
  
  @override
  String get passwordInformation => 'ಪಾಸ್‌ವರ್ಡ್ ಮಾಹಿತಿ';
  
  @override
  String get currentPassword => 'ಪ್ರಸ್ತುತ ಪಾಸ್‌ವರ್ಡ್';
  
  @override
  String get enterCurrentPassword => 'ನಿಮ್ಮ ಪ್ರಸ್ತುತ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ';
  
  @override
  String get newPassword => 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್';
  
  @override
  String get enterNewPassword => 'ನಿಮ್ಮ ಹೊಸ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ';
  
  @override
  String get confirmNewPassword => 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ';
  
  @override
  String get confirmNewPasswordHint => 'ನಿಮ್ಮ ಹೊಸ ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ';
  
  @override
  String get securityTips => 'ಸುರಕ್ಷತಾ ಸಲಹೆಗಳು';
  
  @override
  String get tip1 => 'ಕನಿಷ್ಠ 8 ಅಕ್ಷರಗಳನ್ನು ಬಳಸಿ';
  
  @override
  String get tip2 => 'ದೊಡ್ಡ ಮತ್ತು ಸಣ್ಣ ಅಕ್ಷರಗಳನ್ನು ಸೇರಿಸಿ';
  
  @override
  String get tip3 => 'ಸಂಖ್ಯೆಗಳು ಮತ್ತು ವಿಶೇಷ ಅಕ್ಷರಗಳನ್ನು ಸೇರಿಸಿ';
  
  @override
  String get tip4 => 'ವೈಯಕ್ತಿಕ ಮಾಹಿತಿಯನ್ನು ತಪ್ಪಿಸಿ';
  
  @override
  String get tip5 => 'ಇತರ ಖಾತೆಗಳ ಪಾಸ್‌ವರ್ಡ್‌ಗಳನ್ನು ಮರುಬಳಕೆ ಮಾಡಬೇಡಿ';
  
  @override
  String get passwordChangedSuccess => 'ಪಾಸ್‌ವರ್ಡ್ ಯಶಸ್ವಿಯಾಗಿ ಬದಲಾಯಿಸಲಾಗಿದೆ!';
  
  // Language Settings Screen strings
  @override
  String get selectLanguage => 'Select Language / भाषा चुनें / ಭಾಷೆ ಆಯ್ಕೆ ಮಾಡಿ';
  
  @override
  String get information => 'ಮಾಹಿತಿ';
  
  @override
  String get languageChangesApply => 'ಭಾಷೆ ಬದಲಾವಣೆಗಳು ತಕ್ಷಣವೇ ಅನ್ವಯವಾಗುತ್ತವೆ';
  
  @override
  String get voiceCommandsWork => 'ಧ್ವನಿ ಆದೇಶಗಳು ಎಲ್ಲಾ ಭಾಷೆಗಳಲ್ಲಿ ಕೆಲಸ ಮಾಡುತ್ತವೆ';
  
  @override
  String get preferencesSaved => 'ನಿಮ್ಮ ಆದ್ಯತೆಯನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಉಳಿಸಲಾಗುತ್ತದೆ';
  
  @override
  String get languageChangedSuccess => 'ಭಾಷೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಬದಲಾಯಿಸಲಾಗಿದೆ';
  
  @override
  String get failedToChangeLanguage => 'ಭಾಷೆ ಬದಲಾಯಿಸಲು ವಿಫಲವಾಗಿದೆ';
  
  @override
  String get errorChangingLanguage => 'ಭಾಷೆ ಬದಲಾಯಿಸುವಲ್ಲಿ ದೋಷ';
  
  // Splash Screen strings
  @override
  String get whispTask => 'WhispTask';
  
  @override
  String get voicePoweredTaskManagement => 'ಸ್ವರ-ಶಕ್ತಿಯುತ ಕಾರ್ಯ ನಿರ್ವಹಣೆ';
  
  // Voice Input Screen strings
  @override
  String get testCommandsTitle => 'ಪರಿಶೀಲನೆ ಕಮಾಂಡ್ಗಳು (ಮೈಕ್ರೊಫೋನ್ ಬದಲಾಯಿಸುವಿಕೆ)';
  
  @override
  String get testCommandsHint => 'ಟೈಪ್ ಮಾಡಿ: ಹೋಮ್ವರ್ಕ್ ನಾಳೆ, ಗ್ರೋಸರಿ ಇಂದು ಅಪ್ಡೇಟ್ ಮಾಡಿ';
  
  @override
  String get testCommand => 'ಪರಿಶೀಲನೆ ಕಮಾಂಡ್';
  
  // Task List Screen strings
  @override
  String get listeningForWakeWord => '"ಹೇ ವ್ಹಿಸ್ಪ್" ಕೇಳುತ್ತಿದೆ...';
  
  @override
  String get processingVoiceCommand => 'ಪ್ರೋಸೆಸಿಂಗ್';
  
  @override
  String get premiumFeatures => 'ಪ್ರೀಮಿಯಂ ವೈಶಿಷ್ಟ್ಯಗಳು';
  
  // Add Task Screen strings
  @override
  String get taskAddedSuccessfully => 'ಕಾರ್ಯವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಸೇರಿಸಲಾಗಿದೆ';
  
  @override
  String get taskUpdatedSuccessfully => 'ಕಾರ್ಯವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಪ್ಡೇಟ್ ಮಾಡಲಾಗಿದೆ';
  
  @override
  String get withReminder => 'ರಿಮೈಂಡರ್ ಸಹಿತ';
  
  // Voice Notes Widget strings
  @override
  String get voiceNotes => 'ವಾಯಿಸ್ ನೋಟ್ಸ್';
  
  @override
  String get recording => 'ರೆಕಾರ್ಡಿಂಗ್...';
  
  @override
  String get transcribing => 'ಟ್ರಾಂಸ್ಕ್ರಿಪ್ಶನ್...';
  
  @override
  String get liveTranscription => 'ಲೈವ್ ಟ್ರಾಂಸ್ಕ್ರಿಪ್ಶನ್:';
  
  @override
  String get recordedNotes => 'ರೆಕಾರ್ಡ್ ಮಾಡಿದ ನೋಟ್ಸ್:';
  
  @override
  String get duration => 'ಅವಧಿ';
  
  @override
  String get transcription => 'ಟ್ರಾಂಸ್ಕ್ರಿಪ್ಶನ್:';
  
  @override
  String get created => 'ಸೃಷ್ಟಿಸಲಾಗಿದೆ';
  
  @override
  String get failedToStartRecording => 'ರೆಕಾರ್ಡಿಂಗ್ ಪ್ರಾರಂಭಿಸಲು ವಿಫಲವಾಗಿದೆ';
  
  @override
  String get transcriptionError => 'ಟ್ರಾಂಸ್ಕ್ರಿಪ್ಶನ್ ದೋಷ';
  
  @override
  String get recordingPathNotFound => 'ರೆಕಾರ್ಡಿಂಗ್ ಪಾಥ್ ಸಿಗಲಿಲ್ಲ';
  
  @override
  String get failedToSaveVoiceNote => 'ವಾಯಿಸ್ ನೋಟ್ ಸೇವ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ';
  
  @override
  String get failedToStartRecordingException => 'ರೆಕಾರ್ಡಿಂಗ್ ಪ್ರಾರಂಭಿಸಲು ವಿಫಲವಾಗಿದೆ';
  
  @override
  String get recordingFailed => 'ರೆಕಾರ್ಡಿಂಗ್ ವಿಫಲವಾಗಿದೆ';
  
  @override
  String get voiceNoteSaved => 'ವಾಯಿಸ್ ನೋಟ್ ಸೇವ್ ಆಗಿದೆ';
  
  @override
  String get failedToSave => 'ಸೇವ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ';
  
  // User Avatar Widget strings
  @override
  String get changeProfilePicture => 'ಪ್ರೋಫೈಲ್ ಚಿತ್ರ ಬದಲಾಯಿಸಿ';
  
  @override
  String get camera => 'ಕ್ಯಾಮೆರಾ';
  
  @override
  String get gallery => 'ಗ್ಯಾಲರಿ';
  
  @override
  String get remove => 'ತೆಗೆದು ಹಾಕಿ';
  
  @override
  String get photoTaken => 'ಫೋಟೋ ತೆಗೆದುಕೊಂಡಿದೆ! ಪ್ರೋಫೈಲ್ ಚಿತ್ರ ಅಪ್ಲೋಡ್ ಸುವಿಧೆ ಇದೆ ಬರುತ್ತದೆ।';
  
  @override
  String get failedToTakePhoto => 'ಫೋಟೋ ತೆಗೆದುಕೊಳ್ಳಲು ವಿಫಲವಾಗಿದೆ';
  
  @override
  String get imageSelected => 'ಚಿತ್ರ ಆಯ್ಕೆ ಮಾಡಲಾಗಿದೆ! ಪ್ರೋಫೈಲ್ ಚಿತ್ರ ಅಪ್ಲೋಡ್ ಸುವಿಧೆ ಇದೆ ಬರುತ್ತದೆ।';
  
  @override
  String get failedToPickImage => 'ಚಿತ್ರ ಆಯ್ಕೆ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ';
  
  @override
  String get photoRemoved => 'ಫೋಟೋ ತೆಗೆದು ಹಾಕಲಾಗಿದೆ!';
  
  // Task Card Widget strings
  @override
  String get recurringLabel => 'ಪುನರಾವೃತ್ತಿ';
  
  @override
  String get sampleAdBanner => '📱 ನಮೂನೆ ಜಾಹೀರಾತು ಬ್ಯಾನರ್';
  
  @override
  String get upgradeToRemoveAds => 'ಜಾಹೀರಾತುಗಳನ್ನು ತೆಗೆದುಹಾಕಲು ಪ್ರೀಮಿಯಂಗೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ';
  
  // Premium helper
  @override
  String get premiumFeature => 'ಪ್ರೀಮಿಯಂ ಸುವಿಧೆ';
  
  @override
  String get premiumFeatureAvailable => 'ಪ್ರೋ ಬೇರೆರವರಿಗೆ ಲಭ್ಯವಿದೆ.';
  
  @override
  String get upgradeToProFor => 'ಪ್ರೋಗೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ:';
  
  @override
  String get maybeLater => 'ಆಗ ಬಹುಶಃ';
  
  @override
  String get upgradeNow => 'ಈಗ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ';
  
  @override
  String get dailyLimitReached => 'ದೈನಂದಿನ ಸೀಮೆ ವೆಂಡಿದೆ';
  
  @override
  String get dailyLimitMessage => 'ನೀವು 20 ಕಾರ್ಯಗಳ ದೈನಂದಿನ ಸೀಮೆಯನ್ನು ವೆಂಡಿದೀರಿ.';
  
  @override
  String get upgradeForUnlimited => 'ಅಪರಿಮಿತ ಕಾರ್ಯಗಳಿಗಾಗಿ ಪ್ರೋಗೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ!';
  
  @override
  String get ok => 'ಸರಿ';
  
  @override
  String get upgrade => 'ಅಪ್‌ಗ್ರೇಡ್';
  
  @override
  String get welcomeToPremium => 'ಪ್ರೀಮಿಯಂಗೆ ಸ್ವಾಗತ! 🎉';
  
  @override
  String get purchaseError => 'ಖರೀದಿ ತ್ರುಟಿ:';
  
  @override
  String get pro => 'ಪ್ರೋ';
  
  @override
  String get unlockUnlimitedFeatures => 'ಅಪರಿಮಿತ ಕಾರ್ಯಗಳು, ಕಸ್ಟಂ ವಾಯ್ಸ್‌ಗಳು ಮತ್ತು ಇನ್ನಷ್ಟು ಅನ್‌ಲಾಕ್ ಮಾಡಿ!';
  
  // Notification helper
  @override
  String get enableNotifications => 'ಅಧಿಸೂಚನೆಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ';
  
  @override
  String get notificationPermissionMessage => 'WhispTask ಗೆ ನಿಮ್ಮ ಕಾರ್ಯಗಳಿಗಾಗಿ ರಿಮೈಂಡರ್‌ಗಳನ್ನು ಕಳುಹಿಸಲು ಅಧಿಸೂಚನೆ ಅನುಮತಿ ಅವಶ್ಯಕತೆ.';
  
  @override
  String get benefits => 'ಲಾಭಗಳು:';
  
  @override
  String get neverMissDeadlines => '• ಮಹತ್ವದ ಕೊನೆಯ ದಿನಾಂಕಗಳನ್ನು ಎಲ್ಲದೇ ಕುಂಡಲ್ಲಿ';
  
  @override
  String get stayOrganized => '• ಸಂಘಟಿತ ಮತ್ತು ಉತ್ಪಾದಕವಾಗಿ ಇರಿ';
  
  @override
  String get customizableReminders => '• ಅನುಕೂಲನೀಯ ರಿಮೈಂಡರ್ ಟೋನ್‌ಗಳು';
  
  @override
  String get flexibleScheduling => '• ಲಚೀಲೆ ಶೆಡ್ಯೂಲಿಂಗ್ ವಿಕಲ್ಪಗಳು';
  
  @override
  String get notNow => 'ಈಗ ಅಲ್ಲ';
  
  @override
  String get enable => 'ಸಕ್ರಿಯಗೊಳಿಸಿ';
  
  @override
  String get permissionRequired => 'ಅನುಮತಿ ಅವಶ್ಯಕ';
  
  @override
  String get notificationsDisabled => 'ಅಧಿಸೂಚನೆಗಳು ಅಕ್ಷಮಗೊಳಿಸಲಾಗಿದೆ. ಕಾರ್ಯ ರಿಮೈಂಡರ್‌ಗಳನ್ನು ಸ್ವೀಕರಿಸಲು ದಯವಿಟ್ಟು ನಿಮ್ಮ ಡಿವೈಸ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಅವುಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ.';
  
  @override
  String get cancelNotification => 'ರದ್ದುಗೊಳಿಸಿ';
  
  @override
  String get openSettings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ';
  
  @override
  String get setReminder => 'ರಿಮೈಂಡರ್ ಸೆಟ್ ಮಾಡಿ';
  
  @override
  String get reminderTime => 'ರಿಮೈಂಡರ್ ಸಮಯ';
  
  // Task calendar
  @override
  String get taskCalendar => 'ಕಾರ್ಯ ಕ್ಯಾಲೆಂಡರ್';
  
  @override
  String get monthView => 'ತಿಂಗಳ ದೃಶ್ಯ';
  
  @override
  String get weekView => 'ವಾರ ದೃಶ್ಯ';
  
  @override
  String get dayView => 'ದಿನ ದೃಶ್ಯ';
  
  @override
  String get todaysTasks => 'ಇಂದಿನ ಕಾರ್ಯಗಳು';
  
  @override
  String get tasksFor => 'ಗಾಗಿ ಕಾರ್ಯಗಳು';
  
  @override
  String get noTasksForThisDay => 'ಈ ದಿನಕ್ಕೆ ಯಾವುದೇ ಕಾರ್ಯಗಳಿಲ್ಲ';
  
  @override
  String get duplicate => 'ಡುಪ್ಲಿಕೇಟ್';
  
  @override
  String get snooze5min => '5 ನಿಮಿಷ ಸ್ನೂಜ್';
  
  @override
  String get snooze30min => '30 ನಿಮಿಷ ಸ್ನೂಜ್';
  
  @override
  String get snooze1hour => '1 ಗಂಟೆ ಸ್ನೂಜ್';
  
  @override
  String get reminderCancelled => 'ರಿಮೈಂಡರ್ ರದ್ದುಗೊಳಿಸಲಾಗಿದೆ';
  
  @override
  String get deletingTask => 'ಕಾರ್ಯ ಅಳಿಸಲಾಗುತ್ತಿದೆ...';
  
  @override
  String get setReminderFor => 'ಗಾಗಿ ರಿಮೈಂಡರ್ ಸೆಟ್ ಮಾಡಿ';
  
  @override
  String get errorTaskIdMissing => 'ತ್ರುಟಿ: ಕಾರ್ಯ ಆಈಡಿ ಕೆಡುಗಿದೆ';
  
  @override
  String get upgradeToProLabel => 'ಪ್ರೋಗೆ ಅಪ್ಗ್ರೇಡ್ ಮಾಡಿ';
  
  @override
  String get addFileLabel => 'ಫೈಲ್ ಸೇರಿಸಿ';
  
  @override
  String get addPhotoLabel => 'ಫೋಟೋ ಸೇರಿಸಿ';
  
  @override
  String get clearDateFiltersLabel => 'ದಿನಾಂಕ ಫಿಲ್ಟರ್‌ಗಳನ್ನು ಅಳಿಸಿ';
  
  @override
  String get applyFiltersLabel => 'ಫಿಲ್ಟರ್‌ಗಳನ್ನು ಅಳಿಸಿ';
  
  @override
  String get snoozeReminder => 'ರಿಮೈಂಡರ್ ಸ್ನೂಜ್ ಮಾಡಿ';
  
  @override
  String get selectTaskColor => 'ಕಾರ್ಯದ ಬರ್ಣ ಆಯ್ಕೆಮಾಡಿ';
  
  @override
  String get noColor => 'ಯಾವುದೇ ಬರ್ಣ ಇಲ್ಲ';
  
  @override
  String get deleteReminder => 'ರಿಮೈಂಡರ್ ಅಳಿಸಿ';
  
  @override
  String get deleteReminderConfirm => 'ನೀವು ವಾಸ್ತವಾಗಿ ಇ ರಿಮೈಂಡರ್‌ಅನ್ನು ಅಳಿಸಲು ಇಚ್ಛಿಸುತ್ತೀರಾ?';
  
  @override
  String get smartReminders => 'ಸ್ಮಾರ್ಟ್ ರಿಮೈಂಡರ್‌ಗಳು';
  
  // Task list screen additional strings
  @override
  String get upgradeToProButton => 'ಪ್ರೋಗೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ';
  
  @override
  String get errorPrefix => 'ತ್ರುಟಿ';
  
  @override
  String get logoutConfirm => 'ನೀವು ವಾಸ್ತವಾಗಿ ಲಾಗ್‌ಆಉಟ್ ಮಾಡಲು ಇಚ್ಛಿಸುತ್ತೀರಾ?';
  
  @override
  String get reminderSnoozed5min => 'ರಿಮೈಂಡರ್ 5 ನಿಮಿಷಗಳಿಗೆ ಸ್ನೂಜ್ ಮಾಡಲಾಗಿದೆ';
  
  @override
  String get reminderSnoozed15min => 'ರಿಮೈಂಡರ್ 15 ನಿಮಿಷಗಳಿಗೆ ಸ್ನೂಜ್ ಮಾಡಲಾಗಿದೆ';
  
  @override
  String get snooze15min => '15 ನಿಮಿಷ ಸ್ನೂಜ್';
  
  @override
  String get setReminderTime => 'ರಿಮೈಂಡರ್ ಸಮಯ ಸೆಟ್ ಮಾಡಿ';
  
  @override
  String get recurringTask => 'ಪುನರಾವರ್ತನೆ ಕಾರ್ಯ';
  
  @override
  String get recurringTaskSubtitle => 'ಈ ಕಾರ್ಯವನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಪುನರಾವರ್ತಿಸಿ';
  
  @override
  String get clearFilters => 'ಫಿಲ್ಟರ್‌ಗಳನ್ನು ಸಾಫ್ ಮಾಡಿ';
  
  @override
  String get cancelReminderAction => 'ರಿಮೈಂಡರ್ ರದ್ದುಮಾಡಿ';

  // Add Task Screen additional strings
  @override
  String get dueDateAndTime => 'ಅಂತಿಮ ದಿನಾಂಕ ಮತ್ತು ಸಮಯ';

  @override
  String get saving => 'ಉಳಿಸಲಾಗುತ್ತಿದೆ...';

  @override
  String get repeatEvery => 'ಪ್ರತಿ ಪುನರಾವರ್ತಿಸಿ';

  @override
  String get pleaseEnterValidInterval => 'ದಯವಿಟ್ಟು ಮಾನ್ಯವಾದ ಮಧ್ಯಂತರವನ್ನು (1 ಅಥವಾ ಹೆಚ್ಚು) ನಮೂದಿಸಿ';

  @override
  String get reminderTimeInPast => 'ರಿಮೈಂಡರ್ ಸಮಯ ಹಿಂದಿನದ್ದಾಗಿದೆ';

  @override
  String get reminderIn => 'ರಿಮೈಂಡರ್ ಇನ್';

  @override
  String get selectDueDateFirst => 'ಮೊದಲು ಅಂತಿಮ ದಿನಾಂಕವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get dueDateCannotBeInPast => 'ಅಂತಿಮ ದಿನಾಂಕ ಹಿಂದಿನದ್ದಾಗಿರಬಾರದು';

  @override
  String get reminderCannotBeInPast => 'ರಿಮೈಂಡರ್ ಹಿಂದಿನದ್ದಾಗಿರಬಾರದು';

  @override
  String get fileAttachments => 'ಫೈಲ್ ಅಟ್ಯಾಚ್ಮೆಂಟ್ಗಳು';

  @override
  String get attachFilesAndPhotos => 'ನಿಮ್ಮ ಕಾರ್ಯಕ್ಕೆ ಫೈಲ್ಗಳು ಮತ್ತು ಫೋಟೋಗಳನ್ನು ಲಗತ್ತಿಸಿ';

  @override
  String get repeatEveryHelperText => 'ಉದಾ., ಪ್ರತಿ 2 ದಿನ/ವಾರ/ತಿಂಗಳಿಗೆ 2';

  @override
  String get pleaseSelectRecurringPattern => 'ದಯವಿಟ್ಟು ಪುನರಾವರ್ತಿತ ಮಾದರಿಯನ್ನು ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get recurringTaskMessage => 'ಈ ಕಾರ್ಯವು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಪುನರಾವರ್ತನೆಯಾಗುತ್ತದೆ';

  @override
  String get repeatEveryNumber => 'ಪ್ರತಿ ಪುನರಾವರ್ತಿಸಿ (ಸಂಖ್ಯೆ)';

  @override
  String get repeatEveryHelper => 'ಉದಾ., ಪ್ರತಿ 2 ದಿನ/ವಾರ/ತಿಂಗಳಿಗೆ 2';

  @override
  String get selectedColon => 'ಆಯ್ಕೆ ಮಾಡಲಾಗಿದೆ:';

  @override
  String get dangerZone => 'ಅಪಾಯ ವಲಯ';

  @override
  String get deleteAllTasksDescription => 'ನಿಮ್ಮ ಎಲ್ಲಾ ಕಾರ್ಯಗಳನ್ನು ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಿ (ಖಾತೆ ಉಳಿಯುತ್ತದೆ)';

  @override
  String get deleteAccountDescription => 'ನಿಮ್ಮ ಖಾತೆ ಮತ್ತು ಎಲ್ಲಾ ಸಂಬಂಧಿತ ಡೇಟಾವನ್ನು ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಿ';

  @override
  String get testCrash => 'ಪರೀಕ್ಷಾ ಕ್ರ್ಯಾಶ್';

  @override
  String get testCrashDescription => 'Sentry ಏಕೀಕರಣವನ್ನು ಪರಿಶೀಲಿಸಲು ಪರೀಕ್ಷಾ ದೋಷವನ್ನು ಪ್ರಚೋದಿಸಿ';

  @override
  String get contactSupport => 'ಬೆಂಬಲವನ್ನು ಸಂಪರ್ಕಿಸಿ';

  @override
  String get accountSecurity => 'ಖಾತೆ ಭದ್ರತೆ';

  @override
  String get securityOptions => 'ಭದ್ರತಾ ಆಯ್ಕೆಗಳು';

  @override
  String get accountType => 'ಖಾತೆ ಪ್ರಕಾರ';

  @override
  String get emailVerified => 'ಇಮೇಲ್ ಪರಿಶೀಲಿಸಲಾಗಿದೆ';

  @override
  String get lastSignIn => 'ಕೊನೆಯ ಸೈನ್ ಇನ್';

  @override
  String get loginAlerts => 'ಲಾಗಿನ್ ಎಚ್ಚರಿಕೆಗಳು';

  @override
  String get loginAlertsDescription => 'ಹೊಸ ಸೈನ್-ಇನ್‌ಗಳ ಅಧಿಸೂಚನೆ ಪಡೆಯಿರಿ';

  @override
  String get confirmAccountDeletion => 'ಖಾತೆ ಅಳಿಸುವಿಕೆಯನ್ನು ದೃಢೀಕರಿಸಿ';

  @override
  String get enterPasswordToConfirm => 'ಖಾತೆ ಅಳಿಸುವಿಕೆಯನ್ನು ದೃಢೀಕರಿಸಲು ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ:';

  @override
  String get needHelpContactUs => 'ಸಹಾಯ ಬೇಕೇ? ನೀವು ನಮ್ಮನ್ನು ಹೇಗೆ ಸಂಪರ್ಕಿಸಲು ಬಯಸುತ್ತೀರಿ ಎಂಬುದನ್ನು ಆರಿಸಿ:';

  @override
  String get emailSupport => 'ಇಮೇಲ್ ಬೆಂಬಲ';

  @override
  String get liveChat => 'ಲೈವ್ ಚಾಟ್';

  @override
  String get availableHours => 'ಲಭ್ಯವಿದೆ ಬೆಳಿಗ್ಗೆ 9 ರಿಂದ ಸಂಜೆ 5 ರವರೆಗೆ';

  @override
  String get deleteAllTasksConfirmation => 'ಇದು ನಿಮ್ಮ ಎಲ್ಲಾ ಕಾರ್ಯಗಳನ್ನು ಶಾಶ್ವತವಾಗಿ ಅಳಿಸುತ್ತದೆ. ಈ ಕ್ರಿಯೆಯನ್ನು ರದ್ದುಗೊಳಿಸಲಾಗುವುದಿಲ್ಲ. ನೀವು ಖಚಿತವಾಗಿರುವಿರಾ?';

  @override
  String get deleteAccountConfirmation => 'ಇದು ನಿಮ್ಮ ಖಾತೆ ಮತ್ತು ಎಲ್ಲಾ ಸಂಬಂಧಿತ ಡೇಟಾವನ್ನು ಶಾಶ್ವತವಾಗಿ ಅಳಿಸುತ್ತದೆ. ಈ ಕ್ರಿಯೆಯನ್ನು ರದ್ದುಗೊಳಿಸಲಾಗುವುದಿಲ್ಲ. ನೀವು ಸಂಪೂರ್ಣವಾಗಿ ಖಚಿತವಾಗಿರುವಿರಾ?';

  @override
  String get accountDeletedSuccessfully => 'ಖಾತೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ';

  @override
  String get exportCompleteDescription => 'ನಿಮ್ಮ ಖಾತೆ ಡೇಟಾವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ರಫ್ತು ಮಾಡಲಾಗಿದೆ!';

  @override
  String get exportFailed => 'ರಫ್ತು ವಿಫಲವಾಗಿದೆ';

  @override
  String get failedToDeleteTasks => 'ಕಾರ್ಯಗಳನ್ನು ಅಳಿಸುವಲ್ಲಿ ವಿಫಲವಾಗಿದೆ';

  @override
  String get biometricUpdatedSuccessfully => 'ಬಯೋಮೆಟ್ರಿಕ್ ದೃಢೀಕರಣವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ';

  @override
  String get loginAlertsComingSoon => 'ಲಾಗಿನ್ ಎಚ್ಚರಿಕೆಗಳ ವೈಶಿಷ್ಟ್ಯ ಶೀಘ್ರದಲ್ಲೇ ಬರುತ್ತಿದೆ!';

  @override
  String get sentryTestCompleted => 'Sentry ಪರೀಕ್ಷೆ ಪೂರ್ಣಗೊಂಡಿದೆ - ಈವೆಂಟ್ ID ಗಳಿಗಾಗಿ ಲಾಗ್‌ಗಳನ್ನು ಪರಿಶೀಲಿಸಿ';

  @override
  String get sentryTestFailed => 'Sentry ಪರೀಕ್ಷೆ ವಿಫಲವಾಗಿದೆ';

  @override
  String get downloadAccountData => 'ಖಾತೆ ಡೇಟಾವನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ';

  @override
  String get downloadAccountDataDescription => 'ನಿಮ್ಮ ಎಲ್ಲಾ ಖಾತೆ ಡೇಟಾ ಮತ್ತು ಕಾರ್ಯಗಳನ್ನು ರಫ್ತು ಮಾಡಿ';

  @override
  String get getHelpDescription => 'ನಿಮ್ಮ ಖಾತೆಗಾಗಿ ಸಹಾಯ ಮತ್ತು ಬೆಂಬಲವನ್ನು ಪಡೆಯಿರಿ';

  @override
  String get biometricAuthenticationDescription => 'ಫಿಂಗರ್‌ಪ್ರಿಂಟ್ ಅಥವಾ ಮುಖ ಗುರುತಿಸುವಿಕೆಯನ್ನು ಬಳಸಿ';

  @override
  String get analyticsDataDescription => 'ಬಳಕೆ ಅನಾಲಿಟಿಕ್ಸ್ ಹಂಚಿಕೊಳ್ಳುವ ಮೂಲಕ ಅಪ್ಲಿಕೇಶನ್ ಅನ್ನು ಸುಧಾರಿಸಲು ಸಹಾಯ ಮಾಡಿ';

  @override
  String get analyticsSettingsUpdated => 'ಅನಾಲಿಟಿಕ್ಸ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಅಪ್‌ಡೇಟ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get crashReportSettingsUpdated => 'ಕ್ರ್ಯಾಶ್ ರಿಪೋರ್ಟ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಅಪ್‌ಡೇಟ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get enjoyingPremiumFeatures => 'ಎಲ್ಲಾ ಪ್ರೀಮಿಯಂ ವೈಶಿಷ್ಟ್ಯಗಳನ್ನು ಆನಂದಿಸುತ್ತಿದ್ದೇವೆ';

  @override
  String get unlockPremiumDescription => 'ಅನಿಯಮಿತ ಕಾರ್ಯಗಳು, ಕಸ್ಟಮ್ ಧ್ವನಿಗಳು ಮತ್ತು ಜಾಹೀರಾತುಗಳಿಲ್ಲದೆ ಅನ್‌ಲಾಕ್ ಮಾಡಿ';

}
