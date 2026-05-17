import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/booking_model.dart';
import '../../core/models/chat_model.dart';
import '../../core/enums/app_enums.dart';
import '../../providers/auth_provider.dart';
import 'chat_provider.dart';
import 'package:cargo_app/constants.dart';

class ChatScreen extends StatefulWidget {
  final BookingModel booking;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.booking,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  bool _shouldScrollToBottom = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<ChatProvider>(context, listen: false)
            .markMessagesAsRead(widget.booking.id, authProvider.user!.uid);
      }
      setState(() => _isInitialized = true);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    _messageController.clear();
    _shouldScrollToBottom = true;

    final recipientId = user.uid == widget.booking.cargoOwnerId
        ? (widget.booking.driverId ?? '')
        : widget.booking.cargoOwnerId;

    await chatProvider.sendMessage(
      bookingId: widget.booking.id,
      senderId: user.uid,
      senderName: user.name,
      content: text,
      recipientId: recipientId,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Color _getStatusColor() {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.accepted:
      case BookingStatus.inProgress:
        return primaryGreen;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.declined:
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return Icons.pending;
      case BookingStatus.accepted:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.local_shipping;
      case BookingStatus.completed:
        return Icons.check_circle_outline;
      case BookingStatus.declined:
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _showJobDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.inventory,
              label: 'Cargo',
              value: widget.booking.cargoDescription,
            ),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Pickup',
              value: widget.booking.pickupLocation,
            ),
            _DetailRow(
              icon: Icons.flag,
              label: 'Dropoff',
              value: widget.booking.dropoffLocation,
            ),
            _DetailRow(
              icon: Icons.local_shipping,
              label: 'Vehicle Type',
              value: widget.booking.vehicleTypeDisplayName,
            ),
            if (widget.booking.weight != null)
              _DetailRow(
                icon: Icons.scale,
                label: 'Weight',
                value: '${widget.booking.weight}kg',
              ),
            if (widget.booking.estimatedPrice != null)
              _DetailRow(
                icon: Icons.money,
                label: 'Estimated Price',
                value: '${widget.booking.estimatedPrice!.toStringAsFixed(0)} RWF',
              ),
            if (widget.booking.specialInstructions?.isNotEmpty == true)
              _DetailRow(
                icon: Icons.note,
                label: 'Special Instructions',
                value: widget.booking.specialInstructions!,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.booking.cargoDescription,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showJobDetails,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Job status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: _getStatusColor().withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
                  const SizedBox(width: 8),
                  Text(
                    'Job Status: ${widget.booking.statusDisplayName}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ),

            // Messages list
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: Provider.of<ChatProvider>(context, listen: false)
                    .streamMessages(widget.booking.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !_isInitialized) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading messages: ${snapshot.error}'),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_shouldScrollToBottom) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                      _shouldScrollToBottom = false;
                    });
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe =
                          message.senderId == authProvider.user?.uid;
                      return _MessageBubble(
                        message: message,
                        isMe: isMe,
                        formatTimestamp: _formatTimestamp,
                      );
                    },
                  );
                },
              ),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) => CircleAvatar(
                      backgroundColor: primaryGreen,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: chatProvider.isLoading ? null : _sendMessage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String Function(DateTime) formatTimestamp;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? primaryGreen.withValues(alpha: 0.15) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            Text(message.content, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              formatTimestamp(message.timestamp),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
