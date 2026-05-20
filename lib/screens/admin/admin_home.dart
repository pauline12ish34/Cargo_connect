import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../core/models/user_model.dart';
import '../../core/models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/job_notification_service.dart';
import '../../widgets/app_states.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    final pages = [
      const _OverviewTab(),
      const _VerificationTab(),
      const _UsersTab(),
      const _BookingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            children: [
              TextSpan(text: 'Admin ', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Panel', style: TextStyle(color: Color(0xFFB2FFD6))),
            ],
          ),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            onSelected: (v) {
              if (v == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).signOut();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user?.name ?? 'Admin',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'Verify'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Bookings'),
        ],
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
          builder: (context, bookingsSnap) {
            if (!usersSnap.hasData || !bookingsSnap.hasData) {
              return const AppLoading(message: 'Loading stats…');
            }

            final users = usersSnap.data!.docs
                .map((d) => UserModel.fromFirestore(d))
                .toList();
            final totalDrivers = users.where((u) => u.isDriver).length;
            final totalOwners = users.where((u) => u.isCargoOwner).length;
            final pendingVerification = users
                .where((u) => u.isDriver &&
                    (u.verificationStatus == 'pending' ||
                        u.verificationStatus == 'under_review'))
                .length;
            final verifiedDrivers =
                users.where((u) => u.isDriver && u.isVerified).length;
            final totalBookings = bookingsSnap.data!.docs.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('System Overview',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(
                        label: 'Total Drivers',
                        value: '$totalDrivers',
                        icon: Icons.local_shipping,
                        color: primaryGreen,
                      ),
                      _StatCard(
                        label: 'Cargo Owners',
                        value: '$totalOwners',
                        icon: Icons.business,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        label: 'Pending Review',
                        value: '$pendingVerification',
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                      _StatCard(
                        label: 'Verified Drivers',
                        value: '$verifiedDrivers',
                        icon: Icons.verified,
                        color: Colors.green,
                      ),
                      _StatCard(
                        label: 'Total Bookings',
                        value: '$totalBookings',
                        icon: Icons.receipt_long,
                        color: Colors.purple,
                      ),
                      _StatCard(
                        label: 'Total Users',
                        value: '${totalDrivers + totalOwners}',
                        icon: Icons.people,
                        color: Colors.teal,
                      ),
                    ],
                  ),

                  if (pendingVerification > 0) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$pendingVerification driver(s) waiting for verification. Go to the Verify tab.',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Verification Tab ──────────────────────────────────────────────────────────

class _VerificationTab extends StatelessWidget {
  const _VerificationTab();

  Stream<List<UserModel>> _stream() => FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'driver')
      .where('verificationStatus', whereIn: ['pending', 'under_review'])
      .snapshots()
      .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());

  Future<void> _updateStatus(
      BuildContext context, String uid, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'verificationStatus': status, 'updatedAt': Timestamp.now()});

      // Notify the driver of the outcome
      await JobNotificationService.notifyDriverVerificationResult(
        driverId: uid,
        status: status,
      );

      if (context.mounted) {
        AppSnackbar.showSuccess(
          context,
          status == 'verified' ? 'Driver approved and notified!' : 'Driver rejected and notified.',
        );
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.showError(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading(message: 'Loading pending drivers…');
        }
        if (snapshot.hasError) {
          return AppError(message: 'Error: ${snapshot.error}');
        }

        final drivers = snapshot.data ?? [];
        if (drivers.isEmpty) {
          return const AppEmpty(
            icon: Icons.verified_user,
            title: 'All caught up!',
            subtitle: 'No drivers awaiting verification.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drivers.length,
          itemBuilder: (context, i) {
            final d = drivers[i];
            return _DriverVerificationCard(
              driver: d,
              onApprove: () => _updateStatus(context, d.uid, 'verified'),
              onReject: () => _updateStatus(context, d.uid, 'rejected'),
            );
          },
        );
      },
    );
  }
}

// ─── Users Tab ─────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _search = '';
  String _filter = 'all'; // all | driver | cargoOwner

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name or email…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip('All', 'all', _filter,
                        () => setState(() => _filter = 'all')),
                    const SizedBox(width: 8),
                    _FilterChip('Drivers', 'driver', _filter,
                        () => setState(() => _filter = 'driver')),
                    const SizedBox(width: 8),
                    _FilterChip('Cargo Owners', 'cargoOwner', _filter,
                        () => setState(() => _filter = 'cargoOwner')),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const AppLoading();

              var users = snapshot.data!.docs
                  .map((d) => UserModel.fromFirestore(d))
                  .where((u) => !u.isAdmin)
                  .toList();

              if (_filter != 'all') {
                users = users
                    .where((u) => u.role.name == _filter)
                    .toList();
              }
              if (_search.isNotEmpty) {
                users = users
                    .where((u) =>
                        u.name.toLowerCase().contains(_search) ||
                        u.email.toLowerCase().contains(_search))
                    .toList();
              }

              if (users.isEmpty) {
                return const AppEmpty(title: 'No users found');
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, i) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _UserTile(user: users[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Bookings Tab ──────────────────────────────────────────────────────────────

class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppLoading(message: 'Loading bookings…');

        if (snapshot.data!.docs.isEmpty) {
          return const AppEmpty(
            icon: Icons.receipt_long,
            title: 'No bookings yet',
          );
        }

        final bookings = snapshot.data!.docs
            .map((d) => BookingModel.fromFirestore(d))
            .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, i) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _BookingTile(booking: bookings[i]),
        );
      },
    );
  }
}

// ─── Reusable widgets ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _FilterChip(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13)),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDriver = user.isDriver;
    final color = isDriver ? primaryGreen : Colors.blue;
    final roleLabel = isDriver ? 'Driver' : 'Cargo Owner';

    String statusLabel = '';
    Color statusColor = Colors.grey;
    if (isDriver) {
      switch (user.verificationStatus) {
        case 'verified':
          statusLabel = 'Verified';
          statusColor = Colors.green;
          break;
        case 'under_review':
          statusLabel = 'Under Review';
          statusColor = Colors.blue;
          break;
        case 'rejected':
          statusLabel = 'Rejected';
          statusColor = Colors.red;
          break;
        default:
          statusLabel = 'Pending';
          statusColor = Colors.orange;
      }
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(user.email,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(roleLabel,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ),
                if (isDriver && statusLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(statusLabel,
                      style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingModel booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (booking.status.name) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
      case 'declined':
        statusColor = Colors.red;
        break;
      case 'accepted':
      case 'inProgress':
        statusColor = primaryGreen;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.local_shipping, color: statusColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.cargoDescription,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.pickupLocation} → ${booking.dropoffLocation}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    booking.statusDisplayName,
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (booking.estimatedPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${booking.estimatedPrice!.toStringAsFixed(0)} RWF',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Driver Verification Card (same as admin_verification_screen) ─────────────

class _DriverVerificationCard extends StatelessWidget {
  final UserModel driver;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DriverVerificationCard(
      {required this.driver,
      required this.onApprove,
      required this.onReject});

  @override
  Widget build(BuildContext context) {
    final isUnderReview = driver.verificationStatus == 'under_review';
    final statusColor = isUnderReview ? Colors.blue : Colors.orange;
    final statusLabel = isUnderReview ? 'Under Review' : 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primaryGreen,
                  backgroundImage: driver.profileImageUrl != null
                      ? NetworkImage(driver.profileImageUrl!)
                      : null,
                  child: driver.profileImageUrl == null
                      ? Text(
                          driver.name.isNotEmpty
                              ? driver.name[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(driver.email,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            if (driver.phoneNumber.isNotEmpty)
              _Row(Icons.phone, driver.phoneNumber),
            if (driver.vehicleType != null)
              _Row(Icons.local_shipping,
                  '${driver.vehicleType} · ${driver.vehicleCapacity ?? ''}'),
            if (driver.driverLicenseNumber != null)
              _Row(Icons.badge, 'License: ${driver.driverLicenseNumber}'),
            const SizedBox(height: 12),
            _DocumentChips(driver: driver),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade800))),
      ]),
    );
  }
}

class _DocumentChips extends StatelessWidget {
  final UserModel driver;
  const _DocumentChips({required this.driver});

  @override
  Widget build(BuildContext context) {
    final docs = {
      'License': driver.driverLicense,
      'National ID': driver.nationalId,
      'Vehicle Reg.': driver.vehicleRegistration,
      'Vehicle Photo': driver.vehicleImageUrl,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: docs.entries.map((e) {
        final hasDoc = e.value != null && e.value!.startsWith('http');
        return GestureDetector(
          onTap: hasDoc
              ? () => showDialog(
                    context: context,
                    builder: (_) => _DocDialog(title: e.key, url: e.value!),
                  )
              : null,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: hasDoc
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: hasDoc
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  hasDoc
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 13,
                  color: hasDoc ? Colors.green : Colors.grey),
              const SizedBox(width: 4),
              Text(e.key,
                  style: TextStyle(
                      fontSize: 11,
                      color: hasDoc
                          ? Colors.green.shade700
                          : Colors.grey,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _DocDialog extends StatelessWidget {
  final String title;
  final String url;
  const _DocDialog({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text(title),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context))
            ],
          ),
          Image.network(url,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) =>
                  progress == null
                      ? child
                      : const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator()),
              errorBuilder: (context, error, stack) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.broken_image,
                        size: 48, color: Colors.grey),
                  )),
        ],
      ),
    );
  }
}
