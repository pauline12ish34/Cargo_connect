import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cargo_app/constants.dart';
import 'package:cargo_app/core/models/booking_model.dart';
import 'package:cargo_app/core/models/user_model.dart';
import 'package:cargo_app/core/repositories/user_repository.dart';
import 'package:cargo_app/features/booking/providers/booking_provider.dart';
import 'package:cargo_app/providers/auth_provider.dart';
import 'package:cargo_app/core/enums/app_enums.dart';
import 'package:cargo_app/features/chat/chat_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const JobDetailsScreen({super.key, required this.booking});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  UserModel? _assignedDriver;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }

  Future<void> _loadDriverInfo() async {
    if (widget.booking.driverId != null) {
      setState(() => _isLoading = true);
      try {
        final userRepository = Provider.of<UserRepository>(context, listen: false);
        final driver = await userRepository.getUserById(widget.booking.driverId!);
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
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('Job Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if ((widget.booking.status == BookingStatus.accepted ||
                  widget.booking.status == BookingStatus.inProgress) &&
              widget.booking.driverId != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: _openChat,
              tooltip: 'Open chat',
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(appGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  _StatusBanner(booking: widget.booking)
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: -0.1),

                  const SizedBox(height: 20),

                  // Job Information
                  _SectionCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Job Information',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.description_outlined,
                          label: 'Cargo Description',
                          value: widget.booking.cargoDescription,
                        ),
                        _InfoRow(
                          icon: Icons.radio_button_checked_rounded,
                          label: 'Pickup Location',
                          value: widget.booking.pickupLocation,
                          iconColor: appGreen,
                        ),
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Dropoff Location',
                          value: widget.booking.dropoffLocation,
                          iconColor: statusCancelled,
                        ),
                        _InfoRow(
                          icon: Icons.local_shipping_outlined,
                          label: 'Vehicle Type',
                          value: widget.booking.vehicleTypeDisplayName,
                        ),
                        if (widget.booking.weight != null)
                          _InfoRow(
                            icon: Icons.scale_outlined,
                            label: 'Weight',
                            value: '${widget.booking.weight} kg',
                          ),
                        if (widget.booking.estimatedPrice != null)
                          _InfoRow(
                            icon: Icons.payments_outlined,
                            label: 'Estimated Price',
                            value: '${widget.booking.estimatedPrice!.toStringAsFixed(0)} RWF',
                            isLast: widget.booking.specialInstructions?.isEmpty ?? true,
                          ),
                        if (widget.booking.specialInstructions?.isNotEmpty == true)
                          _InfoRow(
                            icon: Icons.sticky_note_2_outlined,
                            label: 'Special Instructions',
                            value: widget.booking.specialInstructions!,
                            isLast: true,
                          ),
                      ],
                    ),
                  ).animate().fade(delay: 100.ms).slideY(begin: 0.06),

                  const SizedBox(height: 16),

                  // Assigned Driver
                  if (_assignedDriver != null)
                    _DriverCard(
                      driver: _assignedDriver!,
                      booking: widget.booking,
                      onChat: _openChat,
                    )
                        .animate()
                        .fade(delay: 200.ms)
                        .slideY(begin: 0.06),

                  if (_assignedDriver != null) const SizedBox(height: 16),

                  // Timeline
                  _SectionCard(
                    icon: Icons.timeline_rounded,
                    title: 'Timeline',
                    child: Column(
                      children: [
                        _TimelineItem(
                          icon: Icons.add_circle_rounded,
                          title: 'Job Created',
                          subtitle: _formatDateTime(widget.booking.createdAt),
                          isCompleted: true,
                          isFirst: true,
                        ),
                        if (widget.booking.acceptedAt != null)
                          _TimelineItem(
                            icon: Icons.check_circle_rounded,
                            title: 'Job Accepted',
                            subtitle: _formatDateTime(widget.booking.acceptedAt!),
                            isCompleted: true,
                          ),
                        if (widget.booking.status == BookingStatus.declined)
                          const _TimelineItem(
                            icon: Icons.cancel_rounded,
                            title: 'Job Declined',
                            subtitle: 'Driver declined this job',
                            isCompleted: true,
                            isError: true,
                            isLast: true,
                          ),
                        if (widget.booking.status == BookingStatus.cancelled)
                          const _TimelineItem(
                            icon: Icons.cancel_rounded,
                            title: 'Job Cancelled',
                            subtitle: 'Job was cancelled',
                            isCompleted: true,
                            isError: true,
                            isLast: true,
                          ),
                        if (widget.booking.completedAt != null)
                          _TimelineItem(
                            icon: Icons.verified_rounded,
                            title: 'Job Completed',
                            subtitle: _formatDateTime(widget.booking.completedAt!),
                            isCompleted: true,
                            isLast: true,
                          ),
                      ],
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.06),

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (isCargoOwner) ..._buildCargoOwnerActions(),
                  if (!isCargoOwner) ..._buildDriverActions(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildCargoOwnerActions() {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return [
          ElevatedButton.icon(
            onPressed: _cancelJob,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('CANCEL JOB'),
            style: ElevatedButton.styleFrom(
              backgroundColor: statusCancelled,
              foregroundColor: Colors.white,
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
        ];
      case BookingStatus.accepted:
      case BookingStatus.inProgress:
        return [
          ElevatedButton.icon(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('CHAT WITH DRIVER'),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
        ];
      case BookingStatus.declined:
        return [
          ElevatedButton.icon(
            onPressed: _reassignJob,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('FIND ANOTHER DRIVER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: statusPending,
              foregroundColor: Colors.white,
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
        ];
      default:
        return [];
    }
  }

  List<Widget> _buildDriverActions() {
    switch (widget.booking.status) {
      case BookingStatus.accepted:
        return [
          ElevatedButton.icon(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('CHAT WITH CARGO OWNER'),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _completeJob,
            icon: const Icon(Icons.verified_rounded, size: 18),
            label: const Text('MARK AS COMPLETED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
          ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
        ];
      default:
        return [];
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
    final otherUserName = isCargoOwner ? (_assignedDriver?.name ?? 'Driver') : 'Cargo Owner';

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
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final confirmed = await _showConfirmDialog(
      title: 'Find Another Driver',
      content: 'This will make the job available to other drivers. Continue?',
      confirmLabel: 'Continue',
      confirmColor: statusPending,
    );

    if (confirmed == true) {
      final success = await bookingProvider.reassignBooking(widget.booking.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job is now available for other drivers')),
        );
      }
    }
  }

  void _cancelJob() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final confirmed = await _showConfirmDialog(
      title: 'Cancel Job',
      content: 'Are you sure you want to cancel this job?',
      confirmLabel: 'Yes, Cancel',
      confirmColor: statusCancelled,
    );

    if (confirmed == true) {
      final success = await bookingProvider.cancelBooking(widget.booking.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job cancelled successfully')),
        );
      }
    }
  }

  void _completeJob() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final confirmed = await _showConfirmDialog(
      title: 'Complete Job',
      content: 'Mark this job as completed?',
      confirmLabel: 'Complete',
      confirmColor: appGreen,
    );

    if (confirmed == true) {
      final success = await bookingProvider.completeBooking(widget.booking.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job completed successfully!')),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} · '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final BookingModel booking;
  const _StatusBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    final (color, icon, message) = _getStatusConfig(booking.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.statusDisplayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _getStatusConfig(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return (statusPending, Icons.schedule_rounded, 'Waiting for a driver to accept');
      case BookingStatus.accepted:
        return (appGreen, Icons.check_circle_rounded, 'Driver has accepted your job');
      case BookingStatus.declined:
        return (statusCancelled, Icons.cancel_rounded, 'Driver declined — you can reassign');
      case BookingStatus.inProgress:
        return (const Color(0xFF8B5CF6), Icons.local_shipping_rounded, 'Job is currently in progress');
      case BookingStatus.completed:
        return (appGreen, Icons.verified_rounded, 'Job completed successfully');
      case BookingStatus.cancelled:
        return (statusCancelled, Icons.cancel_rounded, 'Job was cancelled');
    }
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: borderGray.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: appGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: appGreen),
                ),
                const SizedBox(width: 10),
                Text(title, style: sectionTitleStyle),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (iconColor ?? textGray).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor ?? textGray),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: textGray,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                    height: 1.4,
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

// ─── Driver Card ──────────────────────────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  final UserModel driver;
  final BookingModel booking;
  final VoidCallback onChat;

  const _DriverCard({required this.driver, required this.booking, required this.onChat});

  @override
  Widget build(BuildContext context) {
    final showChat = booking.status == BookingStatus.accepted ||
        booking.status == BookingStatus.inProgress;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: borderGray.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: appGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_rounded, size: 16, color: appGreen),
                ),
                const SizedBox(width: 10),
                const Text('Assigned Driver', style: sectionTitleStyle),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: appGreen.withOpacity(0.1),
                      backgroundImage: driver.profileImageUrl != null
                          ? NetworkImage(driver.profileImageUrl!)
                          : null,
                      child: driver.profileImageUrl == null
                          ? Text(
                              driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: appGreen,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: statusPending),
                              const SizedBox(width: 4),
                              Text(
                                driver.rating?.toStringAsFixed(1) ?? '—',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.work_outline_rounded,
                                  size: 14, color: textGray),
                              const SizedBox(width: 4),
                              Text(
                                '${driver.completedJobs ?? 0} jobs',
                                style: const TextStyle(fontSize: 13, color: textGray),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (showChat) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Open Chat'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline Item ────────────────────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isError;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isError = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? statusCancelled
        : isCompleted
            ? appGreen
            : textGray;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line + icon column
        SizedBox(
          width: 32,
          child: Column(
            children: [
              if (!isFirst)
                Container(width: 2, height: 12, color: color.withOpacity(0.25)),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  color: color.withOpacity(0.25),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: textGray, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
