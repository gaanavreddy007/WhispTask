// services/auth_service.dart - Enhanced version
// ignore_for_file: deprecated_member_use, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Check if user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  // Convert Firebase User to UserModel (fallback only)
  UserModel? _userFromFirebase(User? user) {
    if (user == null) return null;
    
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName ?? 'User',
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastSignIn: user.metadata.lastSignInTime ?? DateTime.now(),
    );
  }

  // FIXED: Enhanced UserModel stream that fetches from Firestore
  Stream<UserModel?> get user {
    return authStateChanges.asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;
      
      try {
        // Try to get complete user data from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        
        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        } else {
          // Fallback: create user document if it doesn't exist
          await _createUserDocument(firebaseUser);
          return _userFromFirebase(firebaseUser);
        }
      } catch (e) {
        print('Error fetching user data from Firestore: $e');
        // Fallback to basic Firebase user data
        return _userFromFirebase(firebaseUser);
      }
    });
  }

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      } else {
        await _createUserDocument(currentUser);
        return _userFromFirebase(currentUser);
      }
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  // Sign in anonymously
  Future<UserModel?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      
      // Create user document in Firestore
      if (user != null) {
        await _createUserDocument(user);
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }
      
      return _userFromFirebase(user);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      User? user = result.user;
      
      // Update display name
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        user = _auth.currentUser;
        
        // Create user document in Firestore
        await _createUserDocument(user!, displayName: displayName);
        
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }
      
      return _userFromFirebase(user);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password - FIXED VERSION
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    
      User? user = result.user;
    
      if (user != null) {
        // Update last sign in
        await _updateUserDocument(user);
      
        // Fetch complete user data from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        } else {
          // Fallback: create user document if it doesn't exist
          await _createUserDocument(user);
          DocumentSnapshot newUserDoc = await _firestore.collection('users').doc(user.uid).get();
          return UserModel.fromFirestore(newUserDoc);
        }
      }
    
      return null;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Convert anonymous account to permanent account
  Future<UserModel?> linkAnonymousWithEmail(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      if (!isAnonymous) {
        throw Exception('Current user is not anonymous');
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: email.trim(), 
        password: password
      );
      
      UserCredential result = await _auth.currentUser!.linkWithCredential(credential);
      User? user = result.user;
      
      // Update display name and user document
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        user = _auth.currentUser;
        
        // Update user document with new info
        await _updateUserDocument(user!, displayName: displayName, isAnonymous: false);
        
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }
      
      return _userFromFirebase(user);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Update profile - ENHANCED VERSION
  Future<UserModel?> updateProfile({String? displayName, String? email}) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Update display name
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // Update email
      if (email != null && email.isNotEmpty && email != user.email) {
        await user.updateEmail(email.trim());
      }

      // Reload user data
      await user.reload();
      user = _auth.currentUser;

      // Update Firestore document
      if (user != null) {
        await _updateUserDocument(user, displayName: displayName);
        
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }

      return _userFromFirebase(user);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in or user has no email');
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Delete account
  Future<void> deleteAccount(String? password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate if not anonymous
      if (!user.isAnonymous && password != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete user tasks
      await _deleteUserTasks(user.uid);

      // Delete Firebase Auth user
      await user.delete();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, {String? displayName}) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? 'User',
        'isAnonymous': user.isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'taskCount': 0,
        'completedTaskCount': 0,
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  // Update user document in Firestore
  Future<void> _updateUserDocument(
    User user, {
    String? displayName,
    bool? isAnonymous,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'lastSignIn': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updateData['displayName'] = displayName;
      }

      if (isAnonymous != null) {
        updateData['isAnonymous'] = isAnonymous;
        updateData['email'] = user.email;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      print('Error updating user document: $e');
    }
  }

  // Delete all user tasks
  Future<void> _deleteUserTasks(String userId) async {
    try {
      QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting user tasks: $e');
    }
  }

  // Get user stats
  Future<Map<String, int>> getUserStats() async {
    try {
      if (currentUserId == null) return {'taskCount': 0, 'completedTaskCount': 0};

      QuerySnapshot allTasks = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .get();

      QuerySnapshot completedTasks = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .where('isCompleted', isEqualTo: true)
          .get();

      return {
        'taskCount': allTasks.docs.length,
        'completedTaskCount': completedTasks.docs.length,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {'taskCount': 0, 'completedTaskCount': 0};
    }
  }

  // Handle authentication errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This operation is not allowed. Please contact support.';
        case 'requires-recent-login':
          return 'Please log in again to perform this action.';
        case 'credential-already-in-use':
          return 'This account is already linked with another user.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}