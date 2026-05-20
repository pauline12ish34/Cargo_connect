import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo_app/core/models/booking_model.dart';
import 'package:cargo_app/core/models/user_model.dart';
import 'package:cargo_app/core/repositories/user_repository.dart';
import 'package:cargo_app/features/booking/providers/booking_provider.dart';
import 'package:cargo_app/providers/auth_provider.dart';
import 'package:cargo_app/core/enums/app_enums.dart';
import 'package:cargo_app/features/chat/chat_screen.dart';
import 'package:cargo_app/constants.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const JobDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  UserModel? _assignedDriver;
  bool _isLoading = false;
  bool _hasRated = false;
  bool _hasRatedOwner = false;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
    _checkIfRated();
    _checkIfRatedOwner();
  }

  Future<void> _checkIfRated() async {
    final doc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.booking.id)
        .get();
    if (doc.exists && doc.data()?['driverRating'] != null) {
      if (mounted) setState(() => _hasRated = true);
    }
  }

  Future<void> _checkIfRatedOwner() async {
    final doc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.booking.id)
        .get();
    if (doc.exists && doc.data()?['ownerRating'] != null) {
      if (mounted) setState(() => _hasRatedOwner = true);
    }
  }

  Future<void> _loadDriverInfo() async {
    if (widget.booking.driverId != null) {
      setState(() => _isLoading = true);
      try {
        final userRepository =
            Provider.of<UserRepository>(context, listen: false);
        final driver =
            await userRepository.getUserById(widget.booking.driverId!);
        setState(() => _assignedDriver = driver);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load driver info: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCargoOwner = authProvider.user?.role == UserRole.cargoOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if ((widget.booking.status == BookingStatus.accepted ||
                  widget.booking.status == BookingStatus.inProgress) &&
              widget.booking.driverId != null)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: _openChat,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBanner(booking: widget.booking),
                  const SizedBox(height: 24),
                  _SectionCard(
                    title: 'Job Information',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.inventory,
                          label: 'Cargo Description',
                          value: widget.booking.cargoDescription,
                        ),
                        _InfoRow(
                          icon: Icons.location_on,
                          label: 'Pickup Location',
                          value: widget.booking.pickupLocation,
                        ),
                        _InfoRow(
                          icon: Icons.flag,
                          label: 'Dropoff Location',
                          value: widget.booking.dropoffLocation,
                        ),
                        _InfoRow(
                          icon: Icons.local_shipping,
                          label: 'Vehicle Type',
                          value: widget.booking.vehicleTypeDisplayName,
                        ),
                        if (widget.booking.weight != null)
                          _InfoRow(
                            icon: Icons.scale,
                            label: 'Weight',
                            value: '${widget.booking.weight}kg',
                          ),
                        if (widget.booking.estimatedPrice != null)
                          _InfoRow(
                            icon: Icons.money,
                            label: 'Estimated Price',
                            value:
                                '${widget.booking.estimatedPrice!.toStringAsFixed(0)} RWF',
                          ),
                        if (widget.booking.specialInstructions?.isNotEmpty ==
                            true)
                          _InfoRow(
                            icon: Icons.note,
                            label: 'Special Instructions',
                            value: widget.booking.specialInstructions!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Driver info (if assigned)
                  if (_assignedDriver != null) ...[
                    _SectionCard(
                      title: 'Assigned Driver',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: primaryGreen,
                                child: Text(
                                  _assignedDriver!.name.isNotEmpty
                                      ? _assignedDriver!.name[0].toUpperCase()
                                      : 'D',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _assignedDriver!.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (_assignedDriver!.isVerified)
                                          const Tooltip(
                                            message: 'Verified Driver',
                                            child: Icon(Icons.verified,
                                                size: 18, color: Colors.blue),
                                          )
                                        else
                                          Tooltip(
                                            message: 'Not yet verified',
                                            child: Icon(
                                                Icons.warning_amber_rounded,
                                                size: 18,
                                                color: Colors.orange.shade400),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 16, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text(
                                          _assignedDriver!.rating
                                                  ?.toStringAsFixed(1) ??
                                              'No rating',
                                          style:
                                              const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.work,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_assignedDriver!.completedJobs ?? 0} jobs',
                                          style:
                                              const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Timeline
                  _SectionCard(
                    title: 'Timeline',
                    child: Column(
                      children: [
                        _TimelineItem(
                          icon: Icons.add_circle,
                          title: 'Job Created',
                          subtitle: _formatDateTime(widget.booking.createdAt),
                          isCompleted: true,
                        ),
                        if (widget.booking.acceptedAt != null)
                          _TimelineItem(
                            icon: Icons.check_circle,
                            title: 'Job Accepted',
                            subtitle:
                                _formatDateTime(widget.booking.acceptedAt!),
                            isCompleted: true,
                          ),
                        if (widget.booking.status == BookingStatus.declined)
                          const _TimelineItem(
                            icon: Icons.cancel,
                            title: 'Job Declined',
                            subtitle: 'Driver declined this job',
                            isCompleted: true,
                            isError: true,
                          ),
                        if (widget.booking.status == BookingStatus.cancelled)
                          const _TimelineItem(
                            icon: Icons.cancel,
                            title: 'Job Cancelled',
                            subtitle: 'Job was cancelled',
                            isCompleted: true,
                            isError: true,
                          ),
                        if (widget.booking.completedAt != null)
                          _TimelineItem(
                            icon: Icons.check_circle_outline,
                            title: 'Job Completed',
                            subtitle:
                                _formatDateTime(widget.booking.completedAt!),
                            isCompleted: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  if (isCargoOwner) ..._buildCargoOwnerActions(),
                  if (!isCargoOwner) ..._buildDriverActions(),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildCargoOwnerActions() {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cancelJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Job'),
            ),
          ),
        ];
      case BookingStatus.accepted:
      case BookingStatus.inProgress:
        return [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ];
      case BookingStatus.declined:
        return [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _reassignJob,
              icon: const Icon(Icons.refresh),
              label: const Text('Find Another Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ];
      case BookingStatus.completed:
        return [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('Job completed successfully!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_assignedDriver != null && !_hasRated) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showRatingDialog,
                icon: const Icon(Icons.star),
                label: const Text('Rate Driver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else if (_hasRated) ...[
            const SizedBox(height: 8),
            const Center(
              child: Text('You have rated this driver', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ];
      case BookingStatus.cancelled:
        return [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.red),
                SizedBox(width: 12),
                Text(
                  'Job was cancelled',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ];
    }
  }

  List<Widget> _buildDriverActions() {
    switch (widget.booking.status) {
      case BookingStatus.accepted:
        return [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Cargo Owner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Completed'),
            ),
          ),
        ];
      case BookingStatus.completed:
        return [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('Job completed successfully!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (!_hasRatedOwner) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showOwnerRatingDialog,
                icon: const Icon(Icons.star),
                label: const Text('Rate Cargo Owner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Center(
              child: Text('You have rated this cargo owner', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ];
      default:
        return [];
    }
  }

  void _showOwnerRatingDialog() {
    double selectedRating = 5.0;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rate Cargo Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your experience with this cargo owner?'),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.orange),
              onRatingUpdate: (rating) => selectedRating = rating,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _submitOwnerRating(selectedRating);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOwnerRating(double rating) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .update({'ownerRating': rating});

      if (mounted) {
        setState(() => _hasRatedOwner = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted. Thank you!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    }
  }

  void _showRatingDialog() {
    double selectedRating = 5.0;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rate Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How was your experience with ${_assignedDriver!.name}?'),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.orange),
              onRatingUpdate: (rating) => selectedRating = rating,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _submitRating(selectedRating);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(double rating) async {
    if (_assignedDriver == null) return;
    try {
      final driverRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_assignedDriver!.uid);
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id);

      final currentRating = _assignedDriver!.rating ?? 0.0;
      final currentJobs = _assignedDriver!.completedJobs ?? 0;
      final newAvg = currentJobs > 0
          ? ((currentRating * currentJobs) + rating) / (currentJobs + 1)
          : rating;

      await Future.wait([
        driverRef.update({
          'rating': double.parse(newAvg.toStringAsFixed(1)),
          'completedJobs': currentJobs + 1,
        }),
        bookingRef.update({'driverRating': rating}),
      ]);

      if (mounted) {
        setState(() => _hasRated = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted. Thank you!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    }
  }

  void _openChat() {
    if (_assignedDriver == null && widget.booking.driverId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading driver information...')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCargoOwner = authProvider.user?.role == UserRole.cargoOwner;

    final otherUserName =
        isCargoOwner ? (_assignedDriver?.name ?? 'Driver') : 'Cargo Owner';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          booking: widget.booking,
          otherUserName: otherUserName,
        ),
      ),
    );
  }

  void _reassignJob() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Find Another Driver'),
        content: const Text(
            'This will make the job available to other drivers. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await bookingProvider.reassignBooking(widget.booking.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job is now available for other drivers'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _cancelJob() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Job'),
        content: const Text('Are you sure you want to cancel this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await bookingProvider.cancelBooking(widget.booking.id);
      if (success && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _completeJob() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Job'),
        content: const Text('Mark this job as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await bookingProvider.completeBooking(widget.booking.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBanner extends StatelessWidget {
  final BookingModel booking;

  const _StatusBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    switch (booking.status) {
      case BookingStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusMessage = 'Waiting for a driver to accept';
        break;
      case BookingStatus.accepted:
        statusColor = primaryGreen;
        statusIcon = Icons.check_circle;
        statusMessage = 'Driver has accepted your job';
        break;
      case BookingStatus.declined:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusMessage = 'Driver declined — you can reassign';
        break;
      case BookingStatus.inProgress:
        statusColor = Colors.purple;
        statusIcon = Icons.local_shipping;
        statusMessage = 'Job is in progress';
        break;
      case BookingStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusMessage = 'Job completed successfully';
        break;
      case BookingStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusMessage = 'Job was cancelled';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.statusDisplayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor.withValues(alpha: 0.8),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

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
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isError;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isError ? Colors.red : (isCompleted ? Colors.green : Colors.grey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
