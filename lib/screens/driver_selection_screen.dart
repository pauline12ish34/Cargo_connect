

import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/enums/app_enums.dart';
import '../core/repositories/user_repository.dart';
import 'package:provider/provider.dart';
import '../features/booking/providers/booking_provider.dart';
import '../providers/auth_provider.dart';

class DriverSelectionScreen extends StatefulWidget {
  final VehicleType vehicleType;
  final String pickupLocation;
  final String dropoffLocation;
  final bool isReassignment;
  final String? bookingId;

  DriverSelectionScreen({
    Key? key,
    required this.vehicleType,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.isReassignment = false,
    this.bookingId,
  }) : super(key: key);

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
    // ...existing code...
    return Container(); // Replace with actual widget tree
  }
}
