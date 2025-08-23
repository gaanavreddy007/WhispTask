import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Added for Timestamp

import 'package:whisptask/main.dart';
import 'package:whisptask/screens/add_task_screen.dart';
import 'package:whisptask/screens/login_screen.dart';
import 'package:whisptask/widgets/task_card.dart';

void main() {
  group('WhispTask Widget Tests', () {
    testWidgets('LoginScreen displays correctly', (WidgetTester tester) async {
      // Build the login screen directly without Firebase
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify that login screen elements are present
      expect(find.text('WhispTask'), findsOneWidget);
      expect(find.text('Task it. Say it. Done.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsAtLeastNWidgets(1));
    });

    testWidgets('LoadingScreen displays correctly', (WidgetTester tester) async {
      // Build the loading screen directly
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(),
        ),
      );

      // Verify that loading screen elements are present
      expect(find.text('WhispTask'), findsOneWidget);
      expect(find.text('Task it. Say it. Done.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('AddTaskScreen displays correctly', (WidgetTester tester) async {
      // Build the add task screen directly
      await tester.pumpWidget(
        const MaterialApp(
          home: AddTaskScreen(),
        ),
      );

      // Verify that add task screen elements are present
      expect(find.text('Add New Task'), findsOneWidget);
      expect(find.text('What do you need to do?'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('TaskCard displays task information correctly', (WidgetTester tester) async {
      // ✅ Create a proper Firebase Timestamp for testing
      final mockTimestamp = Timestamp.fromDate(DateTime.now());
      
      // Build a TaskCard with test data
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              taskId: 'test-id',
              title: 'Test Task',
              isCompleted: false,
              createdAt: mockTimestamp,
            ),
          ),
        ),
      );

      // Verify task title is displayed
      expect(find.text('Test Task'), findsOneWidget);
    });
  });
}
