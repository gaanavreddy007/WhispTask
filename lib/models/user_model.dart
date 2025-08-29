// lib/models/user_model.dart
// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';

// Type Safety Constants for User Preferences
class ThemeMode {
  static const light = 'light';
  static const dark = 'dark';
  static const system = 'system';
  
  static const List<String> all = [light, dark, system];
}

class NotificationFrequency {
  static const never = 'never';
  static const minimal = 'minimal';
  static const normal = 'normal';
  static const frequent = 'frequent';
  
  static const List<String> all = [never, minimal, normal, frequent];
}

class DefaultTaskView {
  static const list = 'list';
  static const grid = 'grid';
  static const calendar = 'calendar';
  static const kanban = 'kanban';
  
  static const List<String> all = [list, grid, calendar, kanban];
}

// User Preferences Model
class UserPreferences {
  final String theme;
  final String notificationFrequency;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String defaultTaskView;
  final String defaultSortBy;
  final bool autoDeleteCompleted;
  final int autoDeleteAfterDays;
  final bool showTaskCount;
  final bool compactView;
  final List<String> favoriteCategories;
  final Map<String, dynamic> customSettings;

  const UserPreferences({
    this.theme = ThemeMode.system,
    this.notificationFrequency = NotificationFrequency.normal,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.defaultTaskView = DefaultTaskView.list,
    this.defaultSortBy = 'dueDate',
    this.autoDeleteCompleted = false,
    this.autoDeleteAfterDays = 30,
    this.showTaskCount = true,
    this.compactView = false,
    this.favoriteCategories = const [],
    this.customSettings = const {},
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      theme: map['theme'] ?? ThemeMode.system,
      notificationFrequency: map['notificationFrequency'] ?? NotificationFrequency.normal,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      defaultTaskView: map['defaultTaskView'] ?? DefaultTaskView.list,
      defaultSortBy: map['defaultSortBy'] ?? 'dueDate',
      autoDeleteCompleted: map['autoDeleteCompleted'] ?? false,
      autoDeleteAfterDays: map['autoDeleteAfterDays'] ?? 30,
      showTaskCount: map['showTaskCount'] ?? true,
      compactView: map['compactView'] ?? false,
      favoriteCategories: List<String>.from(map['favoriteCategories'] ?? []),
      customSettings: Map<String, dynamic>.from(map['customSettings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'notificationFrequency': notificationFrequency,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'defaultTaskView': defaultTaskView,
      'defaultSortBy': defaultSortBy,
      'autoDeleteCompleted': autoDeleteCompleted,
      'autoDeleteAfterDays': autoDeleteAfterDays,
      'showTaskCount': showTaskCount,
      'compactView': compactView,
      'favoriteCategories': favoriteCategories,
      'customSettings': customSettings,
    };
  }

  UserPreferences copyWith({
    String? theme,
    String? notificationFrequency,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? defaultTaskView,
    String? defaultSortBy,
    bool? autoDeleteCompleted,
    int? autoDeleteAfterDays,
    bool? showTaskCount,
    bool? compactView,
    List<String>? favoriteCategories,
    Map<String, dynamic>? customSettings,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      defaultTaskView: defaultTaskView ?? this.defaultTaskView,
      defaultSortBy: defaultSortBy ?? this.defaultSortBy,
      autoDeleteCompleted: autoDeleteCompleted ?? this.autoDeleteCompleted,
      autoDeleteAfterDays: autoDeleteAfterDays ?? this.autoDeleteAfterDays,
      showTaskCount: showTaskCount ?? this.showTaskCount,
      compactView: compactView ?? this.compactView,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

// User Analytics Model
class UserAnalytics {
  final int totalTasksCreated;
  final int totalTasksCompleted;
  final int totalTasksDeleted;
  final int streakCurrent;
  final int streakLongest;
  final DateTime? lastCompletionDate;
  final double averageCompletionTime; // in hours
  final Map<String, int> categoryBreakdown;
  final Map<String, int> priorityBreakdown;
  final Map<String, int> monthlyCompletions;
  final List<DateTime> productiveDays;
  final double productivityScore;
  final Map<String, dynamic> customMetrics;

  const UserAnalytics({
    this.totalTasksCreated = 0,
    this.totalTasksCompleted = 0,
    this.totalTasksDeleted = 0,
    this.streakCurrent = 0,
    this.streakLongest = 0,
    this.lastCompletionDate,
    this.averageCompletionTime = 0.0,
    this.categoryBreakdown = const {},
    this.priorityBreakdown = const {},
    this.monthlyCompletions = const {},
    this.productiveDays = const [],
    this.productivityScore = 0.0,
    this.customMetrics = const {},
  });

  factory UserAnalytics.fromMap(Map<String, dynamic> map) {
    return UserAnalytics(
      totalTasksCreated: map['totalTasksCreated'] ?? 0,
      totalTasksCompleted: map['totalTasksCompleted'] ?? 0,
      totalTasksDeleted: map['totalTasksDeleted'] ?? 0,
      streakCurrent: map['streakCurrent'] ?? 0,
      streakLongest: map['streakLongest'] ?? 0,
      lastCompletionDate: map['lastCompletionDate'] != null 
          ? (map['lastCompletionDate'] as Timestamp).toDate()
          : null,
      averageCompletionTime: (map['averageCompletionTime'] ?? 0.0).toDouble(),
      categoryBreakdown: Map<String, int>.from(map['categoryBreakdown'] ?? {}),
      priorityBreakdown: Map<String, int>.from(map['priorityBreakdown'] ?? {}),
      monthlyCompletions: Map<String, int>.from(map['monthlyCompletions'] ?? {}),
      productiveDays: (map['productiveDays'] as List<dynamic>?)
          ?.map((timestamp) => (timestamp as Timestamp).toDate())
          .toList() ?? [],
      productivityScore: (map['productivityScore'] ?? 0.0).toDouble(),
      customMetrics: Map<String, dynamic>.from(map['customMetrics'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalTasksCreated': totalTasksCreated,
      'totalTasksCompleted': totalTasksCompleted,
      'totalTasksDeleted': totalTasksDeleted,
      'streakCurrent': streakCurrent,
      'streakLongest': streakLongest,
      'lastCompletionDate': lastCompletionDate != null 
          ? Timestamp.fromDate(lastCompletionDate!)
          : null,
      'averageCompletionTime': averageCompletionTime,
      'categoryBreakdown': categoryBreakdown,
      'priorityBreakdown': priorityBreakdown,
      'monthlyCompletions': monthlyCompletions,
      'productiveDays': productiveDays.map((date) => Timestamp.fromDate(date)).toList(),
      'productivityScore': productivityScore,
      'customMetrics': customMetrics,
    };
  }

  UserAnalytics copyWith({
    int? totalTasksCreated,
    int? totalTasksCompleted,
    int? totalTasksDeleted,
    int? streakCurrent,
    int? streakLongest,
    DateTime? lastCompletionDate,
    double? averageCompletionTime,
    Map<String, int>? categoryBreakdown,
    Map<String, int>? priorityBreakdown,
    Map<String, int>? monthlyCompletions,
    List<DateTime>? productiveDays,
    double? productivityScore,
    Map<String, dynamic>? customMetrics,
  }) {
    return UserAnalytics(
      totalTasksCreated: totalTasksCreated ?? this.totalTasksCreated,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      totalTasksDeleted: totalTasksDeleted ?? this.totalTasksDeleted,
      streakCurrent: streakCurrent ?? this.streakCurrent,
      streakLongest: streakLongest ?? this.streakLongest,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      averageCompletionTime: averageCompletionTime ?? this.averageCompletionTime,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      priorityBreakdown: priorityBreakdown ?? this.priorityBreakdown,
      monthlyCompletions: monthlyCompletions ?? this.monthlyCompletions,
      productiveDays: productiveDays ?? this.productiveDays,
      productivityScore: productivityScore ?? this.productivityScore,
      customMetrics: customMetrics ?? this.customMetrics,
    );
  }
}

class UserModel {
  final String uid;
  final String? email;
  final String displayName;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime lastSignIn;
  final int taskCount;
  final int completedTaskCount;
  final String? photoUrl;
  
  // NEW: Enhanced User Data
  final DateTime updatedAt;
  final String timezone;
  final String language;
  final UserPreferences preferences;
  final UserAnalytics analytics;
  final Map<String, dynamic> metadata;

  UserModel({
    required this.uid,
    this.email,
    required this.displayName,
    required this.isAnonymous,
    required this.createdAt,
    required this.lastSignIn,
    this.taskCount = 0,
    this.completedTaskCount = 0,
    this.photoUrl,
    // Enhanced fields
    DateTime? updatedAt,
    this.timezone = 'UTC',
    this.language = 'en',
    this.preferences = const UserPreferences(),
    this.analytics = const UserAnalytics(),
    this.metadata = const {},
  }) : updatedAt = updatedAt ?? createdAt;

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'] ?? 'User',
      isAnonymous: data['isAnonymous'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSignIn: (data['lastSignIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      taskCount: data['taskCount'] ?? 0,
      completedTaskCount: data['completedTaskCount'] ?? 0,
      photoUrl: data['photoUrl'],
      // Enhanced fields
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timezone: data['timezone'] ?? 'UTC',
      language: data['language'] ?? 'en',
      preferences: data['preferences'] != null 
          ? UserPreferences.fromMap(Map<String, dynamic>.from(data['preferences']))
          : const UserPreferences(),
      analytics: data['analytics'] != null
          ? UserAnalytics.fromMap(Map<String, dynamic>.from(data['analytics']))
          : const UserAnalytics(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSignIn': Timestamp.fromDate(lastSignIn),
      'taskCount': taskCount,
      'completedTaskCount': completedTaskCount,
      'photoUrl': photoUrl,
      // Enhanced fields
      'updatedAt': Timestamp.fromDate(updatedAt),
      'timezone': timezone,
      'language': language,
      'preferences': preferences.toMap(),
      'analytics': analytics.toMap(),
      'metadata': metadata,
    };
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastSignIn,
    int? taskCount,
    int? completedTaskCount,
    String? photoUrl,
    // Enhanced fields
    DateTime? updatedAt,
    String? timezone,
    String? language,
    UserPreferences? preferences,
    UserAnalytics? analytics,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      taskCount: taskCount ?? this.taskCount,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      photoUrl: photoUrl ?? this.photoUrl,
      // Enhanced fields
      updatedAt: updatedAt ?? DateTime.now(),
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      preferences: preferences ?? this.preferences,
      analytics: analytics ?? this.analytics,
      metadata: metadata ?? this.metadata,
    );
  }

  // EXISTING HELPER METHODS (kept as-is)

  // Get completion percentage
  double get completionPercentage {
    if (taskCount == 0) return 0.0;
    return (completedTaskCount / taskCount) * 100;
  }

  // Get user initials for avatar
  String get initials {
    // Handle empty or null displayName
    if (displayName.isEmpty) return 'U';
    
    // Split by spaces and filter out empty strings
    List<String> nameParts = displayName.trim().split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    
    // Handle case where no valid name parts exist
    if (nameParts.isEmpty) return 'U';
    
    // Single name part - return first character
    if (nameParts.length == 1) {
      return nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : 'U';
    }
    
    // Multiple name parts - return first character of first and last parts
    String firstInitial = nameParts.first.isNotEmpty ? nameParts.first[0] : '';
    String lastInitial = nameParts.last.isNotEmpty ? nameParts.last[0] : '';
    
    // If we couldn't get both initials, fall back to first initial or 'U'
    if (firstInitial.isEmpty && lastInitial.isEmpty) return 'U';
    if (lastInitial.isEmpty) return firstInitial.toUpperCase();
    
    return '${firstInitial}${lastInitial}'.toUpperCase();
  }

  // Check if user has completed setup
  bool get hasCompletedSetup {
    return !isAnonymous && email != null && displayName.isNotEmpty;
  }

  // Get user type description
  String get accountType {
    return isAnonymous ? 'Guest Account' : 'Registered Account';
  }

  // Get formatted member since date
  String get memberSince {
    return '${_getMonthName(createdAt.month)} ${createdAt.year}';
  }

  // Get days since registration
  int get daysSinceRegistration {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Get formatted last sign in
  String get formattedLastSignIn {
    Duration difference = DateTime.now().difference(lastSignIn);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  // NEW ANALYTICS HELPER METHODS

  // Current streak status
  bool get hasActiveStreak => analytics.streakCurrent > 0;
  
  // Productivity level based on completion rate
  String get productivityLevel {
    final score = analytics.productivityScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Needs Improvement';
    return 'Getting Started';
  }

  // Most productive category
  String? get topCategory {
    if (analytics.categoryBreakdown.isEmpty) return null;
    return analytics.categoryBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Weekly completion average
  double get weeklyCompletionAverage {
    if (analytics.totalTasksCompleted == 0) return 0.0;
    final weeks = daysSinceRegistration / 7;
    return weeks > 0 ? analytics.totalTasksCompleted / weeks : 0.0;
  }

  // Tasks remaining (active tasks)
  int get activeTasks => taskCount - completedTaskCount;

  // Completion efficiency (0-100%)
  double get completionEfficiency {
    final total = analytics.totalTasksCreated;
    if (total == 0) return 0.0;
    return (analytics.totalTasksCompleted / total) * 100;
  }

  // NEW PREFERENCES HELPER METHODS

  bool get notificationsEnabled => preferences.notificationFrequency != NotificationFrequency.never;
  bool get isDarkMode => preferences.theme == ThemeMode.dark;
  bool get isSystemTheme => preferences.theme == ThemeMode.system;
  bool get isCompactViewPreferred => preferences.compactView;
  
  // Get user's favorite categories for quick access
  List<String> get quickAccessCategories => preferences.favoriteCategories;

  // Check if auto-delete is enabled and overdue
  bool get shouldAutoDeleteCompleted {
    if (!preferences.autoDeleteCompleted) return false;
    if (analytics.lastCompletionDate == null) return false;
    
    final daysSinceLastCompletion = DateTime.now()
        .difference(analytics.lastCompletionDate!)
        .inDays;
    return daysSinceLastCompletion >= preferences.autoDeleteAfterDays;
  }

  // VALIDATION METHODS

  bool get isValid {
    return uid.isNotEmpty &&
           displayName.trim().isNotEmpty &&
           ThemeMode.all.contains(preferences.theme) &&
           NotificationFrequency.all.contains(preferences.notificationFrequency) &&
           DefaultTaskView.all.contains(preferences.defaultTaskView);
  }

  List<String> get validationErrors {
    List<String> errors = [];
    
    if (uid.isEmpty) errors.add('UID is required');
    if (displayName.trim().isEmpty) errors.add('Display name cannot be empty');
    if (!ThemeMode.all.contains(preferences.theme)) errors.add('Invalid theme preference');
    if (!NotificationFrequency.all.contains(preferences.notificationFrequency)) {
      errors.add('Invalid notification frequency');
    }
    if (!DefaultTaskView.all.contains(preferences.defaultTaskView)) {
      errors.add('Invalid default task view');
    }
    
    return errors;
  }

  // ANALYTICS UPDATE HELPERS (for TaskProvider to use)

  UserModel incrementTaskCount() {
    return copyWith(
      taskCount: taskCount + 1,
      analytics: analytics.copyWith(
        totalTasksCreated: analytics.totalTasksCreated + 1,
      ),
    );
  }

  UserModel incrementCompletedCount() {
    final now = DateTime.now();
    final newStreak = _calculateNewStreak(now);
    
    return copyWith(
      completedTaskCount: completedTaskCount + 1,
      analytics: analytics.copyWith(
        totalTasksCompleted: analytics.totalTasksCompleted + 1,
        lastCompletionDate: now,
        streakCurrent: newStreak,
        streakLongest: newStreak > analytics.streakLongest ? newStreak : analytics.streakLongest,
        productiveDays: [...analytics.productiveDays, now],
      ),
    );
  }

  UserModel decrementTaskCount() {
    return copyWith(
      taskCount: taskCount > 0 ? taskCount - 1 : 0,
      analytics: analytics.copyWith(
        totalTasksDeleted: analytics.totalTasksDeleted + 1,
      ),
    );
  }

  int _calculateNewStreak(DateTime completionDate) {
    if (analytics.lastCompletionDate == null) return 1;
    
    final daysDifference = completionDate
        .difference(analytics.lastCompletionDate!)
        .inDays;
    
    // If completed within 1 day, continue streak
    if (daysDifference <= 1) {
      return analytics.streakCurrent + 1;
    } else {
      // Streak broken, start new streak
      return 1;
    }
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, isAnonymous: $isAnonymous, taskCount: $taskCount, completedCount: $completedTaskCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}