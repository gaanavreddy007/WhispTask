import 'package:flutter_test/flutter_test.dart';
import 'package:whisptask/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('Should create task with required fields', () {
      final task = Task(
        title: 'Test Task',
        createdAt: DateTime.now(),
      );

      expect(task.title, 'Test Task');
      expect(task.isCompleted, false);
      expect(task.priority, 'medium');
      expect(task.category, 'general');
      expect(task.isRecurring, false);
    });

    test('Should create task with all fields', () {
      final now = DateTime.now();
      final dueDate = now.add(const Duration(hours: 1));
      
      final task = Task(
        title: 'Complete Task',
        description: 'Task description',
        createdAt: now,
        dueDate: dueDate,
        priority: 'high',
        category: 'work',
        isCompleted: true,
        isRecurring: true,
        recurringPattern: 'daily',
        color: '#FF5722',
      );

      expect(task.title, 'Complete Task');
      expect(task.description, 'Task description');
      expect(task.createdAt, now);
      expect(task.dueDate, dueDate);
      expect(task.priority, 'high');
      expect(task.category, 'work');
      expect(task.isCompleted, true);
      expect(task.isRecurring, true);
      expect(task.recurringPattern, 'daily');
      expect(task.color, '#FF5722');
    });

    test('Should convert task to map correctly', () {
      final now = DateTime.now();
      final task = Task(
        title: 'Test Task',
        description: 'Test Description',
        createdAt: now,
        priority: 'high',
        category: 'work',
        isCompleted: true,
      );

      final map = task.toMap();

      expect(map['title'], 'Test Task');
      expect(map['description'], 'Test Description');
      expect(map['createdAt'], now.millisecondsSinceEpoch);
      expect(map['priority'], 'high');
      expect(map['category'], 'work');
      expect(map['isCompleted'], true);
      expect(map['isRecurring'], false);
      expect(map['recurringPattern'], null);
    });

    test('Should create task from map correctly', () {
      final now = DateTime.now();
      final dueDate = now.add(const Duration(hours: 2));
      
      final map = {
        'title': 'Test Task',
        'description': 'Test Description',
        'createdAt': now.millisecondsSinceEpoch,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'isCompleted': true,
        'priority': 'high',
        'category': 'work',
        'color': '#FF5722',
        'isRecurring': true,
        'recurringPattern': 'weekly',
      };

      final task = Task.fromMap(map, 'test-id');

      expect(task.id, 'test-id');
      expect(task.title, 'Test Task');
      expect(task.description, 'Test Description');
      expect(task.createdAt, DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch));
      expect(task.dueDate, DateTime.fromMillisecondsSinceEpoch(dueDate.millisecondsSinceEpoch));
      expect(task.isCompleted, true);
      expect(task.priority, 'high');
      expect(task.category, 'work');
      expect(task.color, '#FF5722');
      expect(task.isRecurring, true);
      expect(task.recurringPattern, 'weekly');
    });

    test('Should handle null values in fromMap', () {
      final now = DateTime.now();
      final map = {
        'title': 'Minimal Task',
        'createdAt': now.millisecondsSinceEpoch,
      };

      final task = Task.fromMap(map, 'test-id');

      expect(task.id, 'test-id');
      expect(task.title, 'Minimal Task');
      expect(task.description, null);
      expect(task.dueDate, null);
      expect(task.isCompleted, false);
      expect(task.priority, 'medium');
      expect(task.category, 'general');
      expect(task.isRecurring, false);
      expect(task.recurringPattern, null);
    });

    test('Should create copy with modified fields', () {
      final original = Task(
        title: 'Original Task',
        createdAt: DateTime.now(),
        priority: 'low',
      );

      final copy = original.copyWith(
        title: 'Modified Task',
        priority: 'high',
        isCompleted: true,
      );

      expect(copy.title, 'Modified Task');
      expect(copy.priority, 'high');
      expect(copy.isCompleted, true);
      expect(copy.createdAt, original.createdAt); // Should remain the same
      expect(copy.category, original.category); // Should remain the same
    });

    test('Should validate title length constraints', () {
      // Test empty title
      expect(() => Task(title: '', createdAt: DateTime.now()), returnsNormally);
      
      // Test very long title (this would be caught in service layer)
      final longTitle = 'a' * 200;
      expect(() => Task(title: longTitle, createdAt: DateTime.now()), returnsNormally);
    });

    test('Should handle recurring task properties', () {
      final recurringTask = Task(
        title: 'Daily Exercise',
        createdAt: DateTime.now(),
        isRecurring: true,
        recurringPattern: 'daily',
      );

      expect(recurringTask.isRecurring, true);
      expect(recurringTask.recurringPattern, 'daily');

      final map = recurringTask.toMap();
      expect(map['isRecurring'], true);
      expect(map['recurringPattern'], 'daily');

      final reconstructed = Task.fromMap(map, 'test-id');
      expect(reconstructed.isRecurring, true);
      expect(reconstructed.recurringPattern, 'daily');
    });
  });
}
