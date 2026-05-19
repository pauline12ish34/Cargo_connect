import '../../../../widgets/app_states.dart';
import 'package:cargo_app/constants.dart';
import 'package:cargo_app/core/enums/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/booking_model.dart';
import '../../../features/booking/providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../screens/create_job_screen.dart';
import '../../../screens/help_support_screen.dart';
import '../../../screens/job_details_screen.dart';
import '../../../screens/personal_data_screen.dart';
import '../../../screens/settings_screen.dart';
import '../../../widgets/notification_badge_icon.dart';

class CargoOwnerHome extends StatefulWidget {
  const CargoOwnerHome({super.key});

  @override
  State<CargoOwnerHome> createState() => _CargoOwnerHomeState();
}

class _CargoOwnerHomeState extends State<CargoOwnerHome> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings());
  }

  void _loadBookings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    if (authProvider.user != null) {
      bookingProvider.loadCargoOwnerBookings(authProvider.user!.uid);
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final List<Widget> pages = [
      const _DashboardTab(),
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
          const SizedBox(width: 4),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping_rounded),
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
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: cs.surface,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
      floatingActionButton: _selectedIndex != 2
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateJobScreen()),
                ).then((_) => _loadBookings());
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'NEW JOB',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  fontSize: 13,
                ),
              ),
            ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack)
          : null,
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (context, authProvider, bookingProvider, child) {
        final user = authProvider.user;
        final recentBookings = bookingProvider.myBookings.take(3).toList();

        return RefreshIndicator(
          color: appGreen,
          onRefresh: () async =>
              bookingProvider.loadCargoOwnerBookings(user!.uid),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user?.name.split(' ').first ?? 'User'} 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ).animate().fade().slideX(begin: -0.1),
                const SizedBox(height: 4),
                Text(
                  'Manage your cargo shipments with ease',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                ).animate().fade(delay: 100.ms),

                const SizedBox(height: 28),

                // Stats grid
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'All Jobs',
                        value: '${bookingProvider.myBookings.length}',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF3B82F6),
                      ).animate().fade(delay: 200.ms).scale(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _StatCard(
                        title: 'Completed',
                        value:
                            '${bookingProvider.myBookings.where((b) => b.status == BookingStatus.completed).length}',
                        icon: Icons.check_circle_outline_rounded,
                        color: appGreen,
                      ).animate().fade(delay: 280.ms).scale(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Active',
                        value:
                            '${bookingProvider.myBookings.where((b) => b.status == BookingStatus.accepted || b.status == BookingStatus.inProgress).length}',
                        icon: Icons.local_shipping_outlined,
                        color: const Color(0xFF8B5CF6),
                      ).animate().fade(delay: 360.ms).scale(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _StatCard(
                        title: 'Pending',
                        value:
                            '${bookingProvider.myBookings.where((b) => b.status == BookingStatus.pending).length}',
                        icon: Icons.schedule_rounded,
                        color: statusPending,
                      ).animate().fade(delay: 440.ms).scale(),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Shipments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .findAncestorStateOfType<_CargoOwnerHomeState>()
                            ?._onItemTapped(1);
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: appGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 520.ms),

                const SizedBox(height: 12),

                if (bookingProvider.isLoading)
                  Column(
                    children: List.generate(2, (i) => const SkeletonCard()),
                  )
                else if (recentBookings.isEmpty)
                  _buildEmptyState(context)
                else
                  Column(
                    children: recentBookings
                        .asMap()
                        .entries
                        .map((entry) => _JobCard(booking: entry.value)
                            .animate()
                            .fade(delay: (600 + entry.key * 80).ms)
                            .slideY(begin: 0.08))
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appGreen.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              size: 36,
              color: appGreen.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No shipments yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the NEW JOB button to create\nyour first cargo request.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    ).animate().fade(delay: 600.ms);
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
            icon: Icons.inventory_2_outlined,
            message: 'No shipments yet',
            subtitle: 'Your cargo jobs will appear here once created.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: bookingProvider.myBookings.length,
          itemBuilder: (context, index) {
            final booking = bookingProvider.myBookings[index];
            return _JobCard(booking: booking)
                .animate()
                .fade(delay: (index * 50).ms)
                .slideY(begin: 0.05);
          },
        );
      },
    );
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

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Profile card
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
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: appGreen,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: appGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: appGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: appGreen.withOpacity(0.2)),
                      ),
                      child: const Text(
                        'CARGO OWNER',
                        style: TextStyle(
                          color: appGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade().scale(curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              // Menu
              _MenuGroup(
                children: [
                  _MenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PersonalDataScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.business_outlined,
                    title: 'Company Details',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Company Details — coming soon')),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    title: 'App Settings',
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
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About CargoLink',
                    isLast: true,
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'CargoLink',
                      applicationVersion: '1.0.0',
                      children: [
                        const Text(
                          'Connecting cargo owners with reliable drivers across Rwanda.',
                          style: TextStyle(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fade(delay: 280.ms).slideY(begin: 0.08),

              const SizedBox(height: 28),

              // Logout button
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
                    borderRadius: BorderRadius.circular(cardBorderRadius),
                  ),
                ),
              ).animate().fade(delay: 360.ms),
            ],
          ),
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
          const SizedBox(height: 14),
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

// ─── Job Card ─────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final BookingModel booking;
  const _JobCard({required this.booking});

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
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(booking: booking),
          ),
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
                  Text(
                    booking.estimatedPrice != null
                        ? '${booking.estimatedPrice!.toStringAsFixed(0)} RWF'
                        : '—',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              // Route
              Row(
                children: [
                  Column(
                    children: [
                      const Icon(Icons.radio_button_checked_rounded,
                          size: 12, color: appGreen),
                      Container(width: 1.5, height: 12, color: cs.outlineVariant),
                      const Icon(Icons.location_on_rounded,
                          size: 12, color: statusCancelled),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.pickupLocation,
                          style: TextStyle(fontSize: 13, color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          booking.dropoffLocation,
                          style: TextStyle(fontSize: 13, color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    booking.vehicleTypeDisplayName,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(booking.createdAt),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
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
