import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/models/user_model.dart';
import '../core/enums/app_enums.dart';
import '../utils/firebase_auth_helper.dart';

/// Thrown when the user dismisses the Google account picker.
/// Callers can catch this separately to avoid showing an error snackbar.
class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthService() {
    _auth.setLanguageCode('en');
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      print('Attempting to create user with email: $email');

      // Create auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User created successfully, creating Firestore document...');

      // Create user document in Firestore
      if (credential.user != null) {
        final userModel = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          // Initialize driver-specific fields if role is driver
          verificationStatus: role == UserRole.driver ? 'pending' : 'verified',
          isAvailable: role == UserRole.driver ? false : null,
          rating: role == UserRole.driver ? 0.0 : null,
          completedJobs: role == UserRole.driver ? 0 : null,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());

        // Update display name
        await credential.user!.updateDisplayName(name);

        print('User profile created successfully');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth error: ${e.code} - ${e.message}');
      throw _getAuthException(e);
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _getAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Google Sign-In
  Future<UserCredential> signInWithGoogle({UserRole? role}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const GoogleSignInCancelledException();

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Google sign-in failed. Please try again.';
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) throw 'Failed to sign in. Please try again.';

      // Create Firestore profile for first-time Google users
      final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!doc.exists) {
        final effectiveRole = role ?? UserRole.cargoOwner;
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Google User',
          email: userCredential.user!.email ?? '',
          phoneNumber: userCredential.user!.phoneNumber ?? '',
          role: effectiveRole,
          verificationStatus: effectiveRole == UserRole.driver ? 'pending' : 'verified',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          profileImageUrl: userCredential.user!.photoURL,
          isAvailable: effectiveRole == UserRole.driver ? false : null,
          rating: effectiveRole == UserRole.driver ? 0.0 : null,
          completedJobs: effectiveRole == UserRole.driver ? 0 : null,
        );
        await _firestore.collection('users').doc(userCredential.user!.uid).set(userModel.toFirestore());
      }

      if (kDebugMode) debugPrint('[Auth] Google sign-in: ${userCredential.user!.email}');
      return userCredential;
    } on GoogleSignInCancelledException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthHelper.getAuthErrorMessage(e);
    } on PlatformException catch (e) {
      throw FirebaseAuthHelper.getGoogleSignInErrorMessage(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Google sign-in failed. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) await _googleSignIn.disconnect();
      await _auth.signOut();
    } catch (e) {
      try { await _auth.signOut(); } catch (_) {}
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final user = currentUser;
      if (user != null) {
        final updates = <String, dynamic>{
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        if (name != null) {
          updates['name'] = name;
          await user.updateDisplayName(name);
        }
        if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
        if (profileImageUrl != null) {
          updates['profileImageUrl'] = profileImageUrl;
        }

        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update driver verification documents
  Future<void> updateDriverDocuments({
    required String driverLicense,
    required String nationalId,
    required String vehicleRegistration,
    required String vehicleType,
    required String vehicleCapacity,
    String? vehicleImageUrl,
  }) async {
    try {
      final user = currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'driverLicense': driverLicense,
          'nationalId': nationalId,
          'vehicleRegistration': vehicleRegistration,
          'vehicleType': vehicleType,
          'vehicleCapacity': vehicleCapacity,
          'vehicleImageUrl': vehicleImageUrl,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Failed to update driver documents: $e');
    }
  }

  // Update driver availability
  Future<void> updateDriverAvailability(bool isAvailable) async {
    try {
      final user = currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isAvailable': isAvailable,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }

  // Helper method to convert FirebaseAuthException to user-friendly messages
  String _getAuthException(FirebaseAuthException e) {
    return FirebaseAuthHelper.getAuthErrorMessage(e);
  }
}
