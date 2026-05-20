import 'package:flutter/material.dart';
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
  final bool isReassignment;
  final String? bookingId;

  const DriverSelectionScreen({
    super.key,
    required this.vehicleType,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.isReassignment = false,
    this.bookingId,
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

  /// Matches free-text vehicle type from driver profile against the required enum.
  bool _matchesVehicleType(String? driverVehicleStr, VehicleType required) {
    if (driverVehicleStr == null || driverVehicleStr.isEmpty) return false;
    final s = driverVehicleStr.toLowerCase();
    switch (required) {
      case VehicleType.truck:
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
    // Sort by rating descending; drivers with no rating go to the end.
    compatible.sort((a, b) {
      final rA = a.rating ?? -1.0;
      final rB = b.rating ?? -1.0;
      return rB.compareTo(rA);
    });
    return compatible;
  }

  Future<void> _selectDriver(UserModel driver) async {
    final bookingId = widget.bookingId;
    if (bookingId == null) {
      Navigator.pop(context, driver);
      return;
    }

    setState(() => _isAssigning = true);

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final success = await bookingProvider.assignDriverToBooking(bookingId, driver.uid);

    if (!mounted) return;
    setState(() => _isAssigning = false);

    if (success) {
      AppSnackbar.showSuccess(context, '${driver.name} has been notified of your job!');
      Navigator.of(context).popUntil(ModalRoute.withName('/home'));
    } else {
      AppSnackbar.showError(context, bookingProvider.error ?? 'Failed to assign driver');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Driver')),
      body: Stack(
        children: [
          Column(
            children: [
              // Route summary chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _RouteChip(icon: Icons.trip_origin, color: primaryGreen, label: widget.pickupLocation),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                    ),
                    _RouteChip(icon: Icons.location_on, color: Colors.red, label: widget.dropoffLocation),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search drivers by name…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Driver list
              Expanded(
                child: FutureBuilder<List<UserModel>>(
                  future: _driversFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppLoading(message: 'Finding compatible drivers…');
                    }
                    if (snapshot.hasError) {
                      return AppError(
                        message: 'Failed to load drivers.',
                        onRetry: () => setState(() => _driversFuture = _fetchCompatibleDrivers()),
                      );
                    }

                    final allCompatible = snapshot.data ?? [];

                    if (allCompatible.isEmpty) {
                      return AppEmpty(
                        icon: Icons.person_off_outlined,
                        title: 'No drivers available',
                        subtitle: 'No ${widget.vehicleType.name} drivers are online right now. Try again later.',
                      );
                    }

                    final drivers = _searchQuery.isEmpty
                        ? allCompatible
                        : allCompatible.where((d) => d.name.toLowerCase().contains(_searchQuery)).toList();

                    if (drivers.isEmpty) {
                      return AppEmpty(
                        icon: Icons.search_off_rounded,
                        title: 'No results for "$_searchQuery"',
                        subtitle: 'Try a different name.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => setState(() => _driversFuture = _fetchCompatibleDrivers()),
                      color: primaryGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: drivers.length,
                        itemBuilder: (context, index) {
                          final driver = drivers[index];
                          return _DriverCard(
                            driver: driver,
                            isAssigning: _isAssigning,
                            onSelect: () => _selectDriver(driver),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Full-screen overlay while assigning
          if (_isAssigning)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
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

  const _RouteChip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

// ─── Driver Card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final UserModel driver;
  final VoidCallback onSelect;
  final bool isAssigning;

  const _DriverCard({required this.driver, required this.onSelect, required this.isAssigning});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: primaryGreen,
              backgroundImage: (driver.profileImageUrl != null && driver.profileImageUrl!.isNotEmpty)
                  ? NetworkImage(driver.profileImageUrl!)
                  : null,
              child: (driver.profileImageUrl == null || driver.profileImageUrl!.isEmpty)
                  ? Text(driver.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 6),
                    if (driver.isVerified)
                      const Tooltip(
                        message: 'Verified Driver',
                        child: Icon(Icons.verified, size: 15, color: Colors.blue),
                      )
                    else
                      Tooltip(
                        message: 'Not yet verified',
                        child: Icon(Icons.warning_amber_rounded, size: 15, color: Colors.orange.shade400),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  if (driver.vehicleType != null)
                    Text('${driver.vehicleType}  ·  ${driver.vehicleCapacity ?? ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text(driver.rating?.toStringAsFixed(1) ?? '—', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 10),
                    const Icon(Icons.check_circle_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text('${driver.completedJobs ?? 0} jobs', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isAssigning ? null : onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Select', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
