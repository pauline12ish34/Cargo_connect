import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_store_service.dart';
import '../core/repositories/booking_repository.dart';
import '../features/chat/chat_screen.dart';
import '../screens/job_details_screen.dart';
import '../constants.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () => NotificationStoreService.markAllRead(user.uid),
            child: const Text('Mark all read',
                style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationStoreService.notificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['isRead'] == true;
              final type = notif['type'] as String? ?? '';
              final icon = type == 'chat' ? Icons.chat : Icons.local_shipping;
              final color = type == 'chat' ? Colors.blue : primaryGreen;

              return InkWell(
                onTap: () => _onTap(context, notif, user.uid),
                child: Container(
                  color: isRead ? null : primaryGreen.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['body'] ?? '',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(notif['createdAt']),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onTap(BuildContext context, Map<String, dynamic> notif,
      String userId) async {
    // Mark this notification as read
    await NotificationStoreService.markOneRead(userId, notif['id'] as String);

    final type = notif['type'] as String? ?? '';
    final bookingId = notif['bookingId'] as String? ?? '';
    if (bookingId.isEmpty || !context.mounted) return;

    try {
      final booking =
          await FirebaseBookingRepository().getBookingById(bookingId);
      if (booking == null || !context.mounted) return;

      if (type == 'chat') {
        final senderName = notif['senderName'] as String? ?? 'User';
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              ChatScreen(booking: booking, otherUserName: senderName),
        ));
      } else if (type == 'job') {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => JobDetailsScreen(booking: booking),
        ));
      }
    } catch (e) {
      debugPrint('❌ [NotificationsScreen] Navigation failed: $e');
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as dynamic).toDate() as DateTime;
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
