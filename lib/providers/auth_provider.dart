import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/user_model.dart';
import '../core/enums/app_enums.dart';
import '../services/auth_service.dart';
import '../services/device_token_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isGoogleLoading = false; // Separate flag for Google sign-in button
  String? _error;
  StreamSubscription<User?>? _authSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// The raw Firebase Auth user — useful for checking emailVerified without
  /// going through the Firestore UserModel.
  User? get currentFirebaseUser => _authService.currentUser;

  // ── Auth state listener ───────────────────────────────────────────────────────

  Future<void> initializeAuth() async {
    // Cancel any previous subscription before creating a new one
    await _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen(
      (User? firebaseUser) async {
        if (firebaseUser != null) {
          try {
            _user = await _authService.getCurrentUserData();
          } catch (e) {
            _error = _sanitizeError(e);
          }
        } else {
          _user = null;
        }
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ── Sign Up (email) ───────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        role: role,
      );

      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign Up (anonymous, for testing) ─────────────────────────────────────────

  Future<bool> signUpAnonymously({
    required String name,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await FirebaseAuth.instance.signInAnonymously();

      if (credential.user != null) {
        final userModel = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: 'anonymous@test.com',
          phoneNumber: phoneNumber,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isAvailable: role == UserRole.driver ? false : null,
          rating: role == UserRole.driver ? 0.0 : null,
          completedJobs: role == UserRole.driver ? 0 : null,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());

        _user = userModel;
      }

      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign In (email) ───────────────────────────────────────────────────────────

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signInWithEmail(email: email, password: password);
      _user = await _authService.getCurrentUserData();

      // Firebase Auth succeeded but no Firestore profile exists.
      // Sign out immediately so the app is in a clean state.
      if (_user == null) {
        await _authService.signOut();
        throw 'No account found with this email. Please sign up first.';
      }

      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign In (Google) ──────────────────────────────────────────────────────────

  /// Returns [true] on success, [false] on cancellation (no error shown),
  /// and [false] + sets [error] on failure.
  Future<bool> signInWithGoogle({UserRole? role}) async {
    try {
      _setGoogleLoading(true);
      _clearError();

      await _authService.signInWithGoogle(role: role);
      _user = await _authService.getCurrentUserData();

      return true;
    } on GoogleSignInCancelledException {
      // User tapped "back" — not an error, just return false silently
      return false;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    } finally {
      _setGoogleLoading(false);
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      _setLoading(true);
      // Remove device token before signing out so this device no longer
      // receives push notifications for the current user.
      await DeviceTokenService.removeDeviceToken(_user?.uid);
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _setError(_sanitizeError(e));
    } finally {
      _setLoading(false);
    }
  }

  // ── Password reset ─────────────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Email verification ─────────────────────────────────────────────────────────

  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _clearError();

      final user = _authService.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkEmailVerification() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await user.reload();
        _user = await _authService.getCurrentUserData();
        notifyListeners();
      }
    } catch (e) {
      _setError(_sanitizeError(e));
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────────────

  Future<void> refreshUserData() async {
    try {
      _user = await _authService.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      _setError(_sanitizeError(e));
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.updateUserProfile(
        name: name,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
      );
      _user = await _authService.getCurrentUserData();

      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDriverDocuments({
    required String driverLicenseNumber,
    required String nationalId,
    required String vehicleRegistration,
    required String vehicleType,
    required String vehicleCapacity,
    String? vehicleImageUrl,
    String? plateNumber,
    String? insurance,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (_user == null || _user!.uid.isEmpty) {
        _setError('No user logged in');
        return false;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'driverLicenseNumber': driverLicenseNumber,
        'nationalId': nationalId,
        'vehicleRegistration': vehicleRegistration,
        'vehicleType': vehicleType,
        'vehicleCapacity': vehicleCapacity,
        if (vehicleImageUrl != null) 'vehicleImageUrl': vehicleImageUrl,
        if (plateNumber != null) 'plateNumber': plateNumber,
        if (insurance != null) 'insurance': insurance,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _user = await _authService.getCurrentUserData();
      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDriverAvailability(bool isAvailable) async {
    try {
      await _authService.updateDriverAvailability(isAvailable);

      if (_user != null && _user!.role == UserRole.driver) {
        _user = _user!.copyWith(isAvailable: isAvailable);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError(_sanitizeError(e));
      return false;
    }
  }

  // ── Internal helpers ───────────────────────────────────────────────────────────

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setGoogleLoading(bool loading) {
    _isGoogleLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Strips the Dart "Exception: " or "FormatException: " prefix so
  /// the raw user-friendly message from AuthService is displayed as-is.
  static String _sanitizeError(Object e) {
    final raw = e.toString();
    // AuthService now throws plain Strings; this handles legacy Exception wraps
    const prefixes = ['Exception: ', 'Error: ', 'FormatException: '];
    for (final prefix in prefixes) {
      if (raw.startsWith(prefix)) return raw.substring(prefix.length);
    }
    return raw;
  }
}
