// ignore_for_file: avoid_print, unnecessary_string_escapes

import 'package:flutter/material.dart';

import '../models/task.dart';

class VoiceParser {
  // Parse voice input into task object
  static Task parseVoiceToTask(String voiceInput) {
    final cleanInput = _correctSpeechMisinterpretations(voiceInput.trim().toLowerCase());
    
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

  // ULTRA-AGGRESSIVE: Enhanced command parsing that interprets ANY speech
  static Map<String, dynamic> parseVoiceCommand(String command) {
    String cleanCommand = command.toLowerCase().trim();
    print('VoiceParser: Parsing command: "$cleanCommand"');
    
    // Remove wake word if present
    cleanCommand = cleanCommand.replaceAll(RegExp(r'^(hey whisp,?\s*|whisp,?\s*)'), '');
    
    // First check explicit task update commands
    if (isTaskUpdateCommand(cleanCommand)) {
      print('VoiceParser: Detected as task update command');
      return {
        'type': 'task_update',
        'action': extractAction(cleanCommand),
        'taskIdentifier': extractTaskIdentifierFromCommand(cleanCommand),
        'originalCommand': command
      };
    }
    
    // Check explicit task creation commands
    if (isCreateTaskCommand(cleanCommand)) {
      print('VoiceParser: Detected as task creation command');
      return {
        'type': 'create_task',
        'title': extractTaskTitle(cleanCommand),
        'originalCommand': command
      };
    }
    
    // FALLBACK: Try to interpret ANY speech as either task creation or update
    print('VoiceParser: Using fallback interpretation');
    return _interpretAnySpeedAsCommand(cleanCommand, command);
  }
  
  // NEW: Interpret any speech as a potential command with smart task detection
  static Map<String, dynamic> _interpretAnySpeedAsCommand(String cleanCommand, String originalCommand) {
    // First validate the command
    final validation = validateVoiceCommand(originalCommand);
    if (!validation.isValid) {
      return {
        'type': 'error',
        'errorType': validation.errorType,
        'suggestion': validation.suggestion,
        'originalCommand': originalCommand
      };
    }
    
    // Check if this could be updating an existing task (contains time/date words)
    // This should catch "homework tomorrow", "home tomorrow", "buy groceries tomorrow", etc.
    if (_containsTimeWords(cleanCommand)) {
      // Extract potential task name
      final taskName = _extractTaskFromTimeCommand(cleanCommand);
      
      print('VoiceParser: Time-based command detected. Task name: "$taskName"');
      
      // If we have a meaningful task name OR contains task keywords, treat as update
      if ((taskName.isNotEmpty && taskName != 'task' && taskName.length > 2) || 
          _containsTaskKeywords(cleanCommand)) {
        print('VoiceParser: Routing to task update with setDueDate action');
        return {
          'type': 'task_update',
          'action': 'setDueDate',
          'taskIdentifier': taskName.isNotEmpty ? taskName : _extractTaskFromTimeCommand(cleanCommand),
          'dueDate': _extractTimeFromCommand(cleanCommand),
          'originalCommand': originalCommand
        };
      }
    }
    
    // If it contains action words, treat as task update
    if (_containsActionWords(cleanCommand)) {
      return {
        'type': 'task_update',
        'action': _guessActionFromSpeech(cleanCommand),
        'taskIdentifier': _guessTaskFromSpeech(cleanCommand),
        'originalCommand': originalCommand
      };
    }
    
    // Otherwise, treat as task creation
    return {
      'type': 'create_task',
      'title': _cleanSpeechAsTaskTitle(cleanCommand),
      'originalCommand': originalCommand
    };
  }
  
  // Check if speech contains action words
  static bool _containsActionWords(String speech) {
    final actionWords = [
      'complete', 'finish', 'done', 'mark', 'set',
      'start', 'begin', 'resume', 'pause', 'stop',
      'cancel', 'delete', 'remove', 'priority',
      'first', 'second', 'third', 'last', 'next'
    ];
    
    return actionWords.any((word) => speech.contains(word));
  }
  
  // Check if speech contains time/date words
  static bool _containsTimeWords(String speech) {
    final timeWords = [
      'tomorrow', 'today', 'tonight', 'yesterday',
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
      'morning', 'afternoon', 'evening', 'night',
      'next week', 'this week', 'next month', 'this month',
      'due', 'deadline', 'by'
    ];
    
    return timeWords.any((word) => speech.contains(word));
  }
  
  // Check if speech contains common task keywords
  static bool _containsTaskKeywords(String speech) {
    final taskKeywords = [
      'homework', 'assignment', 'project', 'work', 'study',
      'groceries', 'shopping', 'buy', 'purchase',
      'meeting', 'appointment', 'call', 'email',
      'exercise', 'workout', 'gym', 'run',
      'clean', 'laundry', 'dishes', 'cook',
      'read', 'book', 'article', 'paper',
      'home', 'house', 'office', 'school'
    ];
    
    return taskKeywords.any((word) => speech.contains(word));
  }
  
  // Extract task name from time-based command
  static String _extractTaskFromTimeCommand(String speech) {
    // Remove time words to isolate task name
    final timeWords = [
      'tomorrow', 'today', 'tonight', 'yesterday',
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
      'morning', 'afternoon', 'evening', 'night',
      'next week', 'this week', 'next month', 'this month',
      'due', 'deadline', 'by'
    ];
    
    String taskName = speech;
    for (String word in timeWords) {
      taskName = taskName.replaceAll(word, ' ');
    }
    
    // Remove articles, action words, and clean up
    taskName = taskName.replaceAll(RegExp(r'\b(the|my|a|an|this|that|task|is|buy|update|create|add|make|do)\b'), ' ');
    taskName = taskName.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return taskName.isNotEmpty ? taskName : 'task';
  }
  
  // Extract time/date from command
  static String _extractTimeFromCommand(String speech) {
    final timePatterns = {
      'tomorrow': 'tomorrow',
      'today': 'today', 
      'tonight': 'tonight',
      'monday': 'monday',
      'tuesday': 'tuesday',
      'wednesday': 'wednesday',
      'thursday': 'thursday',
      'friday': 'friday',
      'saturday': 'saturday',
      'sunday': 'sunday',
      'next week': 'next week',
      'this week': 'this week'
    };
    
    for (String pattern in timePatterns.keys) {
      if (speech.contains(pattern)) {
        return timePatterns[pattern]!;
      }
    }
    
    return 'tomorrow'; // Default fallback
  }
  
  // Guess action from any speech
  static String _guessActionFromSpeech(String speech) {
    if (speech.contains('complete') || speech.contains('finish') || speech.contains('done')) {
      return 'complete';
    }
    if (speech.contains('start') || speech.contains('begin')) {
      return 'start';
    }
    if (speech.contains('pause') || speech.contains('stop')) {
      return 'pause';
    }
    if (speech.contains('cancel') || speech.contains('delete') || speech.contains('remove')) {
      return 'delete';
    }
    if (speech.contains('priority')) {
      return 'changePriority';
    }
    // Default to complete for any unclear action
    return 'complete';
  }
  
  // Guess task identifier from speech
  static String _guessTaskFromSpeech(String speech) {
    // Remove action words to isolate task identifier
    final actionWords = ['complete', 'finish', 'done', 'mark', 'set', 'start', 'begin', 'pause', 'stop', 'cancel', 'delete', 'remove'];
    String taskPart = speech;
    
    for (String word in actionWords) {
      taskPart = taskPart.replaceAll(word, ' ');
    }
    
    // Remove common articles
    taskPart = taskPart.replaceAll(RegExp(r'\b(the|my|a|an|this|that|task)\b'), ' ');
    taskPart = taskPart.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Handle numbered references
    if (taskPart.contains('first') || taskPart.contains('1')) return '#1';
    if (taskPart.contains('second') || taskPart.contains('2')) return '#2';
    if (taskPart.contains('third') || taskPart.contains('3')) return '#3';
    
    return taskPart.isNotEmpty ? taskPart : '#1';
  }
  
  // Clean any speech as task title
  static String _cleanSpeechAsTaskTitle(String speech) {
    // Apply speech corrections first
    String title = _correctSpeechMisinterpretations(speech);
    
    // Remove common prefixes that might be misheard
    final prefixes = ['hey', 'ok', 'um', 'uh', 'so', 'well', 'now'];
    
    for (String prefix in prefixes) {
      if (title.startsWith('$prefix ')) {
        title = title.substring(prefix.length + 1);
      }
    }
    
    // Remove time words that shouldn't be in title (improved logic)
    final timeWords = ['tomorrow', 'today', 'tonight', 'later', 'soon'];
    for (String timeWord in timeWords) {
      // Remove time word at start: "tomorrow homework" -> "homework"
      if (title.startsWith('$timeWord ')) {
        title = title.substring(timeWord.length + 1).trim();
      }
      // Remove time word at end: "homework tomorrow" -> "homework"
      else if (title.endsWith(' $timeWord')) {
        title = title.substring(0, title.length - timeWord.length - 1).trim();
      }
      // If only time word, use default
      else if (title.trim() == timeWord) {
        title = 'Voice Task';
      }
    }
    
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    return title.trim().isEmpty ? 'Voice Task' : title.trim();
  }

  // Enhanced task update command detection
  static bool isTaskUpdateCommandEnhanced(String command) {
    final patterns = [
      r'mark\s+.*\s+as\s+(done|complete|finished)',
      r'complete\s+.*',
      r'finish\s+.*',
      r'mark\s+task\s+.*\s+(complete|done)',
      r'(done|complete|finish)\s+.*',
    ];
    
    return patterns.any((pattern) => RegExp(pattern).hasMatch(command));
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

  // More selective task creation detection
  static bool isCreateTaskCommand(String command) {
    final lowerCommand = command.toLowerCase().trim();
    
    // Skip very short or likely incomplete commands
    if (lowerCommand.length < 3 || lowerCommand.split(' ').length < 2) {
      return false;
    }
    
    // Skip commands that are likely speech fragments or incomplete
    final fragmentPatterns = [
      RegExp(r'^(by|to|for|with|in|on|at)\s+\w+$', caseSensitive: false), // "by today", "to work"
      RegExp(r'^\w{1,2}$'), // Single letters or very short words
      RegExp(r'^(um|uh|er|ah|well|so|now|then)(\s+\w+)?$', caseSensitive: false), // Filler words
    ];
    
    for (final pattern in fragmentPatterns) {
      if (pattern.hasMatch(lowerCommand)) {
        return false;
      }
    }
    
    // Explicit task creation indicators
    final creationKeywords = [
      'add', 'create', 'new', 'remind me', 'remember to', 'need to', 'have to',
      'buy', 'call', 'email', 'visit', 'go to', 'pick up', 'drop off'
    ];
    
    final hasCreationKeyword = creationKeywords.any((keyword) => 
        lowerCommand.startsWith(keyword) || lowerCommand.contains(' $keyword '));
    
    // If it has creation keywords or is a substantial command (3+ words), treat as creation
    return hasCreationKeyword || lowerCommand.split(' ').length >= 3;
  }

  // ULTRA-AGGRESSIVE: Extract task title from ANY speech
  static String extractTaskTitle(String command) {
    String title = _correctSpeechMisinterpretations(command.toLowerCase().trim());
    
    // Remove task creation prefixes if present
    final prefixes = [
      'add task', 'create task', 'new task', 'remind me to',
      'hey whisp', 'whisp', 'whisper', 'hey', 'ok', 'um', 'uh'
    ];
    
    for (String prefix in prefixes) {
      if (title.startsWith(prefix)) {
        title = title.substring(prefix.length).trim();
      }
    }
    
    // Remove time words that shouldn't be in title (improved logic)
    final timeWords = ['tomorrow', 'today', 'tonight', 'later', 'soon'];
    for (String timeWord in timeWords) {
      // Remove time word at start: "tomorrow homework" -> "homework"
      if (title.startsWith('$timeWord ')) {
        title = title.substring(timeWord.length + 1).trim();
      }
      // Remove time word at end: "homework tomorrow" -> "homework"
      else if (title.endsWith(' $timeWord')) {
        title = title.substring(0, title.length - timeWord.length - 1).trim();
      }
      // If only time word, use default
      else if (title.trim() == timeWord) {
        title = 'Voice Task';
      }
    }
    
    // Clean up and capitalize
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    return title.isEmpty ? 'Voice Task' : title;
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
    
    // Clean up extra spaces
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    
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
    if (input.contains('urgent') || input.contains('asap') || input.contains('emergency') || 
        input.contains('important') || input.contains('high priority') || input.contains('critical')) {
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
    } else if (input.contains('yearly') || input.contains('every year')) {
      return 'yearly';
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