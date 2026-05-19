import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_states.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationEmail();
    });
  }

  Future<void> _sendVerificationEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.sendEmailVerification();
  }

  Future<void> _resendVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendEmailVerification();
    if (!mounted) return;
    if (success) {
      AppSnackbar.showSuccess(
        context,
        'Verification email sent! Please check your inbox.',
      );
    } else {
      AppSnackbar.showError(
        context,
        authProvider.error ?? 'Could not send email. Please wait a moment and try again.',
      );
    }
  }

  Future<void> _checkVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkEmailVerification();
    if (!mounted) return;

    final user = authProvider.currentFirebaseUser;
    if (user != null && user.emailVerified) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      AppSnackbar.showInfo(
        context,
        'Email not verified yet. Please click the link in your inbox, then try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final userEmail = authProvider.user?.email ?? 'your email';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: appGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 40,
                    color: appGreen,
                  ),
                ).animate().fade(duration: 500.ms).scale(curve: Curves.easeOutBack),

                const SizedBox(height: 24),

                Text('Verify your Email', style: welcomeTitleStyle.copyWith(color: cs.onSurface))
                    .animate().fade(delay: 200.ms).slideX(begin: -0.1),

                const SizedBox(height: 10),

                Text(
                  'We sent a verification link to:\n$userEmail\n\nClick the link in your inbox to verify your account.',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.7,
                  ),
                ).animate().fade(delay: 300.ms),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _checkVerification,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text("I'VE VERIFIED MY EMAIL"),
                ).animate().fade(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 14),

                OutlinedButton(
                  onPressed: authProvider.isLoading ? null : _resendVerification,
                  child: const Text("RESEND EMAIL"),
                ).animate().fade(delay: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 28),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (route) => false),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                  ),
                ).animate().fade(delay: 600.ms),

                const SizedBox(height: 16),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appGreen.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, size: 18, color: appGreen),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Don't see it? Check your spam or junk folder.",
                          style: TextStyle(color: appGreen, fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 700.ms),
              ],
            ),
          );
        },
      ),
    );
  }
}
