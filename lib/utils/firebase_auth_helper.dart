import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FirebaseAuthHelper {
  static Future<void> configureFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      auth.setLanguageCode('en');

      if (kDebugMode) {
        debugPrint('[Auth] Firebase Auth configured');
        debugPrint('[Auth] Current user: ${auth.currentUser?.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Auth] Error configuring Firebase Auth: $e');
      }
    }
  }

  /// Returns a user-friendly message for a [FirebaseAuthException].
  static String getAuthErrorMessage(FirebaseAuthException error) {
    if (kDebugMode) {
      debugPrint('[Auth] FirebaseAuthException: code=${error.code} msg=${error.message}');
    }
    switch (error.code) {
      // ── Network ────────────────────────────────────────────────────────────
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';

      // ── Rate limits ────────────────────────────────────────────────────────
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';

      // ── Configuration ──────────────────────────────────────────────────────
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'app-not-authorized':
        return 'App not authorized to use Firebase Authentication.';

      // ── Email/Password ──────────────────────────────────────────────────────
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with letters and numbers.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'requires-recent-login':
        return 'Please log in again to complete this action.';

      // ── Google Sign-In ─────────────────────────────────────────────────────
      case 'sign_in_failed':
        return 'Google sign-in failed. Please try again.';
      case 'sign_in_cancelled':
        return 'Sign-in was cancelled.';
      case 'network_error':
        return 'A network error occurred during Google sign-in. Check your connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but a different sign-in method.';
      case 'credential-already-in-use':
        return 'This Google account is already linked to another user.';
      case 'popup-blocked':
        return 'Sign-in popup was blocked. Please allow popups and try again.';
      case 'popup-closed-by-user':
        return 'Sign-in popup was closed. Please try again.';
      case 'cancelled-popup-request':
        return 'Only one sign-in popup can be open at a time.';

      // ── Verification ───────────────────────────────────────────────────────
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check and try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please restart the process.';
      case 'captcha-check-failed':
        return 'Security check failed. Please try again.';

      default:
        if (kDebugMode) {
          debugPrint('[Auth] Unhandled error code: ${error.code}');
        }
        return error.message ?? 'An unexpected error occurred. Please try again.';
    }
  }

  /// Returns a user-friendly message for a [PlatformException]
  /// thrown by the google_sign_in package.
  static String getGoogleSignInErrorMessage(PlatformException error) {
    if (kDebugMode) {
      debugPrint('[Auth] PlatformException: code=${error.code} msg=${error.message}');
    }
    switch (error.code) {
      case 'sign_in_failed':
        return 'Google sign-in failed. Please try again.';
      case 'sign_in_canceled':
      case 'sign_in_cancelled':
        return 'Sign-in was cancelled.';
      case 'network_error':
        return 'A network error occurred. Please check your connection.';
      case 'access_denied':
        return 'Access was denied. Please grant the required permissions.';
      default:
        return error.message ?? 'Google sign-in failed. Please try again.';
    }
  }
}
