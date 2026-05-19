import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/chat_model.dart';
import '../../services/notification_store_service.dart';
import '../../core/repositories/chat_repository.dart';
import '../../services/cloud_function_service.dart' as notification_service;
import '../../core/repositories/user_repository.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _chatRepository;

  ChatProvider(this._chatRepository);

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Send a message
  Future<bool> sendMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required String content,
    String recipientId = '',
    MessageType type = MessageType.text,
  }) async {
    try {
      _setError(null);

      final message = ChatMessage(
        id: '', // Will be set by Firestore
        bookingId: bookingId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: type,
        timestamp: DateTime.now(),
      );

      final messageId = await _chatRepository.sendMessage(message);

      // Add to local list immediately
      _messages.add(message.copyWith(id: messageId));
      notifyListeners();


      // Send push notification to recipient — fire and forget, never block chat
      if (recipientId.isNotEmpty) {
        unawaited(_sendChatNotification(recipientId, senderName, content, bookingId));
      }

      return true;
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    }
  }

  Future<void> _sendChatNotification(
      String recipientId, String senderName, String content, String bookingId) async {
    try {
      final userRepo = FirebaseUserRepository();
      final recipient = await userRepo.getUserById(recipientId);
      final fcmToken = recipient?.fcmToken;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️  [Chat] No fcmToken for recipient $recipientId');
        return;
      }
      await Future.wait([
        notification_service.NotificationService.sendNotificationToUser(
          {'token': fcmToken, 'title': 'New message from $senderName', 'body': content},
          data: {'type': 'chat', 'bookingId': bookingId, 'senderName': senderName},
        ),
        NotificationStoreService.storeNotification(
          recipientId: recipientId,
          title: 'New message from $senderName',
          body: content,
          type: 'chat',
          bookingId: bookingId,
          senderName: senderName,
        ),
      ]);
      debugPrint('✅ [Chat] Notification sent to $recipientId');
    } catch (e) {
      debugPrint('❌ [Chat] Failed to send chat notification: $e');
    }
  }

  // Load messages for a booking
  Future<void> loadMessages(String bookingId) async {
    try {
      _setLoading(true);
      _setError(null);

      final messages = await _chatRepository.getMessagesForBooking(bookingId);
      _messages = messages;

    } catch (e) {
      _setError('Failed to load messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Stream messages for real-time updates
  Stream<List<ChatMessage>> streamMessages(String bookingId) {
    return _chatRepository.getMessagesStreamForBooking(bookingId);
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String bookingId, String userId) async {
    try {
      await _chatRepository.markMessagesAsRead(bookingId, userId);

      // Update local messages
      _messages = _messages.map((message) {
        if (message.senderId != userId) {
          return message.copyWith(isRead: true);
        }
        return message;
      }).toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to mark messages as read: $e');
    }
  }

  // Get unread message count
  Future<void> loadUnreadCount(String bookingId, String userId) async {
    try {
      final count = await _chatRepository.getUnreadMessageCount(bookingId, userId);
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load unread count: $e');
    }
  }

  // Send system message (for job status updates)
  Future<void> sendSystemMessage({
    required String bookingId,
    required String content,
  }) async {
    await sendMessage(
      bookingId: bookingId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      recipientId: '',
      type: MessageType.system,
    );
  }

  // Clear messages when switching chats
  void clearMessages() {
    _messages.clear();
    _unreadCount = 0;
    notifyListeners();
  }
}