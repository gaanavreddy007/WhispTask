// ignore_for_file: unused_local_variable, unused_import

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whisptask/services/auth_service.dart';
import 'package:whisptask/models/user_model.dart';

// Import generated mocks
import 'auth_service_test.mocks.dart';

// Mock Firebase App
class MockFirebaseApp extends Mock implements FirebaseApp {}

// Annotations for mock generation
@GenerateMocks([
  FirebaseAuth,
  User,
  UserCredential,
  FirebaseFirestore,
  DocumentReference,
  DocumentSnapshot,
  CollectionReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('Authentication Service Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockDocumentSnapshot mockDocumentSnapshot;

    setUpAll(() async {
      // Setup Firebase for testing
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Initialize mocks
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocument = MockDocumentReference<Map<String, dynamic>>();
      mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      // Inject mocks into the service - delay initialization to avoid Firebase calls
      authService = AuthService(
        firebaseAuth: mockAuth,
        firestore: mockFirestore,
      );

      // Common mock setups
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-uid');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.isAnonymous).thenReturn(false);
      when(mockUser.displayName).thenReturn('Test User');
      when(mockUser.phoneNumber).thenReturn(null);
      when(mockUser.photoURL).thenReturn(null);
      when(mockUser.emailVerified).thenReturn(true);
      when(mockFirestore.collection('users')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.doc(any)).thenReturn(mockDocument as DocumentReference<Map<String, dynamic>>);
      when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot as DocumentSnapshot<Map<String, dynamic>>);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn({
        'uid': 'test-uid',
        'email': 'test@example.com',
        'displayName': 'Test User',
      });
    });

    group('User Authentication', () {
      test('should return current user when logged in', () {
        expect(authService.currentUser, equals(mockUser));
      });

      test('should return null when no user is logged in', () {
        when(mockAuth.currentUser).thenReturn(null);
        expect(authService.currentUser, isNull);
      });

      test('should correctly check if user is logged in', () {
        expect(authService.isLoggedIn, isTrue);
        when(mockAuth.currentUser).thenReturn(null);
        expect(authService.isLoggedIn, isFalse);
      });

      test('should correctly check if user is anonymous', () {
        when(mockUser.isAnonymous).thenReturn(true);
        expect(authService.isAnonymous, isTrue);

        when(mockUser.isAnonymous).thenReturn(false);
        expect(authService.isAnonymous, isFalse);
      });
    });

    group('Sign In and Registration', () {
      test('should sign in with email and password and return user model', () async {
        const email = 'test@example.com';
        const password = 'password123';

        when(mockAuth.signInWithEmailAndPassword(email: email, password: password))
            .thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.isAnonymous).thenReturn(false);
        
        // Mock Firestore document operations
        when(mockCollection.doc('test-uid')).thenReturn(mockDocument);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot as DocumentSnapshot<Map<String, dynamic>>);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.id).thenReturn('test-uid');
        when(mockDocumentSnapshot.data()).thenReturn({
          'uid': 'test-uid',
          'email': email,
          'displayName': 'Test User',
          'createdAt': Timestamp.now(),
        });

        final result = await authService.signInWithEmailPassword(email, password);

        expect(result, isNotNull);
        expect(result?.uid, 'test-uid');
        verify(mockAuth.signInWithEmailAndPassword(email: email, password: password)).called(1);
      });

      test('should register with email and password and create user document', () async {
        const email = 'new@example.com';
        const password = 'new-password';
        const displayName = 'New User';

        when(mockAuth.createUserWithEmailAndPassword(email: email, password: password))
            .thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('new-uid');
        when(mockUser.email).thenReturn(email);
        when(mockUser.displayName).thenReturn(displayName);
        when(mockUser.isAnonymous).thenReturn(false);

        when(mockCollection.doc('new-uid')).thenReturn(mockDocument);
        when(mockDocument.set(any)).thenAnswer((_) async => {});
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot as DocumentSnapshot<Map<String, dynamic>>);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.id).thenReturn('new-uid');
        when(mockDocumentSnapshot.data()).thenReturn({
          'uid': 'new-uid',
          'email': email,
          'displayName': displayName,
          'createdAt': Timestamp.now(),
        });

        final result = await authService.registerWithEmailPassword(email, password, displayName);

        expect(result, isNotNull);
        expect(result?.email, email);
        verify(mockDocument.set(any)).called(1);
      });
    });

    group('Profile and Account Management', () {
      test('should sign out successfully', () async {
        when(mockAuth.signOut()).thenAnswer((_) async => {});
        await authService.signOut();
        verify(mockAuth.signOut()).called(1);
      });

      test('should send password reset email', () async {
        const email = 'reset@example.com';
        when(mockAuth.sendPasswordResetEmail(email: email)).thenAnswer((_) async => {});

        await authService.resetPassword(email);

        verify(mockAuth.sendPasswordResetEmail(email: email)).called(1);
      });

      test('should update user profile data in firestore', () async {
        const newDisplayName = 'Updated Name';
        const newEmail = 'updated@example.com';

        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.updateDisplayName(newDisplayName)).thenAnswer((_) async => {});
        when(mockUser.updateEmail(newEmail)).thenAnswer((_) async => {});
        when(mockCollection.doc('test-uid')).thenReturn(mockDocument);
        when(mockDocument.update(any)).thenAnswer((_) async => {});
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot as DocumentSnapshot<Map<String, dynamic>>);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.id).thenReturn('test-uid');
        when(mockDocumentSnapshot.data()).thenReturn({
          'uid': 'test-uid',
          'email': newEmail,
          'displayName': newDisplayName,
          'createdAt': Timestamp.now(),
        });

        final result = await authService.updateProfile(
          displayName: newDisplayName,
          email: newEmail,
        );

        expect(result, isNotNull);
        verify(mockDocument.update(any)).called(1);
      });

      test('should delete user account and data', () async {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.delete()).thenAnswer((_) async {});
        when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) async => mockUserCredential);
        when(mockCollection.doc('test-uid')).thenReturn(mockDocument);
        when(mockDocument.delete()).thenAnswer((_) async {});
        when(mockUser.isAnonymous).thenReturn(false);

        await authService.deleteAccount('password123');

        verify(mockDocument.delete()).called(1);
        verify(mockUser.delete()).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle sign-in failure gracefully', () async {
        when(mockAuth.signInWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(FirebaseAuthException(code: 'user-not-found'));

        final result = await authService.signInWithEmailPassword('wrong@test.com', 'wrong-pass');
        expect(result, isNull);
      });

      test('should handle registration failure gracefully', () async {
        when(mockAuth.createUserWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

        final result = await authService.registerWithEmailPassword('existing@test.com', 'password', 'Existing User');
        expect(result, isNull);
      });
    });
  });
}
