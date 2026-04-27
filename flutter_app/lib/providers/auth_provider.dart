import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  UserModel? _userProfile;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  String get role => _userProfile?.role ?? 'farmer';

  AppAuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _firebaseUser = null;
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _firebaseUser = user;
    _status = AuthStatus.loading;
    notifyListeners();

    final profile = await _authService.getUserProfile(user.uid);
    _userProfile = profile ??
        UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
        );

    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithPhone(String phone, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signInWithPhone(phone, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void updateUserProfile(UserModel updated) {
    _userProfile = updated;
    notifyListeners();
  }

  /// Re-fetches user profile from Firestore and notifies listeners.
  Future<void> refreshUserProfile() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    final profile = await _authService.getUserProfile(uid);
    if (profile != null) {
      _userProfile = profile;
      notifyListeners();
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found. Please check your credentials.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }
}
