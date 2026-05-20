import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/notifications_screen.dart';
import '../services/notification_store_service.dart';

/// AppBar action icon that shows a red badge with the unread notification count.
/// Tapping it opens [NotificationsScreen].
class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    // listen: true so the badge rebuilds when auth state changes
    final uid = Provider.of<AuthProvider>(context).user?.uid;

    if (uid == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_none_outlined),
        tooltip: 'Notifications',
        onPressed: () {},
      );
    }

    return StreamBuilder<int>(
      stream: NotificationStoreService.unreadCountStream(uid),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;

        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_outlined),
              if (unread > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
