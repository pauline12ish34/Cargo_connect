import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationStoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> storeNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    required String bookingId,
    String? senderName,
  }) async {
    try {
      await _db
          .collection('userNotifications')
          .doc(recipientId)
          .collection('items')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'bookingId': bookingId,
        if (senderName != null) 'senderName': senderName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [NotificationStore] Failed to store: $e');
    }
  }

  static Stream<int> unreadCountStream(String userId) {
    return _db
        .collection('userNotifications')
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Future<void> markOneRead(String userId, String notificationId) async {
    try {
      await _db
          .collection('userNotifications')
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('❌ [NotificationStore] Failed to mark one read: $e');
    }
  }

  static Future<void> markAllRead(String userId) async {
    try {
      final batch = _db.batch();
      final unread = await _db
          .collection('userNotifications')
          .doc(userId)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [NotificationStore] Failed to mark read: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> notificationsStream(String userId) {
    return _db
        .collection('userNotifications')
        .doc(userId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }
}
