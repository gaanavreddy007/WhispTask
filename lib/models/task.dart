// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Task {
  String? id;
  String title;
  String? description;
  DateTime createdAt;
  DateTime? dueDate;
  DateTime? completedAt;
  bool isCompleted;
  String priority; // 'high', 'medium', 'low'
  String category;
  String? color;
  
  // RECURRING FIELDS
  bool isRecurring;
  String? recurringPattern; // 'daily', 'weekly', 'monthly', 'yearly'
  int? recurringInterval; // Every X days/weeks/months (e.g., every 2 weeks)
  DateTime? lastProcessedAt; // Last time recurring task was processed
  DateTime? nextDueDate; // Next calculated due date for recurring tasks
  List<String> completedDates; // Track completion history for recurring tasks
  
  // NOTIFICATION/REMINDER FIELDS
  bool hasReminder;
  DateTime? reminderTime;
  String reminderType; // 'once', 'daily', 'weekly', 'monthly'
  String notificationTone; // 'default', 'chime', 'bell', 'whistle'
  List<String> repeatDays; // For weekly reminders: ['mon', 'tue', 'wed']
  int reminderMinutesBefore; // Minutes before due date to remind
  bool isReminderActive;
  int? notificationId; // Positive integer for managing local notifications
  int? snoozeCount;
  DateTime? lastSnoozedAt;
  DateTime? reminderCancelledAt;
  DateTime? migratedAt;
  DateTime? importedAt;
  DateTime? restoredAt;
  DateTime? archivedAt;
  
  // NEW DAY 6: VOICE NOTES FIELDS
  List<VoiceNote> voiceNotes; // Voice recordings with transcriptions
  bool hasVoiceNotes;
  
  // NEW DAY 6: ATTACHMENT FIELDS
  List<TaskAttachment> attachments; // File attachments
  bool hasAttachments;
  
  // USER AND METADATA
  String? userId; // User ID for task ownership
  DateTime? updatedAt; // Last modification time
  Map<String, dynamic>? metadata; // Additional flexible data storage
  List<String> tags; // Custom tags for better organization
  int estimatedMinutes; // Time estimation for task completion
  String status; // 'pending', 'in_progress', 'completed', 'overdue', 'cancelled'

  Task({
    this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.isCompleted = false,
    this.priority = 'medium',
    this.category = 'general',
    this.color,
    
    // Recurring defaults
    this.isRecurring = false,
    this.recurringPattern,
    this.recurringInterval,
    this.lastProcessedAt,
    this.nextDueDate,
    this.completedDates = const [],
    
    // Reminder defaults
    this.hasReminder = false,
    this.reminderTime,
    this.reminderType = 'once',
    this.notificationTone = 'default',
    this.repeatDays = const [],
    this.reminderMinutesBefore = 0,
    this.isReminderActive = true,
    this.notificationId,
    this.snoozeCount,
    this.lastSnoozedAt,
    this.reminderCancelledAt,
    this.migratedAt,
    this.importedAt,
    this.restoredAt,
    this.archivedAt,
    
    // NEW: Voice notes and attachments defaults
    this.voiceNotes = const [],
    this.hasVoiceNotes = false,
    this.attachments = const [],
    this.hasAttachments = false,
    
    // Additional defaults
    this.userId,
    this.updatedAt,
    this.metadata,
    this.tags = const [],
    this.estimatedMinutes = 0,
    this.status = 'pending',
  });

  // Convert Task to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'priority': priority,
      'category': category,
      'color': color,
      
      // Recurring fields
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'recurringInterval': recurringInterval,
      'lastProcessedAt': lastProcessedAt?.millisecondsSinceEpoch,
      'nextDueDate': nextDueDate?.millisecondsSinceEpoch,
      'completedDates': completedDates,
      
      // Reminder fields
      'hasReminder': hasReminder,
      'reminderTime': reminderTime?.millisecondsSinceEpoch,
      'notificationId': notificationId,
      'notificationTone': notificationTone,
      'snoozeCount': snoozeCount,
      'lastSnoozedAt': lastSnoozedAt?.millisecondsSinceEpoch,
      'reminderCancelledAt': reminderCancelledAt?.millisecondsSinceEpoch,
      'migratedAt': migratedAt?.millisecondsSinceEpoch,
      'importedAt': importedAt?.millisecondsSinceEpoch,
      'restoredAt': restoredAt?.millisecondsSinceEpoch,
      'archivedAt': archivedAt?.millisecondsSinceEpoch,
      'repeatDays': repeatDays,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isReminderActive': isReminderActive,
      
      // NEW: Voice notes and attachments
      'voiceNotes': voiceNotes.map((note) => note.toMap()).toList(),
      'hasVoiceNotes': hasVoiceNotes,
      'attachments': attachments.map((att) => att.toMap()).toList(),
      'hasAttachments': hasAttachments,
      
      // Additional fields
      'userId': userId,
      'updatedAt': (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      'metadata': metadata,
      'tags': tags,
      'estimatedMinutes': estimatedMinutes,
      'status': status,
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
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      dueDate: map['dueDate'] != null 
          ? (map['dueDate'] is Timestamp
              ? (map['dueDate'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['dueDate']))
          : null,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] is Timestamp
              ? (map['completedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['completedAt']))
          : null,
      isCompleted: map['isCompleted'] ?? false,
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? 'general',
      color: map['color'],
      
      // Recurring fields with defaults
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
      recurringInterval: map['recurringInterval'],
      lastProcessedAt: map['lastProcessedAt'] != null 
          ? (map['lastProcessedAt'] is Timestamp
              ? (map['lastProcessedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['lastProcessedAt']))
          : null,
      nextDueDate: map['nextDueDate'] != null 
          ? (map['nextDueDate'] is Timestamp
              ? (map['nextDueDate'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['nextDueDate']))
          : null,
      completedDates: List<String>.from(map['completedDates'] ?? []),
      
      // Reminder fields with defaults
      hasReminder: map['hasReminder'] ?? false,
      reminderTime: map['reminderTime'] != null 
          ? (map['reminderTime'] is Timestamp
              ? (map['reminderTime'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['reminderTime']))
          : null,
      notificationId: map['notificationId'],
      notificationTone: map['notificationTone'] ?? 'default',
      snoozeCount: map['snoozeCount'],
      lastSnoozedAt: map['lastSnoozedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['lastSnoozedAt']) : null,
      reminderCancelledAt: map['reminderCancelledAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['reminderCancelledAt']) : null,
      migratedAt: map['migratedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['migratedAt']) : null,
      importedAt: map['importedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['importedAt']) : null,
      restoredAt: map['restoredAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['restoredAt']) : null,
      archivedAt: map['archivedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['archivedAt']) : null,
      repeatDays: List<String>.from(map['repeatDays'] ?? []),
      reminderMinutesBefore: map['reminderMinutesBefore'] ?? 0,
      isReminderActive: map['isReminderActive'] ?? true,
      
      // NEW: Voice notes and attachments parsing
      voiceNotes: (map['voiceNotes'] as List<dynamic>?)
          ?.map((note) => VoiceNote.fromMap(note as Map<String, dynamic>))
          .toList() ?? [],
      hasVoiceNotes: map['hasVoiceNotes'] ?? false,
      attachments: (map['attachments'] as List<dynamic>?)
          ?.map((att) => TaskAttachment.fromMap(att as Map<String, dynamic>))
          .toList() ?? [],
      hasAttachments: map['hasAttachments'] ?? false,
      
      // Additional fields
      userId: map['userId'],
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['updatedAt']))
          : null,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      tags: List<String>.from(map['tags'] ?? []),
      estimatedMinutes: map['estimatedMinutes'] ?? 0,
      status: map['status'] ?? 'pending',
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    bool? isCompleted,
    String? priority,
    String? category,
    String? color,
    bool? isRecurring,
    String? recurringPattern,
    int? recurringInterval,
    DateTime? lastProcessedAt,
    DateTime? nextDueDate,
    List<String>? completedDates,
    bool? hasReminder,
    DateTime? reminderTime,
    String? reminderType,
    String? notificationTone,
    List<String>? repeatDays,
    int? reminderMinutesBefore,
    bool? isReminderActive,
    int? notificationId,
    int? snoozeCount,
    DateTime? lastSnoozedAt,
    DateTime? reminderCancelledAt,
    DateTime? migratedAt,
    DateTime? importedAt,
    DateTime? restoredAt,
    DateTime? archivedAt,
    List<VoiceNote>? voiceNotes,
    bool? hasVoiceNotes,
    List<TaskAttachment>? attachments,
    bool? hasAttachments,
    String? userId,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    int? estimatedMinutes,
    String? status,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      color: color ?? this.color,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      lastProcessedAt: lastProcessedAt ?? this.lastProcessedAt,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      completedDates: completedDates ?? this.completedDates,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      notificationId: notificationId ?? this.notificationId,
      notificationTone: notificationTone ?? this.notificationTone,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastSnoozedAt: lastSnoozedAt ?? this.lastSnoozedAt,
      reminderCancelledAt: reminderCancelledAt ?? this.reminderCancelledAt,
      migratedAt: migratedAt ?? this.migratedAt,
      importedAt: importedAt ?? this.importedAt,
      restoredAt: restoredAt ?? this.restoredAt,
      archivedAt: archivedAt ?? this.archivedAt,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      isReminderActive: isReminderActive ?? this.isReminderActive,
      voiceNotes: voiceNotes ?? this.voiceNotes,
      hasVoiceNotes: hasVoiceNotes ?? this.hasVoiceNotes,
      attachments: attachments ?? this.attachments,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status: status ?? this.status,
    );
  }

  // HELPER METHODS FOR REMINDERS
  bool get hasActiveReminder => hasReminder && isReminderActive && !isCompleted;
  
  DateTime? get nextReminderTime {
    if (!hasActiveReminder || reminderTime == null) return null;
    
    final now = DateTime.now();
    
    switch (reminderType) {
      case 'daily':
        var next = DateTime(now.year, now.month, now.day, 
            reminderTime!.hour, reminderTime!.minute);
        if (next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;
        
      case 'weekly':
        if (repeatDays.isEmpty) return reminderTime;
        
        // Find next occurrence based on repeat days
        var next = DateTime(now.year, now.month, now.day,
            reminderTime!.hour, reminderTime!.minute);
        
        for (int i = 0; i < 7; i++) {
          final dayName = _getDayName(next.weekday);
          if (repeatDays.contains(dayName) && next.isAfter(now)) {
            return next;
          }
          next = next.add(const Duration(days: 1));
        }
        return next;
        
      case 'monthly':
        var next = DateTime(now.year, now.month, reminderTime!.day,
            reminderTime!.hour, reminderTime!.minute);
        if (next.isBefore(now)) {
          // Move to next month
          if (next.month == 12) {
            next = DateTime(next.year + 1, 1, next.day, next.hour, next.minute);
          } else {
            next = DateTime(next.year, next.month + 1, next.day, next.hour, next.minute);
          }
        }
        return next;
        
      default: // 'once'
        return reminderTime?.isAfter(now) == true ? reminderTime : null;
    }
  }

  // HELPER METHODS FOR RECURRING TASKS
  bool get isRecurringActive => isRecurring && !isCompleted && recurringPattern != null;
  
  DateTime? get nextRecurrenceDue {
    if (!isRecurringActive || dueDate == null) return null;
    
    final interval = recurringInterval ?? 1;
    final now = DateTime.now();
    
    switch (recurringPattern) {
      case 'daily':
        var next = dueDate!;
        while (next.isBefore(now)) {
          next = next.add(Duration(days: interval));
        }
        return next;
        
      case 'weekly':
        var next = dueDate!;
        while (next.isBefore(now)) {
          next = next.add(Duration(days: 7 * interval));
        }
        return next;
        
      case 'monthly':
        var next = dueDate!;
        while (next.isBefore(now)) {
          if (next.month + interval > 12) {
            next = DateTime(next.year + 1, (next.month + interval) % 12, next.day, next.hour, next.minute);
          } else {
            next = DateTime(next.year, next.month + interval, next.day, next.hour, next.minute);
          }
        }
        return next;
        
      case 'yearly':
        var next = dueDate!;
        while (next.isBefore(now)) {
          next = DateTime(next.year + interval, next.month, next.day, next.hour, next.minute);
        }
        return next;
        
      default:
        return null;
    }
  }

  bool get needsRecurringProcessing {
    if (!isRecurringActive) return false;
    
    final now = DateTime.now();
    
    // Check if task was completed and needs to generate next occurrence
    if (isCompleted && completedAt != null) {
      final timeSinceCompletion = now.difference(completedAt!);
      
      // If completed recently and we haven't processed the next occurrence yet
      if (timeSinceCompletion.inHours < 24 && 
          (lastProcessedAt == null || lastProcessedAt!.isBefore(completedAt!))) {
        return true;
      }
    }
    
    // Check if we've passed the due date and need to create next occurrence
    if (dueDate != null && now.isAfter(dueDate!) && 
        (lastProcessedAt == null || lastProcessedAt!.isBefore(dueDate!))) {
      return true;
    }
    
    return false;
  }

  // STATUS AND PRIORITY HELPERS
  bool get isOverdue => !isCompleted && dueDate != null && DateTime.now().isAfter(dueDate!);
  
  // MISSING GETTERS - FIXES PROBLEMS 1 & 2
  bool get isHighPriority => priority.toLowerCase() == 'high';
  
  bool get isUrgent {
    // A task is urgent if it's high priority OR due within 24 hours
    if (isHighPriority) return true;
    if (dueDate == null) return false;
    
    final now = DateTime.now();
    final hoursUntilDue = dueDate!.difference(now).inHours;
    return hoursUntilDue <= 24 && hoursUntilDue > 0;
  }
  
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final due = dueDate!;
    return now.year == due.year && now.month == due.month && now.day == due.day;
  }
  
  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final due = dueDate!;
    return tomorrow.year == due.year && tomorrow.month == due.month && tomorrow.day == due.day;
  }
  
  String get priorityLevel {
    switch (priority.toLowerCase()) {
      case 'high':
        return '🔴 High';
      case 'low':
        return '🟢 Low';
      default:
        return '🟡 Medium';
    }
  }

  String get statusDisplay {
    if (isCompleted) return '✅ Completed';
    if (isOverdue) return '⏰ Overdue';
    if (isDueToday) return '📅 Due Today';
    if (isDueTomorrow) return '📋 Due Tomorrow';
    return '📝 Pending';
  }

  // COLOR AND VISUAL HELPERS
  String get displayColor {
    if (color != null && color!.isNotEmpty) return color!;
    
    // Default color based on priority
    switch (priority.toLowerCase()) {
      case 'high':
        return '#FF5722'; // Red
      case 'low':
        return '#4CAF50'; // Green
      default:
        return '#2196F3'; // Blue
    }
  }

  String get categoryColor {
    // Default category colors
    switch (category.toLowerCase()) {
      case 'work':
        return '#1976D2';
      case 'personal':
        return '#7B1FA2';
      case 'health':
        return '#388E3C';
      case 'finance':
        return '#F57C00';
      case 'education':
        return '#5D4037';
      case 'shopping':
        return '#E91E63';
      case 'travel':
        return '#00ACC1';
      default:
        return '#616161';
    }
  }

  // UTILITY METHODS
  Duration? get timeUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    if (dueDate!.isBefore(now)) return Duration.zero;
    return dueDate!.difference(now);
  }

  Duration? get timeSinceCreated => DateTime.now().difference(createdAt);
  
  Duration? get timeToComplete => completedAt?.difference(createdAt);

  String get formattedDueDate {
    if (dueDate == null) return 'No due date';
    
    final now = DateTime.now();
    final due = dueDate!;
    final difference = due.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(due)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(due)}';
    } else if (difference.inDays == -1) {
      return 'Yesterday at ${_formatTime(due)}';
    } else if (difference.inDays > 0 && difference.inDays < 7) {
      return '${_getDayName(due.weekday)} at ${_formatTime(due)}';
    } else {
      return '${due.day}/${due.month}/${due.year} at ${_formatTime(due)}';
    }
  }

  bool hasTag(String tag) => tags.contains(tag.toLowerCase());
  
  void addTag(String tag) {
    final lowercaseTag = tag.toLowerCase();
    if (!tags.contains(lowercaseTag)) {
      tags.add(lowercaseTag);
    }
  }
  
  void removeTag(String tag) => tags.remove(tag.toLowerCase());

  // NEW: Voice notes helpers
  void addVoiceNote(VoiceNote note) {
    voiceNotes.add(note);
    hasVoiceNotes = voiceNotes.isNotEmpty;
  }
  
  void removeVoiceNote(String noteId) {
    voiceNotes.removeWhere((note) => note.id == noteId);
    hasVoiceNotes = voiceNotes.isNotEmpty;
  }
  
  VoiceNote? getVoiceNote(String noteId) {
    try {
      return voiceNotes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }
  
  // NEW: Attachment helpers
  void addAttachment(TaskAttachment attachment) {
    attachments.add(attachment);
    hasAttachments = attachments.isNotEmpty;
  }
  
  void removeAttachment(String attachmentId) {
    attachments.removeWhere((att) => att.id == attachmentId);
    hasAttachments = attachments.isNotEmpty;
  }
  
  TaskAttachment? getAttachment(String attachmentId) {
    try {
      return attachments.firstWhere((att) => att.id == attachmentId);
    } catch (e) {
      return null;
    }
  }

  // VALIDATION METHODS
  bool get isValid {
    if (title.trim().isEmpty) return false;
    if (priority.isNotEmpty && !['high', 'medium', 'low'].contains(priority.toLowerCase())) return false;
    if (reminderType.isNotEmpty && !['once', 'daily', 'weekly', 'monthly'].contains(reminderType.toLowerCase())) return false;
    if (recurringPattern != null && !['daily', 'weekly', 'monthly', 'yearly'].contains(recurringPattern!.toLowerCase())) return false;
    if (notificationTone.isNotEmpty && !['default', 'chime', 'bell', 'whistle'].contains(notificationTone.toLowerCase())) return false;
    if (recurringInterval != null && recurringInterval! < 1) return false;
    if (reminderMinutesBefore < 0) return false;
    if (estimatedMinutes < 0) return false;
    
    return true;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (title.trim().isEmpty) errors.add('Title cannot be empty');
    if (priority.isNotEmpty && !['high', 'medium', 'low'].contains(priority.toLowerCase())) {
      errors.add('Priority must be high, medium, or low');
    }
    if (reminderType.isNotEmpty && !['once', 'daily', 'weekly', 'monthly'].contains(reminderType.toLowerCase())) {
      errors.add('Reminder type must be once, daily, weekly, or monthly');
    }
    if (recurringPattern != null && !['daily', 'weekly', 'monthly', 'yearly'].contains(recurringPattern!.toLowerCase())) {
      errors.add('Recurring pattern must be daily, weekly, monthly, or yearly');
    }
    if (notificationTone.isNotEmpty && !['default', 'chime', 'bell', 'whistle'].contains(notificationTone.toLowerCase())) {
      errors.add('Notification tone must be default, chime, bell, or whistle');
    }
    if (recurringInterval != null && recurringInterval! < 1) {
      errors.add('Recurring interval must be at least 1');
    }
    if (reminderMinutesBefore < 0) {
      errors.add('Reminder minutes before cannot be negative');
    }
    if (estimatedMinutes < 0) {
      errors.add('Estimated minutes cannot be negative');
    }
    if (hasReminder && reminderType == 'weekly' && repeatDays.isEmpty) {
      errors.add('Weekly reminders must specify repeat days');
    }
    
    return errors;
  }

  // COMPLETION TRACKING FOR RECURRING TASKS
  void markCompleted({DateTime? completionTime}) {
    final completionDate = completionTime ?? DateTime.now();
    
    isCompleted = true;
    completedAt = completionDate;
    status = 'completed';
    
    // Track completion for recurring tasks
    if (isRecurring) {
      final dateString = '${completionDate.year}-${completionDate.month.toString().padLeft(2, '0')}-${completionDate.day.toString().padLeft(2, '0')}';
      if (!completedDates.contains(dateString)) {
        completedDates.add(dateString);
      }
    }
  }

  // Create next occurrence for recurring task
  Task createNextOccurrence() {
    if (!isRecurring || recurringPattern == null) return this;
    
    final nextDue = nextRecurrenceDue;
    if (nextDue == null) return this;
    
    return copyWith(
      id: null, // Will get new ID when saved
      isCompleted: false,
      completedAt: null,
      dueDate: nextDue,
      createdAt: DateTime.now(),
      lastProcessedAt: DateTime.now(),
      status: 'pending',
      // Keep all other properties including reminders, voice notes, and attachments
    );
  }

  // PRIVATE HELPER METHODS
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'mon';
      case 2: return 'tue';
      case 3: return 'wed';
      case 4: return 'thu';
      case 5: return 'fri';
      case 6: return 'sat';
      case 7: return 'sun';
      default: return '';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  @override
  String toString() => 'Task(id: $id, title: $title, status: $status, priority: $priority)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}

// NEW DAY 6: Voice Note Model
class VoiceNote {
  String id;
  String taskId;
  String filePath; // Local path to audio file
  String? cloudUrl; // Firebase Storage URL
  String? transcription; // Speech-to-text transcription
  DateTime recordedAt;
  Duration duration;
  bool isTranscribed;
  double? fileSize; // File size in MB

  VoiceNote({
    required this.id,
    required this.taskId,
    required this.filePath,
    this.cloudUrl,
    this.transcription,
    required this.recordedAt,
    required this.duration,
    this.isTranscribed = false,
    this.fileSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'filePath': filePath,
      'cloudUrl': cloudUrl,
      'transcription': transcription,
      'recordedAt': recordedAt.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'isTranscribed': isTranscribed,
      'fileSize': fileSize,
    };
  }

  factory VoiceNote.fromMap(Map<String, dynamic> map) {
    return VoiceNote(
      id: map['id'] ?? '',
      taskId: map['taskId'] ?? '',
      filePath: map['filePath'] ?? '',
      cloudUrl: map['cloudUrl'],
      transcription: map['transcription'],
      recordedAt: map['recordedAt'] is Timestamp
          ? (map['recordedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['recordedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      duration: Duration(milliseconds: map['duration'] ?? 0),
      isTranscribed: map['isTranscribed'] ?? false,
      fileSize: map['fileSize']?.toDouble(),
    );
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  VoiceNote copyWith({
    String? id,
    String? taskId,
    String? filePath,
    String? cloudUrl,
    String? transcription,
    DateTime? recordedAt,
    Duration? duration,
    bool? isTranscribed,
    double? fileSize,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      filePath: filePath ?? this.filePath,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      transcription: transcription ?? this.transcription,
      recordedAt: recordedAt ?? this.recordedAt,
      duration: duration ?? this.duration,
      isTranscribed: isTranscribed ?? this.isTranscribed,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

// NEW DAY 6: Task Attachment Model
class TaskAttachment {
  String id;
  String taskId;
  String fileName;
  String filePath; // Local path
  String? cloudUrl; // Firebase Storage URL
  String fileType; // 'image', 'document', 'audio', 'video', 'other'
  double fileSize; // Size in MB
  DateTime attachedAt;
  String? mimeType;

  TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.filePath,
    this.cloudUrl,
    required this.fileType,
    required this.fileSize,
    required this.attachedAt,
    this.mimeType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'fileName': fileName,
      'filePath': filePath,
      'cloudUrl': cloudUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'attachedAt': attachedAt.millisecondsSinceEpoch,
      'mimeType': mimeType,
    };
  }

  factory TaskAttachment.fromMap(Map<String, dynamic> map) {
    return TaskAttachment(
      id: map['id'] ?? '',
      taskId: map['taskId'] ?? '',
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      cloudUrl: map['cloudUrl'],
      fileType: map['fileType'] ?? 'other',
      fileSize: (map['fileSize'] ?? 0.0).toDouble(),
      attachedAt: map['attachedAt'] is Timestamp
          ? (map['attachedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['attachedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      mimeType: map['mimeType'],
    );
  }

  String get formattedFileSize {
    if (fileSize < 1) {
      return '${(fileSize * 1024).toStringAsFixed(1)} KB';
    }
    return '${fileSize.toStringAsFixed(1)} MB';
  }

  IconData get fileIcon {
    switch (fileType.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.video_file;
      default:
        return Icons.attach_file;
    }
  }

  TaskAttachment copyWith({
    String? id,
    String? taskId,
    String? fileName,
    String? filePath,
    String? cloudUrl,
    String? fileType,
    double? fileSize,
    DateTime? attachedAt,
    String? mimeType,
  }) {
    return TaskAttachment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      attachedAt: attachedAt ?? this.attachedAt,
      mimeType: mimeType ?? this.mimeType,
    );
  }
}

// ENUM-LIKE CONSTANTS FOR TYPE SAFETY
class TaskPriority {
  static const String high = 'high';
  static const String medium = 'medium';
  static const String low = 'low';
  
  static const List<String> all = [high, medium, low];
}

class TaskCategory {
  static const String work = 'work';
  static const String personal = 'personal';
  static const String health = 'health';
  static const String finance = 'finance';
  static const String education = 'education';
  static const String shopping = 'shopping';
  static const String travel = 'travel';
  static const String general = 'general';
  
  static const List<String> all = [
    work, personal, health, finance, education, shopping, travel, general
  ];
}

class TaskStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String overdue = 'overdue';
  static const String cancelled = 'cancelled';
  
  static const List<String> all = [
    pending, inProgress, completed, overdue, cancelled
  ];
}

class RecurringPattern {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';
  
  static const List<String> all = [daily, weekly, monthly, yearly];
}

class ReminderType {
  static const String once = 'once';
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  
  static const List<String> all = [once, daily, weekly, monthly];
}

class NotificationTone {
  static const String defaultTone = 'default';
  static const String chime = 'chime';
  static const String bell = 'bell';
  static const String whistle = 'whistle';
  
  static const List<String> all = [defaultTone, chime, bell, whistle];
}