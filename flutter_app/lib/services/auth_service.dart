import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sign in with email and password directly.
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sign in using a phone number: looks up the associated email in Firestore
  /// and then authenticates with email + password.
  Future<UserCredential> signInWithPhone(
      String phone, String password) async {
    final q = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account associated with this phone number.',
      );
    }

    final email = q.docs.first.data()['email'] as String? ?? '';
    if (email.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Could not retrieve email for this phone number.',
      );
    }

    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Fetch user role from Firestore (because custom claims require token refresh).
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String? ?? 'farmer';
      }
    } catch (_) {}
    return 'farmer';
  }

  /// Fetch full user profile from Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
}
