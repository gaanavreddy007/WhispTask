import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String? id;
  String title;
  String? description;
  DateTime createdAt;
  DateTime? dueDate;
  bool isCompleted;
  String priority; // 'high', 'medium', 'low'
  String category;
  String? color;
  bool isRecurring;
  String? recurringPattern; // 'daily', 'weekly', 'monthly'
  
  // NEW - Reminder/Notification fields
  bool hasReminder;
  DateTime? reminderTime;
  String reminderType; // 'once', 'daily', 'weekly', 'monthly'
  String notificationTone; // 'default', 'chime', 'bell', 'whistle'
  List<String> repeatDays; // For weekly reminders: ['mon', 'tue', 'wed']
  int reminderMinutesBefore; // Minutes before due date to remind
  bool isReminderActive;
  String? notificationId; // For managing local notifications

  Task({
    this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.priority = 'medium',
    this.category = 'general',
    this.color,
    this.isRecurring = false,
    this.recurringPattern,
    // NEW reminder defaults
    this.hasReminder = false,
    this.reminderTime,
    this.reminderType = 'once',
    this.notificationTone = 'default',
    this.repeatDays = const [],
    this.reminderMinutesBefore = 0,
    this.isReminderActive = true,
    this.notificationId,
  });

  // Convert Task to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'priority': priority,
      'category': category,
      'color': color,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      // NEW reminder fields
      'hasReminder': hasReminder,
      'reminderTime': reminderTime?.millisecondsSinceEpoch,
      'reminderType': reminderType,
      'notificationTone': notificationTone,
      'repeatDays': repeatDays,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isReminderActive': isReminderActive,
      'notificationId': notificationId,
    };
  }

  // Create Task from Firestore Map
  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      dueDate: map['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate']) 
          : null,
      isCompleted: map['isCompleted'] ?? false,
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? 'general',
      color: map['color'],
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
      // NEW reminder fields with defaults
      hasReminder: map['hasReminder'] ?? false,
      reminderTime: map['reminderTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['reminderTime']) 
          : null,
      reminderType: map['reminderType'] ?? 'once',
      notificationTone: map['notificationTone'] ?? 'default',
      repeatDays: List<String>.from(map['repeatDays'] ?? []),
      reminderMinutesBefore: map['reminderMinutesBefore'] ?? 0,
      isReminderActive: map['isReminderActive'] ?? true,
      notificationId: map['notificationId'],
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    String? priority,
    String? category,
    String? color,
    bool? isRecurring,
    String? recurringPattern,
    bool? hasReminder,
    DateTime? reminderTime,
    String? reminderType,
    String? notificationTone,
    List<String>? repeatDays,
    int? reminderMinutesBefore,
    bool? isReminderActive,
    String? notificationId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      color: color ?? this.color,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderType: reminderType ?? this.reminderType,
      notificationTone: notificationTone ?? this.notificationTone,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      isReminderActive: isReminderActive ?? this.isReminderActive,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  // Helper methods for reminders
  bool get hasActiveReminder => hasReminder && isReminderActive && !isCompleted;
  
  DateTime? get nextReminderTime {
    if (!hasActiveReminder || reminderTime == null) return null;
    
    switch (reminderType) {
      case 'daily':
        final now = DateTime.now();
        var next = DateTime(now.year, now.month, now.day, 
            reminderTime!.hour, reminderTime!.minute);
        if (next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case 'weekly':
        // Complex weekly logic would go here
        return reminderTime;
      default:
        return reminderTime;
    }
  }
}