// ignore_for_file: avoid_print, unnecessary_string_escapes

import 'package:flutter/material.dart';

import '../models/task.dart';

class VoiceParser {
  // Parse voice input into task object
  static Task parseVoiceToTask(String voiceInput) {
    final cleanInput = _correctSpeechMisinterpretations(voiceInput.trim().toLowerCase());
    
    // Extract task title (main content)
    String title = _extractTitle(cleanInput);
    
    // Extract description if mentioned
    String? description = _extractDescription(cleanInput);
    
    // Extract due date if mentioned
    DateTime? dueDate = _extractDueDate(cleanInput);
    
    // Extract category
    String category = _extractCategory(cleanInput);
    
    // Extract priority (using your string-based priority)
    String priority = _extractPriority(cleanInput);
    
    // Extract recurring pattern and interval
    String? recurringPattern = _extractRecurringPattern(cleanInput);
    int? recurringInterval = _extractRecurringInterval(cleanInput);
    bool isRecurring = recurringPattern != null;
    
    // Extract color
    String? color = _extractColor(cleanInput);
    
    // Extract reminder information
    bool hasReminder = _extractHasReminder(cleanInput);
    DateTime? reminderTime = _extractReminderTime(cleanInput, dueDate);
    String reminderType = _extractReminderType(cleanInput);
    int reminderMinutesBefore = _extractReminderMinutesBefore(cleanInput);
    String notificationTone = _extractNotificationTone(cleanInput);
    List<String> repeatDays = _extractRepeatDays(cleanInput);
    
    debugPrint('Parsed voice task: $title | Category: $category | Priority: $priority | Recurring: $isRecurring ($recurringPattern every $recurringInterval) | Reminder: $hasReminder');
    
    return Task(
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      category: category,
      priority: priority,
      color: color,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      recurringInterval: isRecurring ? (recurringInterval ?? 1) : null,
      status: 'pending',
      // Reminder fields
      hasReminder: hasReminder,
      reminderTime: reminderTime,
      reminderType: reminderType,
      reminderMinutesBefore: reminderMinutesBefore,
      notificationTone: notificationTone,
      repeatDays: repeatDays,
      isReminderActive: hasReminder,
      // Initialize empty collections for voice notes and attachments
      voiceNotes: [],
      attachments: [],
      hasVoiceNotes: false,
      hasAttachments: false,
    );
  }

  // NEW: Parse task update commands (Day 8)
  static TaskUpdateCommand parseTaskUpdateCommand(String voiceInput) {
    final cleanInput = voiceInput.trim().toLowerCase();
    debugPrint('Parsing task update command: $cleanInput');
    
    // Determine the action type
    TaskUpdateAction action = _extractUpdateAction(cleanInput);
    
    // Extract task identifier
    String taskIdentifier = _extractTaskIdentifierFromCommand(cleanInput);
    
    // Extract additional parameters based on action
    Map<String, dynamic> parameters = _extractUpdateParameters(cleanInput, action);
    
    debugPrint('Parsed update command - Action: $action, Identifier: "$taskIdentifier", Params: $parameters');
    
    return TaskUpdateCommand(
      action: action,
      taskIdentifier: taskIdentifier,
      parameters: parameters,
    );
  }

  // NEW: Check if command is for task updates
  static bool isTaskUpdateCommand(String command) {
    final lowerCommand = command.toLowerCase();
    print('VoiceParser: Checking if task update command: "$lowerCommand"');
    
    // Check for explicit update patterns first
    final updatePatterns = [
      // Completion patterns
      RegExp(r'\b(mark\s+.*\s+(as\s+)?(done|complete|completed|finished))', caseSensitive: false),
      RegExp(r'\b.*\s+(done|complete|completed|finished)$', caseSensitive: false),
      RegExp(r'^(complete|finish|done)\s+', caseSensitive: false),
      
      // Status change patterns  
      RegExp(r'^(start|begin|pause|cancel|delete|remove)\s+', caseSensitive: false),
      RegExp(r'^update\s+', caseSensitive: false),
      RegExp(r'\b(set|change)\s+priority', caseSensitive: false),
      RegExp(r'\bupdate\s+.*\s+(priority|status|due)', caseSensitive: false),
    ];

    // Check if any update pattern matches
    for (final pattern in updatePatterns) {
      if (pattern.hasMatch(lowerCommand)) {
        print('VoiceParser: Pattern matched: ${pattern.pattern}');
        return true;
      }
    }
    
    // Additional keyword-based check for edge cases
    final updateKeywords = [
      'mark as done', 'mark as complete', 'mark as finished',
      'mark complete', 'mark finished', 'mark done',
    ];

    return updateKeywords.any((keyword) => lowerCommand.contains(keyword));
  }

  // NEW: Extract update action from command
  static TaskUpdateAction _extractUpdateAction(String input) {
    // Completion actions
    if (RegExp(r'\b(mark as done|mark as complete|mark as finished|mark complete|mark finished|mark done|complete|finish|done)\b').hasMatch(input)) {
      return TaskUpdateAction.markComplete;
    }
    
    // Start/Resume actions
    if (RegExp(r'\b(start|begin|resume)\b').hasMatch(input)) {
      return TaskUpdateAction.start;
    }
    
    // Pause actions
    if (RegExp(r'\b(pause|stop)\b').hasMatch(input)) {
      return TaskUpdateAction.pause;
    }
    
    // Cancel actions
    if (RegExp(r'\b(cancel|abort)\b').hasMatch(input)) {
      return TaskUpdateAction.cancel;
    }
    
    // Delete actions
    if (RegExp(r'\b(delete|remove)\b').hasMatch(input)) {
      return TaskUpdateAction.delete;
    }
    
    // Priority changes
    if (RegExp(r'\b(set priority|change priority|priority)\b').hasMatch(input)) {
      return TaskUpdateAction.changePriority;
    }
    
    return TaskUpdateAction.markComplete; // Default action
  }

  // NEW: Extract task identifier from update command
  static String _extractTaskIdentifierFromCommand(String input) {
    print('VoiceParser: Extracting task identifier from: "$input"');
    
    // First, try specific patterns for "mark [title] as [action]" format
    final markAsMatch = RegExp(r'mark\s+(.*?)\s+as\s+(done|complete|completed|finished)', caseSensitive: false).firstMatch(input);
    if (markAsMatch != null) {
      final taskIdentifier = markAsMatch.group(1)?.trim();
      if (taskIdentifier != null && taskIdentifier.isNotEmpty) {
        print('VoiceParser: Mark-as pattern matched, extracted: "$taskIdentifier"');
        return taskIdentifier;
      }
    }
    
    // Then try the fallback pattern for "[title] [action]" format
    final fallbackMatch = RegExp(r'(.+?)\s+(done|complete|completed|finished|deleted)$', caseSensitive: false).firstMatch(input);
    if (fallbackMatch != null) {
      final taskIdentifier = fallbackMatch.group(1)?.trim();
      if (taskIdentifier != null && taskIdentifier.isNotEmpty && !taskIdentifier.startsWith('mark ')) {
        print('VoiceParser: Fallback pattern matched, extracted: "$taskIdentifier"');
        return taskIdentifier;
      }
    }
    
    // Define patterns from most specific to most general
    final patterns = {
      // Pattern: "update [title] [time/action]" - extract just the title
      RegExp(r'^update\s+(.*?)\s+(is\s+today|is\s+tomorrow|today|tomorrow|tonight|this\s+week|next\s+week|monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false): 1,
      // Pattern: "mark [title] as done/complete/finished"
      RegExp(r'mark\s+(.*?)\s+as\s+(done|complete|completed|finished)', caseSensitive: false): 1,
      // Pattern: "mark task [title] complete/done"
      RegExp(r'mark\s+task\s+(.*?)\s+(complete|completed|done)', caseSensitive: false): 1,
      // Pattern: "[action] [title]" - for commands starting with action
      RegExp(r'^(complete|finish|done|delete|remove|start|pause|cancel)\s+(.+)', caseSensitive: false): 2,
      // Pattern: "update [title]" - simple update command (must be last to avoid conflicts)
      RegExp(r'^update\s+(.+)', caseSensitive: false): 1,
    };

    for (var entry in patterns.entries) {
      final match = entry.key.firstMatch(input);
      if (match != null && match.groupCount >= entry.value) {
        final taskIdentifier = match.group(entry.value)?.trim();
        if (taskIdentifier != null && taskIdentifier.isNotEmpty) {
          print('VoiceParser: Pattern matched, extracted: "$taskIdentifier"');
          return taskIdentifier;
        }
      }
    }

    // Comprehensive fuzzy matching for all edge cases
    final timeWords = ['today', 'tomorrow', 'tonight', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday', 'this week', 'next week', 'weekend'];
    final taskKeywords = ['exam', 'homework', 'milk', 'groceries', 'work', 'meeting', 'call', 'study', 'project', 'assignment', 'test', 'quiz', 'shopping', 'buy', 'get', 'exercise', 'workout', 'clean', 'wash', 'cook', 'email', 'phone', 'text', 'message'];
    
    // Handle misheard commands with comprehensive phonetic similarities
    final phoneticMap = {
      'tet': 'exam', 'teh': 'the', 'bai': 'buy', 'bhai': 'buy', 'bike': 'buy',
      'homwork': 'homework', 'homevork': 'homework', 'homewerk': 'homework',
      'grocerys': 'groceries', 'groseries': 'groceries', 'grosery': 'grocery',
      'milc': 'milk', 'melk': 'milk', 'mlik': 'milk',
      'exem': 'exam', 'egzam': 'exam', 'eksam': 'exam', 'exams': 'exam',
      'studie': 'study', 'studdy': 'study', 'studi': 'study',
      'meating': 'meeting', 'meting': 'meeting', 'meeteng': 'meeting',
      'cal': 'call', 'cole': 'call', 'kol': 'call',
      'werk': 'work', 'wurk': 'work', 'wark': 'work'
    };
    
    String cleanedInput = input.toLowerCase();
    
    // Apply phonetic corrections
    for (var entry in phoneticMap.entries) {
      cleanedInput = cleanedInput.replaceAll(entry.key, entry.value);
    }
    
    // Extract task keyword with time word
    for (String timeWord in timeWords) {
      if (cleanedInput.contains(timeWord)) {
        for (String keyword in taskKeywords) {
          if (cleanedInput.contains(keyword)) {
            print('VoiceParser: Found task keyword "$keyword" with time "$timeWord", extracting: "$keyword"');
            return keyword;
          }
        }
        
        // If time word found but no keyword, extract the main word before time
        final beforeTime = cleanedInput.split(timeWord)[0].trim();
        final words = beforeTime.split(' ').where((w) => w.isNotEmpty && w.length > 2).toList();
        if (words.isNotEmpty) {
          final lastWord = words.last.trim();
          if (lastWord.isNotEmpty && lastWord.length > 2) {
            print('VoiceParser: Extracting word before time: "$lastWord"');
            return lastWord;
          }
        }
      }
    }

    // Additional check for task keywords without time words
    for (String keyword in taskKeywords) {
      if (cleanedInput.contains(keyword)) {
        print('VoiceParser: Found task keyword "$keyword" without time word, extracting: "$keyword"');
        return keyword;
      }
    }

    print('VoiceParser: No patterns matched, returning whole command: "$input"');
    return input; // Fallback to the whole command if no specific pattern matches
  }


  // NEW: Extract additional parameters for update commands
  static Map<String, dynamic> _extractUpdateParameters(String input, TaskUpdateAction action) {
    Map<String, dynamic> parameters = {};
    
    switch (action) {
      case TaskUpdateAction.changePriority:
        String priority = _extractPriorityFromCommand(input);
        parameters['priority'] = priority;
        break;
        
      case TaskUpdateAction.markComplete:
        // Check if should add completion note
        if (input.contains('with note') || input.contains('add note')) {
          parameters['addNote'] = true;
        }
        break;
        
      default:
        break;
    }
    
    return parameters;
  }

  // NEW: Extract priority from command
  static String _extractPriorityFromCommand(String input) {
    if (RegExp(r'\b(high|urgent|important|asap|critical)\b').hasMatch(input)) {
      return 'high';
    } else if (RegExp(r'\b(low|later|sometime|when possible)\b').hasMatch(input)) {
      return 'low';
    } else if (RegExp(r'\b(medium|normal|regular)\b').hasMatch(input)) {
      return 'medium';
    }
    return 'medium'; // Default
  }

  // NEW: Get task matching confidence score
  static double getTaskMatchingScore(String voiceIdentifier, String taskTitle) {
    final voiceWords = voiceIdentifier.toLowerCase().split(' ');
    final taskWords = taskTitle.toLowerCase().split(' ');
    
    int matches = 0;
    int totalWords = voiceWords.length;
    
    for (String voiceWord in voiceWords) {
      if (voiceWord.length < 2) continue; // Skip very short words
      
      for (String taskWord in taskWords) {
        if (taskWord.contains(voiceWord) || voiceWord.contains(taskWord)) {
          matches++;
          break; // Found match for this voice word, move to next
        }
      }
    }
    
    return totalWords > 0 ? matches / totalWords.toDouble() : 0.0;
  }

  // NEW: Generate voice feedback messages
  static String generateVoiceFeedback(TaskUpdateAction action, String taskTitle, {bool success = true}) {
    if (!success) {
      return "Sorry, I couldn't find the task '$taskTitle'. Please try again.";
    }
    
    switch (action) {
      case TaskUpdateAction.markComplete:
        return "Task '$taskTitle' marked as complete.";
      case TaskUpdateAction.start:
        return "Started working on '$taskTitle'.";
      case TaskUpdateAction.pause:
        return "Paused '$taskTitle'.";
      case TaskUpdateAction.cancel:
        return "Cancelled '$taskTitle'.";
      case TaskUpdateAction.delete:
        return "Deleted '$taskTitle'.";
      case TaskUpdateAction.changePriority:
        return "Changed priority for '$taskTitle'.";
    }
  }

  // Simplified command parsing
  static Map<String, dynamic> parseVoiceCommand(String command) {
    String cleanCommand = command.toLowerCase().trim();
    print('VoiceParser: Parsing command: "$cleanCommand"');
    
    // Remove wake word if present
    cleanCommand = cleanCommand.replaceAll(RegExp(r'^(hey whisp,?\s*|whisp,?\s*)'), '');
    
    // Simple action detection
    if (_isUpdateCommand(cleanCommand)) {
      return {
        'type': 'task_update',
        'action': _getSimpleAction(cleanCommand),
        'taskIdentifier': _getSimpleTaskIdentifier(cleanCommand),
        'originalCommand': command
      };
    }
    
    // Default to task creation
    return {
      'type': 'create_task',
      'title': _getSimpleTitle(cleanCommand),
      'originalCommand': command
    };
  }
  
  // Simple update command detection
  static bool _isUpdateCommand(String command) {
    final updateWords = ['done', 'complete', 'finish', 'delete', 'remove', 'mark'];
    return updateWords.any((word) => command.contains(word));
  }
  
  // Simple action extraction
  static String _getSimpleAction(String command) {
    if (command.contains('done') || command.contains('complete') || command.contains('finish')) {
      return 'complete';
    }
    if (command.contains('delete') || command.contains('remove')) {
      return 'delete';
    }
    return 'complete';
  }
  
  // Simple task identifier extraction
  static String _getSimpleTaskIdentifier(String command) {
    // Remove action words
    String identifier = command
        .replaceAll(RegExp(r'\b(mark|as|done|complete|finish|delete|remove)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    return identifier.isEmpty ? 'task' : identifier;
  }
  
  // Simple title extraction
  static String _getSimpleTitle(String command) {
    // Remove common prefixes
    String title = command
        .replaceAll(RegExp(r'^(add|create|new)\s+'), '')
        .trim();
    
    if (title.isEmpty) title = 'Voice Task';
    
    // Capitalize first letter
    return title[0].toUpperCase() + title.substring(1);
  }
  
  

  // Simplified task update command detection
  static bool isTaskUpdateCommandEnhanced(String command) {
    final updateWords = ['done', 'complete', 'finish', 'delete', 'remove', 'mark'];
    return updateWords.any((word) => command.toLowerCase().contains(word));
  }

  // Extract action from command
  static String extractAction(String command) {
    if (command.contains('done') || command.contains('complete') || command.contains('finish')) {
      return 'complete';
    }
    if (command.contains('start') || command.contains('begin')) {
      return 'start';
    }
    if (command.contains('pause') || command.contains('stop')) {
      return 'pause';
    }
    if (command.contains('cancel') || command.contains('abort')) {
      return 'cancel';
    }
    if (command.contains('delete') || command.contains('remove')) {
      return 'delete';
    }
    if (command.contains('priority')) {
      return 'changePriority';
    }
    if (command.contains('update')) {
      return 'setDueDate';
    }
    return 'unknown';
  }

  // Enhanced task identifier extraction with regex patterns
  static String extractTaskIdentifierFromCommand(String command) {
    print('VoiceParser: Extracting task identifier from: "$command"');
    
    // First, try specific patterns for "mark [title] as [action]" format
    final markAsMatch = RegExp(r'mark\s+(.*?)\s+as\s+(done|complete|completed|finished)', caseSensitive: false).firstMatch(command);
    if (markAsMatch != null) {
      final taskIdentifier = markAsMatch.group(1)?.trim();
      if (taskIdentifier != null && taskIdentifier.isNotEmpty) {
        print('VoiceParser: Mark-as pattern matched, extracted: "$taskIdentifier"');
        return taskIdentifier;
      }
    }
    
    // Then try the fallback pattern for "[title] [action]" format
    final fallbackMatch = RegExp(r'(.+?)\s+(done|complete|completed|finished|deleted)$', caseSensitive: false).firstMatch(command);
    if (fallbackMatch != null) {
      final taskIdentifier = fallbackMatch.group(1)?.trim();
      if (taskIdentifier != null && taskIdentifier.isNotEmpty && !taskIdentifier.startsWith('mark ')) {
        print('VoiceParser: Fallback pattern matched, extracted: "$taskIdentifier"');
        return taskIdentifier;
      }
    }
    
    // Define patterns from most specific to most general
    final patterns = {
      // Pattern: "update [title] [time/action]" - extract just the title
      RegExp(r'^update\s+(.*?)\s+(is\s+today|is\s+tomorrow|today|tomorrow|tonight|this\s+week|next\s+week|monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false): 1,
      // Pattern: "mark [title] as done/complete/finished"
      RegExp(r'mark\s+(.*?)\s+as\s+(done|complete|completed|finished)', caseSensitive: false): 1,
      // Pattern: "mark task [title] complete/done"
      RegExp(r'mark\s+task\s+(.*?)\s+(complete|completed|done)', caseSensitive: false): 1,
      // Pattern: "[action] [title]" - for commands starting with action
      RegExp(r'^(complete|finish|done|delete|remove|start|pause|cancel)\s+(.+)', caseSensitive: false): 2,
      // Pattern: "update [title]" - simple update command (must be last to avoid conflicts)
      RegExp(r'^update\s+(.+)', caseSensitive: false): 1,
    };

    for (var entry in patterns.entries) {
      final match = entry.key.firstMatch(command);
      if (match != null && match.groupCount >= entry.value) {
        final taskIdentifier = match.group(entry.value)?.trim();
        if (taskIdentifier != null && taskIdentifier.isNotEmpty) {
          print('VoiceParser: Pattern matched, extracted: "$taskIdentifier"');
          return taskIdentifier;
        }
      }
    }

    print('VoiceParser: No patterns matched, returning whole command: "$command"');
    return command; // Fallback to the whole command if no specific pattern matches
  }

  // Simplified task creation detection
  static bool isCreateTaskCommand(String command) {
    final lowerCommand = command.toLowerCase().trim();
    
    // Skip very short commands
    if (lowerCommand.length < 3) return false;
    
    // If it's not an update command, treat as creation
    return !_isUpdateCommand(lowerCommand);
  }

  // Simplified task title extraction
  static String extractTaskTitle(String command) {
    print('VoiceParser: Extracting title from: "$command"');
    String title = command.trim();
    
    // Remove wake words
    final wakeWords = ['hey whisp', 'hey whisper', 'hey wisp', 'whisp', 'whisper'];
    String lowerTitle = title.toLowerCase();
    
    for (String wake in wakeWords) {
      if (lowerTitle.startsWith('$wake ')) {
        title = title.substring(wake.length).trim();
        break;
      }
    }
    
    // Remove creation prefixes and reminder phrases
    final prefixes = [
      'add ', 'create ', 'new ', 'remind me to ', 'reminder to ', 
      'remember to ', 'don\'t forget to ', 'make sure to ', 'need to ',
      'have to ', 'should ', 'must '
    ];
    lowerTitle = title.toLowerCase();
    
    for (String prefix in prefixes) {
      if (lowerTitle.startsWith(prefix)) {
        title = title.substring(prefix.length).trim();
        lowerTitle = title.toLowerCase(); // Update for next iteration
        break;
      }
    }
    
    // Remove time-related suffixes that shouldn't be in the title
    final timeSuffixes = [
      RegExp(r'\s+at\s+\d{1,2}(?::\d{2})?\s*(?:am|pm|AM|PM)?.*$'),
      RegExp(r'\s+tomorrow.*$'),
      RegExp(r'\s+today.*$'),
      RegExp(r'\s+tonight.*$'),
      RegExp(r'\s+high priority.*$'),
      RegExp(r'\s+low priority.*$'),
      RegExp(r'\s+daily.*$'),
      RegExp(r'\s+weekly.*$'),
      RegExp(r'\s+monthly.*$'),
    ];
    
    for (RegExp suffix in timeSuffixes) {
      title = title.replaceFirst(suffix, '').trim();
    }
    
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    final finalTitle = title.isEmpty ? 'Voice Task' : title;
    print('VoiceParser: Final title: "$finalTitle"');
    return finalTitle;
  }

  // NEW: Correct common speech misinterpretations
  static String _correctSpeechMisinterpretations(String input) {
    final corrections = {
      // Common misheard words
      'bike': 'buy',
      'by': 'buy',
      'bye': 'buy',
      'bhai': 'buy',
      'bai': 'buy',
      'pie': 'buy',
      
      // Homework variations
      'omework': 'homework',
      'home work': 'homework',
      'homework': 'homework',
      
      // Grocery variations
      'groceries': 'groceries',
      'grocery': 'groceries',
      'grossery': 'groceries',
      'grosseries': 'groceries',
      
      // Communication
      'call mom': 'call mom',
      'call mum': 'call mom',
      'call mother': 'call mom',
      'email': 'email',
      'e-mail': 'email',
      'e mail': 'email',
      
      // Time words
      'tomorrow': 'tomorrow',
      'today': 'today',
      'tonight': 'tonight',
      'to day': 'today',
      'to night': 'tonight',
      'to morrow': 'tomorrow',
      
      // Common task words
      'meeting': 'meeting',
      'meting': 'meeting',
      'appointment': 'appointment',
      'apointment': 'appointment',
      'exercise': 'exercise',
      'excercise': 'exercise',
      'workout': 'workout',
      'work out': 'workout',
      
      // Action corrections
      'complete': 'complete',
      'complet': 'complete',
      'finish': 'finish',
      'finnish': 'finish',
      'done': 'done',
      'dun': 'done',
      'delete': 'delete',
      'delet': 'delete',
      'remove': 'remove',
      'remov': 'remove',
    };
    
    String corrected = input;
    corrections.forEach((wrong, correct) {
      corrected = corrected.replaceAll(RegExp(r'\b' + RegExp.escape(wrong) + r'\b'), correct);
    });
    
    return corrected;
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
    
    // Remove time-related suffixes (IMPROVED: More precise patterns)
    final timePatterns = [
      RegExp(r'\s+(at\s+\d+:\d+[^\w]*)$'), // "at 3:00 pm"
      RegExp(r'\s+(tomorrow)(?!\s+\w+)', caseSensitive: false), // "tomorrow" but not "tomorrow homework"
      RegExp(r'\s+(today)(?!\s+\w+)', caseSensitive: false), // "today" but not "today homework"  
      RegExp(r'\s+(tonight)(?!\s+\w+)', caseSensitive: false), // "tonight" but not "tonight homework"
      RegExp(r'\s+(in\s+\d+\s*(minutes?|hours?|days?))$'), // "in 30 minutes"
      RegExp(r'\s+(later)$'), // "later" at end
      RegExp(r'\s+(daily|weekly|monthly)$'), // recurring at end
      RegExp(r'^(tomorrow|today|tonight)\s+', caseSensitive: false), // Remove time words at start
    ];
    
    for (RegExp pattern in timePatterns) {
      title = title.replaceFirst(pattern, '');
    }
    
    // Remove priority words
    final priorityWords = ['urgent', 'important', 'high priority', 'low priority', 'asap'];
    for (String word in priorityWords) {
      title = title.replaceAll(word, '').trim();
    }
    
    // Remove duplicate words (fix "do do do homework" -> "do homework")
    title = _removeDuplicateWords(title);
    
    // Clean up extra spaces
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Remove common speech recognition artifacts
    title = _cleanSpeechArtifacts(title);
    
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    return title.trim().isEmpty ? 'New Voice Task' : title.trim();
  }

  // Remove duplicate consecutive words (fix "do do do homework" -> "do homework")
  static String _removeDuplicateWords(String text) {
    List<String> words = text.split(' ');
    List<String> cleanWords = [];
    
    for (int i = 0; i < words.length; i++) {
      String currentWord = words[i].toLowerCase();
      
      // Skip if this word is the same as the previous word
      if (cleanWords.isEmpty || cleanWords.last.toLowerCase() != currentWord) {
        cleanWords.add(words[i]);
      }
    }
    
    return cleanWords.join(' ');
  }

  // Clean common speech recognition artifacts
  static String _cleanSpeechArtifacts(String text) {
    String cleaned = text;
    
    // Remove common speech artifacts
    final artifacts = [
      RegExp(r'\b(um|uh|er|ah)\b', caseSensitive: false),
      RegExp(r'\b(like|you know)\b', caseSensitive: false),
      RegExp(r'\b(well|so)\s+', caseSensitive: false),
      RegExp(r'\s+(please|thanks?)\s*$', caseSensitive: false),
    ];
    
    for (RegExp artifact in artifacts) {
      cleaned = cleaned.replaceAll(artifact, ' ');
    }
    
    // Remove extra punctuation and clean spaces
    cleaned = cleaned.replaceAll(RegExp(r'[.,!?]+$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
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
    // Complete categories from manual task creation: 'general', 'work', 'personal', 'health', 'shopping', 'study'
    final categories = {
      'work': ['work', 'office', 'meeting', 'project', 'client', 'boss', 'job', 'business', 'conference', 'presentation', 'deadline', 'report'],
      'personal': ['personal', 'home', 'family', 'friend', 'call', 'visit', 'birthday', 'anniversary', 'relationship', 'social'],
      'health': ['health', 'doctor', 'medicine', 'exercise', 'gym', 'workout', 'appointment', 'checkup', 'therapy', 'dental', 'medical', 'fitness'],
      'shopping': ['buy', 'shop', 'grocery', 'store', 'purchase', 'groceries', 'market', 'mall', 'online', 'order', 'delivery'],
      'study': ['study', 'homework', 'assignment', 'exam', 'class', 'school', 'university', 'college', 'research', 'learn', 'course', 'education'],
    };
    
    for (String category in categories.keys) {
      for (String keyword in categories[category]!) {
        if (RegExp(r'\b' + keyword + r'\b', caseSensitive: false).hasMatch(input)) {
          return category;
        }
      }
    }
    
    return 'general'; // Default category
  }

  static String _extractPriority(String input) {
    // Using your string-based priority system: 'high', 'medium', 'low'
    if (input.contains('urgent') || input.contains('asap') || input.contains('emergency') || 
        input.contains('important') || input.contains('high priority') || input.contains('critical')) {
      return 'high';
    } else if (input.contains('low priority') || input.contains('when i have time') || input.contains('sometime')) {
      return 'low';
    }
    return 'medium'; // Default priority
  }

  static String? _extractRecurringPattern(String input) {
    // Daily patterns
    if (input.contains('daily') || input.contains('every day') || 
        input.contains('each day') || input.contains('everyday')) {
      return 'daily';
    }
    
    // Weekly patterns
    if (input.contains('weekly') || input.contains('every week') || 
        input.contains('each week') || input.contains('once a week') ||
        input.contains('once weekly')) {
      return 'weekly';
    }
    
    // Monthly patterns
    if (input.contains('monthly') || input.contains('every month') || 
        input.contains('each month') || input.contains('once a month') ||
        input.contains('once monthly')) {
      return 'monthly';
    }
    
    // Yearly patterns
    if (input.contains('yearly') || input.contains('every year') || 
        input.contains('each year') || input.contains('annually') ||
        input.contains('once a year')) {
      return 'yearly';
    }
    
    return null;
  }

  static int? _extractRecurringInterval(String input) {
    // Look for patterns like "every 2 days", "every 3 weeks", etc.
    final intervalMatch = RegExp(r'every\s+(\d+)\s+(day|week|month|year)', caseSensitive: false).firstMatch(input);
    if (intervalMatch != null) {
      return int.tryParse(intervalMatch.group(1)!) ?? 1;
    }
    
    // Look for patterns like "every other day", "every second week"
    if (input.contains('every other') || input.contains('every second')) {
      return 2;
    } else if (input.contains('every third')) {
      return 3;
    } else if (input.contains('every fourth')) {
      return 4;
    }
    
    // Look for patterns like "twice daily", "three times weekly"
    if (input.contains('twice') || input.contains('2 times')) {
      return 2;
    } else if (input.contains('three times') || input.contains('3 times')) {
      return 3;
    } else if (input.contains('four times') || input.contains('4 times')) {
      return 4;
    }
    
    // Look for number words
    final numberWords = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10
    };
    
    for (final entry in numberWords.entries) {
      if (input.contains('every ${entry.key}')) {
        return entry.value;
      }
    }
    
    // Default to 1 if recurring pattern is detected
    return 1;
  }

  static String? _extractColor(String input) {
    // Complete colors from manual task creation: 'red', 'pink', 'purple', 'indigo', 'blue', 'cyan', 'teal', 'green', 'yellow', 'orange'
    final colorMap = {
      'red': ['red', 'urgent', 'important', 'critical'],
      'pink': ['pink', 'rose', 'magenta'],
      'purple': ['purple', 'violet', 'study', 'learning'],
      'indigo': ['indigo', 'dark blue', 'navy'],
      'blue': ['blue', 'work', 'business', 'office'],
      'cyan': ['cyan', 'light blue', 'aqua'],
      'teal': ['teal', 'turquoise', 'blue green'],
      'green': ['green', 'health', 'fitness', 'nature'],
      'yellow': ['yellow', 'personal', 'bright', 'sunny'],
      'orange': ['orange', 'shopping', 'warm', 'energy'],
    };
    
    for (String color in colorMap.keys) {
      for (String keyword in colorMap[color]!) {
        if (RegExp(r'\b' + keyword.replaceAll(' ', r'\s+') + r'\b', caseSensitive: false).hasMatch(input)) {
          return color;
        }
      }
    }
    
    return 'blue'; // Default color to match manual task creation
  }

  // NEW: Comprehensive validation for voice commands
  static ValidationResult validateVoiceCommand(String command) {
    final cleanCommand = command.toLowerCase().trim();
    
    // Check for empty or too short commands
    if (cleanCommand.length < 2) {
      return ValidationResult(
        isValid: false,
        errorType: 'too_short',
        suggestion: 'Please speak a longer command'
      );
    }
    
    // Check for incomplete fragments
    final fragmentPatterns = [
      RegExp(r'^(um|uh|er|ah|well|so|now|then)$', caseSensitive: false),
      RegExp(r'^(by|to|for|with|in|on|at)$', caseSensitive: false),
      RegExp(r'^\w{1,2}$'), // Single letters or very short words
      RegExp(r'^(the|a|an|this|that)$', caseSensitive: false), // Articles only
      RegExp(r'^(and|or|but|if|when|where)$', caseSensitive: false), // Conjunctions only
    ];
    
    for (final pattern in fragmentPatterns) {
      if (pattern.hasMatch(cleanCommand)) {
        return ValidationResult(
          isValid: false,
          errorType: 'incomplete_fragment',
          suggestion: 'Command seems incomplete. Please try again.'
        );
      }
    }
    
    // Check for ambiguous time-only commands
    final timeOnlyPatterns = [
      RegExp(r'^(tomorrow|today|tonight|later|soon)$', caseSensitive: false),
      RegExp(r'^(morning|afternoon|evening|night)$', caseSensitive: false),
      RegExp(r'^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$', caseSensitive: false),
    ];
    
    for (final pattern in timeOnlyPatterns) {
      if (pattern.hasMatch(cleanCommand)) {
        return ValidationResult(
          isValid: false,
          errorType: 'time_only',
          suggestion: 'Please specify what task is due $cleanCommand'
        );
      }
    }
    
    // Check for nonsensical combinations
    final nonsensicalPatterns = [
      'buy homework', 'bike homework', 'homework buy', 'homework bike',
      'call groceries', 'email homework', 'study groceries',
      'work tomorrow homework', 'buy study', 'call buy'
    ];
    
    for (final pattern in nonsensicalPatterns) {
      if (cleanCommand.contains(pattern)) {
        return ValidationResult(
          isValid: false,
          errorType: 'nonsensical',
          suggestion: 'That combination doesn\'t make sense. Please clarify your command.'
        );
      }
    }
    
    // Check for repeated words (speech recognition glitch)
    final words = cleanCommand.split(' ');
    if (words.length >= 3) {
      final repeatedWord = words.where((word) => 
        words.where((w) => w == word).length >= 3).firstOrNull;
      if (repeatedWord != null) {
        return ValidationResult(
          isValid: false,
          errorType: 'repeated_words',
          suggestion: 'I heard repeated words. Please try again.'
        );
      }
    }
    
    // Check for conflicting actions in same command
    final actionWords = ['complete', 'start', 'pause', 'delete', 'create', 'add'];
    final foundActions = actionWords.where((action) => cleanCommand.contains(action)).toList();
    if (foundActions.length > 1) {
      return ValidationResult(
        isValid: false,
        errorType: 'conflicting_actions',
        suggestion: 'Please specify one action at a time.'
      );
    }
    
    // Check for extremely long commands (likely speech recognition error)
    if (cleanCommand.length > 100) {
      return ValidationResult(
        isValid: false,
        errorType: 'too_long',
        suggestion: 'Command too long. Please speak more concisely.'
      );
    }
    
    // Check for commands with only numbers or special characters
    if (RegExp(r'^[\d\s\-\.\,\!\?\;]+$').hasMatch(cleanCommand)) {
      return ValidationResult(
        isValid: false,
        errorType: 'invalid_content',
        suggestion: 'Please speak a clear task command.'
      );
    }
    
    return ValidationResult(isValid: true);
  }

  // Create task from any reasonable speech
  static Task createTaskFromSpeech(String speech) {
    print('VoiceParser: 🚀 CREATE TASK FROM SPEECH: "$speech"');
    final title = extractTaskTitle(speech);
    print('VoiceParser: 📝 EXTRACTED TITLE: "$title"');
    final cleanSpeech = speech.toLowerCase();
    
    // Extract due date with time
    DateTime? dueDate;
    final now = DateTime.now();
    
    // Check for specific times first
    final timeRegex = RegExp(r'at (\d{1,2})(?::(\d{2}))?\s*(am|pm|AM|PM)?');
    final timeMatch = timeRegex.firstMatch(cleanSpeech);
    
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
      String? ampm = timeMatch.group(3)?.toLowerCase();
      
      // Convert to 24-hour format
      if (ampm == 'pm' && hour != 12) {
        hour += 12;
      } else if (ampm == 'am' && hour == 12) {
        hour = 0;
      } else if (ampm == null && hour <= 12) {
        // Assume PM for times 1-12 without AM/PM specified
        if (hour < 8) hour += 12; // 1-7 likely PM, 8-12 likely AM/PM as specified
      }
      
      if (cleanSpeech.contains('tomorrow')) {
        final tomorrow = now.add(Duration(days: 1));
        dueDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
      } else {
        // Default to today
        dueDate = DateTime(now.year, now.month, now.day, hour, minute);
        // If the time has already passed today, schedule for tomorrow
        if (dueDate.isBefore(now)) {
          final tomorrow = now.add(Duration(days: 1));
          dueDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
        }
      }
    } else {
      // Fallback to general date detection
      if (cleanSpeech.contains('tomorrow')) {
        final tomorrow = now.add(Duration(days: 1));
        dueDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);
      } else if (cleanSpeech.contains('today')) {
        dueDate = DateTime(now.year, now.month, now.day, 23, 59);
      } else if (cleanSpeech.contains('tonight')) {
        dueDate = DateTime(now.year, now.month, now.day, 20, 0);
      }
    }
    
    // Smart category detection
    String category = 'general';
    if (cleanSpeech.contains('homework') || cleanSpeech.contains('study') || cleanSpeech.contains('assignment') || 
        cleanSpeech.contains('project') || cleanSpeech.contains('submit') || cleanSpeech.contains('research')) {
      category = 'work';
    } else if (cleanSpeech.contains('buy') || cleanSpeech.contains('grocery') || cleanSpeech.contains('groceries') || 
               cleanSpeech.contains('shopping') || cleanSpeech.contains('purchase')) {
      category = 'shopping';
    } else if (cleanSpeech.contains('work') || cleanSpeech.contains('meeting') || cleanSpeech.contains('office') ||
               cleanSpeech.contains('bills') || cleanSpeech.contains('pay bills')) {
      category = 'work';
    } else if (cleanSpeech.contains('call') || cleanSpeech.contains('email') || cleanSpeech.contains('message') ||
               cleanSpeech.contains('mom') || cleanSpeech.contains('family') || cleanSpeech.contains('friend')) {
      category = 'personal';
    } else if (cleanSpeech.contains('exercise') || cleanSpeech.contains('gym') || cleanSpeech.contains('workout') ||
               cleanSpeech.contains('fitness') || cleanSpeech.contains('health')) {
      category = 'health';
    }
    
    // Smart priority detection
    String priority = 'medium';
    if (cleanSpeech.contains('urgent') || cleanSpeech.contains('important') || cleanSpeech.contains('asap') || 
        cleanSpeech.contains('high priority') || cleanSpeech.contains('high') || cleanSpeech.contains('critical')) {
      priority = 'high';
    } else if (cleanSpeech.contains('low priority') || cleanSpeech.contains('low')) {
      priority = 'low';
    }
    
    // Smart recurring pattern detection
    String? recurringPattern = _extractRecurringPattern(cleanSpeech);
    int? recurringInterval = _extractRecurringInterval(cleanSpeech);
    bool isRecurring = recurringPattern != null;
    
    // Extract color
    String? color = _extractColor(cleanSpeech);
    
    // Extract description
    String? description = _extractDescription(cleanSpeech);
    
    // Extract reminder information
    bool hasReminder = _extractHasReminder(cleanSpeech);
    DateTime? reminderTime = _extractReminderTime(cleanSpeech, dueDate);
    String reminderType = _extractReminderType(cleanSpeech);
    int reminderMinutesBefore = _extractReminderMinutesBefore(cleanSpeech);
    String notificationTone = _extractNotificationTone(cleanSpeech);
    List<String> repeatDays = _extractRepeatDays(cleanSpeech);
    
    // CRITICAL: Auto-fix reminder inconsistencies
    if (hasReminder && reminderTime == null) {
      // If user wants reminder but no specific time, set default
      reminderTime = dueDate ?? DateTime.now().add(Duration(hours: 1));
    } else if (!hasReminder) {
      // If no reminder requested, clear all reminder fields
      reminderTime = null;
      reminderType = 'once';
      reminderMinutesBefore = 0;
      repeatDays = [];
    }
    
    final task = Task(
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      category: category,
      priority: priority,
      color: color,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      recurringInterval: isRecurring ? (recurringInterval ?? 1) : null,
      status: 'pending',
      // Reminder fields
      hasReminder: hasReminder,
      reminderTime: reminderTime,
      reminderType: reminderType,
      reminderMinutesBefore: reminderMinutesBefore,
      notificationTone: notificationTone,
      repeatDays: repeatDays,
      isReminderActive: hasReminder,
      // Initialize empty collections for voice notes and attachments
      voiceNotes: [],
      attachments: [],
      hasVoiceNotes: false,
      hasAttachments: false,
    );
    
    // FINAL VALIDATION: Ensure all critical fields are properly set
    final validatedTask = _validateAndFixTask(task);
    
    print('VoiceParser: ✅ CREATED TASK OBJECT: "${validatedTask.title}" | Category: ${validatedTask.category} | Priority: ${validatedTask.priority} | Recurring: $isRecurring ($recurringPattern every ${validatedTask.recurringInterval})');
    return validatedTask;
  }

  // Extract reminder information from voice input
  static bool _extractHasReminder(String input) {
    final reminderPatterns = [
      r'\bremind\s+me\b',
      r'\bset\s+reminder\b',
      r'\bnotify\s+me\b',
      r'\balert\s+me\b',
      r'\bnotification\b',
      r'\breminder\b',
      r'\balarm\b',
    ];
    
    for (final pattern in reminderPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  static DateTime? _extractReminderTime(String input, DateTime? dueDate) {
    // If no reminder keywords, return null
    if (!_extractHasReminder(input)) return null;
    
    final now = DateTime.now();
    
    // Check for specific time patterns
    final timePatterns = [
      // "remind me at 3pm", "notify at 9am"
      RegExp(r'\b(?:at|@)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b', caseSensitive: false),
      // "remind me in 30 minutes"
      RegExp(r'\bin\s+(\d+)\s*(?:minute|min)s?\b', caseSensitive: false),
      // "remind me in 2 hours"
      RegExp(r'\bin\s+(\d+)\s*(?:hour|hr)s?\b', caseSensitive: false),
      // "remind me 15 minutes before"
      RegExp(r'(\d+)\s*(?:minute|min)s?\s+before\b', caseSensitive: false),
    ];
    
    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        if (pattern.pattern.contains('at|@')) {
          // Specific time (3pm, 9am)
          final hour = int.parse(match.group(1)!);
          final minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
          final ampm = match.group(3)!.toLowerCase();
          
          var adjustedHour = hour;
          if (ampm == 'pm' && hour != 12) adjustedHour += 12;
          if (ampm == 'am' && hour == 12) adjustedHour = 0;
          
          return DateTime(now.year, now.month, now.day, adjustedHour, minute);
        } else if (pattern.pattern.contains('in.*minute')) {
          // In X minutes
          final minutes = int.parse(match.group(1)!);
          return now.add(Duration(minutes: minutes));
        } else if (pattern.pattern.contains('in.*hour')) {
          // In X hours
          final hours = int.parse(match.group(1)!);
          return now.add(Duration(hours: hours));
        } else if (pattern.pattern.contains('before')) {
          // X minutes before due date
          if (dueDate != null) {
            final minutes = int.parse(match.group(1)!);
            return dueDate.subtract(Duration(minutes: minutes));
          }
        }
      }
    }
    
    // Default: if due date exists, remind 30 minutes before
    if (dueDate != null) {
      return dueDate.subtract(const Duration(minutes: 30));
    }
    
    // Default: remind in 1 hour
    return now.add(const Duration(hours: 1));
  }

  static String _extractReminderType(String input) {
    if (RegExp(r'\bdaily\b', caseSensitive: false).hasMatch(input)) return 'daily';
    if (RegExp(r'\bweekly\b', caseSensitive: false).hasMatch(input)) return 'weekly';
    if (RegExp(r'\bmonthly\b', caseSensitive: false).hasMatch(input)) return 'monthly';
    return 'once'; // Default
  }

  static int _extractReminderMinutesBefore(String input) {
    final patterns = [
      RegExp(r'(\d+)\s*(?:minute|min)s?\s+before\b', caseSensitive: false),
      RegExp(r'(\d+)\s*(?:hour|hr)s?\s+before\b', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final number = int.parse(match.group(1)!);
        if (pattern.pattern.contains('hour')) {
          return number * 60; // Convert hours to minutes
        }
        return number;
      }
    }
    
    return 30; // Default: 30 minutes before
  }

  static String _extractNotificationTone(String input) {
    if (RegExp(r'\bchime\b', caseSensitive: false).hasMatch(input)) return 'chime';
    if (RegExp(r'\bbell\b', caseSensitive: false).hasMatch(input)) return 'bell';
    if (RegExp(r'\bwhistle\b', caseSensitive: false).hasMatch(input)) return 'whistle';
    if (RegExp(r'\balarm\b', caseSensitive: false).hasMatch(input)) return 'alarm';
    return 'default';
  }

  // Extract description from voice input
  static String? _extractDescription(String input) {
    // Look for description patterns
    final descriptionPatterns = [
      RegExp(r'\bdescription[:\s]+(.+?)(?:\s+(?:due|remind|priority|category|color)|$)', caseSensitive: false),
      RegExp(r'\bdetails[:\s]+(.+?)(?:\s+(?:due|remind|priority|category|color)|$)', caseSensitive: false),
      RegExp(r'\bnotes?[:\s]+(.+?)(?:\s+(?:due|remind|priority|category|color)|$)', caseSensitive: false),
      RegExp(r'\babout[:\s]+(.+?)(?:\s+(?:due|remind|priority|category|color)|$)', caseSensitive: false),
      // Pattern for "task title with description additional details"
      RegExp(r'\bwith\s+(?:description|details|notes?)\s+(.+?)(?:\s+(?:due|remind|priority|category|color)|$)', caseSensitive: false),
    ];
    
    for (final pattern in descriptionPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    
    return null; // No description found
  }

  // Extract repeat days for weekly reminders
  static List<String> _extractRepeatDays(String input) {
    final days = <String>[];
    
    // Check for specific days mentioned
    final dayPatterns = {
      'monday': ['monday', 'mon'],
      'tuesday': ['tuesday', 'tue'],
      'wednesday': ['wednesday', 'wed'],
      'thursday': ['thursday', 'thu'],
      'friday': ['friday', 'fri'],
      'saturday': ['saturday', 'sat'],
      'sunday': ['sunday', 'sun'],
    };
    
    for (final entry in dayPatterns.entries) {
      for (final dayVariant in entry.value) {
        if (RegExp(r'\b' + dayVariant + r'\b', caseSensitive: false).hasMatch(input)) {
          days.add(entry.key.substring(0, 3)); // Add 3-letter abbreviation
          break;
        }
      }
    }
    
    // Check for common patterns
    if (RegExp(r'\bweekdays?\b', caseSensitive: false).hasMatch(input)) {
      days.addAll(['mon', 'tue', 'wed', 'thu', 'fri']);
    }
    if (RegExp(r'\bweekends?\b', caseSensitive: false).hasMatch(input)) {
      days.addAll(['sat', 'sun']);
    }
    if (RegExp(r'\bevery\s+day\b', caseSensitive: false).hasMatch(input)) {
      days.addAll(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']);
    }
    
    return days.toSet().toList(); // Remove duplicates
  }

  // CRITICAL: Validate and fix task to ensure all fields are properly set
  static Task _validateAndFixTask(Task task) {
    // Validate and fix priority
    final validPriorities = ['high', 'medium', 'low'];
    String fixedPriority = task.priority.toLowerCase();
    if (!validPriorities.contains(fixedPriority)) {
      fixedPriority = 'medium'; // Default fallback
    }
    
    // Validate and fix category
    final validCategories = ['general', 'work', 'personal', 'shopping', 'health', 'study', 'finance'];
    String fixedCategory = task.category.toLowerCase();
    if (!validCategories.contains(fixedCategory)) {
      fixedCategory = 'general'; // Default fallback
    }
    
    // Validate and fix recurring fields
    String? fixedRecurringPattern = task.recurringPattern?.toLowerCase();
    int? fixedRecurringInterval = task.recurringInterval;
    
    if (task.isRecurring) {
      final validPatterns = ['daily', 'weekly', 'monthly', 'yearly'];
      if (fixedRecurringPattern == null || !validPatterns.contains(fixedRecurringPattern)) {
        fixedRecurringPattern = 'daily'; // Default fallback
      }
      if (fixedRecurringInterval == null || fixedRecurringInterval <= 0) {
        fixedRecurringInterval = 1; // Default interval
      }
    } else {
      fixedRecurringPattern = null;
      fixedRecurringInterval = null;
    }
    
    // Validate and fix reminder type
    String fixedReminderType = task.reminderType.toLowerCase();
    final validReminderTypes = ['once', 'daily', 'weekly', 'monthly'];
    if (!validReminderTypes.contains(fixedReminderType)) {
      fixedReminderType = 'once'; // Default fallback
    }
    
    // Return validated task
    return task.copyWith(
      priority: fixedPriority,
      category: fixedCategory,
      recurringPattern: fixedRecurringPattern,
      recurringInterval: fixedRecurringInterval,
      reminderType: fixedReminderType,
    );
  }

  // Validate parsed task
  static bool isValidTask(Task task) {
    return task.title.isNotEmpty && 
           task.title != 'New Voice Task' && 
           task.title.length > 2;
  }
}

// NEW: Task update command data class
class TaskUpdateCommand {
  final TaskUpdateAction action;
  final String taskIdentifier;
  final Map<String, dynamic> parameters;

  TaskUpdateCommand({
    required this.action,
    required this.taskIdentifier,
    required this.parameters,
  });

  @override
  String toString() {
    return 'TaskUpdateCommand(action: $action, identifier: $taskIdentifier, params: $parameters)';
  }
}

// NEW: Available update actions
enum TaskUpdateAction {
  markComplete,
  start,
  pause,
  cancel,
  delete,
  changePriority,
}

// NEW: Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorType;
  final String? suggestion;

  ValidationResult({
    required this.isValid,
    this.errorType,
    this.suggestion,
  });
}
