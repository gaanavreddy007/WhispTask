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
      dueDate: map['dueDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dueDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? 'general',
      color: map['color'],
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
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
    );
  }
}
