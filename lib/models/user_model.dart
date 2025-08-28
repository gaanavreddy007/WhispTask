// lib/models/user_model.dart
// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String displayName;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime lastSignIn;
  final int taskCount;
  final int completedTaskCount;
  final String? photoUrl;

  UserModel({
    required this.uid,
    this.email,
    required this.displayName,
    required this.isAnonymous,
    required this.createdAt,
    required this.lastSignIn,
    this.taskCount = 0,
    this.completedTaskCount = 0,
    this.photoUrl,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'] ?? 'User',
      isAnonymous: data['isAnonymous'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSignIn: (data['lastSignIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      taskCount: data['taskCount'] ?? 0,
      completedTaskCount: data['completedTaskCount'] ?? 0,
      photoUrl: data['photoUrl'],
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSignIn': Timestamp.fromDate(lastSignIn),
      'taskCount': taskCount,
      'completedTaskCount': completedTaskCount,
      'photoUrl': photoUrl,
    };
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastSignIn,
    int? taskCount,
    int? completedTaskCount,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      taskCount: taskCount ?? this.taskCount,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  // Get completion percentage
  double get completionPercentage {
    if (taskCount == 0) return 0.0;
    return (completedTaskCount / taskCount) * 100;
  }

  // Get user initials for avatar
  String get initials {
    // Handle empty or null displayName
    if (displayName.isEmpty) return 'U';
    
    // Split by spaces and filter out empty strings
    List<String> nameParts = displayName.trim().split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    
    // Handle case where no valid name parts exist
    if (nameParts.isEmpty) return 'U';
    
    // Single name part - return first character
    if (nameParts.length == 1) {
      return nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : 'U';
    }
    
    // Multiple name parts - return first character of first and last parts
    String firstInitial = nameParts.first.isNotEmpty ? nameParts.first[0] : '';
    String lastInitial = nameParts.last.isNotEmpty ? nameParts.last[0] : '';
    
    // If we couldn't get both initials, fall back to first initial or 'U'
    if (firstInitial.isEmpty && lastInitial.isEmpty) return 'U';
    if (lastInitial.isEmpty) return firstInitial.toUpperCase();
    
    return '${firstInitial}${lastInitial}'.toUpperCase();
  }

  // Check if user has completed setup
  bool get hasCompletedSetup {
    return !isAnonymous && email != null && displayName.isNotEmpty;
  }

  // Get user type description
  String get accountType {
    return isAnonymous ? 'Guest Account' : 'Registered Account';
  }

  // Get formatted member since date
  String get memberSince {
    return '${_getMonthName(createdAt.month)} ${createdAt.year}';
  }

  // Get days since registration
  int get daysSinceRegistration {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Get formatted last sign in
  String get formattedLastSignIn {
    Duration difference = DateTime.now().difference(lastSignIn);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, isAnonymous: $isAnonymous)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}