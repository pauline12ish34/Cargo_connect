import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../core/models/user_model.dart';
import '../widgets/app_states.dart';

class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  Stream<List<UserModel>> _pendingDriversStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('verificationStatus', whereIn: ['pending', 'under_review'])
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  Future<void> _updateStatus(BuildContext context, String uid, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'verificationStatus': status, 'updatedAt': Timestamp.now()});

      if (context.mounted) {
        AppSnackbar.showSuccess(
          context,
          status == 'verified' ? 'Driver approved successfully' : 'Driver rejected',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError(context, 'Failed to update: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Verification'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _pendingDriversStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Loading pending drivers…');
          }
          if (snapshot.hasError) {
            return AppError(message: 'Failed to load drivers: ${snapshot.error}');
          }

          final drivers = snapshot.data ?? [];

          if (drivers.isEmpty) {
            return const AppEmpty(
              icon: Icons.verified_user,
              title: 'All caught up!',
              subtitle: 'No drivers are waiting for verification.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return _DriverVerificationCard(
                driver: driver,
                onApprove: () => _updateStatus(context, driver.uid, 'verified'),
                onReject: () => _updateStatus(context, driver.uid, 'rejected'),
              );
            },
          );
        },
      ),
    );
  }
}

class _DriverVerificationCard extends StatelessWidget {
  final UserModel driver;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DriverVerificationCard({
    required this.driver,
    required this.onApprove,
    required this.onReject,
  });

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
            // Header row
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
                          driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(driver.email,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const Divider(height: 24),

            // Driver details
            _DetailRow(Icons.phone, driver.phoneNumber),
            if (driver.vehicleType != null)
              _DetailRow(Icons.local_shipping, '${driver.vehicleType} · ${driver.vehicleCapacity ?? ''}'),
            if (driver.driverLicenseNumber != null)
              _DetailRow(Icons.badge, 'License: ${driver.driverLicenseNumber}'),

            const SizedBox(height: 12),

            // Document links
            _DocumentLinks(driver: driver),

            const SizedBox(height: 16),

            // Action buttons
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }
}

class _DocumentLinks extends StatelessWidget {
  final UserModel driver;
  const _DocumentLinks({required this.driver});

  @override
  Widget build(BuildContext context) {
    final docs = <String, String?>{
      'Driver License': driver.driverLicense,
      'National ID': driver.nationalId,
      'Vehicle Reg.': driver.vehicleRegistration,
      'Vehicle Photo': driver.vehicleImageUrl,
    };

    final uploaded = docs.entries.where((e) => e.value != null && e.value!.startsWith('http')).toList();
    final missing = docs.entries.where((e) => e.value == null || !e.value!.startsWith('http')).toList();

    if (uploaded.isEmpty && missing.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documents', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ...uploaded.map((e) => _DocChip(label: e.key, url: e.value!, uploaded: true)),
            ...missing.map((e) => _DocChip(label: e.key, url: '', uploaded: false)),
          ],
        ),
      ],
    );
  }
}

class _DocChip extends StatelessWidget {
  final String label;
  final String url;
  final bool uploaded;

  const _DocChip({required this.label, required this.url, required this.uploaded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploaded
          ? () => _showDocumentDialog(context, label, url)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: uploaded
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: uploaded
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              uploaded ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 13,
              color: uploaded ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: uploaded ? Colors.green.shade700 : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentDialog(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
              errorBuilder: (context, error, stack) => const Padding(
                padding: EdgeInsets.all(32),
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
