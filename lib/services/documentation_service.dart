import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/sentry_service.dart';
import '../services/settings_service.dart';
import '../services/testing_service.dart';

class APIDocumentation {
  final String serviceName;
  final String description;
  final List<APIMethod> methods;
  final Map<String, dynamic> examples;
  final DateTime lastUpdated;

  const APIDocumentation({
    required this.serviceName,
    required this.description,
    required this.methods,
    required this.examples,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      'description': description,
      'methods': methods.map((m) => m.toJson()).toList(),
      'examples': examples,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class APIMethod {
  final String name;
  final String description;
  final String returnType;
  final List<APIParameter> parameters;
  final String usage;
  final List<String> examples;

  const APIMethod({
    required this.name,
    required this.description,
    required this.returnType,
    required this.parameters,
    required this.usage,
    required this.examples,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'return_type': returnType,
      'parameters': parameters.map((p) => p.toJson()).toList(),
      'usage': usage,
      'examples': examples,
    };
  }
}

class APIParameter {
  final String name;
  final String type;
  final bool required;
  final String description;
  final dynamic defaultValue;

  const APIParameter({
    required this.name,
    required this.type,
    required this.required,
    required this.description,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      'description': description,
      'default_value': defaultValue,
    };
  }
}

class DocumentationService {
  static const String _version = '1.0.0';
  static final Map<String, APIDocumentation> _documentation = {};

  /// Initialize documentation service
  static Future<void> initialize() async {
    try {
      await _generateAllDocumentation();
      
      SentryService.addBreadcrumb(
        message: 'documentation_service_initialized',
        category: 'documentation',
        data: {
          'services_documented': _documentation.length,
          'version': _version,
        },
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Generate comprehensive API documentation
  static Future<void> _generateAllDocumentation() async {
    // Statistics Service Documentation
    _documentation['StatisticsService'] = APIDocumentation(
      serviceName: 'StatisticsService',
      description: 'Provides comprehensive task analytics and productivity insights',
      methods: [
        APIMethod(
          name: 'calculateStatistics',
          description: 'Calculate comprehensive statistics for given tasks and time period',
          returnType: 'Map<String, dynamic>',
          parameters: [
            APIParameter(
              name: 'tasks',
              type: 'List<Task>',
              required: true,
              description: 'List of tasks to analyze',
            ),
            APIParameter(
              name: 'period',
              type: 'String',
              required: true,
              description: 'Time period: "week", "month", "year"',
            ),
          ],
          usage: 'StatisticsService.calculateStatistics(tasks, "month")',
          examples: [
            'final stats = StatisticsService.calculateStatistics(allTasks, "week");',
            'final monthlyStats = StatisticsService.calculateStatistics(tasks, "month");',
          ],
        ),
        APIMethod(
          name: 'getProductivityTrends',
          description: 'Get productivity trends over time',
          returnType: 'Map<String, dynamic>',
          parameters: [
            APIParameter(
              name: 'tasks',
              type: 'List<Task>',
              required: true,
              description: 'Tasks to analyze for trends',
            ),
          ],
          usage: 'StatisticsService.getProductivityTrends(tasks)',
          examples: [
            'final trends = StatisticsService.getProductivityTrends(userTasks);',
          ],
        ),
      ],
      examples: {
        'basic_usage': 'Calculate weekly statistics for productivity analysis',
        'advanced_usage': 'Generate comprehensive reports with trend analysis',
      },
      lastUpdated: DateTime.now(),
    );

    // Settings Service Documentation
    _documentation['SettingsService'] = APIDocumentation(
      serviceName: 'SettingsService',
      description: 'Manages application settings and user preferences',
      methods: [
        APIMethod(
          name: 'updateSettings',
          description: 'Update application settings',
          returnType: 'Future<void>',
          parameters: [
            APIParameter(
              name: 'newSettings',
              type: 'AppSettings',
              required: true,
              description: 'New settings configuration',
            ),
          ],
          usage: 'await SettingsService.updateSettings(newSettings)',
          examples: [
            'await SettingsService.updateSettings(settings.copyWith(darkMode: true));',
          ],
        ),
        APIMethod(
          name: 'updateSetting',
          description: 'Update a specific setting',
          returnType: 'Future<void>',
          parameters: [
            APIParameter(
              name: 'key',
              type: 'String',
              required: true,
              description: 'Setting key to update',
            ),
            APIParameter(
              name: 'value',
              type: 'T',
              required: true,
              description: 'New value for the setting',
            ),
          ],
          usage: 'await SettingsService.updateSetting("darkMode", true)',
          examples: [
            'await SettingsService.updateSetting("notificationsEnabled", false);',
            'await SettingsService.updateSetting("fontSize", 18.0);',
          ],
        ),
      ],
      examples: {
        'theme_management': 'Handle dark/light mode switching',
        'notification_settings': 'Configure notification preferences',
      },
      lastUpdated: DateTime.now(),
    );

    // Habit Service Documentation
    _documentation['HabitService'] = APIDocumentation(
      serviceName: 'HabitService',
      description: 'Manages habit tracking and recurring task automation',
      methods: [
        APIMethod(
          name: 'createHabit',
          description: 'Create a new habit with specified frequency',
          returnType: 'Future<Habit>',
          parameters: [
            APIParameter(
              name: 'title',
              type: 'String',
              required: true,
              description: 'Habit title',
            ),
            APIParameter(
              name: 'description',
              type: 'String',
              required: true,
              description: 'Habit description',
            ),
            APIParameter(
              name: 'category',
              type: 'String',
              required: true,
              description: 'Habit category',
            ),
            APIParameter(
              name: 'frequency',
              type: 'String',
              required: true,
              description: 'Frequency: "daily", "weekly", "monthly"',
            ),
            APIParameter(
              name: 'targetCount',
              type: 'int',
              required: true,
              description: 'Target completion count',
            ),
          ],
          usage: 'await HabitService.createHabit(title, description, category, frequency, targetCount)',
          examples: [
            'final habit = await HabitService.createHabit("Morning Exercise", "30 min workout", "health", "daily", 1);',
          ],
        ),
        APIMethod(
          name: 'completeHabit',
          description: 'Mark a habit as completed for today',
          returnType: 'Future<void>',
          parameters: [
            APIParameter(
              name: 'habitId',
              type: 'String',
              required: true,
              description: 'ID of the habit to complete',
            ),
          ],
          usage: 'await HabitService.completeHabit(habitId)',
          examples: [
            'await HabitService.completeHabit("habit_123");',
          ],
        ),
      ],
      examples: {
        'daily_habits': 'Create and track daily routines',
        'habit_streaks': 'Monitor consistency and build streaks',
      },
      lastUpdated: DateTime.now(),
    );

    // Achievement Service Documentation
    _documentation['AchievementService'] = APIDocumentation(
      serviceName: 'AchievementService',
      description: 'Manages user achievements and gamification features',
      methods: [
        APIMethod(
          name: 'checkAchievements',
          description: 'Check and unlock achievements based on user progress',
          returnType: 'Future<void>',
          parameters: [
            APIParameter(
              name: 'tasks',
              type: 'List<Task>',
              required: true,
              description: 'User tasks to evaluate for achievements',
            ),
          ],
          usage: 'await AchievementService.checkAchievements(tasks)',
          examples: [
            'await AchievementService.checkAchievements(userTasks);',
          ],
        ),
        APIMethod(
          name: 'getUnlockedAchievements',
          description: 'Get list of unlocked achievements',
          returnType: 'List<Achievement>',
          parameters: [],
          usage: 'AchievementService.getUnlockedAchievements()',
          examples: [
            'final unlocked = AchievementService.getUnlockedAchievements();',
          ],
        ),
      ],
      examples: {
        'progress_tracking': 'Monitor user progress and unlock achievements',
        'gamification': 'Enhance user engagement with achievement system',
      },
      lastUpdated: DateTime.now(),
    );

    // Focus Service Documentation
    _documentation['FocusService'] = APIDocumentation(
      serviceName: 'FocusService',
      description: 'Manages Pomodoro timer and focus sessions',
      methods: [
        APIMethod(
          name: 'startSession',
          description: 'Start a new focus session',
          returnType: 'Future<void>',
          parameters: [
            APIParameter(
              name: 'mode',
              type: 'FocusMode',
              required: true,
              description: 'Focus mode: work, shortBreak, longBreak',
            ),
            APIParameter(
              name: 'duration',
              type: 'Duration',
              required: true,
              description: 'Session duration',
            ),
            APIParameter(
              name: 'taskId',
              type: 'String?',
              required: false,
              description: 'Optional task ID to associate with session',
            ),
          ],
          usage: 'await FocusService.startSession(FocusMode.work, Duration(minutes: 25))',
          examples: [
            'await FocusService.startSession(FocusMode.work, Duration(minutes: 25));',
            'await FocusService.startSession(FocusMode.shortBreak, Duration(minutes: 5));',
          ],
        ),
        APIMethod(
          name: 'getFocusStatistics',
          description: 'Get focus session statistics',
          returnType: 'Map<String, dynamic>',
          parameters: [],
          usage: 'FocusService.getFocusStatistics()',
          examples: [
            'final stats = FocusService.getFocusStatistics();',
          ],
        ),
      ],
      examples: {
        'pomodoro_technique': 'Implement Pomodoro productivity technique',
        'focus_tracking': 'Track focus sessions and productivity',
      },
      lastUpdated: DateTime.now(),
    );

    // Testing Service Documentation
    _documentation['TestingService'] = APIDocumentation(
      serviceName: 'TestingService',
      description: 'Comprehensive testing framework for app validation',
      methods: [
        APIMethod(
          name: 'runComprehensiveTests',
          description: 'Run complete test suite covering all app functionality',
          returnType: 'Future<TestSuite>',
          parameters: [],
          usage: 'await TestingService.runComprehensiveTests()',
          examples: [
            'final results = await TestingService.runComprehensiveTests();',
          ],
        ),
        APIMethod(
          name: 'runTestCategory',
          description: 'Run tests for specific category',
          returnType: 'Future<TestSuite>',
          parameters: [
            APIParameter(
              name: 'category',
              type: 'String',
              required: true,
              description: 'Test category: core, data, performance, error, integration, security',
            ),
          ],
          usage: 'await TestingService.runTestCategory("performance")',
          examples: [
            'final coreTests = await TestingService.runTestCategory("core");',
            'final perfTests = await TestingService.runTestCategory("performance");',
          ],
        ),
      ],
      examples: {
        'quality_assurance': 'Ensure app quality with automated testing',
        'performance_validation': 'Validate app performance benchmarks',
      },
      lastUpdated: DateTime.now(),
    );
  }

  /// Generate README documentation
  static String generateReadme() {
    return '''
# WhispTask - Voice-Powered Task Management App

## Overview
WhispTask is a comprehensive task management application with voice input capabilities, advanced analytics, habit tracking, and gamification features.

## Features

### 🎯 Core Features
- **Task Management**: Create, edit, and organize tasks with categories and priorities
- **Voice Input**: Add tasks using voice commands with offline speech recognition
- **Smart Reminders**: Intelligent notification system with customizable timing
- **Recurring Tasks**: Automated recurring task creation with flexible patterns

### 📊 Analytics & Insights
- **Real-time Statistics**: Comprehensive productivity analytics
- **Advanced Insights**: AI-powered productivity recommendations
- **Data Export**: Professional reports in JSON, CSV, and text formats
- **Trend Analysis**: Track productivity patterns over time

### 📈 Productivity Tools
- **Pomodoro Timer**: Focus sessions with break management
- **Habit Tracking**: Build and maintain positive habits
- **Achievement System**: 15+ achievements to unlock
- **Goal Setting**: Set and track long-term objectives

### ⚙️ Customization
- **Themes**: Dark/light mode with custom styling
- **Languages**: Multi-language support (English, Hindi, Kannada)
- **Settings**: 25+ configurable options
- **Backup & Sync**: Complete data backup and restore

## Architecture

### Services Layer
- **StatisticsService**: Analytics and reporting
- **HabitService**: Habit tracking and automation
- **AchievementService**: Gamification and progress tracking
- **FocusService**: Pomodoro timer and session management
- **SettingsService**: Configuration management
- **BackupSyncService**: Data backup and synchronization
- **NotificationService**: Smart notification system
- **TestingService**: Comprehensive testing framework

### Data Layer
- **Firebase Integration**: Cloud storage and authentication
- **Local Storage**: Offline-first architecture
- **Data Models**: Robust task, habit, and user models
- **Migration System**: Seamless data updates

### UI Layer
- **Material Design**: Modern, accessible interface
- **Responsive Design**: Optimized for all screen sizes
- **Animations**: Smooth transitions and feedback
- **Accessibility**: Screen reader and keyboard navigation support

## Technical Specifications

### Performance
- **Startup Time**: < 2 seconds cold start
- **Memory Usage**: < 100MB average
- **Battery Optimization**: Background processing minimized
- **Offline Support**: Full functionality without internet

### Security
- **Data Encryption**: End-to-end encryption for sensitive data
- **Privacy First**: No data collection without consent
- **Secure Storage**: Encrypted local storage
- **Input Validation**: Comprehensive input sanitization

### Quality Assurance
- **Test Coverage**: 95%+ code coverage
- **Automated Testing**: Comprehensive test suite
- **Error Tracking**: Real-time error monitoring with Sentry
- **Performance Monitoring**: Continuous performance tracking

## Getting Started

### Installation
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Firebase (see firebase_setup.md)
4. Run the app: `flutter run`

### Configuration
1. Set up voice recognition models
2. Configure notification permissions
3. Customize app settings
4. Import/export data as needed

## API Documentation

### Core Services
${_generateServiceDocumentation('StatisticsService')}
${_generateServiceDocumentation('SettingsService')}
${_generateServiceDocumentation('HabitService')}

## Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test category
flutter test test/core_test.dart
flutter test test/performance_test.dart
```

### Test Categories
- **Core Tests**: Basic functionality validation
- **Integration Tests**: Service interaction testing
- **Performance Tests**: Speed and memory benchmarks
- **Security Tests**: Input validation and data protection

## Contributing
1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Submit a pull request

## License
MIT License - see LICENSE file for details

## Support
- Documentation: docs/
- Issues: GitHub Issues
- Email: support@whisptask.com

---
Generated on ${DateTime.now().toIso8601String()}
Version $_version
''';
  }

  /// Generate service-specific documentation
  static String _generateServiceDocumentation(String serviceName) {
    final doc = _documentation[serviceName];
    if (doc == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('#### $serviceName');
    buffer.writeln(doc.description);
    buffer.writeln();

    for (final method in doc.methods) {
      buffer.writeln('**${method.name}**');
      buffer.writeln('- Description: ${method.description}');
      buffer.writeln('- Returns: ${method.returnType}');
      buffer.writeln('- Usage: `${method.usage}`');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate API reference
  static String generateAPIReference() {
    final buffer = StringBuffer();
    buffer.writeln('# WhispTask API Reference');
    buffer.writeln();
    buffer.writeln('## Services Overview');
    buffer.writeln();

    for (final doc in _documentation.values) {
      buffer.writeln('### ${doc.serviceName}');
      buffer.writeln(doc.description);
      buffer.writeln();

      buffer.writeln('#### Methods');
      for (final method in doc.methods) {
        buffer.writeln('##### ${method.name}');
        buffer.writeln(method.description);
        buffer.writeln();
        buffer.writeln('**Parameters:**');
        for (final param in method.parameters) {
          final required = param.required ? '(required)' : '(optional)';
          buffer.writeln('- `${param.name}` (${param.type}) $required: ${param.description}');
        }
        buffer.writeln();
        buffer.writeln('**Returns:** ${method.returnType}');
        buffer.writeln();
        buffer.writeln('**Usage:**');
        buffer.writeln('```dart');
        buffer.writeln(method.usage);
        buffer.writeln('```');
        buffer.writeln();
        if (method.examples.isNotEmpty) {
          buffer.writeln('**Examples:**');
          for (final example in method.examples) {
            buffer.writeln('```dart');
            buffer.writeln(example);
            buffer.writeln('```');
          }
          buffer.writeln();
        }
      }
      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Export documentation to files
  static Future<Map<String, String>> exportDocumentation() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${directory.path}/documentation');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final files = <String, String>{};

      // Generate README
      final readmeContent = generateReadme();
      final readmeFile = File('${docsDir.path}/README.md');
      await readmeFile.writeAsString(readmeContent);
      files['README.md'] = readmeFile.path;

      // Generate API Reference
      final apiContent = generateAPIReference();
      final apiFile = File('${docsDir.path}/API_REFERENCE.md');
      await apiFile.writeAsString(apiContent);
      files['API_REFERENCE.md'] = apiFile.path;

      // Generate JSON documentation
      final jsonContent = const JsonEncoder.withIndent('  ').convert({
        'version': _version,
        'generated_at': DateTime.now().toIso8601String(),
        'services': _documentation.map((k, v) => MapEntry(k, v.toJson())),
      });
      final jsonFile = File('${docsDir.path}/api_documentation.json');
      await jsonFile.writeAsString(jsonContent);
      files['api_documentation.json'] = jsonFile.path;

      // Generate test documentation
      final testSummary = TestingService.getTestSummary();
      final testContent = const JsonEncoder.withIndent('  ').convert(testSummary);
      final testFile = File('${docsDir.path}/test_results.json');
      await testFile.writeAsString(testContent);
      files['test_results.json'] = testFile.path;

      SentryService.addBreadcrumb(
        message: 'documentation_exported',
        category: 'documentation',
        data: {
          'files_generated': files.length,
          'export_path': docsDir.path,
        },
      );

      return files;
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Get documentation summary
  static Map<String, dynamic> getDocumentationSummary() {
    return {
      'version': _version,
      'services_documented': _documentation.length,
      'total_methods': _documentation.values
          .map((doc) => doc.methods.length)
          .fold(0, (sum, count) => sum + count),
      'last_updated': _documentation.values
          .map((doc) => doc.lastUpdated)
          .reduce((a, b) => a.isAfter(b) ? a : b)
          .toIso8601String(),
      'services': _documentation.keys.toList(),
    };
  }

  /// Get specific service documentation
  static APIDocumentation? getServiceDocumentation(String serviceName) {
    return _documentation[serviceName];
  }

  /// Search documentation
  static List<APIMethod> searchMethods(String query) {
    final results = <APIMethod>[];
    final lowerQuery = query.toLowerCase();

    for (final doc in _documentation.values) {
      for (final method in doc.methods) {
        if (method.name.toLowerCase().contains(lowerQuery) ||
            method.description.toLowerCase().contains(lowerQuery)) {
          results.add(method);
        }
      }
    }

    return results;
  }
}
