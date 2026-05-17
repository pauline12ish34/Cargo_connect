

import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/enums/app_enums.dart';
import '../core/repositories/user_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _userRepository = FirebaseUserRepository();
    _driversFuture = _fetchAvailableDrivers();
  }


  Future<List<UserModel>> _fetchAvailableDrivers() async {
    final allDrivers = await _userRepository.getUsersByRole(UserRole.driver);
    // Filter for available drivers (isAvailable == true)
    return allDrivers.where((d) => d.isAvailable == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Driver'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _driversFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load drivers.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No available drivers found.'),
                ],
              ),
            );
          }
          final drivers = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: driver.profileImageUrl != null && driver.profileImageUrl!.isNotEmpty
                        ? NetworkImage(driver.profileImageUrl!)
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    radius: 28,
                  ),
                  title: Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (driver.vehicleType != null) Text('Vehicle: ${driver.vehicleType}'),
                      if (driver.vehicleCapacity != null) Text('Capacity: ${driver.vehicleCapacity}'),
                      if (driver.rating != null) Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(driver.rating!.toStringAsFixed(1)),
                        ],
                      ),
                      if (driver.completedJobs != null) Text('Jobs: ${driver.completedJobs}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement driver selection logic
                      Navigator.pop(context, driver);
                    },
                    child: const Text('Select'),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
