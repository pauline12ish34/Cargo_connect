import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../core/enums/app_enums.dart';
import '../features/booking/providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/page_transitions.dart';
import '../widgets/app_states.dart';
import 'driver_selection_screen.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _cargoDescriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _estimatedPriceController = TextEditingController();

  VehicleType _selectedVehicleType = VehicleType.truck;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _cargoDescriptionController.dispose();
    _weightController.dispose();
    _specialInstructionsController.dispose();
    _estimatedPriceController.dispose();
    super.dispose();
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    if (authProvider.user == null) {
      AppSnackbar.showError(context, 'You must be logged in to create a job.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(appGreen),
        ),
      ),
    );

    final bookingId = await bookingProvider.createBooking(
      cargoOwnerId: authProvider.user!.uid,
      pickupLocation: _pickupController.text.trim(),
      dropoffLocation: _dropoffController.text.trim(),
      cargoDescription: _cargoDescriptionController.text.trim(),
      vehicleType: _selectedVehicleType,
      weight: _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null,
      specialInstructions: _specialInstructionsController.text.isNotEmpty
          ? _specialInstructionsController.text.trim()
          : null,
      estimatedPrice: _estimatedPriceController.text.isNotEmpty
          ? double.tryParse(_estimatedPriceController.text)
          : null,
    );

    if (mounted) Navigator.of(context).pop();

    if (bookingId != null && mounted) {
      AppSnackbar.showSuccess(context, 'Job created! Now select a driver.');
      final assigned = await Navigator.of(context).push<bool>(FadePageRoute(
        page: DriverSelectionScreen(
          vehicleType: _selectedVehicleType,
          pickupLocation: _pickupController.text.trim(),
          dropoffLocation: _dropoffController.text.trim(),
          bookingId: bookingId,
        ),
      ));
      if (assigned == true && mounted) {
        Navigator.of(context).pop(); // return to home after driver is assigned
      }
    } else if (mounted) {
      AppSnackbar.showError(
        context,
        bookingProvider.error ?? 'Could not create the job. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('Create New Job'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Shipment Details',
                    style: welcomeTitleStyle,
                  ).animate().fade(duration: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 6),
                  const Text(
                    'Fill in your cargo information below',
                    style: welcomeSubtitleStyle,
                  ).animate().fade(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  // ── Route Section ─────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.route_rounded,
                    label: 'Route',
                  ).animate().fade(delay: 150.ms),

                  const SizedBox(height: 12),

                  // Route card with connected look
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(cardBorderRadius),
                      border: Border.all(color: borderGray.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.radio_button_checked_rounded,
                                      size: 18, color: appGreen),
                                  Container(width: 1.5, height: 36, color: borderGray),
                                  const Icon(Icons.location_on_rounded,
                                      size: 18, color: statusCancelled),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _pickupController,
                                      decoration: const InputDecoration(
                                        hintText: 'Pickup location',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                      ),
                                      validator: (value) => (value == null || value.isEmpty)
                                          ? 'Pickup location is required'
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _dropoffController,
                                      decoration: const InputDecoration(
                                        hintText: 'Dropoff location',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                      ),
                                      validator: (value) => (value == null || value.isEmpty)
                                          ? 'Dropoff location is required'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // ── Cargo Section ─────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.inventory_2_rounded,
                    label: 'Cargo',
                  ).animate().fade(delay: 250.ms),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _cargoDescriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Describe your cargo (type, contents, etc.)',
                      prefixIcon: Icon(Icons.description_outlined, size: 20),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please describe your cargo'
                        : null,
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.08),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    decoration: const InputDecoration(
                      hintText: 'Weight (optional)',
                      prefixIcon: Icon(Icons.scale_outlined, size: 20),
                      suffixText: 'kg',
                      suffixStyle: TextStyle(color: textGray, fontWeight: FontWeight.w500),
                    ),
                  ).animate().fade(delay: 350.ms).slideY(begin: 0.08),

                  const SizedBox(height: 24),

                  // ── Vehicle Type Section ──────────────────────────────────
                  _SectionHeader(
                    icon: Icons.local_shipping_rounded,
                    label: 'Vehicle Type',
                  ).animate().fade(delay: 400.ms),

                  const SizedBox(height: 12),

                  _VehicleTypeSelector(
                    selected: _selectedVehicleType,
                    onSelected: (type) => setState(() => _selectedVehicleType = type),
                  ).animate().fade(delay: 450.ms).slideY(begin: 0.08),

                  const SizedBox(height: 24),

                  // ── Payment Section ───────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.payments_outlined,
                    label: 'Pricing',
                  ).animate().fade(delay: 500.ms),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _estimatedPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Estimated price (optional)',
                      prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                      suffixText: 'RWF',
                      suffixStyle: TextStyle(color: textGray, fontWeight: FontWeight.w500),
                    ),
                  ).animate().fade(delay: 550.ms).slideY(begin: 0.08),

                  const SizedBox(height: 24),

                  // ── Special Instructions ──────────────────────────────────
                  _SectionHeader(
                    icon: Icons.notes_rounded,
                    label: 'Special Instructions',
                    optional: true,
                  ).animate().fade(delay: 600.ms),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _specialInstructionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Any special handling, fragile items, etc.',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.sticky_note_2_outlined, size: 20),
                      ),
                    ),
                  ).animate().fade(delay: 650.ms).slideY(begin: 0.08),

                  const SizedBox(height: 36),

                  ElevatedButton(
                    onPressed: bookingProvider.isLoading ? null : _createJob,
                    child: bookingProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('FIND A DRIVER'),
                  ).animate().fade(delay: 700.ms).scale(begin: const Offset(0.97, 0.97)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool optional;

  const _SectionHeader({
    required this.icon,
    required this.label,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: appGreen),
        const SizedBox(width: 8),
        Text(label, style: sectionTitleStyle),
        if (optional) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: borderGray.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Optional',
              style: TextStyle(fontSize: 10, color: textGray, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Vehicle Type Selector ────────────────────────────────────────────────────
class _VehicleTypeSelector extends StatelessWidget {
  final VehicleType selected;
  final ValueChanged<VehicleType> onSelected;

  const _VehicleTypeSelector({required this.selected, required this.onSelected});

  static const _vehicleData = [
    (VehicleType.truck, Icons.fire_truck_rounded, 'Truck'),
    (VehicleType.van, Icons.airport_shuttle_rounded, 'Van'),
    (VehicleType.pickup, Icons.directions_car_rounded, 'Pickup'),
    (VehicleType.lorry, Icons.local_shipping_rounded, 'Lorry'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: _vehicleData.map((data) {
        final (type, icon, label) = data;
        final isSelected = selected == type;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? appGreen.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? appGreen : borderGray.withOpacity(0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => onSelected(type),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(icon,
                      size: 22,
                      color: isSelected ? appGreen : textGray),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? appGreen : textDark,
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    const Icon(Icons.check_circle_rounded, size: 16, color: appGreen),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
