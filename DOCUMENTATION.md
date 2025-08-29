# Whisp Task Manager - Complete Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Directory Structure](#directory-structure)
3. [Core Components](#core-components)
4. [Features](#features)
5. [Development Guide](#development-guide)
6. [Testing](#testing)
7. [Building for Production](#building-for-production)
8. [Architecture Overview](#architecture-overview)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)
11. [License](#license)

## Project Overview
A Flutter-based task management application with voice control capabilities, user authentication, and real-time notifications.

## Directory Structure

### 1. Core Application
- `main.dart` - Application entry point, initializes providers and runs the app
- `lib/`
  - `models/`
    - `task.dart` - Task data model and related enums
    - `user_model.dart` - User data model and authentication state
  - `providers/`
    - `auth_provider.dart` - Manages user authentication state
    - `task_provider.dart` - Manages task state and business logic
    - `voice_provider.dart` - Handles voice command processing
  - `screens/`
    - `account_settings_screen.dart` - User account management
    - `add_task_screen.dart` - Task creation and editing
    - `change_password_screen.dart` - Password update functionality
    - `login_screen.dart` - User authentication
    - `profile_screen.dart` - User profile management
    - `signup_screen.dart` - New user registration
    - `splash_screen.dart` - Initial loading screen
    - `task_list_screen.dart` - Displays and manages user's tasks
    - `voice_input_screen.dart` - Screen for voice input and commands
  - `services/`
    - `auth_service.dart` - Handles user authentication and account management
    - `file_attachment_service.dart` - Manages file attachments for tasks
    - `notification_service.dart` - Handles local notifications
    - `task_service.dart` - Manages task-related operations and data
    - `voice_notes_service.dart` - Handles voice recording and management
    - `voice_parser.dart` - Processes and interprets voice commands
    - `voice_service.dart` - Core voice interaction service
    - `transcription_service.dart` - Handles speech-to-text conversion
  - `utils/`
    - `notification_helper.dart` - Helper methods for notifications
    - `validators.dart` - Input validation utilities
    - `voice_test_runner.dart` - Testing utilities for voice features
    - `responsive_helper.dart` - Responsive layout utilities
  - `widgets/`
    - `auth_text_field.dart` - Custom text field for auth forms
    - `auth_wrapper.dart` - Handles auth state and routing
    - `file_attachments_widget.dart` - Displays and manages file attachments
    - `filter_dialog.dart` - Task filtering and sorting UI
    - `notification_test_widget.dart` - Notification testing UI
    - `password_strength_indicator.dart` - Visual password strength meter
    - `task_calendar.dart` - Calendar view for tasks
    - `task_card.dart` - Reusable task item component
    - `user_avatar.dart` - Displays user profile picture or initials
    - `voice_notes_widget.dart` - UI for recording and managing voice notes

### 2. Platform-Specific Code
- `android/` - Android platform configuration
- `ios/` - iOS platform configuration
- `web/` - Web platform configuration
- `windows/` - Windows desktop configuration
- `macos/` - macOS desktop configuration
- `linux/` - Linux desktop configuration

### 3. Assets
- `assets/`
  - `images/` - App icons and images
    - `app_icon.png` - Application icon
    - `logo.png` - Application logo
    - `placeholder_task.png` - Placeholder image for tasks
  - `sounds/` - Notification sounds
    - `bell.mp3` - Notification sound
    - `buzz.mp3` - Alert sound
    - `chime.mp3` - Success sound

## Core Components

### State Management
The app uses Provider pattern for state management with several providers:
- `AuthProvider`: Manages user authentication state
- `TaskProvider`: Handles task-related state and operations
- `VoiceProvider`: Manages voice command processing

### Features
- **User Authentication**: Email/password sign-in and registration
- **Task Management**: Create, read, update, and delete tasks
- **Voice Notes**: Record and attach voice memos to tasks
- **File Attachments**: Attach files to tasks
- **Voice Commands**: Control the app using voice
- **Notifications**: Local notifications for task reminders
- **Calendar View**: Visualize tasks on a calendar
- **Responsive Design**: Works on mobile and desktop

## Development Guide

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK (as required by Flutter version)
- Android Studio / Xcode (for mobile development)
- VS Code (recommended IDE)

### Setup Instructions
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase (see Firebase Setup section)
4. Run the app using `flutter run`

### Firebase Setup
1. Create a new Firebase project
2. Add Android and iOS apps to the Firebase project
3. Download and add the configuration files:
   - Android: `google-services.json` to `android/app/`
   - iOS: `GoogleService-Info.plist` to `ios/Runner/`
4. Enable Email/Password authentication in Firebase Console
5. Set up Firestore database with appropriate security rules

## Testing

### Unit Tests
Run unit tests using:
```bash
flutter test
```

### Widget Tests
Run widget tests using:
```bash
flutter test test/widget_test.dart
```

### Integration Tests
Run integration tests using:
```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# Open Xcode and archive the app
```

### Web
```bash
flutter build web --release
```

## Architecture Overview

The app follows the MVVM (Model-View-ViewModel) architecture pattern with Provider for state management. Key architectural components include:

- **Models**: Data models representing app entities
- **Providers**: State management and business logic
- **Services**: Reusable services for common functionality
- **Screens**: UI components organized by feature
- **Widgets**: Reusable UI components

## Troubleshooting

### Common Issues

1. **Firebase Not Initialized**
   - Ensure Firebase configuration files are in place
   - Verify Firebase initialization in `main.dart`

2. **Voice Commands Not Working**
   - Check microphone permissions
   - Verify internet connection for speech recognition

3. **Build Failures**
   - Run `flutter clean` and `flutter pub get`
   - Ensure all dependencies are compatible

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
