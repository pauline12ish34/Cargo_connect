import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../features/profile/providers/profile_provider.dart';

mixin LogoutMixin {
  void showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // dismiss confirmation dialog

                // Capture everything before the async gap
                final navigator = Navigator.of(context, rootNavigator: true);
                final authProv = Provider.of<AuthProvider>(context, listen: false);
                final profileProv = Provider.of<ProfileProvider>(context, listen: false);

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Logging out...'),
                      ],
                    ),
                  ),
                );

                try {
                  await authProv.signOut();
                  profileProv.logout();
                  authProv.clearError();

                  // Pop loading dialog, then clear the full stack and go to login
                  navigator.pop();
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                } catch (e) {
                  navigator.pop(); // dismiss loading dialog
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}
