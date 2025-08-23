import 'package:flutter_test/flutter_test.dart';
import 'package:whisptask/models/task.dart';
import 'mocks/mock_task_service.dart';

void main() {
  group('Task Model Tests', () {
    test('should create a task with default values', () {
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

    test('should create a task with custom values', () {
      final createdAt = DateTime.now();
      final dueDate = createdAt.add(const Duration(days: 1));
      
      final task = Task(
        id: '1',
        title: 'Custom Task',
        description: 'A custom task',
        createdAt: createdAt,
        dueDate: dueDate,
        isCompleted: true,
        priority: 'high',
        category: 'work',
        color: '#FF0000',
        isRecurring: true,
        recurringPattern: 'weekly',
      );

      expect(task.id, '1');
      expect(task.title, 'Custom Task');
      expect(task.description, 'A custom task');
      expect(task.createdAt, createdAt);
      expect(task.dueDate, dueDate);
      expect(task.isCompleted, true);
      expect(task.priority, 'high');
      expect(task.category, 'work');
      expect(task.color, '#FF0000');
      expect(task.isRecurring, true);
      expect(task.recurringPattern, 'weekly');
    });

    test('should copy task with updated values', () {
      final task = Task(
        id: '1',
        title: 'Original',
        createdAt: DateTime.now(),
      );
      
      final updatedTask = task.copyWith(
        title: 'Updated',
        isCompleted: true,
        priority: 'high',
      );

      expect(updatedTask.id, '1');
      expect(updatedTask.title, 'Updated');
      expect(updatedTask.isCompleted, true);
      expect(updatedTask.priority, 'high');
      expect(updatedTask.category, 'general'); // Should keep original value
    });

    test('should convert to and from map', () {
      final createdAt = DateTime.now();
      final dueDate = createdAt.add(const Duration(days: 1));
      
      final task = Task(
        title: 'Test Task',
        description: 'Test Description',
        createdAt: createdAt,
        dueDate: dueDate,
        isCompleted: true,
        priority: 'high',
        category: 'work',
        color: '#FF0000',
        isRecurring: true,
        recurringPattern: 'daily',
      );

      final map = task.toMap();
      final reconstructedTask = Task.fromMap(map, 'test_id');

      expect(reconstructedTask.id, 'test_id');
      expect(reconstructedTask.title, task.title);
      expect(reconstructedTask.description, task.description);
      expect(reconstructedTask.createdAt, task.createdAt);
      expect(reconstructedTask.dueDate, task.dueDate);
      expect(reconstructedTask.isCompleted, task.isCompleted);
      expect(reconstructedTask.priority, task.priority);
      expect(reconstructedTask.category, task.category);
      expect(reconstructedTask.color, task.color);
      expect(reconstructedTask.isRecurring, task.isRecurring);
      expect(reconstructedTask.recurringPattern, task.recurringPattern);
    });
  });

  group('TaskService Tests', () {
    late MockTaskService taskService;

    setUp(() {
      taskService = MockTaskService();
    });

    tearDown(() {
      taskService.dispose();
    });

    group('Task Creation', () {
      test('should create a task successfully', () async {
        final task = Task(
          title: 'Test Task',
          createdAt: DateTime.now(),
        );
        
        final taskId = await taskService.createTask(task);
        final createdTask = await taskService.getTaskById(taskId);

        expect(taskId, isNotEmpty);
        expect(createdTask, isNotNull);
        expect(createdTask!.title, 'Test Task');
        expect(createdTask.id, taskId);
      });

      test('should throw error for empty title', () async {
        final task = Task(
          title: '',
          createdAt: DateTime.now(),
        );
        
        expect(
          () => taskService.createTask(task),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Task title cannot be empty'),
          )),
        );
      });

      test('should throw error for title too long', () async {
        final longTitle = 'a' * 101; // 101 characters
        final task = Task(
          title: longTitle,
          createdAt: DateTime.now(),
        );
        
        expect(
          () => taskService.createTask(task),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Task title too long'),
          )),
        );
      });

      test('should throw error for description too long', () async {
        final longDescription = 'a' * 501; // 501 characters
        final task = Task(
          title: 'Valid Title',
          description: longDescription,
          createdAt: DateTime.now(),
        );
        
        expect(
          () => taskService.createTask(task),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Task description too long'),
          )),
        );
      });
    });

    group('Task Retrieval', () {
      test('should get all tasks stream', () async {
        final task1 = Task(title: 'Task 1', createdAt: DateTime.now());
        final task2 = Task(title: 'Task 2', createdAt: DateTime.now());
        
        await taskService.createTask(task1);
        await taskService.createTask(task2);
        
        final stream = taskService.getTasks();
        final tasks = await stream.first;
        
        expect(tasks.length, 2);
        expect(tasks.map((t) => t.title).contains('Task 1'), true);
        expect(tasks.map((t) => t.title).contains('Task 2'), true);
      });

      test('should get tasks by category', () async {
        await taskService.createTask(Task(
          title: 'Work Task',
          category: 'work',
          createdAt: DateTime.now(),
        ));
        
        await taskService.createTask(Task(
          title: 'Personal Task',
          category: 'personal',
          createdAt: DateTime.now(),
        ));

        final workStream = taskService.getTasksByCategory('work');
        final workTasks = await workStream.first;
        
        expect(workTasks.length, 1);
        expect(workTasks.first.title, 'Work Task');
        expect(workTasks.first.category, 'work');
      });

      test('should get incomplete tasks', () async {
        await taskService.createTask(Task(
          title: 'Complete Task',
          isCompleted: true,
          createdAt: DateTime.now(),
        ));
        
        await taskService.createTask(Task(
          title: 'Incomplete Task',
          isCompleted: false,
          createdAt: DateTime.now(),
        ));

        final incompleteStream = taskService.getIncompleteTasks();
        final incompleteTasks = await incompleteStream.first;
        
        expect(incompleteTasks.length, 1);
        expect(incompleteTasks.first.title, 'Incomplete Task');
        expect(incompleteTasks.first.isCompleted, false);
      });

      test('should get task by ID', () async {
        final task = Task(
          title: 'Specific Task',
          createdAt: DateTime.now(),
        );
        
        final taskId = await taskService.createTask(task);
        final retrievedTask = await taskService.getTaskById(taskId);
        
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, 'Specific Task');
        expect(retrievedTask.id, taskId);
      });

      test('should return null for non-existent task ID', () async {
        final retrievedTask = await taskService.getTaskById('non_existent_id');
        expect(retrievedTask, isNull);
      });
    });

    group('Task Updates', () {
      test('should update task successfully', () async {
        final task = Task(
          title: 'Original Task',
          createdAt: DateTime.now(),
        );
        
        final taskId = await taskService.createTask(task);
        final createdTask = await taskService.getTaskById(taskId);
        
        final updatedTask = createdTask!.copyWith(
          title: 'Updated Task',
          isCompleted: true,
          priority: 'high',
        );
        
        await taskService.updateTask(updatedTask);
        final retrievedTask = await taskService.getTaskById(taskId);
        
        expect(retrievedTask!.title, 'Updated Task');
        expect(retrievedTask.isCompleted, true);
        expect(retrievedTask.priority, 'high');
      });

      test('should throw error when updating task with null ID', () async {
        final task = Task(
          title: 'Task without ID',
          createdAt: DateTime.now(),
        );
        
        expect(
          () => taskService.updateTask(task),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Task ID cannot be null'),
          )),
        );
      });

      test('should toggle task completion', () async {
        final task = Task(
          title: 'Toggle Task',
          isCompleted: false,
          createdAt: DateTime.now(),
        );
        
        final taskId = await taskService.createTask(task);
        
        // Toggle to completed
        await taskService.toggleTaskCompletion(taskId, true);
        final completedTask = await taskService.getTaskById(taskId);
        expect(completedTask!.isCompleted, true);
        
        // Toggle back to incomplete
        await taskService.toggleTaskCompletion(taskId, false);
        final incompleteTask = await taskService.getTaskById(taskId);
        expect(incompleteTask!.isCompleted, false);
      });
    });

    group('Task Deletion', () {
      test('should delete task successfully', () async {
        final task = Task(
          title: 'Task to Delete',
          createdAt: DateTime.now(),
        );
        
        final taskId = await taskService.createTask(task);
        await taskService.deleteTask(taskId);
        
        final deletedTask = await taskService.getTaskById(taskId);
        expect(deletedTask, isNull);
        
        final allTasks = taskService.allTasks;
        expect(allTasks.length, 0);
      });

      test('should throw error when deleting non-existent task', () async {
        expect(
          () => taskService.deleteTask('non_existent_id'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Task not found'),
          )),
        );
      });
    });

    group('Task Filtering and Search', () {
      setUp(() async {
        // Add test data
        await taskService.createTask(Task(
          title: 'High Priority Work Task',
          priority: 'high',
          category: 'work',
          isCompleted: false,
          createdAt: DateTime.now(),
        ));
        
        await taskService.createTask(Task(
          title: 'Medium Priority Personal Task',
          priority: 'medium',
          category: 'personal',
          isCompleted: true,
          createdAt: DateTime.now(),
        ));
        
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        await taskService.createTask(Task(
          title: 'Overdue Task',
          dueDate: pastDate,
          isCompleted: false,
          createdAt: DateTime.now(),
        ));
        
        final today = DateTime.now();
        final todayDue = DateTime(today.year, today.month, today.day, 14, 30);
        await taskService.createTask(Task(
          title: 'Today\'s Task',
          dueDate: todayDue,
          createdAt: DateTime.now(),
        ));
      });

      test('should get tasks by priority', () {
        final highPriorityTasks = taskService.getTasksByPriority('high');
        final mediumPriorityTasks = taskService.getTasksByPriority('medium');
        
        expect(highPriorityTasks.length, 1);
        expect(highPriorityTasks.first.title, 'High Priority Work Task');
        expect(mediumPriorityTasks.length, 1);
        expect(mediumPriorityTasks.first.title, 'Medium Priority Personal Task');
      });

      test('should get completed tasks', () {
        final completedTasks = taskService.getCompletedTasks();
        
        expect(completedTasks.length, 1);
        expect(completedTasks.first.title, 'Medium Priority Personal Task');
        expect(completedTasks.first.isCompleted, true);
      });

      test('should get overdue tasks', () {
        final overdueTasks = taskService.getOverdueTasks();
        
        expect(overdueTasks.length, 1);
        expect(overdueTasks.first.title, 'Overdue Task');
        expect(overdueTasks.first.dueDate!.isBefore(DateTime.now()), true);
      });

      test('should get today\'s tasks', () {
        final todaysTasks = taskService.getTodaysTasks();
        
        expect(todaysTasks.length, 1);
        expect(todaysTasks.first.title, 'Today\'s Task');
      });

      test('should search tasks by title and description', () async {
        await taskService.createTask(Task(
          title: 'Buy groceries',
          description: 'Milk, eggs, bread',
          createdAt: DateTime.now(),
        ));
        
        final groceryResults = taskService.searchTasks('grocery');
        final milkResults = taskService.searchTasks('milk');
        final workResults = taskService.searchTasks('work');
        
        expect(groceryResults.length, 1);
        expect(groceryResults.first.title, 'Buy groceries');
        expect(milkResults.length, 1);
        expect(milkResults.first.title, 'Buy groceries');
        expect(workResults.length, 1);
        expect(workResults.first.title, 'High Priority Work Task');
      });
    });

    group('Stream Updates', () {
      test('should update streams when task is added', () async {
        final stream = taskService.getTasks();
        
        // Listen to stream and collect emissions
        final emissions = <List<Task>>[];
        final subscription = stream.listen((tasks) {
          emissions.add(tasks);
        });
        
        // Wait for initial emission
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Add a task
        await taskService.createTask(Task(
          title: 'Stream Test Task',
          createdAt: DateTime.now(),
        ));
        
        // Wait for stream update
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(emissions.length, greaterThanOrEqualTo(2));
        expect(emissions.last.length, 1);
        expect(emissions.last.first.title, 'Stream Test Task');
        
        await subscription.cancel();
      });

      test('should update incomplete tasks stream when task completion is toggled', () async {
        final task = Task(
          title: 'Stream Toggle Task',
          isCompleted: false,
          createdAt: DateTime.now(),
        );
        
        final taskId = await taskService.createTask(task);
        final stream = taskService.getIncompleteTasks();
        
        // Listen to stream
        final emissions = <List<Task>>[];
        final subscription = stream.listen((tasks) {
          emissions.add(tasks);
        });
        
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Toggle completion
        await taskService.toggleTaskCompletion(taskId, true);
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(emissions.length, greaterThanOrEqualTo(2));
        expect(emissions.last.length, 0); // No incomplete tasks
        
        await subscription.cancel();
      });
    });
  });
}