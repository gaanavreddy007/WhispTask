import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/voice_parser.dart';

class VoiceTestRunner {
  static void runParsingTests() {
    if (kDebugMode) {
      print('\n=== WHISPTASK VOICE PARSING TESTS ===\n');
    }
    
    final testCases = [
      {
        'input': 'Buy groceries',
        'expectedTitle': 'Buy groceries',
        'expectedCategory': 'shopping',
        'expectedPriority': 'medium'
      },
      {
        'input': 'Urgent doctor appointment tomorrow',
        'expectedTitle': 'Doctor appointment',
        'expectedCategory': 'health',
        'expectedPriority': 'high'
      },
      {
        'input': 'Call mom at 6 PM',
        'expectedTitle': 'Call mom',
        'expectedCategory': 'personal',
        'expectedPriority': 'medium'
      },
      {
        'input': 'Exercise at gym daily',
        'expectedTitle': 'Exercise at gym',
        'expectedCategory': 'health',
        'expectedPriority': 'medium'
      },
      {
        'input': 'Important work meeting weekly',
        'expectedTitle': 'Work meeting',
        'expectedCategory': 'work',
        'expectedPriority': 'high'
      },
    ];

    for (var testCase in testCases) {
      final task = VoiceParser.parseVoiceToTask(testCase['input'] as String);
      final passed = _validateTask(task, testCase);
      
      if (kDebugMode) {
        print('${passed ? "✅" : "❌"} "${testCase['input']}"');
      }
      if (kDebugMode) {
        print('   Result: ${task.title} | ${task.category} | ${task.priority}');
      }
      // ignore: curly_braces_in_flow_control_structures
      if (task.isRecurring) if (kDebugMode) {
        print('   Recurring: ${task.recurringPattern}');
      }
      // ignore: curly_braces_in_flow_control_structures
      if (task.dueDate != null) if (kDebugMode) {
        print('   Due: ${task.dueDate}');
      }
      if (kDebugMode) {
        print('');
      }
    }
  }

  static bool _validateTask(Task task, Map<String, dynamic> expected) {
    return task.title.toLowerCase().contains((expected['expectedTitle'] as String).toLowerCase()) &&
           task.category == expected['expectedCategory'] &&
           task.priority == expected['expectedPriority'];
  }
}