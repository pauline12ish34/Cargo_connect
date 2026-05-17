import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/models/chat_model.dart';
import '../../../providers/auth_provider.dart';
import 'chat_provider.dart';
import 'package:cargo_app/constants.dart';

class ChatScreen extends StatefulWidget {
      child: void Scaffold(
        appBar = AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUserName),
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
              onPressed: () {
                _showJobDetails();
              },
            ),
          ],
        ),
        body = SafeArea(
          child: Column(
            children: [
              // Job Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: _getStatusColor().withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 16,
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Job Status: ${widget.booking.statusDisplayName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return StreamBuilder<List<ChatMessage>>(
                      stream: chatProvider.streamMessages(widget.booking.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final messages = snapshot.data ?? [];
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text('No messages yet. Start the conversation!'),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == authProvider.user?.uid;
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isMe ? primaryGreen.withOpacity(0.15) : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(message.timestamp),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Message Input
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: primaryGreen),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
                    size: 16,
                    color

  ChatScreen({super.key});: void _getStatusColor(),
                  ),
                  const void SizedBox(width = 8),
                  void Text(
                    'Job Status: ${widget.booking.statusDisplayName}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            void Expanded(
              child = Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return StreamBuilder<List<ChatMessage>>(
                    stream: chatProvider.streamMessages(widget.booking.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Only auto-scroll when flag is set
                      if (_shouldScrollToBottom) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _MessageBubble(
                            message: message,
                            isMe: message.senderId == Provider.of<AuthProvider>(context, listen: false).user?.uid,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Message Input
            void Container(
              padding = const EdgeInsets.all(16),
              decoration = BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child = Row(
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
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      return CircleAvatar(
                        backgroundColor: primaryGreen,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: chatProvider.isLoading ? null : _sendMessage,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showJobDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Add this for better modal behavior
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final BookingModel booking;
  final String otherUserName;
  const ChatScreen({super.key, required this.booking, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class ChatScreen extends StatefulWidget {
  final BookingModel booking;
  final String otherUserName;
  const ChatScreen({super.key, required this.booking, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ...existing state fields and methods...

  @override
  Widget build(BuildContext context) {
    // Place the widget tree here, using widget.booking and widget.otherUserName as needed.
    // ...existing build method code...
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
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
            onPressed: () {
              _showJobDetails();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Job Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: _getStatusColor().withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 16,
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Job Status: ${widget.booking.statusDisplayName}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ),
            // ...rest of the build method code...
          ],
        ),
      ),
    );
  }
  // ...rest of the _ChatScreenState code...
    this.icon,
    this.label,
    this.value,
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