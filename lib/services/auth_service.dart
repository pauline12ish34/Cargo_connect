import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/models/user_model.dart';
import '../core/enums/app_enums.dart';
import '../utils/firebase_auth_helper.dart';

/// Sentinel returned when the user cancels the Google sign-in flow.
/// Callers can check for this to avoid showing an error snackbar.
class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
  @override
  String toString() => 'Google sign-in was cancelled by the user.';
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Declare once with the scopes the app needs.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthService() {
    _auth.setLanguageCode('en');
  }

  // ── Getters ─────────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Firestore user data ──────────────────────────────────────────────────────

  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // ── Email / Password ─────────────────────────────────────────────────────────

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userModel = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isAvailable: role == UserRole.driver ? false : null,
          rating: role == UserRole.driver ? 0.0 : null,
          completedJobs: role == UserRole.driver ? 0 : null,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());

        await credential.user!.updateDisplayName(name);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthHelper.getAuthErrorMessage(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthHelper.getAuthErrorMessage(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────────

  /// Signs the user in with Google.
  ///
  /// Returns a [UserCredential] on success.
  /// Throws [GoogleSignInCancelledException] if the user dismisses the picker.
  /// Throws a [String] with a human-readable message for any other failure.
  Future<UserCredential> signInWithGoogle({UserRole? role}) async {
    try {
      // ① Present the Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User dismissed the picker — treat as cancellation, not an error
      if (googleUser == null) throw const GoogleSignInCancelledException();

      // ② Exchange the Google token for a Firebase credential
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Google sign-in failed. Please try again.';
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ③ Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw 'Failed to sign in. Please try again.';
      }

      // ④ Create Firestore profile for first-time Google users
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        final effectiveRole = role ?? UserRole.cargoOwner;
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Google User',
          email: userCredential.user!.email ?? '',
          phoneNumber: userCredential.user!.phoneNumber ?? '',
          role: effectiveRole,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          profileImageUrl: userCredential.user!.photoURL,
          isAvailable: effectiveRole == UserRole.driver ? false : null,
          rating: effectiveRole == UserRole.driver ? 0.0 : null,
          completedJobs: effectiveRole == UserRole.driver ? 0 : null,
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestore());
      }

      if (kDebugMode) {
        debugPrint('[Auth] Google sign-in successful: ${userCredential.user!.email}');
      }

      return userCredential;
    } on GoogleSignInCancelledException {
      rethrow; // Caller handles this silently
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthHelper.getAuthErrorMessage(e);
    } on PlatformException catch (e) {
      throw FirebaseAuthHelper.getGoogleSignInErrorMessage(e);
    } catch (e) {
      if (e is String) rethrow; // Already a user-friendly message
      throw 'Google sign-in failed. Please try again.';
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      // Revoke Google token so the account picker appears next time
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
      await _auth.signOut();
    } catch (e) {
      // Best-effort: sign out of Firebase even if Google revocation fails
      try {
        await _auth.signOut();
      } catch (_) {}
      throw 'Failed to sign out. Please try again.';
    }
  }

  // ── Password reset ─────────────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthHelper.getAuthErrorMessage(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  // ── Profile update ─────────────────────────────────────────────────────────────

  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw 'No user is signed in.';

    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) {
        updates['name'] = name;
        await user.updateDisplayName(name);
      }
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  Future<void> updateDriverDocuments({
    required String driverLicense,
    required String nationalId,
    required String vehicleRegistration,
    required String vehicleType,
    required String vehicleCapacity,
    String? vehicleImageUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw 'No user is signed in.';
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'driverLicense': driverLicense,
        'nationalId': nationalId,
        'vehicleRegistration': vehicleRegistration,
        'vehicleType': vehicleType,
        'vehicleCapacity': vehicleCapacity,
        if (vehicleImageUrl != null) 'vehicleImageUrl': vehicleImageUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw 'Failed to update driver documents. Please try again.';
    }
  }

  Future<void> updateDriverAvailability(bool isAvailable) async {
    final user = currentUser;
    if (user == null) throw 'No user is signed in.';
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw 'Failed to update availability. Please try again.';
    }
  }
}
