# WhispTask - Comprehensive Compatibility Guide

> **Complete technical reference for WhispTask voice-enabled task management application**  
> Covers all configurations, constants, and compatibility settings for development and deployment

## 1. Firebase Configuration

### Authentication Providers
- **Email/Password**: `password`
- **Google Sign-In**: `google.com`
- **Apple Sign-In**: `apple.com`
- **Phone Authentication**: `phone`

### Firestore Collections
```dart
const String usersCollection = 'users';
const String tasksCollection = 'tasks';
const String userPreferencesCollection = 'user_preferences';
const String premiumSubscriptionsCollection = 'premium_subscriptions';
const String voiceCommandHistoryCollection = 'voice_command_history';
```

### Storage Bucket Paths
- Profile Pictures: `profile_pictures/{userId}.jpg`
- Task Attachments: `task_attachments/{taskId}/{filename}`
- Voice Notes: `voice_notes/{userId}/{taskId}_{timestamp}.wav`

## 2. Multilingual Support Configuration

### Language Settings
```dart
// Supported Languages
const Map<String, String> supportedLanguages = {
  'en': 'English',
  'hi': 'हिंदी',
  'kn': 'ಕನ್ನಡ',
};

const Map<String, Locale> supportedLocales = {
  'en': Locale('en'),
  'hi': Locale('hi'),
  'kn': Locale('kn'),
};

// Language Preference Keys
const String selectedLanguageKey = 'selected_language';
const String systemLanguageDetectedKey = 'system_language_detected';
const String languageInitializedKey = 'language_initialized';

// Localization File Paths
const Map<String, String> localizationPaths = {
  'en': 'lib/l10n/app_localizations_en.dart',
  'hi': 'lib/l10n/app_localizations_hi.dart',
  'kn': 'lib/l10n/app_localizations_kn.dart',
};

// Voice Command Language Support
const Map<String, List<String>> voiceCommandLanguages = {
  'en': ['en-US', 'en-GB', 'en-AU', 'en-CA', 'en-IN'],
  'hi': ['hi-IN'],
  'kn': ['kn-IN'],
};
```

### Localization Constants
```dart
// Text Direction Support
const Map<String, TextDirection> languageDirections = {
  'en': TextDirection.ltr,
  'hi': TextDirection.ltr,
  'kn': TextDirection.ltr,
};

// Font Family Support
const Map<String, String> languageFonts = {
  'en': 'Roboto',
  'hi': 'NotoSansDevanagari',
  'kn': 'NotoSansKannada',
};

// Number Format Locales
const Map<String, String> numberFormatLocales = {
  'en': 'en_US',
  'hi': 'hi_IN',
  'kn': 'kn_IN',
};
```

## 3. SharedPreferences Keys
```dart
// Authentication & User
const String authTokenKey = 'auth_token';
const String userIdKey = 'user_id';
const String userEmailKey = 'user_email';
const String userDisplayNameKey = 'user_display_name';
const String userPhotoUrlKey = 'user_photo_url';
const String isPremiumUserKey = 'is_premium_user';
const String subscriptionTypeKey = 'subscription_type';
const String subscriptionExpiryKey = 'subscription_expiry';

// App Settings
const String themeModeKey = 'theme_mode';
const String notificationEnabledKey = 'notifications_enabled';
const String voiceCommandEnabledKey = 'voice_command_enabled';
const String ttsRateKey = 'tts_speech_rate';  // Default: 0.5
const String ttsVolumeKey = 'tts_volume';  // Default: 1.0
const String wakeWordEnabledKey = 'wake_word_enabled';
const String backgroundListeningKey = 'background_listening_enabled';
const String voiceFeedbackEnabledKey = 'voice_feedback_enabled';

// Privacy & Security
const String biometricAuthEnabledKey = 'biometric_auth_enabled';
const String analyticsEnabledKey = 'analytics_enabled';
const String crashReportsEnabledKey = 'crash_reports_enabled';
const String marketingEmailsEnabledKey = 'marketing_emails_enabled';
const String voiceDataProcessingKey = 'voice_data_processing_enabled';

// Feature Flags
const String adsEnabledKey = 'ads_enabled';
const String cloudBackupEnabledKey = 'cloud_backup_enabled';
const String advancedVoiceFeaturesKey = 'advanced_voice_features';
const String debugModeEnabledKey = 'debug_mode_enabled';
const String betaFeaturesEnabledKey = 'beta_features_enabled';

// Performance Settings
const String appLaunchOptimizedKey = 'app_launch_optimized';
const String voiceProcessingOptimizedKey = 'voice_processing_optimized';
const String batteryOptimizationKey = 'battery_optimization_enabled';
const String dataUsageOptimizationKey = 'data_usage_optimization';

// Onboarding & Tutorial
const String hasCompletedOnboardingKey = 'has_completed_onboarding';
const String hasSeenVoiceTutorialKey = 'has_seen_voice_tutorial';
const String hasSeenPremiumIntroKey = 'has_seen_premium_intro';
const String tutorialStepKey = 'current_tutorial_step';
```

## 4. Notification Channels
```dart
const String defaultNotificationChannelId = 'default_channel';
const String reminderNotificationChannelId = 'reminder_channel';
const String voiceNotificationChannelId = 'voice_command_channel';
const String premiumNotificationChannelId = 'premium_updates_channel';
const String backupNotificationChannelId = 'backup_status_channel';

// Notification Importance Levels
enum NotificationImportance {
  none,
  min,
  low,
  default,
  high,
  max
}
```

## 4. Task Status & Priorities
```dart
enum TaskStatus {
  pending,
  inProgress,
  completed,
  overdue,
  cancelled,
  recurring
}

enum TaskPriority {
  none,
  low,
  medium,
  high
}
```

## 5. Voice Command System

### Command Keywords
```dart
// Task operation verbs
const List<String> taskVerbs = [
  'add', 'create', 'new', 'make', 'set',
  'complete', 'finish', 'done', 'mark',
  'delete', 'remove', 'cancel',
  'update', 'change', 'modify', 'set',
  'schedule', 'plan', 'organize', 'arrange'
];

// Task object nouns
const List<String> taskNouns = [
  'task', 'reminder', 'todo', 'item', 'homework', 'assignment',
  'meeting', 'appointment', 'event', 'chore', 'errand'
];

// Time-based keywords
const List<String> timeKeywords = [
  'today', 'tomorrow', 'tonight', 'morning', 'afternoon', 'evening',
  'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  'next week', 'this week', 'next month', 'in an hour', 'in a day'
];

// Wake word configuration
const String wakeWord = 'hey whisp';
const double wakeWordConfidenceThreshold = 0.85;

// Voice command confidence thresholds
const Map<String, double> confidenceThresholds = {
  'task_creation': 0.7,
  'task_update': 0.65,
  'task_deletion': 0.75,
  'general_query': 0.6
};
```

## 6. In-App Purchases (RevenueCat)

### Product Identifiers
```dart
const Map<String, String> productIdentifiers = {
  'premium_monthly': 'com.whisptask.premium.monthly',
  'premium_yearly': 'com.whisptask.premium.yearly',
  'premium_lifetime': 'com.whisptask.premium.lifetime',
};

// Entitlements
const String premiumEntitlement = 'premium';
const String cloudBackupEntitlement = 'cloud_backup';
const String advancedVoiceEntitlement = 'advanced_voice';

// Trial Periods (in days)
const Map<String, int> trialPeriods = {
  'monthly': 7,
  'yearly': 14,
  'lifetime': 0
};
```

## 7. Testing & Debugging Configuration

### Test Environment Settings
```dart
// Test Database Configuration
const String testFirebaseProjectId = 'whisptask-test';
const String testFirestoreEmulatorHost = 'localhost:8080';
const String testAuthEmulatorHost = 'localhost:9099';
const String testStorageEmulatorHost = 'localhost:9199';

// Mock Data Configuration
const Map<String, dynamic> mockUserData = {
  'userId': 'test_user_123',
  'email': 'test@whisptask.com',
  'displayName': 'Test User',
  'isPremium': false,
  'language': 'en',
};

const List<Map<String, dynamic>> mockTasks = [
  {
    'id': 'task_1',
    'title': 'Test Task 1',
    'description': 'This is a test task',
    'isCompleted': false,
    'priority': 'medium',
    'category': 'work',
  },
  {
    'id': 'task_2',
    'title': 'Test Task 2',
    'description': 'Another test task',
    'isCompleted': true,
    'priority': 'high',
    'category': 'personal',
  },
];
```

### Debug Screen Configuration
```dart
// Debug Feature Flags
const Map<String, bool> debugFeatures = {
  'show_debug_info': true,
  'enable_test_commands': true,
  'mock_voice_recognition': false,
  'simulate_premium': false,
  'force_crash_reporting': false,
  'verbose_logging': true,
};

// Test Voice Commands
const List<String> testVoiceCommands = [
  'Hey Whisp, add task buy groceries',
  'Hey Whisp, mark homework as done',
  'Hey Whisp, show me today\'s tasks',
  'Hey Whisp, set reminder for meeting at 3 PM',
  'Hey Whisp, delete completed tasks',
];

// Performance Monitoring
const Map<String, dynamic> performanceThresholds = {
  'app_launch_time_ms': 3000,
  'voice_recognition_delay_ms': 1000,
  'task_sync_time_ms': 2000,
  'ui_response_time_ms': 100,
  'memory_usage_mb': 150,
};
```

### Error Tracking Configuration
```dart
// Sentry Configuration
const String sentryDsn = 'YOUR_SENTRY_DSN';
const String sentryEnvironment = 'production'; // or 'development', 'staging'
const double sentrySampleRate = 1.0;

// Error Categories
enum ErrorCategory {
  authentication,
  voice_processing,
  task_management,
  network,
  ui,
  performance,
  premium_features,
}

// Log Levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}
```

## 8. Performance & Optimization Configuration

### Memory Management
```dart
const Map<String, int> memoryLimits = {
  'maxTasksInMemory': 1000,
  'maxVoiceHistoryItems': 100,
  'maxTaskHistoryItems': 200,
  'cacheExpirationDays': 7,
};

// Image Processing
const Map<String, dynamic> imageConfig = {
  'maxWidth': 1200,
  'maxHeight': 1200,
  'quality': 80,
  'format': 'jpeg',
  'maxFileSizeMB': 5,
};

// Voice Processing
const Map<String, dynamic> voiceConfig = {
  'maxRecordingDuration': 300, // seconds
  'sampleRate': 16000,
  'bitRate': 128000,
  'noiseReduction': true,
  'echoCancellation': true,
};
```

### App Launch Optimization
```dart
// Startup Configuration
const Map<String, dynamic> startupConfig = {
  'parallel_service_init': true,
  'lazy_provider_loading': true,
  'background_service_delay_ms': 1000,
  'cache_preload_enabled': true,
  'splash_screen_min_duration_ms': 1500,
};

// Background Processing
const Map<String, dynamic> backgroundConfig = {
  'sync_interval_minutes': 15,
  'battery_optimization_enabled': true,
  'background_voice_processing': false,
  'offline_mode_enabled': true,
};
```

## 9. Security & Privacy Configuration

### Authentication Security
```dart
// Biometric Authentication
const Map<String, dynamic> biometricSettings = {
  'enabled_by_default': false,
  'supported_types': ['fingerprint', 'face', 'iris'],
  'fallback_to_pin': true,
  'max_failed_attempts': 3,
  'lockout_duration_minutes': 5,
};

// Session Management
const Map<String, dynamic> sessionConfig = {
  'token_expiry_hours': 24,
  'refresh_token_expiry_days': 30,
  'auto_logout_inactive_hours': 8,
  'concurrent_sessions_limit': 3,
};
```

### Data Encryption
```dart
// Encryption Configuration
const Map<String, String> encryptionSettings = {
  'algorithm': 'AES-256-GCM',
  'key_derivation': 'PBKDF2',
  'salt_length': '32',
  'iteration_count': '100000',
};

// Data Classification
enum DataSensitivity {
  public,
  internal,
  confidential,
  restricted,
}

const Map<String, DataSensitivity> dataClassification = {
  'user_email': DataSensitivity.confidential,
  'task_content': DataSensitivity.confidential,
  'voice_recordings': DataSensitivity.restricted,
  'usage_analytics': DataSensitivity.internal,
  'crash_reports': DataSensitivity.internal,
};
```

### Privacy Controls
```dart
// Privacy Settings
const Map<String, dynamic> privacyDefaults = {
  'analytics_enabled': true,
  'crash_reports_enabled': true,
  'marketing_emails_enabled': false,
  'voice_data_processing_enabled': true,
  'location_services_enabled': false,
  'contact_sync_enabled': false,
};

// Data Retention Policies
const Map<String, int> dataRetentionDays = {
  'completed_tasks': 365,
  'voice_command_history': 90,
  'error_logs': 30,
  'analytics_data': 730,
  'deleted_user_data': 30,
};

// GDPR Compliance
const Map<String, bool> gdprSettings = {
  'right_to_access': true,
  'right_to_rectification': true,
  'right_to_erasure': true,
  'right_to_portability': true,
  'right_to_object': true,
};
```

## 10. Cross-Platform Compatibility Settings

### Platform-Specific Features
```dart
// iOS Specific
const Map<String, dynamic> iosConfig = {
  'app_store_id': '1234567890',
  'bundle_identifier': 'com.example.whisptask',
  'minimum_ios_version': '12.0',
  'supports_siri_shortcuts': true,
  'supports_widgets': true,
  'supports_app_clips': false,
};

// Android Specific
const Map<String, dynamic> androidConfig = {
  'package_name': 'com.example.whisptask',
  'minimum_sdk_version': 21,
  'target_sdk_version': 34,
  'supports_widgets': true,
  'supports_shortcuts': true,
  'supports_adaptive_icons': true,
};

// Web Specific
const Map<String, dynamic> webConfig = {
  'pwa_enabled': true,
  'offline_support': true,
  'web_push_notifications': true,
  'service_worker_enabled': true,
  'manifest_theme_color': '#2196F3',
};

// Desktop Specific
const Map<String, dynamic> desktopConfig = {
  'windows_support': true,
  'macos_support': true,
  'linux_support': true,
  'system_tray_integration': true,
  'global_hotkeys': true,
};
```

### Device Capabilities
```dart
// Required Permissions
const List<String> requiredPermissions = [
  'microphone',
  'notifications',
  'storage',
];

const List<String> optionalPermissions = [
  'camera',
  'location',
  'contacts',
  'calendar',
  'biometric',
];

// Hardware Requirements
const Map<String, dynamic> hardwareRequirements = {
  'minimum_ram_mb': 1024,
  'minimum_storage_mb': 100,
  'microphone_required': true,
  'speaker_required': true,
  'network_required': true,
};
```

## 12. API Endpoints
```dart
const String baseUrl = 'https://api.whisptask.com/v2';

class ApiEndpoints {
  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  
  // Tasks
  static const String tasks = '/tasks';
  static const String bulkTasks = '/tasks/bulk';
  
  // User
  static const String userProfile = '/user/profile';
  static const String userPreferences = '/user/preferences';
  
  // Voice
  static const String voiceProcess = '/voice/process';
  static const String voiceHistory = '/voice/history';
  
  // Premium Features
  static const String backup = '/premium/backup';
  static const String restore = '/premium/restore';
  static const String subscriptionStatus = '/premium/status';
}
```

## 14. Error Codes
```dart
class ErrorCodes {
  // Authentication Errors (100-199)
  static const int invalidCredentials = 101;
  static const int emailAlreadyInUse = 102;
  static const int weakPassword = 103;
  static const int userDisabled = 104;
  static const int tooManyRequests = 105;
  
  // Task Errors (200-299)
  static const int taskNotFound = 201;
  static const int invalidTaskData = 202;
  static const int taskLimitReached = 203;
  
  // Voice Command Errors (300-399)
  static const int voiceCommandNotUnderstood = 301;
  static const int invalidCommandFormat = 302;
  static const int speechRecognitionTimeout = 303;
  static const int speechRecognitionError = 304;
  
  // Premium Feature Errors (400-499)
  static const int premiumFeatureRequired = 401;
  static const int subscriptionExpired = 402;
  static const int paymentRequired = 403;
  
  // Network & Server Errors (500-599)
  static const int serverError = 500;
  static const int maintenanceMode = 503;
  static const int apiRateLimitExceeded = 529;
}
```

## 9. Voice Command Patterns
```dart
// Supported command patterns with enhanced matching
const List<Map<String, dynamic>> commandPatterns = [
  {
    'intent': 'create_task',
    'patterns': [
      r'(?:add|create|new|make)\s+(?:a\s+)?(?:task|reminder|todo)?\s*(?:called|named|for)?\s*[\'"](.*?)[\'"]',
      r'(?:remind me to|i need to|don\'t forget to)\s+([^\.,!?]+)',
    ],
    'confidence': 0.8
  },
  {
    'intent': 'complete_task',
    'patterns': [
      r'(?:complete|finish|mark|done)\s+(?:task|item)?\s*(?:[\'"](.*?)[\'"])',
      r'(?:i\'ve finished|i completed|i\'m done with)\s+([^\.,!?]+)',
    ],
    'confidence': 0.75
  },
  // Additional patterns...
];

// Fuzzy matching configuration
const Map<String, dynamic> fuzzyMatchingConfig = {
  'minSimilarityScore': 0.6,
  'maxCandidates': 10,
  'titleWeight': 0.7,
  'descriptionWeight': 0.25,
  'tagsWeight': 0.05,
  'useFuzzyMatching': true,
  'enablePartialMatching': true,
  'maxEditDistance': 2,
  'prefixWeight': 0.3,
  'suffixWeight': 0.1,
  'consecutiveWeight': 0.6
};
```

## 10. Performance Configuration

### Memory Management
```dart
const Map<String, int> memoryLimits = {
  'maxTasksInMemory': 1000,
  'maxVoiceHistoryItems': 100,
  'maxTaskHistoryItems': 200,
  'cacheExpirationDays': 7,
};

// Image Processing
const Map<String, dynamic> imageConfig = {
  'maxWidth': 1200,
  'maxHeight': 1200,
  'quality': 80,
  'format': 'jpeg',
  'maxFileSizeMB': 5,
};

// Voice Processing
const Map<String, dynamic> voiceConfig = {
  'maxRecordingDuration': 300, // seconds
  'sampleRate': 16000,
  'bitRate': 128000,
  'noiseReduction': true,
  'echoCancellation': true,
};
```

## 11. Analytics Events
```dart
class AnalyticsEvents {
  // Authentication
  static const String login = 'login';
  static const String signup = 'signup';
  static const String logout = 'logout';
  
  // Task Management
  static const String taskCreated = 'task_created';
  static const String taskCompleted = 'task_completed';
  static const String taskDeleted = 'task_deleted';
  
  // Voice Commands
  static const String voiceCommand = 'voice_command';
  static const String wakeWordDetected = 'wake_word_detected';
  static const String commandRecognized = 'command_recognized';
  
  // Premium Features
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionRenewed = 'subscription_renewed';
  static const String subscriptionCancelled = 'subscription_cancelled';
  
  // Error Tracking
  static const String error = 'error_occurred';
  static const String voiceRecognitionError = 'voice_recognition_error';
  static const String syncError = 'sync_error';
}
```

## 13. Version History

### v2.5.0 (Current - December 2024)
- **Multilingual Support**: Added full support for English, Hindi, and Kannada
- **Language Settings**: Implemented dedicated language selection screen with real-time switching
- **Voice Command Multilingual**: Extended voice commands to support all three languages
- **Performance Optimization**: Reduced app launch time by 60-70% (from 6-8s to 2-3s)
- **Critical Bug Fixes**: Resolved 10 major release-blocking issues
- **Debug Screen**: Added comprehensive manual testing interface
- **Package Name Fix**: Updated from "whispnask" to "whisptask" across all platforms
- **Sentry Integration**: Fixed 403 ProjectId mismatch errors

### v2.4.0 (November 2024)
- **Voice Command Enhancements**: Improved fuzzy matching and task identification
- **Error Recovery**: Added exponential backoff for speech recognition stability
- **Task Matching**: Enhanced natural language processing for better command understanding
- **Duplicate Prevention**: Smart detection to prevent creating similar tasks
- **Time-based Commands**: Added support for "homework tomorrow" style updates

### v2.3.0 (October 2024)
- **Premium Features**: Complete RevenueCat integration with subscription tiers
- **Ad Integration**: AdMob implementation for free tier users
- **Advanced Voice**: Premium-only advanced voice command features
- **Cloud Backup**: Automatic backup for premium subscribers
- **Custom Themes**: Premium theme customization options

### v2.2.0 (September 2024)
- **Cross-Platform Support**: Full deployment for iOS, Android, Web, and Desktop
- **Widget Support**: Home screen widgets for quick task access
- **Notification Enhancements**: Custom sounds and advanced scheduling
- **Calendar Integration**: Premium calendar view and synchronization
- **Productivity Analytics**: Usage tracking and productivity insights

### v2.1.0 (August 2024)
- **Wake Word Detection**: "Hey Whisp" activation system
- **Voice Notes**: Audio recording and transcription for tasks
- **File Attachments**: Support for task-related file uploads
- **Recurring Tasks**: Advanced recurring task patterns
- **Batch Operations**: Bulk task management capabilities

### v2.0.0 (July 2024)
- **Complete Voice Overhaul**: New speech-to-text engine integration
- **Fuzzy Task Matching**: Intelligent task identification system
- **Natural Language**: Enhanced command understanding
- **Error Handling**: Comprehensive error recovery and user feedback
- **Firebase Integration**: Complete backend migration to Firebase

### v1.5.0 (June 2024)
- **Task Categories**: Organizational system with color coding
- **Advanced Search**: Full-text search across tasks and notes
- **Notification System**: Multi-channel notification management
- **User Profiles**: Account management and preferences
- **Performance**: Memory optimization and faster sync

### v1.0.0 (May 2024)
- **Initial Release**: Core task management functionality
- **Basic Voice Commands**: Simple voice-to-task conversion
- **Firebase Auth**: User authentication and data sync
- **Cross-Platform**: Flutter-based multi-platform support
- **Offline Mode**: Local storage and sync capabilities
