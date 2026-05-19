import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../core/models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_states.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAllAsRead());
  }

  Future<void> _markAllAsRead() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? const AppEmpty(
              icon: Icons.notifications_off_outlined,
              message: 'Not signed in',
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(uid)
                  .collection('items')
                  .orderBy('createdAt', descending: true)
                  .limit(60)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoading(message: 'Loading…');
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const AppEmpty(
                    icon: Icons.notifications_none_outlined,
                    message: 'No notifications yet',
                    subtitle: 'Job updates and alerts will appear here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final notif = NotificationModel.fromDoc(docs[index]);
                    return _NotificationTile(notif: notif)
                        .animate()
                        .fade(delay: (index * 30).ms)
                        .slideY(begin: 0.04);
                  },
                );
              },
            ),
    );
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  const _NotificationTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconData = _iconFor(notif.status);
    final color = _colorFor(notif.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: notif.isRead ? cs.surface : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notif.isRead
              ? cs.outlineVariant.withOpacity(0.5)
              : color.withOpacity(0.25),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, size: 22, color: color),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight:
                notif.isRead ? FontWeight.w500 : FontWeight.bold,
            fontSize: 14,
            color: cs.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notif.body,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              _timeAgo(notif.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
        trailing: notif.isRead
            ? null
            : Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  IconData _iconFor(String status) {
    switch (status) {
      case 'assigned':
        return Icons.assignment_ind_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'assigned':
        return const Color(0xFF3B82F6);
      case 'accepted':
      case 'completed':
        return appGreen;
      case 'cancelled':
        return statusCancelled;
      default:
        return statusPending;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
