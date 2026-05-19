import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_states.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordReset(
      emailController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/password-reset-confirmation');
    } else if (mounted) {
      AppSnackbar.showError(
        context,
        authProvider.error ?? 'Failed to send reset email. Please try again.',
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
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
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
                      Icons.lock_reset_rounded,
                      size: 40,
                      color: appGreen,
                    ),
                  ).animate().fade(duration: 500.ms).scale(curve: Curves.easeOutBack),

                  const SizedBox(height: 24),

                  Text('Reset Password', style: welcomeTitleStyle.copyWith(color: cs.onSurface))
                      .animate().fade(delay: 200.ms).slideX(begin: -0.1),

                  const SizedBox(height: 10),

                  Text(
                    'Enter your registered email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15, height: 1.7),
                  ).animate().fade(delay: 300.ms),

                  const SizedBox(height: 36),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.08),

                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handlePasswordReset,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('SEND RESET LINK'),
                  ).animate().fade(delay: 500.ms).scale(begin: const Offset(0.97, 0.97)),

                  const SizedBox(height: 20),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Back to Login',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                      ),
                    ),
                  ).animate().fade(delay: 600.ms),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
