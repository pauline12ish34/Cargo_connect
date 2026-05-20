import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FirebaseAuthHelper {
  static Future<void> configureFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;

      // Set app language
      auth.setLanguageCode('en');

      // For debugging, print current settings
      if (kDebugMode) {
        print('Firebase Auth configured:');
        print('Current user: ${auth.currentUser?.email}');
        print('Language code: ${auth.languageCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error configuring Firebase Auth: $e');
      }
    }
  }

  /// Handles common Firebase Auth errors and provides user-friendly messages
  static String getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'app-not-authorized':
        return 'App not authorized to use Firebase Authentication.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      default:
        return error.message ?? 'An unknown error occurred. Please try again.';
    }
  }

  static String getGoogleSignInErrorMessage(PlatformException error) {
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
