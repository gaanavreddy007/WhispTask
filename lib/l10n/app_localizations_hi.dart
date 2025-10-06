// ignore_for_file: use_super_parameters

import 'app_localizations.dart';

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'व्हिस्पटास्क';

  @override
  String get appDescription => 'आवाज़ से सक्रिय कार्य प्रबंधन';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signUp => 'साइन अप करें';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get displayName => 'प्रदर्शन नाम';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get resetPassword => 'पासवर्ड रीसेट करें';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है?';

  @override
  String get dontHaveAccount => 'खाता नहीं है?';

  // Permission related strings
  @override
  String get requestingMicrophonePermission => 'माइक्रोफोन अनुमति का अनुरोध कर रहे हैं...';

  @override
  String get requestingNotificationPermission => 'सूचना अनुमति का अनुरोध कर रहे हैं...';

  @override
  String get requestingStoragePermission => 'स्टोरेज अनुमति का अनुरोध कर रहे हैं...';

  @override
  String get requestingCameraPermission => 'कैमरा अनुमति का अनुरोध कर रहे हैं...';

  @override
  String get requestingPermissions => 'अनुमतियों का अनुरोध कर रहे हैं...';

  @override
  String get microphonePermissionRequired => 'माइक्रोफोन अनुमति आवश्यक';

  @override
  String get microphonePermissionDescription => 'व्हिस्पटास्क को वॉयस कमांड और टास्क बनाने के लिए माइक्रोफोन एक्सेस की आवश्यकता है। कृपया सेटिंग्स में अनुमति दें।';

  @override
  String get microphonePermissionDenied => 'माइक्रोफोन अनुमति अस्वीकृत';

  @override
  String get microphonePermissionDeniedDescription => 'माइक्रोफोन अनुमति के बिना वॉयस फीचर काम नहीं करेंगे। आप इसे बाद में सेटिंग्स में सक्षम कर सकते हैं।';

  @override
  String get notificationPermissionRequired => 'सूचना अनुमति आवश्यक';

  @override
  String get notificationPermissionDescription => 'व्हिस्पटास्क को टास्क की याद दिलाने के लिए सूचना एक्सेस की आवश्यकता है। कृपया सेटिंग्स में अनुमति दें।';

  @override
  String get storagePermissionRequired => 'स्टोरेज अनुमति आवश्यक';

  @override
  String get storagePermissionDescription => 'व्हिस्पटास्क को वॉयस रिकॉर्डिंग और टास्क अटैचमेंट सेव करने के लिए स्टोरेज एक्सेस की आवश्यकता है। कृपया सेटिंग्स में अनुमति दें।';

  @override
  String get cameraPermissionRequired => 'कैमरा अनुमति आवश्यक';

  @override
  String get cameraPermissionDescription => 'व्हिस्पटास्क को टास्क में फोटो जोड़ने के लिए कैमरा एक्सेस की आवश्यकता है। कृपया सेटिंग्स में अनुमति दें।';

  @override
  String get tasks => 'कार्य';

  @override
  String get addTask => 'कार्य जोड़ें';

  @override
  String get editTask => 'कार्य संपादित करें';

  @override
  String get deleteTask => 'कार्य हटाएं';

  @override
  String get taskTitle => 'कार्य शीर्षक';

  @override
  String get taskDescription => 'कार्य विवरण';

  @override
  String get dueDate => 'देय तिथि';

  @override
  String get priority => 'प्राथमिकता';

  @override
  String get category => 'श्रेणी';

  @override
  String get completed => 'पूर्ण';

  @override
  String get pending => 'लंबित';

  @override
  String get overdue => 'देरी से';

  @override
  String get today => 'आज';

  @override
  String get tomorrow => 'कल';

  @override
  String get thisWeek => 'इस सप्ताह';

  @override
  String get high => 'उच्च';

  @override
  String get medium => 'मध्यम';

  @override
  String get low => 'कम';

  @override
  String get voiceCommands => 'आवाज़ कमांड';

  @override
  String get startListening => 'सुनना शुरू करें';

  @override
  String get stopListening => 'सुनना बंद करें';

  @override
  String get voiceInputHint => 'आवाज़ कमांड शुरू करने के लिए "हे व्हिस्प" कहें';

  @override
  String get sayHeyWhisp => '"हे व्हिस्प" कहें';

  @override
  String get listeningForCommands => 'कमांड सुन रहे हैं...';

  @override
  String get voiceCommandProcessed => 'आवाज़ कमांड प्रोसेस हो गया';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get reminder => 'अनुस्मारक';

  @override
  String get taskReminder => 'कार्य अनुस्मारक';

  @override
  String get dailyDigest => 'दैनिक सकरय';

  @override
  String get completionCelebration => 'पूर्णता उत्सव';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get preferences => 'प्राथमिकताएं';

  @override
  String get language => 'भाषा';

  @override
  String get theme => 'थीम';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get lightMode => 'लाइट मोड';

  @override
  String get systemMode => 'सिस्टम मोड';

  @override
  String get premium => 'प्रीमियम';

  @override
  String get upgradeToPro => 'प्रो में अपग्रेड करें';

  @override
  String get unlimitedTasks => 'असीमित कार्य';

  @override
  String get advancedFeatures => 'उन्नत सुविधाएं';

  @override
  String get premiumSupport => 'प्रीमियम सहायता';

  @override
  String get save => 'सेव करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get search => 'खोजें';

  @override
  String get filter => 'फ़िलइट';

  @override
  String get sort => 'सॉर्ट करें';

  @override
  String get refresh => 'रिफ्रेश करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफलता';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get taskCreated => 'कार्य सफलतापूर्वक बनाया गया';

  @override
  String get taskUpdated => 'कार्य सफलतापूर्वक अपडेट हुआ';

  @override
  String get taskDeleted => 'कार्य सफलतापूर्वक हटाया गया';

  @override
  String get taskCompleted => 'कार्य पूरा हुआ!';

  @override
  String get noTasksFound => 'कोई कार्य नहीं मिला';

  @override
  String get internetRequired => 'इंटरनेट कनेक्शन आवश्यक है';

  @override
  String get somethingWentWrong => 'कुछ गलत हुआ';

  @override
  String get rememberMe => 'मुझे याद रखें';

  @override
  String get welcomeBack => 'वापस स्वागत है';

  @override
  String get signInToContinue => 'अपने कार्यों का प्रबंधन जारी रखने के लिए साइन इन करें';

  @override
  String get enterEmailHint => 'अपना ईमेल पता दर्ज करें';

  @override
  String get enterPasswordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get acceptTermsError => 'कृपया सेवा की शर्तों को स्वीकार करें';

  @override
  String get joinWhispTask => 'व्हिस्पटास्क में शामिल हों';

  @override
  String get convertGuestAccount => 'अपने अतिथि खाते को स्थायी खाते में बदलें';

  @override
  String get startOrganizingTasks => 'वॉयस कमांड के साथ अपने कार्यों का आयोजन शुरू करें';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get enterFullNameHint => 'अपना पूरा नाम दर्ज करें';

  @override
  String get createPasswordHint => 'एक मजबूत पासवर्ड बनाएं';

  @override
  String get reenterPasswordHint => 'अपना पासवर्ड फिर से दर्ज करें';

  @override
  String get voiceInput => 'वॉयस इनपुट';

  @override
  String get pleaseProvideValidTask => 'कृपया एक वैध कार्य विवरण प्रदान करें';

  @override
  String get taskCreatedSuccessfully => 'कार्य सफलतापूर्वक बनाया गया!';

  @override
  String get failedToSaveTask => 'कार्य सहेजने में विफल';

  @override
  String get listeningSpeak => 'सुन रहे हैं... अब बोलें!';

  @override
  String get tapToSpeak => 'बोलने के लिए टैप करें';

  @override
  String get initializing => 'प्रारंभ हो रहा है...';

  @override
  String get youSaid => 'आपने कहा:';

  @override
  String get taskPreview => 'कार्य पूर्वावलोकन:';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get saveTask => 'कार्य सहेजें';

  @override
  String get voiceCommandsExamples => 'वॉयस कमांड उदाहरण:';

  @override
  String get voiceExample1 => '• "मुझे किराने का सामान खरीदने की याद दिलाएं"';

  @override
  String get voiceExample2 => '• "शाम 6 बजे माँ को फोन करें"';

  @override
  String get voiceExample3 => '• "महत्वपूर्ण: कल प्रोजेक्ट जमा करें"';

  @override
  String get voiceExample4 => '• "रोज़ाना जिम में व्यायाम करें"';

  @override
  String get voiceExample5 => '• "बिल भुगतान उच्च प्राथमिकता"';

  @override
  String get recurring => 'आवर्ती';

  @override
  String get recurringLabel => 'दोहराव';

  @override
  String get due => 'देय';

  @override
  String get voiceInputHelp => 'वॉयस इनपुट सहायता';

  @override
  String get howToUseVoiceInput => 'वॉयस इनपुट का उपयोग कैसे करें:';

  @override
  String get voiceStep1 => '1. सुनना शुरू करने के लिए माइक्रोफ़ोन बटन पर टैप करें';

  @override
  String get voiceStep2 => '2. अपना कार्य स्पष्ट रूप से बोलें';

  @override
  String get voiceStep3 => '3. पार्स किए गए कार्य की समीक्षा करें';

  @override
  String get voiceStep4 => '4. इसे अपनी सूची में जोड़ने के लिए "कार्य सहेजें" पर टैप करें';

  @override
  String get voiceFeatures => 'वॉयस सुविधाएं:';

  @override
  String get voiceFeatureTime => '• समय: "शाम 6 बजे", "कल"';

  @override
  String get voiceFeaturePriority => '• प्राथमिकता: "तत्काल", "महत्वपूर्ण", "कम प्राथमिकता"';

  @override
  String get voiceFeatureRecurring => '• आवर्ती: "दैनिक", "साप्ताहिक", "मासिक"';

  @override
  String get voiceFeatureCategories => '• श्रेणियां: कीवर्ड से स्वचालित रूप से पहचानी जाती हैं';

  @override
  String get gotIt => 'समझ गया!';
  
  @override
  String get taskTitleHint => 'अपना कार्य दर्ज करें...';
  
  @override
  String get pleaseEnterTaskTitle => 'कृपया कार्य का शीर्षक दर्ज करें';
  
  @override
  String get titleTooLong => 'शीर्षक 100 अक्षरों से कम होना चाहिए';
  
  @override
  String get descriptionOptional => 'विवरण (वैकल्पिक)';
  
  @override
  String get addMoreDetails => 'अधिक विवरण जोड़ें...';
  
  @override
  String get descriptionTooLong => 'विवरण 500 अक्षरों से कम होना चाहिए';
  
  @override
  String get initializingVoiceServices => 'वॉइस सेवाएं प्रारंभ की जा रही हैं...';
  
  @override
  String get taskProperties => 'कार्य गुण';
  
  @override
  String get taskColor => 'कार्य रंग';
  
  @override
  String get selected => 'चयनित';
  
  // Account Settings Screen strings
  @override
  String get accountSettings => 'खाता सेटिंग्स';
  
  @override
  String get security => 'सुरक्षा';
  
  @override
  String get privacy => 'गोपनीयता';
  
  @override
  String get account => 'खाता';
  
  @override
  String get securityPreferences => 'सुरक्षा प्राथमिकताएं';
  
  @override
  String get biometricAuthentication => 'बायोमेट्रिक प्रमाणीकरण';
  
  @override
  String get biometricAuthDescription => 'ऐप अनलॉक करने के लिए फिंगरप्रिंट या चेहरा पहचान का उपयोग करें';
  
  @override
  String get biometricEnabled => 'बायोमेट्रिक प्रमाणीकरण सक्षम!';
  
  @override
  String get biometricDisabled => 'बायोमेट्रिक प्रमाणीकरण अक्षम';
  
  @override
  String get failedToUpdateBiometric => 'बायोमेट्रिक सेटिंग्स अपडेट करने में विफल';
  
  @override
  String get dataPrivacy => 'डेटा गोपनीयता';
  
  @override
  String get analyticsData => 'एनालिटिक्स डेटा';
  
  @override
  String get analyticsDescription => 'उपयोग एनालिटिक्स साझा करके ऐप सुधारने में मदद करें';
  
  @override
  String get crashReports => 'क्रैश रिपोर्ट';
  
  @override
  String get crashReportsDescription => 'समस्याओं को ठीक करने में मदद के लिए स्वचालित रूप से क्रैश रिपोर्ट भेजें';
  
  @override
  String get marketingEmails => 'मार्केटिंग ईमेल';
  
  @override
  String get marketingEmailsDescription => 'सुझाव, अपडेट और प्रचारक सामग्री प्राप्त करें';
  
  @override
  String get failedToUpdateSettings => 'सेटिंग्स अपडेट करने में विफल';
  
  @override
  String get pushNotifications => 'पुश नोटिफिकेशन';
  
  @override
  String get pushNotificationsDescription => 'कार्य अनुस्मारक और ऐप अपडेट प्राप्त करें';
  
  @override
  String get dataManagement => 'डेटा प्रबंधन';
  
  @override
  String get exportData => 'डेटा निर्यात करें';
  
  @override
  String get exportDataDescription => 'अपने कार्यों और खाता डेटा की एक प्रति डाउनलोड करें';
  
  @override
  String get importData => 'डेटा आयात करें';
  
  @override
  String get importDataDescription => 'पिछले निर्यात से डेटा पुनर्स्थापित करें';
  
  @override
  String get clearCache => 'कैश साफ़ करें';
  
  @override
  String get clearCacheDescription => 'स्थानीय रूप से संग्रहीत ऐप डेटा और प्राथमिकताएं साफ़ करें';
  
  @override
  String get exportingData => 'डेटा निर्यात किया जा रहा है...';
  
  @override
  String get exportComplete => 'निर्यात पूर्ण';
  
  @override
  String get dataExportedSuccessfully => 'आपका डेटा सफलतापूर्वक निर्यात किया गया है!';
  
  @override
  String get fileSize => 'फ़ाइल आकार';
  
  @override
  String get syncing => 'सिंक हो रहा है...';
  
  @override
  String get synced => 'सिंक हो गया';
  
  @override
  String get syncError => 'सिंक त्रुटि - पुनः प्रयास के लिए टैप करें';
  
  @override
  String get offline => 'ऑफ़लाइन - ऑनलाइन होने पर सिंक होगा';
  
  @override
  String get tapToSync => 'सिंक करने के लिए टैप करें';
  
  // Task List Screen strings
  @override
  String get all => 'सभी';
  
  @override
  String get voiceCommandsReady => 'वॉइस कमांड तैयार - माइक शुरू करने के लिए टैप करें';
  
  @override
  String get listeningForHeyWhisp => '"हे व्हिस्प" सुन रहा है...';
  
  @override
  String get voiceError => 'वॉइस त्रुटि - फिर कोशिश करें';
  
  @override
  String get stopVoiceCommands => 'वॉइस कमांड बंद करें';
  
  @override
  String get startVoiceCommands => 'वॉइस कमांड शुरू करें';
  
  @override
  String get calendarView => 'कैलेंडर दृश्य';
  
  @override
  String get logout => 'लॉग आउट';
  
  @override
  String get todaysProductivity => 'आज की उत्पादकता';
  
  @override
  String get great => 'बहुत बढ़िया!';
  
  @override
  String get good => 'अच्छा';
  
  @override
  String get keepGoing => 'जारी रखें!';

  // Provider error messages
  @override
  String get userNotAuthenticated => 'उपयोगकर्ता प्रमाणित नहीं है';
  
  @override
  String get dailyTaskLimitReached => 'दैनिक कार्य सीमा पहुंच गई (20 कार्य)। असीमित कार्यों के लिए प्रो में अपग्रेड करें!';
  
  @override
  String get failedToLoadTasks => 'कार्य लोड करने में विफल';
  
  @override
  String get failedToAddTask => 'कार्य जोड़ने में विफल';
  
  @override
  String get failedToUpdateTask => 'कार्य अपडेट करने में विफल';
  
  @override
  String get failedToDeleteTask => 'कार्य हटाने में विफल';
  
  @override
  String get failedToToggleTaskCompletion => 'कार्य पूर्णता टॉगल करने में विफल';
  
  @override
  String get failedToUpdateTasks => 'कार्य अपडेट करने में विफल';
  
  @override
  String get failedToDeleteAllTasks => 'सभी कार्य हटाने में विफल';
  
  @override
  String get failedToSnoozeReminder => 'रिमाइंडर स्नूज़ करने में विफल';
  
  @override
  String get failedToCancelReminder => 'रिमाइंडर रद्द करने में विफल';
  
  @override
  String get failedToInitializeAuth => 'प्रमाणीकरण प्रारंभ करने में विफल';
  
  @override
  String get purchaseFailed => 'खरीदारी विफल';
  
  @override
  String get restoreFailed => 'पुनर्स्थापना विफल';
  
  @override
  String get pleaseEnterValidEmail => 'कृपया एक वैध ईमेल पता दर्ज करें';
  
  @override
  String get passwordMustBe6Characters => 'पासवर्ड कम से कम 6 अक्षर लंबा होना चाहिए';
  
  @override
  String get pleaseEnterYourName => 'कृपया अपना नाम दर्ज करें';
  
  @override
  String get failedToRegister => 'पंजीकरण में विफल';
  
  @override
  String get pleaseEnterYourPassword => 'कृपया अपना पासवर्ड दर्ज करें';
  
  @override
  String get failedToSignIn => 'साइन इन करने में विफल';
  
  @override
  String get currentUserNotAnonymous => 'वर्तमान उपयोगकर्ता अनाम नहीं है';
  
  @override
  String get failedToLinkAnonymousAccount => 'अनाम खाता लिंक करने में विफल';
  
  @override
  String get failedToResetPassword => 'पासवर्ड रीसेट करने में विफल';
  
  @override
  String get nameCannotBeEmpty => 'नाम खाली नहीं हो सकता';
  
  @override
  String get failedToUpdateProfile => 'प्रोफ़ाइल अपडेट करने में विफल';
  
  @override
  String get failedToUpdatePreferences => 'प्राथमिकताएं अपडेट करने में विफल';
  
  @override
  String get failedToUpdateNotificationSettings => 'सूचना सेटिंग्स अपडेट करने में विफल';
  
  @override
  String get failedToUpdateDisplaySettings => 'डिस्प्ले सेटिंग्स अपडेट करने में विफल';
  
  @override
  String get failedToUpdateVoiceSettings => 'वॉयस सेटिंग्स अपडेट करने में विफल';
  
  @override
  String get failedToUpdatePrivacySettings => 'गोपनीयता सेटिंग्स अपडेट करने में विफल';
  
  @override
  String get failedToResetPreferences => 'प्राथमिकताएं रीसेट करने में विफल';
  
  @override
  String get failedToSyncPreferences => 'प्राथमिकताएं सिंक करने में विफल';
  
  @override
  String get failedToExportUserData => 'उपयोगकर्ता डेटा निर्यात करने में विफल';
  
  @override
  String get failedToImportUserData => 'उपयोगकर्ता डेटा आयात करने में विफल';
  
  @override
  String get failedToClearCache => 'कैश साफ़ करने में विफल';
  
  @override
  String get failedToCreateBackup => 'बैकअप बनाने में विफल';
  
  @override
  String get failedToGetBackups => 'बैकअप प्राप्त करने में विफल';
  
  @override
  String get failedToRestoreFromBackup => 'बैकअप से पुनर्स्थापित करने में विफल';
  
  @override
  String get failedToSyncUserData => 'उपयोगकर्ता डेटा सिंक करने में विफल';
  
  @override
  String get failedToSyncAcrossDevices => 'डिवाइसेस में सिंक करने में विफल';
  
  @override
  String get failedToResolveSyncConflicts => 'सिंक संघर्ष हल करने में विफल';
  
  @override
  String get failedToGetSyncStatistics => 'सिंक आंकड़े प्राप्त करने में विफल';

  // Date filter labels
  @override
  String get onDate => 'पर';
  
  @override
  String get fromDateToDate => 'से';
  
  @override
  String get afterDate => 'के बाद';
  
  @override
  String get beforeDate => 'से पहले';
  
  @override
  String get notSet => 'सेट नहीं';
  
  @override
  String get premiumFeaturesList => '• कस्टम वॉइस पैक\n• ऑफ़लाइन मोड\n• स्मार्ट टैग\n• कस्टम थीम\n• उन्नत एनालिटिक्स\n• कोई विज्ञापन नहीं';
  
  @override
  String get advertisementSpace => 'विज्ञापन स्थान';
  
  @override
  String get removeWithPro => 'प्रो के साथ हटाएं';
  
  @override
  String get activeFilters => 'सक्रिय फिल्टर:';
  
  @override
  String get clearAll => 'सभी साफ़ करें';
  
  @override
  String get overdueReminder => 'अतिदेय अनुस्मारक';
  
  @override
  String get overdueReminders => 'अतिदेय अनुस्मारक';
  
  // Premium Purchase Screen strings
  @override
  String get upgradeToPremium => 'प्रीमियम में अपग्रेड करें';
  
  @override
  String get whispTaskPremium => 'व्हिस्पटास्क प्रीमियम';
  
  @override
  String get unlockFullPotential => 'वॉइस-पावर्ड उत्पादकता की पूरी क्षमता अनलॉक करें';
  
  @override
  String get customVoicePacks => 'कस्टम वॉइस पैक';
  
  @override
  String get customVoicePacksDesc => 'कई वॉइस व्यक्तित्व और उच्चारण में से चुनें';
  
  @override
  String get offlineMode => 'ऑफ़लाइन मोड';
  
  @override
  String get offlineModeDesc => 'इंटरनेट कनेक्शन के बिना वॉइस कमांड का उपयोग करें';
  
  @override
  String get smartTags => 'स्मार्ट टैग';
  
  @override
  String get smartTagsDesc => 'AI-संचालित स्वचालित कार्य वर्गीकरण';
  
  @override
  String get customThemes => 'कस्टम थीम';
  
  @override
  String get customThemesDesc => 'सुंदर थीम के साथ अपने ऐप को व्यक्तिगत बनाएं';
  
  @override
  String get advancedAnalytics => 'उन्नत एनालिटिक्स';
  
  @override
  String get advancedAnalyticsDesc => 'विस्तृत उत्पादकता अंतर्दृष्टि और रिपोर्ट';
  
  @override
  String get noAds => 'कोई विज्ञापन नहीं';
  
  @override
  String get noAdsDesc => 'विज्ञापन-मुक्त अनुभव का आनंद लें';
  
  @override
  String get choose => 'चुनें';

  // Additional Task List Screen localization keys
  @override
  String get processing => 'प्रसंस्करण';

  @override
  String get listening => 'सुन रहा है';

  @override
  String get voiceServiceUnavailable => 'वॉयस सेवा अनुपलब्ध';

  @override
  String get supportTheAppWithPremium => 'प्रीमियम के साथ ऐप का समर्थन करें';

  @override
  String get activeReminders => 'सक्रिय अनुस्मारक';

  @override
  String get snooze5Min => '5 मिनट स्नूज़';

  @override
  String get reminderSnoozedFor5Minutes => '5 मिनट के लिए अनुस्मारक स्नूज़ किया गया';

  @override
  String get taskDetails => 'कार्य विवरण';

  @override
  String get status => 'स्थिति';

  @override
  String get markPending => 'लंबित चिह्नित करें';

  @override
  String get markDone => 'पूर्ण चिह्नित करें';

  @override
  String get snooze15m => '15 मिनट स्नूज़';

  @override
  String get reminderSnoozedFor15Minutes => '15 मिनट के लिए अनुस्मारक स्नूज़ किया गया';

  @override
  String get taskHasActiveReminder => 'इस कार्य में एक सक्रिय अनुस्मारक है। इसे हटाने से अनुस्मारक भी रद्द हो जाएगा।';

  @override
  String get areYouSureDeleteTask => 'क्या आप वाकई इस कार्य को हटाना चाहते हैं?';

  @override
  String get taskAndReminderDeletedSuccessfully => 'कार्य और अनुस्मारक सफलतापूर्वक हटा दिया गया';

  @override
  String get taskDeletedSuccessfully => 'कार्य सफलतापूर्वक हटा दिया गया';

  @override
  String get copy => 'कॉपी';

  @override
  String get reminderNeedsAttention => 'ध्यान चाहिए';

  @override
  String get reminderSet => 'सेट';

  @override
  String get reminders => 'अनुस्मारक';

  @override
  String get cancelReminder => 'अनुस्मारक रद्द करें';

  @override
  String get taskHasActiveReminderDeleteWarning => 'इस कार्य में एक सक्रिय अनुस्मारक है। इसे हटाने से अनुस्मारक भी रद्द हो जाएगा।';

  @override
  String get yes => 'हाँ';

  @override
  String get cancelReminderButton => 'अनुस्मारक रद्द करें';

  @override
  String get no => 'नहीं';

  @override
  String get reminderNeedAttention => 'आपका ध्यान चाहिए';

  @override
  String get soon => 'जल्द';

  @override
  String get updated => 'अपडेट किया गया';

  @override
  String get yesterday => 'कल';

  @override
  String get justNow => 'अभी';

  @override
  String get ago => 'पहले';

  @override
  String get inTime => 'में';

  @override
  String get filterTasks => 'कार्य फ़िल्टर करें';

  @override
  String get clearAllFilters => 'सभी फ़िल्टर साफ़ करें';

  @override
  String get selectCategories => 'श्रेणियां चुनें';

  @override
  String get properties => 'गुण';

  @override
  String get dates => 'तारीखें';

  @override
  String get specialFilters => 'विशेष फ़िल्टर';

  @override
  String get recurringTasksOnly => 'केवल आवर्ती कार्य';

  @override
  String get showOnlyTasksRepeat => 'केवल दोहराए जाने वाले कार्य दिखाएं';

  @override
  String get tasksWithRemindersOnly => 'केवल अनुस्मारक वाले कार्य';

  @override
  String get showOnlyTasksReminders => 'केवल सक्रिय अनुस्मारक वाले कार्य दिखाएं';

  @override
  String get overdueTasksOnly => 'केवल देर से किए गए कार्य';

  @override
  String get showOnlyTasksPastDue => 'केवल निर्धारित तिथि बीत चुके कार्य दिखाएं';

  @override
  String get dueDateRange => 'नियत तिथि सीमा';

  @override
  String get nextWeek => 'अगला सप्ताह';

  @override
  String get customDateRange => 'कस्टम दिनांक सीमा';

  @override
  String get startDate => 'प्रारंभ तिथि';

  @override
  String get endDate => 'समाप्ति तिथि';

  @override
  String get selectDate => 'तारीख चुनें';

  @override
  String get categories => 'श्रेणियां';

  @override
  String get colors => 'रंग';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get taskMarkedIncomplete => 'कार्य अधूरे के रूप में चिह्नित किया गया';

  @override
  String get taskCompletedNextOccurrence => 'कार्य पूरा हो गया! अगली घटना बनाई गई';

  @override
  String get taskDuplicatedSuccess => 'कार्य सफलतापूर्वक डुप्लिकेट किया गया!';

  @override
  String get failedToDuplicateTask => 'कार्य डुप्लिकेट करने में विफल';

  @override
  String get reminderSnoozedMinutes => 'अनुस्मारक को स्नूज किया गया';

  @override
  String get confirmDeleteTask => 'क्या आप वाकई हटाना चाहते हैं';

  @override
  String get willCancelActiveReminder => 'यह सक्रिय अनुस्मारक को भी रद्द कर देगा।';

  @override
  String get willStopFutureRecurring => 'यह सभी भविष्य की आवर्ती घटनाओं को रोक देगा।';

  @override
  String get taskDeletedSuccess => 'कार्य सफलतापूर्वक डिलीट किया गया!';


  @override
  String get selectTime => 'समय चुनें';

  @override
  String get reminderSetFor => 'अनुस्मारक सेट किया गया';

  @override
  String get failedToSetReminder => 'अनुस्मारक सेट करने में विफल';

  @override
  String get passwordStrength => 'पासवर्ड की मजबूती';

  @override
  String get passwordRequirements => 'पासवर्ड आवश्यकताएं';

  @override
  String get strong => 'मजबूत';

  @override
  String get user => 'उपयोगकर्ता';

  @override
  String get minutes => 'मिनट';
  
  @override
  String get chooseYourPlan => 'अपना प्लान चुनें';
  
  @override
  String get monthly => 'मासिक';
  
  @override
  String get yearly => 'वार्षिक';
  
  @override
  String get month => '/माह';
  
  @override
  String get year => '/वर्ष';
  
  @override
  String get allPremiumFeatures => 'सभी प्रीमियम सुविधाएं';
  
  @override
  String get cancelAnytime => 'कभी भी रद्द करें';
  
  @override
  String get instantActivation => 'तत्काल सक्रियण';
  
  @override
  String get saveVsMonthly => 'मासिक की तुलना में 33% बचत';
  
  @override
  String get prioritySupport => 'प्राथमिकता सहायता';
  
  @override
  String get earlyAccess => 'नई सुविधाओं तक जल्दी पहुंच';
  
  @override
  String get restorePurchases => 'खरीदारी पुनर्स्थापित करें';
  
  @override
  String get termsAndPrivacy => 'खरीदारी करके, आप हमारी सेवा की शर्तों और गोपनीयता नीति से सहमत होते हैं। सदस्यताएं रद्द न होने तक स्वचालित रूप से नवीनीकृत होती हैं।';
  
  @override
  String get premiumActive => 'प्रीमियम सक्रिय';
  
  @override
  String get premiumActiveDesc => 'आपके पास सभी प्रीमियम सुविधाओं तक पहुंच है।';
  
  @override
  String get continue_ => 'जारी रखें';
  
  @override
  String get popular => 'लोकप्रिय';
  
  @override
  String get monthlyPremiumActivated => 'मासिक प्रीमियम सक्रिय! 🎉';
  
  @override
  String get yearlyPremiumActivated => 'वार्षिक प्रीमियम सक्रिय! 🎉';
  
  @override
  String get purchasesRestored => 'खरीदारी सफलतापूर्वक पुनर्स्थापित!';
  
  @override
  String get failedToRestore => 'खरीदारी पुनर्स्थापित करने में विफल';
  
  // Login Screen strings
  @override
  String get or => 'या';
  
  @override
  String get continueAsGuest => 'अतिथि के रूप में जारी रखें';

  @override
  String get continueWithGoogle => 'Google के साथ जारी रखें';

  @override
  String get signInWithGoogle => 'Google से साइन इन करें';

  @override
  String get linkWithGoogle => 'Google से जोड़ें';

  @override
  String get byContingTermsPrivacy => 'जारी रखकर, आप हमारी सेवा की शर्तों और गोपनीयता नीति से सहमत होते हैं।';
  
  @override
  String get forgotPasswordTitle => 'पासवर्ड भूल गए?';
  
  @override
  String get forgotPasswordDesc => 'अपना ईमेल पता दर्ज करें और हम आपको पासवर्ड रीसेट करने के लिए एक लिंक भेजेंगे।';
  
  @override
  String get emailAddress => 'ईमेल पता';
  
  @override
  String get enterEmailAddress => 'अपना ईमेल पता दर्ज करें';
  
  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';
  
  @override
  String get backToSignIn => 'साइन इन पर वापस जाएं';
  
  @override
  String get passwordResetSent => 'पासवर्ड रीसेट लिंक आपके ईमेल पर भेजा गया';
  
  // Signup Screen strings
  @override
  String get iAgreeToTerms => 'मैं सहमत हूं ';
  
  @override
  String get termsOfService => 'सेवा की शर्तें';
  
  @override
  String get and => ' और ';
  
  @override
  String get privacyPolicy => 'गोपनीयता नीति';
  
  @override
  String get atLeast8Characters => 'कम से कम 8 अक्षर';
  
  @override
  String get containsLowercase => 'छोटे अक्षर शामिल हैं';
  
  @override
  String get containsUppercase => 'बड़े अक्षर शामिल हैं';
  
  @override
  String get containsNumber => 'संख्या शामिल है';
  
  @override
  String get containsSpecialChar => 'विशेष अक्षर शामिल है';
  
  // Profile Screen strings
  @override
  String get accountStatistics => 'खाता आंकड़े';
  
  @override
  String get totalTasks => 'कुल कार्य';
  
  @override
  String get completionRate => 'पूर्णता दर';
  
  @override
  String get memberSince => 'सदस्य बने';
  
  @override
  String get profileInformation => 'प्रोफ़ाइल जानकारी';
  
  @override
  String get saveChanges => 'परिवर्तन सहेजें';
  
  @override
  String get accountActions => 'खाता क्रियाएं';
  
  @override
  String get upgradeAccount => 'खाता अपग्रेड करें';
  
  @override
  String get upgradeAccountDesc => 'डिवाइसों में सिंक करने के लिए स्थायी खाता बनाएं';
  
  @override
  String get changePassword => 'पासवर्ड बदलें';
  
  @override
  String get changePasswordDesc => 'अपना खाता पासवर्ड अपडेट करें';
  
  @override
  String get accountSettingsDesc => 'गोपनीयता और सुरक्षा सेटिंग्स प्रबंधित करें';
  
  @override
  String get signOutDesc => 'अपने खाते से साइन आउट करें';
  
  @override
  String get signOutTitle => 'साइन आउट';
  
  @override
  String get signOutConfirm => 'क्या आप वाकई अपने खाते से साइन आउट करना चाहते हैं?';
  
  @override
  String get profileUpdatedSuccess => 'प्रोफ़ाइल सफलतापूर्वक अपडेट हो गई!';
  
  // Change Password Screen strings
  @override
  String get changePasswordTitle => 'अपना पासवर्ड बदलें';
  
  @override
  String get changePasswordSubtitle => 'मजबूत, अनोखे पासवर्ड का उपयोग करके अपने खाते को सुरक्षित रखें';
  
  @override
  String get passwordInformation => 'पासवर्ड जानकारी';
  
  @override
  String get currentPassword => 'वर्तमान पासवर्ड';
  
  @override
  String get enterCurrentPassword => 'अपना वर्तमान पासवर्ड दर्ज करें';
  
  @override
  String get newPassword => 'नया पासवर्ड';
  
  @override
  String get enterNewPassword => 'अपना नया पासवर्ड दर्ज करें';
  
  @override
  String get confirmNewPassword => 'नया पासवर्ड पुष्टि करें';
  
  @override
  String get confirmNewPasswordHint => 'अपने नए पासवर्ड की पुष्टि करें';
  
  @override
  String get securityTips => 'सुरक्षा सुझाव';
  
  @override
  String get tip1 => 'कम से कम 8 अक्षरों का उपयोग करें';
  
  @override
  String get tip2 => 'बड़े और छोटे अक्षर शामिल करें';
  
  @override
  String get tip3 => 'संख्या और विशेष अक्षर जोड़ें';
  
  @override
  String get tip4 => 'व्यक्तिगत जानकारी से बचें';
  
  @override
  String get tip5 => 'अन्य खातों के पासवर्ड दोबारा उपयोग न करें';
  
  @override
  String get passwordChangedSuccess => 'पासवर्ड सफलतापूर्वक बदल दिया गया!';
  
  // Language Settings Screen strings
  @override
  String get selectLanguage => 'Select Language / भाषा चुनें / ಭಾಷೆ ಆಯ್ಕೆ ಮಾಡಿ';
  
  @override
  String get information => 'जानकारी';
  
  @override
  String get languageChangesApply => 'भाषा परिवर्तन तुरंत लागू होते हैं';
  
  @override
  String get voiceCommandsWork => 'वॉयस कमांड सभी भाषाओं में काम करते हैं';
  
  @override
  String get preferencesSaved => 'आपकी प्राथमिकता स्वचालित रूप से सहेजी जाती है';
  
  @override
  String get languageChangedSuccess => 'भाषा सफलतापूर्वक बदल दी गई';
  
  @override
  String get failedToChangeLanguage => 'भाषा बदलने में असफल';
  
  @override
  String get errorChangingLanguage => 'भाषा बदलने में त्रुटि';
  
  // Splash Screen strings
  @override
  String get whispTask => 'WhispTask';
  
  @override
  String get voicePoweredTaskManagement => 'आवाज-संचालित कार्य प्रबंधन';
  
  // Voice Input Screen strings
  @override
  String get testCommandsTitle => 'टेस्ट कमांड (माइक्रोफोन विकल्प)';
  
  @override
  String get testCommandsHint => 'टाइप करें: होमवर्क कल, ग्रॉसरी आज अपडेट करें';
  
  @override
  String get testCommand => 'टेस्ट कमांड';
  
  // Task List Screen strings
  @override
  String get listeningForWakeWord => '"हे व्हिस्प" सुन रहा है...';
  
  @override
  String get processingVoiceCommand => 'प्रोसेसिंग';
  
  @override
  String get premiumFeatures => 'प्रीमियम फीचर्स';
  
  // Add Task Screen strings
  @override
  String get taskAddedSuccessfully => 'कार्य सफलतापूर्वक जोड़ा गया';
  
  @override
  String get taskUpdatedSuccessfully => 'कार्य सफलतापूर्वक अपडेट किया गया';
  
  @override
  String get withReminder => 'रिमाइंडर के साथ';
  
  // Voice Notes Widget strings
  @override
  String get voiceNotes => 'वॉयस नोट्स';
  
  @override
  String get recording => 'रिकॉर्डिंग...';
  
  @override
  String get transcribing => 'ट्रांसक्रिप्शन...';
  
  @override
  String get liveTranscription => 'लाइव ट्रांसक्रिप्शन:';
  
  @override
  String get recordedNotes => 'रिकॉर्ड किए गए नोट्स:';
  
  @override
  String get duration => 'अवधि';
  
  @override
  String get transcription => 'ट्रांसक्रिप्शन:';
  
  @override
  String get created => 'बनाया गया';
  
  @override
  String get failedToStartRecording => 'रिकॉर्डिंग शुरू करने में असफल';
  
  @override
  String get transcriptionError => 'ट्रांसक्रिप्शन त्रुटि';
  
  @override
  String get recordingPathNotFound => 'रिकॉर्डिंग पथ नहीं मिला';
  
  @override
  String get failedToSaveVoiceNote => 'वॉयस नोट सेव करने में असफल';
  
  @override
  String get failedToStartRecordingException => 'रिकॉर्डिंग शुरू करने में असफल';
  
  @override
  String get recordingFailed => 'रिकॉर्डिंग असफल';
  
  @override
  String get voiceNoteSaved => 'वॉयस नोट सेव हो गया';
  
  @override
  String get failedToSave => 'सेव करने में असफल';
  
  // User Avatar Widget strings
  @override
  String get changeProfilePicture => 'प्रोफाइल चित्र बदलें';
  
  @override
  String get camera => 'कैमरा';
  
  @override
  String get gallery => 'गैलरी';
  
  @override
  String get remove => 'हटाएं';
  
  @override
  String get photoTaken => 'फोटो ली गई! प्रोफाइल चित्र अपलोड सुविधा जल्द आएगी।';
  
  @override
  String get failedToTakePhoto => 'फोटो लेने में असफल';
  
  @override
  String get imageSelected => 'छवि चुनी गई! प्रोफाइल चित्र अपलोड सुविधा जल्द आएगी।';
  
  @override
  String get failedToPickImage => 'छवि चुनने में असफल';
  
  @override
  String get photoRemoved => 'फोटो हटा दी गई!';
  
  // Task Card Widget strings
  
  @override
  String get sampleAdBanner => '📱 नमूना विज्ञापन बैनर';
  
  @override
  String get upgradeToRemoveAds => 'विज्ञापन हटाने के लिए प्रीमियम में अपग्रेड करें';
  
  // Premium helper
  @override
  String get premiumFeature => 'प्रीमियम सुविधा';
  
  @override
  String get premiumFeatureAvailable => 'प्रो उपयोगकर्ताओं के लिए उपलब्ध है।';
  
  @override
  String get upgradeToProFor => 'प्रो के लिए अपग्रेड करें:';
  
  @override
  String get maybeLater => 'शायद बाद में';
  
  @override
  String get upgradeNow => 'अभी अपग्रेड करें';
  
  @override
  String get dailyLimitReached => 'दैनिक सीमा पूरी हो गई';
  
  @override
  String get dailyLimitMessage => 'आपने 20 कार्यों की दैनिक सीमा पूरी कर ली है।';
  
  @override
  String get upgradeForUnlimited => 'असीमित कार्यों के लिए प्रो में अपग्रेड करें!';
  
  @override
  String get ok => 'ठीक है';
  
  @override
  String get upgrade => 'अपग्रेड';
  
  @override
  String get welcomeToPremium => 'प्रीमियम में आपका स्वागत है! 🎉';
  
  @override
  String get purchaseError => 'खरीदारी त्रुटि:';
  
  @override
  String get pro => 'प्रो';
  
  @override
  String get unlockUnlimitedFeatures => 'असीमित कार्य, कस्टम आवाज़ें और बहुत कुछ अनलॉक करें!';
  
  // Notification helper
  @override
  String get enableNotifications => 'अधिसूचनाएं सक्षम करें';
  
  @override
  String get notificationPermissionMessage => 'WhispTask को आपके कार्यों के लिए रिमाइंडर भेजने के लिए अधिसूचना अनुमति की आवश्यकता है।';
  
  @override
  String get benefits => 'लाभ:';
  
  @override
  String get neverMissDeadlines => '• महत्वपूर्ण समय सीमा कभी न चूकें';
  
  @override
  String get stayOrganized => '• व्यवस्थित और उत्पादक रहें';
  
  @override
  String get customizableReminders => '• अनुकूलन योग्य रिमाइंडर टोन';
  
  @override
  String get flexibleScheduling => '• लचीले शेड्यूलिंग विकल्प';
  
  @override
  String get notNow => 'अभी नहीं';
  
  @override
  String get enable => 'सक्षम करें';
  
  @override
  String get permissionRequired => 'अनुमति आवश्यक';
  
  @override
  String get notificationsDisabled => 'अधिसूचनाएं अक्षम हैं। कृपया कार्य रिमाइंडर प्राप्त करने के लिए उन्हें अपनी डिवाइस सेटिंग्स में सक्षम करें।';
  
  @override
  String get cancelNotification => 'रद्द करें';
  
  @override
  String get openSettings => 'सेटिंग्स खोलें';
  
  @override
  String get setReminder => 'रिमाइंडर सेट करें';
  
  @override
  String get reminderTime => 'रिमाइंडर समय';
  
  // Task calendar
  @override
  String get taskCalendar => 'कार्य कैलेंडर';
  
  @override
  String get monthView => 'मासिक दृश्य';
  
  @override
  String get weekView => 'साप्ताहिक दृश्य';
  
  @override
  String get dayView => 'दैनिक दृश्य';
  
  @override
  String get todaysTasks => 'आज के कार्य';
  
  @override
  String get tasksFor => 'के लिए कार्य';
  
  @override
  String get noTasksForThisDay => 'इस दिन के लिए कोई कार्य नहीं';
  
  @override
  String get duplicate => 'डुप्लिकेट';
  
  @override
  String get snooze5min => '5 मिनट स्नूज़';
  
  @override
  String get snooze30min => '30 मिनट स्नूज़';
  
  @override
  String get snooze1hour => '1 घंटा स्नूज़';
  
  @override
  String get reminderCancelled => 'रिमाइंडर रद्द किया गया';
  
  @override
  String get deletingTask => 'कार्य हटाया जा रहा है...';
  
  @override
  String get setReminderFor => 'के लिए रिमाइंडर सेट करें';
  
  @override
  String get errorTaskIdMissing => 'त्रुटि: कार्य आईडी गुम है';
  
  @override
  String get upgradeToProLabel => 'प्रो में अपग्रेड करें';
  
  @override
  String get addFileLabel => 'फ़ाइल जोड़ें';
  
  @override
  String get addPhotoLabel => 'फोटो जोड़ें';
  
  @override
  String get clearDateFiltersLabel => 'दिनांक फ़िल्टर साफ़ करें';
  
  @override
  String get applyFiltersLabel => 'फ़िल्टर लागू करें';
  
  // Additional notification helper strings
  @override
  String get snoozeReminder => 'रिमाइंडर स्नूज़ करें';
  
  @override
  String get selectTaskColor => 'कार्य रंग चुनें';
  
  @override
  String get noColor => 'कोई रंग नहीं';
  
  @override
  String get deleteReminder => 'रिमाइंडर हटाएं';
  
  @override
  String get deleteReminderConfirm => 'क्या आप वाकई इस रिमाइंडर को हटाना चाहते हैं?';
  
  @override
  String get smartReminders => 'स्मार्ट रिमाइंडर';
  
  // Task list screen additional strings
  @override
  String get upgradeToProButton => 'प्रो में अपग्रेड करें';
  
  @override
  String get errorPrefix => 'त्रुटि';
  
  @override
  String get logoutConfirm => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';
  
  @override
  String get reminderSnoozed5min => 'रिमाइंडर 5 मिनट के लिए स्नूज़ किया गया';
  
  @override
  String get reminderSnoozed15min => 'रिमाइंडर 15 मिनट के लिए स्नूज़ किया गया';
  
  @override
  String get snooze15min => '15 मिनट स्नूज़';
  
  @override
  String get setReminderTime => 'रिमाइंडर समय सेट करें';
  
  @override
  String get recurringTask => 'आवर्ती कार्य';
  
  @override
  String get recurringTaskSubtitle => 'इस कार्य को स्वचालित रूप से दोहराएं';
  
  @override
  String get clearFilters => 'फ़िल्टर साफ़ करें';
  
  @override
  String get cancelReminderAction => 'रिमाइंडर रद्द करें';

  // Add Task Screen additional strings
  @override
  String get dueDateAndTime => 'देय तिथि और समय';

  @override
  String get saving => 'सहेजा जा रहा है...';

  @override
  String get repeatEvery => 'दोहराएं हर';

  @override
  String get pleaseEnterValidInterval => 'कृपया एक वैध अंतराल (1 या अधिक) दर्ज करें';

  @override
  String get reminderTimeInPast => 'रिमाइंडर समय अतीत में है';

  @override
  String get reminderIn => 'रिमाइंडर में';

  @override
  String get selectDueDateFirst => 'पहले देय तिथि चुनें';

  @override
  String get dueDateCannotBeInPast => 'देय तिथि अतीत में नहीं हो सकती';

  @override
  String get reminderCannotBeInPast => 'रिमाइंडर अतीत में नहीं हो सकता';

  @override
  String get fileAttachments => 'फ़ाइल अटैचमेंट';

  @override
  String get attachFilesAndPhotos => 'अपने कार्य में फ़ाइलें और फ़ोटो संलग्न करें';

  @override
  String get repeatEveryHelperText => 'उदा., हर 2 दिन/सप्ताह/महीने के लिए 2';

  @override
  String get pleaseSelectRecurringPattern => 'कृपया एक आवर्ती पैटर्न चुनें';

  @override
  String get recurringTaskMessage => 'यह कार्य स्वचालित रूप से दोहराया जाएगा';

  @override
  String get repeatEveryNumber => 'दोहराएं हर (संख्या)';

  @override
  String get repeatEveryHelper => 'उदा., हर 2 दिन/सप्ताह/महीने के लिए 2';

  @override
  String get selectedColon => 'चयनित:';

  @override
  String get dangerZone => 'खतरा क्षेत्र';

  @override
  String get deleteAllTasksDescription => 'स्थायी रूप से अपने सभी कार्य हटाएं (खाता बना रहेगा)';

  @override
  String get deleteAccountDescription => 'स्थायी रूप से अपना खाता और सभी संबंधित डेटा हटाएं';

  @override
  String get testCrash => 'टेस्ट क्रैश';

  @override
  String get testCrashDescription => 'Sentry एकीकरण सत्यापित करने के लिए एक परीक्षण त्रुटि ट्रिगर करें';

  @override
  String get contactSupport => 'सहायता से संपर्क करें';

  @override
  String get accountSecurity => 'खाता सुरक्षा';

  @override
  String get securityOptions => 'सुरक्षा विकल्प';

  @override
  String get accountType => 'खाता प्रकार';

  @override
  String get emailVerified => 'ईमेल सत्यापित';

  @override
  String get lastSignIn => 'अंतिम साइन इन';

  @override
  String get loginAlerts => 'लॉगिन अलर्ट';

  @override
  String get loginAlertsDescription => 'नए साइन-इन की सूचना प्राप्त करें';

  @override
  String get confirmAccountDeletion => 'खाता हटाने की पुष्टि करें';

  @override
  String get enterPasswordToConfirm => 'खाता हटाने की पुष्टि के लिए अपना पासवर्ड दर्ज करें:';

  @override
  String get needHelpContactUs => 'सहायता चाहिए? चुनें कि आप हमसे कैसे संपर्क करना चाहते हैं:';

  @override
  String get emailSupport => 'ईमेल सहायता';

  @override
  String get liveChat => 'लाइव चैट';

  @override
  String get availableHours => 'उपलब्ध सुबह 9 बजे - शाम 5 बजे';

  @override
  String get deleteAllTasksConfirmation => 'यह स्थायी रूप से आपके सभी कार्यों को हटा देगा। इस क्रिया को पूर्ववत नहीं किया जा सकता। क्या आप सुनिश्चित हैं?';

  @override
  String get deleteAccountConfirmation => 'यह स्थायी रूप से आपका खाता और सभी संबंधित डेटा हटा देगा। इस क्रिया को पूर्ववत नहीं किया जा सकता। क्या आप बिल्कुल सुनिश्चित हैं?';

  @override
  String get accountDeletedSuccessfully => 'खाता सफलतापूर्वक हटा दिया गया';

  @override
  String get exportCompleteDescription => 'आपका खाता डेटा सफलतापूर्वक निर्यात हो गया है!';

  @override
  String get exportFailed => 'निर्यात असफल';

  @override
  String get failedToDeleteTasks => 'कार्य हटाने में असफल';

  @override
  String get biometricUpdatedSuccessfully => 'बायोमेट्रिक प्रमाणीकरण सफलतापूर्वक अपडेट किया गया';

  @override
  String get loginAlertsComingSoon => 'लॉगिन अलर्ट सुविधा जल्द आ रही है!';

  @override
  String get sentryTestCompleted => 'Sentry परीक्षण पूर्ण - इवेंट ID के लिए लॉग जांचें';

  @override
  String get sentryTestFailed => 'Sentry परीक्षण असफल';

  @override
  String get downloadAccountData => 'खाता डेटा डाउनलोड करें';

  @override
  String get downloadAccountDataDescription => 'अपना सभी खाता डेटा और कार्य निर्यात करें';

  @override
  String get getHelpDescription => 'अपने खाते के लिए सहायता और समर्थन प्राप्त करें';

  @override
  String get biometricAuthenticationDescription => 'फिंगरप्रिंट या चेहरे की पहचान का उपयोग करें';

  @override
  String get analyticsDataDescription => 'उपयोग एनालिटिक्स साझा करके ऐप को बेहतर बनाने में मदद करें';

  @override
  String get analyticsSettingsUpdated => 'एनालिटिक्स सेटिंग्स अपडेट की गईं';

  @override
  String get crashReportSettingsUpdated => 'क्रैश रिपोर्ट सेटिंग्स अपडेट की गईं';

  @override
  String get enjoyingPremiumFeatures => 'सभी प्रीमियम सुविधाओं का आनंद ले रहे हैं';

  @override
  String get unlockPremiumDescription => 'असीमित कार्य, कस्टम आवाज़ें, और कोई विज्ञापन नहीं अनलॉक करें';

}
