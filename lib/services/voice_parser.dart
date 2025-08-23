import 'package:flutter/material.dart';

import '../models/task.dart';

class VoiceParser {
  // Parse voice input into task object
  static Task parseVoiceToTask(String voiceInput) {
    final cleanInput = voiceInput.trim().toLowerCase();
    
    // Extract task title (main content)
    String title = _extractTitle(cleanInput);
    
    // Extract due date if mentioned
    DateTime? dueDate = _extractDueDate(cleanInput);
    
    // Extract category
    String category = _extractCategory(cleanInput);
    
    // Extract priority (using your string-based priority)
    String priority = _extractPriority(cleanInput);
    
    // Extract recurring pattern
    String? recurringPattern = _extractRecurringPattern(cleanInput);
    bool isRecurring = recurringPattern != null;
    
    // Extract color
    String? color = _extractColor(cleanInput);
    
    debugPrint('Parsed voice task: $title | Category: $category | Priority: $priority');
    
    return Task(
      title: title,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      category: category,
      priority: priority,
      color: color,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
    );
  }

  static String _extractTitle(String input) {
    // Remove common task prefixes
    final prefixes = [
      'remind me to ',
      'add task ',
      'create task ',
      'new task ',
      'task ',
      'i need to ',
      'remember to ',
    ];
    
    String title = input;
    for (String prefix in prefixes) {
      if (title.startsWith(prefix)) {
        title = title.substring(prefix.length);
        break;
      }
    }
    
    // Remove time-related suffixes
    final timePatterns = [
      RegExp(r'\s+at\s+\d+:\d+.*$'),
      RegExp(r'\s+tomorrow.*$'),
      RegExp(r'\s+today.*$'),
      RegExp(r'\s+in\s+\d+.*$'),
      RegExp(r'\s+later.*$'),
      RegExp(r'\s+daily.*$'),
      RegExp(r'\s+weekly.*$'),
      RegExp(r'\s+monthly.*$'),
    ];
    
    for (RegExp pattern in timePatterns) {
      title = title.replaceFirst(pattern, '');
    }
    
    // Remove priority words
    final priorityWords = ['urgent', 'important', 'high priority', 'low priority', 'asap'];
    for (String word in priorityWords) {
      title = title.replaceAll(word, '').trim();
    }
    
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    return title.trim().isEmpty ? 'New Voice Task' : title.trim();
  }

  static DateTime? _extractDueDate(String input) {
    final now = DateTime.now();
    
    // Check for specific time patterns
    final timeRegex = RegExp(r'at\s+(\d{1,2}):?(\d{2})?\s*(am|pm)?', caseSensitive: false);
    final match = timeRegex.firstMatch(input);
    
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      String? ampm = match.group(3)?.toLowerCase();
      
      // Convert to 24-hour format
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      
      return DateTime(now.year, now.month, now.day, hour, minute);
    }
    
    // Check for relative time patterns
    if (input.contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }
    
    if (input.contains('next week')) {
      return now.add(const Duration(days: 7));
    }
    
    if (input.contains('in 1 hour')) {
      return now.add(const Duration(hours: 1));
    }
    
    if (input.contains('in 30 minutes')) {
      return now.add(const Duration(minutes: 30));
    }
    
    return null;
  }

  static String _extractCategory(String input) {
    final categories = {
      'work': ['work', 'office', 'meeting', 'project', 'client', 'boss'],
      'personal': ['personal', 'home', 'family', 'friend'],
      'health': ['health', 'doctor', 'medicine', 'exercise', 'gym', 'workout'],
      'shopping': ['buy', 'shop', 'grocery', 'store', 'purchase'],
      'study': ['study', 'homework', 'assignment', 'exam', 'class', 'school'],
      'finance': ['pay', 'bill', 'bank', 'money', 'budget', 'tax'],
    };
    
    for (String category in categories.keys) {
      for (String keyword in categories[category]!) {
        if (input.contains(keyword)) {
          return category;
        }
      }
    }
    
    return 'general';
  }

  static String _extractPriority(String input) {
    // Using your string-based priority system: 'high', 'medium', 'low'
    if (input.contains('urgent') || input.contains('asap') || input.contains('emergency') || input.contains('important')) {
      return 'high';
    } else if (input.contains('low priority') || input.contains('when i have time') || input.contains('sometime')) {
      return 'low';
    }
    return 'medium'; // Default priority
  }

  static String? _extractRecurringPattern(String input) {
    if (input.contains('daily') || input.contains('every day')) {
      return 'daily';
    } else if (input.contains('weekly') || input.contains('every week')) {
      return 'weekly';
    } else if (input.contains('monthly') || input.contains('every month')) {
      return 'monthly';
    }
    return null;
  }

  static String? _extractColor(String input) {
    final colorMap = {
      'red': ['red', 'urgent'],
      'blue': ['blue', 'work'],
      'green': ['green', 'health'],
      'yellow': ['yellow', 'personal'],
      'purple': ['purple', 'study'],
      'orange': ['orange', 'shopping'],
    };
    
    for (String color in colorMap.keys) {
      for (String keyword in colorMap[color]!) {
        if (input.contains(keyword)) {
          return color;
        }
      }
    }
    
    return null;
  }

  // Validate parsed task
  static bool isValidTask(Task task) {
    return task.title.isNotEmpty && 
           task.title != 'New Voice Task' && 
           task.title.length > 2;
  }
}