import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's tasks collection reference
  CollectionReference get _tasksCollection {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // Create new task
  Future<String> createTask(Task task) async {
    try {
      // Validate task data
      if (task.title.trim().isEmpty) {
        throw Exception('Task title cannot be empty');
      }
      
      if (task.title.length > 100) {
        throw Exception('Task title too long (max 100 characters)');
      }
      
      if (task.description != null && task.description!.length > 500) {
        throw Exception('Task description too long (max 500 characters)');
      }
      
      DocumentReference docRef = await _tasksCollection.add(task.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get all tasks
  Stream<List<Task>> getTasks() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Get tasks by category
  Stream<List<Task>> getTasksByCategory(String category) {
    return _tasksCollection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Get incomplete tasks
  Stream<List<Task>> getIncompleteTasks() {
    return _tasksCollection
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Update task
  Future<void> updateTask(Task task) async {
    if (task.id == null) throw Exception('Task ID cannot be null');
    
    try {
      await _tasksCollection.doc(task.id).update(task.toMap());
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? DateTime.now().millisecondsSinceEpoch : null,
      });
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  // Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      DocumentSnapshot doc = await _tasksCollection.doc(taskId).get();
      if (doc.exists) {
        return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }
}