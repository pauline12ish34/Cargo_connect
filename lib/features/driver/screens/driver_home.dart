import '../../../../widgets/app_states.dart';
import 'package:cargo_app/core/enums/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/booking_model.dart';
import '../../../features/booking/providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../constants.dart';
import '../../../screens/driver_profile_edit_screen.dart';
import '../../../screens/vehicle_details_screen.dart';
import '../../../screens/settings_screen.dart';
import '../../../screens/help_support_screen.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../screens/job_details_screen.dart';
import '../../../widgets/notification_badge_icon.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    if (authProvider.user != null) {
      bookingProvider.loadDriverBookings(authProvider.user!.uid);
      bookingProvider.loadAvailableBookings(authProvider.user!.uid);
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final List<Widget> pages = [
      _DashboardTab(onNavigateToTab: _onItemTapped),
      const _AvailableJobsTab(),
      const _MyJobsTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              fontFamily: 'Lexend',
            ),
            children: [
              TextSpan(text: 'Cargo', style: TextStyle(color: cs.onSurface)),
              const TextSpan(text: 'Link', style: TextStyle(color: appGreen)),
            ],
          ),
        ),
        elevation: 0,
        actions: [
          const NotificationBadgeIcon(),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final isAvailable = authProvider.user?.isAvailable ?? false;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isAvailable ? 'ONLINE' : 'OFFLINE',
                        key: ValueKey(isAvailable),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isAvailable ? appGreen : textGray,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isAvailable,
                        onChanged: (value) =>
                            authProvider.updateDriverAvailability(value),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Find Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'My Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: appGreen,
          unselectedItemColor: textGray,
          backgroundColor: cs.surface,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final Function(int) onNavigateToTab;
  const _DashboardTab({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (context, authProvider, bookingProvider, child) {
        final user = authProvider.user;
        final availableJobs = bookingProvider.availableBookings;
        final isOnline = user?.isAvailable == true;

        return RefreshIndicator(
          color: appGreen,
          onRefresh: () async {
            bookingProvider.loadDriverBookings(user!.uid);
            bookingProvider.loadAvailableBookings(user.uid);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.name.split(' ').first ?? 'Driver'} 🚛',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ).animate().fade().slideX(begin: -0.1),
                const SizedBox(height: 4),
                Text(
                  isOnline
                      ? 'You are ready to receive new jobs'
                      : 'Go online to see available jobs near you',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                ).animate().fade(delay: 100.ms),

                const SizedBox(height: 28),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Completed',
                        value: '${user?.completedJobs ?? 0}',
                        icon: Icons.check_circle_outline_rounded,
                        color: appGreen,
                      ).animate().fade(delay: 200.ms).scale(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Rating',
                        value: user?.rating?.toStringAsFixed(1) ?? '—',
                        icon: Icons.star_outline_rounded,
                        color: statusPending,
                      ).animate().fade(delay: 300.ms).scale(),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Jobs section
                if (isOnline) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Near You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigateToTab(1),
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: appGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 400.ms),
                  const SizedBox(height: 12),

                  if (bookingProvider.isLoading)
                    Column(
                      children: List.generate(
                        2,
                        (i) => const SkeletonCard(),
                      ),
                    )
                  else if (availableJobs.isEmpty)
                    _buildEmptyState(
                      context,
                      icon: Icons.search_off_rounded,
                      message: 'No jobs nearby right now',
                      subtitle: 'Check back soon — new shipments are posted frequently.',
                    )
                  else
                    Column(
                      children: availableJobs
                          .take(3)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) => _AvailableJobCard(booking: entry.value)
                              .animate()
                              .fade(delay: (500 + entry.key * 100).ms)
                              .slideY(begin: 0.08))
                          .toList(),
                    ),
                ] else
                  _buildOfflineState().animate().fade(delay: 400.ms),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfflineState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9EC),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: statusPending.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusPending.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: statusPending,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'You are currently Offline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Switch to Online to start discovering\ncargo shipments in your area.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF78350F),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Available Jobs Tab ───────────────────────────────────────────────────────
class _AvailableJobsTab extends StatelessWidget {
  const _AvailableJobsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (context, authProvider, bookingProvider, child) {
        if (authProvider.user?.isAvailable == false) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: textGray.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded, size: 40, color: textGray),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'You are Offline',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Go online using the toggle in the top bar to see available jobs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textGray, fontSize: 14, height: 1.6),
                  ),
                ],
              ).animate().fade(duration: 400.ms),
            ),
          );
        }

        if (bookingProvider.isLoading) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: List.generate(3, (i) => const SkeletonCard()),
          );
        }

        final availableJobs = bookingProvider.availableBookings;
        if (availableJobs.isEmpty) {
          return const AppEmpty(
            icon: Icons.search_off_rounded,
            message: 'No jobs available right now',
            subtitle: 'New shipments will appear here when posted nearby.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: availableJobs.length,
          itemBuilder: (context, index) => _AvailableJobCard(booking: availableJobs[index])
              .animate()
              .fade(delay: (index * 50).ms)
              .slideY(begin: 0.05),
        );
      },
    );
  }
}

// ─── My Jobs Tab ──────────────────────────────────────────────────────────────
class _MyJobsTab extends StatelessWidget {
  const _MyJobsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: List.generate(3, (i) => const SkeletonCard()),
          );
        }

        if (bookingProvider.myBookings.isEmpty) {
          return const AppEmpty(
            icon: Icons.assignment_outlined,
            message: 'No jobs assigned yet',
            subtitle: 'Accept a job from the "Find Jobs" tab to get started.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: bookingProvider.myBookings.length,
          itemBuilder: (context, index) =>
              _MyJobCard(booking: bookingProvider.myBookings[index])
                  .animate()
                  .fade(delay: (index * 50).ms)
                  .slideY(begin: 0.05),
        );
      },
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Available Job Card ───────────────────────────────────────────────────────
class _AvailableJobCard extends StatelessWidget {
  final BookingModel booking;
  const _AvailableJobCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.cargoDescription,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: appGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${booking.estimatedPrice?.toStringAsFixed(0) ?? '—'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: appGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildRouteInfo(context),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  booking.vehicleTypeDisplayName,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _showAcceptDialog(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('ACCEPT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Column(
          children: [
            const Icon(Icons.radio_button_checked_rounded, size: 13, color: appGreen),
            Container(width: 1.5, height: 14, color: cs.outlineVariant),
            const Icon(Icons.location_on_rounded, size: 13, color: statusCancelled),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.pickupLocation,
                style: TextStyle(fontSize: 13, color: cs.onSurface, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                booking.dropoffLocation,
                style: TextStyle(fontSize: 13, color: cs.onSurface, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAcceptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Job?'),
        content: Text(
          'Are you sure you want to accept the delivery of "${booking.cargoDescription}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
              await bookingProvider.acceptBooking(booking.id, authProvider.user!.uid);
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }
}

// ─── My Job Card ──────────────────────────────────────────────────────────────
class _MyJobCard extends StatelessWidget {
  final BookingModel booking;
  const _MyJobCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailsScreen(booking: booking)),
        ),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.statusDisplayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cs.outlineVariant, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                booking.cargoDescription,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.dropoffLocation,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return statusPending;
      case BookingStatus.accepted:
      case BookingStatus.inProgress:
        return appGreen;
      case BookingStatus.completed:
        return textDark;
      default:
        return statusCancelled;
    }
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ProfileProvider>(
      builder: (context, authProvider, profileProvider, child) {
        final user = profileProvider.currentUser ?? authProvider.user;
        final isOnline = user?.isAvailable == true;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Profile header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: appGreen.withOpacity(0.1),
                          backgroundImage: user?.profileImageUrl != null
                              ? NetworkImage(user!.profileImageUrl!)
                              : null,
                          child: user?.profileImageUrl == null
                              ? Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : 'D',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: appGreen,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isOnline ? appGreen : textGray,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'Driver',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (user?.email != null) ...[
                      const SizedBox(height: 4),
                      Text(user!.email, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Badge('DRIVER', appGreen),
                        const SizedBox(width: 8),
                        _Badge(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          isOnline ? appGreen : textGray,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade().scale(curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              // Menu section
              _MenuGroup(
                children: [
                  _MenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const DriverProfileEditScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.directions_car_outlined,
                    title: 'Vehicle Details',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const VehicleDetailsScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    isLast: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                  ),
                ],
              ).animate().fade(delay: 200.ms).slideY(begin: 0.08),

              const SizedBox(height: 16),

              _MenuGroup(
                children: [
                  _MenuTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    isLast: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                    ),
                  ),
                ],
              ).animate().fade(delay: 280.ms).slideY(begin: 0.08),

              const SizedBox(height: 28),

              // Logout
              Container(
                decoration: BoxDecoration(
                  color: statusCancelled.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(cardBorderRadius),
                  border: Border.all(color: statusCancelled.withOpacity(0.2)),
                ),
                child: ListTile(
                  onTap: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    }
                  },
                  leading: const Icon(Icons.logout_rounded, color: statusCancelled, size: 20),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: statusCancelled,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: statusCancelled, size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cardBorderRadius)),
                ),
              ).animate().fade(delay: 360.ms),
            ],
          ),
        );
      },
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

// ─── Menu Group ───────────────────────────────────────────────────────────────
class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

// ─── Menu Tile ────────────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: appGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: appGreen),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.outlineVariant, size: 20),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(cardBorderRadius))
                : BorderRadius.zero,
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
