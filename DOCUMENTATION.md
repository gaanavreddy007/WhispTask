# Whisp Task Manager - Complete Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Directory Structure](#directory-structure)
3. [Core Components](#core-components)
4. [Screens](#screens)
5. [Services](#services)
6. [Utilities](#utilities)
7. [Widgets](#widgets)
8. [Development Guide](#development-guide)

## Project Overview
A Flutter-based task management application with voice control capabilities, user authentication, and real-time notifications.

## Directory Structure

### 1. Core Application
- `main.dart` - Application entry point, initializes providers and runs the app

### 2. Models
- `models/task.dart` - Task data model with properties like title, description, due date, status, etc.
- `models/user_model.dart` - User data model containing user information and authentication details

### 3. Providers (State Management)
- `providers/auth_provider.dart` - Manages authentication state and user session
- `providers/task_provider.dart` - Handles task-related state and operations
- `providers/voice_provider.dart` - Manages voice command processing and state

### 4. Screens
- `screens/account_settings_screen.dart` - User account management and settings
- `screens/add_task_screen.dart` - Interface for creating new tasks
- `screens/login_screen.dart` - User authentication screen
- `screens/profile_screen.dart` - Displays and manages user profile
- `screens/signup_screen.dart` - New user registration
- `screens/splash_screen.dart` - Initial loading screen with app branding
- `screens/task_list_screen.dart` - Main screen displaying user's task list
- `screens/voice_input_screen.dart` - Interface for voice command input

### 5. Services
- `services/auth_service.dart` - Handles authentication with backend
- `services/notification_service.dart` - Manages local and push notifications
- `services/task_service.dart` - API calls and operations for tasks
- `services/voice_parser.dart` - Processes and interprets voice commands
- `services/voice_service.dart` - Handles voice recognition functionality

### 6. Utils
- `utils/notification_helper.dart` - Helper functions for notification handling
- `utils/validators.dart` - Input validation utilities
- `utils/voice_test_runner.dart` - Testing utilities for voice features

### 7. Widgets
- `widgets/auth_text_field.dart` - Custom text field for authentication forms
- `widgets/auth_wrapper.dart` - Handles authentication state and routing
- `widgets/notification_test_widget.dart` - Widget for testing notifications
- `widgets/password_strength_indicator.dart` - Visual indicator for password strength
- `widgets/task_card.dart` - Reusable task item widget
- `widgets/user_avatar.dart` - Displays user profile picture or initials

## Core Components

### State Management
The app uses Provider pattern for state management with three main providers:
1. **AuthProvider**: Manages user authentication state
2. **TaskProvider**: Handles all task-related state
3. **VoiceProvider**: Manages voice command processing

### Data Flow
1. **UI Layer**: Screens and Widgets
2. **State Management**: Providers
3. **Services**: API and business logic
4. **Models**: Data structures

## Development Guide

### Adding a New Feature
1. **Create a new screen** in `lib/screens/`
2. **Add necessary providers** in `lib/providers/`
3. **Create services** in `lib/services/` for business logic
4. **Add models** in `lib/models/` for data structures
5. **Create reusable widgets** in `lib/widgets/`

### Code Organization
- Keep business logic in services
- Use providers for state management
- Keep UI components in widgets
- Group related features together

### Testing
- Unit tests: `test/`
- Widget tests: `test/widgets/`
- Integration tests: `test_driver/`

## Dependencies
- Flutter SDK
- Provider (state management)
- Firebase (authentication, database)
- Speech to Text (voice commands)
- Local Notifications
- Shared Preferences

## Getting Started
1. Clone the repository
2. Run `flutter pub get`
3. Set up Firebase configuration
4. Run `flutter run`

## Architecture Diagram
```
┌───────────────────────┐     ┌───────────────────────┐
│                       │     │                       │
│      UI Layer         │◄───►│    Providers         │
│   (Screens/Widgets)   │     │   (State Management) │
│                       │     │                       │
└───────────┬───────────┘     └───────────┬───────────┘
            │                             │
            ▼                             ▼
┌───────────────────────┐     ┌───────────────────────┐
│                       │     │                       │
│      Services         │◄────┤      Models          │
│ (Business Logic/APIs) │     │   (Data Structures)  │
│                       │     │                       │
└───────────────────────┘     └───────────────────────┘
```

## Common Patterns
1. **Dependency Injection**: Used throughout the app for better testability
2. **Repository Pattern**: For data layer abstraction
3. **Observer Pattern**: Used in state management
4. **Factory Pattern**: For creating complex objects

## Best Practices
1. Follow Flutter's official style guide
2. Write meaningful comments and documentation
3. Keep widget trees shallow
4. Use const constructors where possible
5. Handle errors gracefully
6. Write tests for critical functionality

## Troubleshooting
- **Voice not working**: Check microphone permissions
- **Authentication issues**: Verify Firebase configuration
- **UI not updating**: Ensure `notifyListeners()` is called after state changes
- **Build errors**: Run `flutter clean` and `flutter pub get`
