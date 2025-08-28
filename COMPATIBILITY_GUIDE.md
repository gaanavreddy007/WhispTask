# Whisp Task Manager - Compatibility Guide

## 1. Firebase Configuration

### Authentication Providers
- **Email/Password**: `password`
- **Google Sign-In**: `google.com`
- **Apple Sign-In**: `apple.com`

### Firestore Collections
```dart
const String usersCollection = 'users';
const String tasksCollection = 'tasks';
const String userPreferencesCollection = 'user_preferences';
```

### Storage Bucket Paths
- Profile Pictures: `profile_pictures/{userId}.jpg`
- Task Attachments: `task_attachments/{taskId}/{filename}`

## 2. SharedPreferences Keys
```dart
// Authentication
const String authTokenKey = 'auth_token';
const String userIdKey = 'user_id';
const String userEmailKey = 'user_email';

// App Settings
const String themeModeKey = 'theme_mode';
const String notificationEnabledKey = 'notifications_enabled';
const String voiceCommandEnabledKey = 'voice_command_enabled';
```

## 3. Notification Channels
```dart
const String defaultNotificationChannelId = 'default_channel';
const String reminderNotificationChannelId = 'reminder_channel';
const String voiceNotificationChannelId = 'voice_command_channel';
```

## 4. Task Status Values
```dart
enum TaskStatus {
  pending,
  inProgress,
  completed,
  overdue,
  cancelled
}
```

## 5. Voice Command Keywords
```dart
const List<String> taskVerbs = [
  'add', 'create', 'new', 'make', 'set',
  'complete', 'finish', 'done',
  'delete', 'remove', 'cancel',
  'update', 'change', 'modify'
];

const List<String> taskNouns = [
  'task', 'reminder', 'todo', 'item'
];

const Map<String, TaskPriority> priorityMap = {
  'low': TaskPriority.low,
  'medium': TaskPriority.medium,
  'high': TaskPriority.high,
  'urgent': TaskPriority.high
};
```

## 6. API Endpoints
```dart
const String baseUrl = 'https://api.whisptask.com/v1';

class ApiEndpoints {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String tasks = '/tasks';
  static const String userProfile = '/user/profile';
  static const String voiceProcess = '/voice/process';
}
```

## 7. Widget Keys
```dart
// Main App
const String appTitleKey = 'app_title';

// Auth Screens
const String emailFieldKey = 'email_field';
const String passwordFieldKey = 'password_field';
const String loginButtonKey = 'login_button';
const String signupButtonKey = 'signup_button';

// Task Screens
const String taskListKey = 'task_list';
const String addTaskFABKey = 'add_task_fab';
const String taskItemKey = 'task_item_';
```

## 8. Error Codes
```dart
class ErrorCodes {
  // Authentication Errors (100-199)
  static const int invalidCredentials = 101;
  static const int emailAlreadyInUse = 102;
  static const int weakPassword = 103;
  static const int userDisabled = 104;
  
  // Task Errors (200-299)
  static const int taskNotFound = 201;
  static const int invalidTaskData = 202;
  
  // Voice Command Errors (300-399)
  static const int voiceCommandNotUnderstood = 301;
  static const int invalidCommandFormat = 302;
}
```

## 9. Important File Paths
```dart
// Assets
const String appLogoPath = 'assets/images/logo.png';
const String defaultProfilePicPath = 'assets/images/default_profile.png';

// Sound Files
const String notificationSoundPath = 'assets/sounds/notification.mp3';
const String errorSoundPath = 'assets/sounds/error.mp3';
```

## 10. Version Information
```yaml
# Minimum Requirements
minSdkVersion: 21
targetSdkVersion: 33
compileSdkVersion: 33

# Dependencies
flutter_version: '>=3.0.0 <4.0.0'
provider: ^6.0.5
firebase_core: ^2.13.1
firebase_auth: ^4.6.2
cloud_firestore: ^4.7.1
```

## Usage Guidelines
1. Always use these constants instead of hardcoded values
2. When adding new features, add new constants to the appropriate section
3. Update this document when making changes to any core identifiers
4. Follow the same naming conventions for new additions

## Version History
- v1.0.0: Initial release
- v1.0.1: Added voice command support
- v1.1.0: Added task categories and filtering
