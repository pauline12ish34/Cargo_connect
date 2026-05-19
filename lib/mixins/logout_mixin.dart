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

                // Navigate to login immediately — avoids black screen while
                // auth state listener fires during async sign-out
                profileProv.logout();
                authProv.clearError();
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);

                // Sign out in background after navigation
                authProv.signOut();
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}
