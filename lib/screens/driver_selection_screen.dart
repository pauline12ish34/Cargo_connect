import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../core/models/user_model.dart';
import '../core/enums/app_enums.dart';
import '../core/repositories/user_repository.dart';
import '../features/booking/providers/booking_provider.dart';
import '../widgets/app_states.dart';

class DriverSelectionScreen extends StatefulWidget {
  final VehicleType vehicleType;
  final String pickupLocation;
  final String dropoffLocation;
  final String? bookingId;
  final bool isReassignment;

  const DriverSelectionScreen({
    super.key,
    required this.vehicleType,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.bookingId,
    this.isReassignment = false,
  });

  @override
  State<DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  late final FirebaseUserRepository _userRepository;
  late Future<List<UserModel>> _driversFuture;
  String _searchQuery = '';
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _userRepository = FirebaseUserRepository();
    _driversFuture = _fetchCompatibleDrivers();
  }

  /// Returns true if a driver's free-text vehicle type matches the required enum.
  bool _matchesVehicleType(String? driverVehicleStr, VehicleType required) {
    if (driverVehicleStr == null || driverVehicleStr.isEmpty) return false;
    final s = driverVehicleStr.toLowerCase();
    switch (required) {
      case VehicleType.truck:
        // "truck" but NOT "pickup truck" (pickup is its own type)
        return s.contains('truck') && !s.contains('pickup');
      case VehicleType.van:
        return s.contains('van');
      case VehicleType.pickup:
        return s.contains('pickup');
      case VehicleType.lorry:
        return s.contains('lorry');
    }
  }

  Future<List<UserModel>> _fetchCompatibleDrivers() async {
    final allDrivers = await _userRepository.getUsersByRole(UserRole.driver);
    final compatible = allDrivers
        .where((d) =>
            d.isAvailable == true &&
            _matchesVehicleType(d.vehicleType, widget.vehicleType))
        .toList();
    // Sort by rating descending; null ratings go to the end.
    compatible.sort((a, b) {
      final rA = a.rating ?? -1.0;
      final rB = b.rating ?? -1.0;
      return rB.compareTo(rA);
    });
    return compatible;
  }

  Future<void> _assignDriver(UserModel driver) async {
    if (widget.bookingId == null) {
      // Fallback: just pop with the driver (e.g. reassignment flow handled by caller)
      Navigator.pop(context, driver);
      return;
    }

    setState(() => _isAssigning = true);
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.assignDriverToBooking(
        widget.bookingId!,
        driver.uid,
      );
      if (!mounted) return;
      if (success) {
        AppSnackbar.showSuccess(
          context,
          '${driver.name} has been assigned to your job.',
        );
        Navigator.pop(context, true);
      } else {
        AppSnackbar.showError(
          context,
          bookingProvider.error ?? 'Could not assign driver. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Driver'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route + vehicle type summary
              Container(
                color: cs.surface,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _RouteChip(
                          icon: Icons.radio_button_checked_rounded,
                          color: appGreen,
                          label: widget.pickupLocation,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 16, color: cs.onSurfaceVariant),
                        ),
                        _RouteChip(
                          icon: Icons.location_on_rounded,
                          color: statusCancelled,
                          label: widget.dropoffLocation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Vehicle type badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: appGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: appGreen.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_shipping_rounded,
                                  size: 14, color: appGreen),
                              const SizedBox(width: 6),
                              Text(
                                'Requires: ${widget.vehicleType.name[0].toUpperCase()}${widget.vehicleType.name.substring(1)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: appGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search drivers by name…',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
              ).animate().fade(duration: 400.ms),

              // Drivers list
              Expanded(
                child: FutureBuilder<List<UserModel>>(
                  future: _driversFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(appGreen),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _ErrorState(
                        onRetry: () => setState(() {
                          _driversFuture = _fetchCompatibleDrivers();
                        }),
                      );
                    }

                    final allCompatible = snapshot.data ?? [];
                    final drivers = _searchQuery.isEmpty
                        ? allCompatible
                        : allCompatible
                            .where((d) => d.name
                                .toLowerCase()
                                .contains(_searchQuery))
                            .toList();

                    if (allCompatible.isEmpty) {
                      return _NoDriversState(
                        vehicleTypeName:
                            widget.vehicleType.name[0].toUpperCase() +
                                widget.vehicleType.name.substring(1),
                      );
                    }

                    if (drivers.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48, color: cs.onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text(
                              'No drivers matching "$_searchQuery"',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant),
                            ),
                          ],
                        ).animate().fade(duration: 300.ms),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => setState(
                          () => _driversFuture = _fetchCompatibleDrivers()),
                      color: appGreen,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: drivers.length,
                        itemBuilder: (context, index) {
                          return _DriverCard(
                            driver: drivers[index],
                            isAssigning: _isAssigning,
                            onSelect: () => _assignDriver(drivers[index]),
                          )
                              .animate()
                              .fade(delay: (index * 60).ms)
                              .slideY(begin: 0.06);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Full-screen loading overlay during assignment
          if (_isAssigning)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(appGreen),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Route Chip ───────────────────────────────────────────────────────────────
class _RouteChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _RouteChip(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Driver Card ──────────────────────────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  final UserModel driver;
  final VoidCallback onSelect;
  final bool isAssigning;

  const _DriverCard({
    required this.driver,
    required this.onSelect,
    required this.isAssigning,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with online dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: appGreen.withValues(alpha: 0.1),
                  backgroundImage:
                      driver.profileImageUrl?.isNotEmpty == true
                          ? NetworkImage(driver.profileImageUrl!)
                          : null,
                  child: driver.profileImageUrl?.isNotEmpty != true
                      ? Text(
                          driver.name.isNotEmpty
                              ? driver.name[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            fontSize: 22,
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
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: appGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // Driver info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Rating row (always show, prominent)
                  if (driver.rating != null)
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled =
                              i < (driver.rating! + 0.5).floor();
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: statusPending,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          driver.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 6),

                  // Stats chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      if (driver.completedJobs != null &&
                          driver.completedJobs! > 0)
                        _StatChip(
                          icon: Icons.check_circle_outline_rounded,
                          color: appGreen,
                          label: '${driver.completedJobs} jobs',
                        ),
                      if (driver.vehicleType != null)
                        _StatChip(
                          icon: Icons.local_shipping_outlined,
                          color: cs.onSurfaceVariant,
                          label: driver.vehicleType!,
                        ),
                      if (driver.vehicleCapacity != null)
                        _StatChip(
                          icon: Icons.scale_outlined,
                          color: cs.onSurfaceVariant,
                          label: driver.vehicleCapacity!,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Select button
            ElevatedButton(
              onPressed: isAssigning ? null : onSelect,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(72, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatChip(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── No Drivers State ─────────────────────────────────────────────────────────
class _NoDriversState extends StatelessWidget {
  final String vehicleTypeName;
  const _NoDriversState({required this.vehicleTypeName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: appGreen.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_off_rounded,
                  size: 40,
                  color: appGreen.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Available $vehicleTypeName Drivers',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no available drivers with a $vehicleTypeName right now. Please check back later or choose a different vehicle type.',
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 14, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusCancelled.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 40, color: statusCancelled),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load drivers',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style:
                  ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
            ),
          ],
        ).animate().fade(duration: 400.ms),
      ),
    );
  }
}
