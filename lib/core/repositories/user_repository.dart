import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../enums/app_enums.dart';
import '../../services/cloudinary_service.dart';

abstract class UserRepository {
  Future<UserModel?> getUserById(String uid);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String uid);
  Future<List<UserModel>> getUsersByRole(UserRole role);
  Stream<UserModel?> userStream(String uid);
  Future<String> uploadProfileImage(String uid, File imageFile);
  Future<String> uploadDocument(String uid, File documentFile, String documentType);
  Future<void> updateUserWithDocuments(String uid, Map<String, String> documentUrls);
}

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'users';

  @override
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  @override
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('role', isEqualTo: role.toString().split('.').last)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }

  @override
  Stream<UserModel?> userStream(String uid) {
    return _firestore
        .collection(_collectionName)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  @override
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      return await CloudinaryService.uploadFile(imageFile, folder: 'users/$uid/profile');
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  @override
  Future<String> uploadDocument(String uid, File documentFile, String documentType) async {
    try {
      return await CloudinaryService.uploadFile(documentFile, folder: 'users/$uid/documents');
    } catch (e) {
      throw Exception('Failed to upload $documentType: $e');
    }
  }

  @override
  Future<void> updateUserWithDocuments(String uid, Map<String, String> documentUrls) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).update(documentUrls);
    } catch (e) {
      throw Exception('Failed to update user documents: $e');
    }
  }
}
