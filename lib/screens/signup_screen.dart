import '../widgets/app_states.dart';
import 'package:cargo_app/screens/driver_details.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../core/enums/app_enums.dart';
import '../constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.cargoOwner;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == UserRole.driver) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverSignupScreen(
            initialName: _nameController.text.trim(),
            initialEmail: _emailController.text.trim(),
            initialPhone: _phoneController.text.trim(),
            initialPassword: _passwordController.text,
          ),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      role: _selectedRole,
    );

    if (success && mounted) {
      AppSnackbar.showSuccess(
        context,
        'Account created! Please verify your email to continue.',
      );
      Navigator.pushReplacementNamed(context, '/email-verification');
    } else if (mounted && authProvider.error != null) {
      AppSnackbar.showError(context, authProvider.error!);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle(role: _selectedRole);

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (mounted && authProvider.error != null) {
      AppSnackbar.showError(context, authProvider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const AppLoading(message: 'Creating account…');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Text('Create Account', style: welcomeTitleStyle.copyWith(color: cs.onSurface))
                      .animate()
                      .fade(duration: 400.ms)
                      .slideX(begin: -0.1),

                  const SizedBox(height: 8),

                  Text(
                    'Join the network of cargo professionals',
                    style: welcomeSubtitleStyle.copyWith(color: cs.onSurfaceVariant),
                  ).animate().fade(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  // ── Role selector ─────────────────────────────────────────
                  Text(
                    'I am a:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      fontSize: 14,
                    ),
                  ).animate().fade(delay: 150.ms),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _RoleCard(
                        role: UserRole.cargoOwner,
                        title: 'Cargo Owner',
                        icon: Icons.inventory_2_outlined,
                        selected: _selectedRole,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.cargoOwner),
                      ),
                      const SizedBox(width: 14),
                      _RoleCard(
                        role: UserRole.driver,
                        title: 'Driver',
                        icon: Icons.local_shipping_outlined,
                        selected: _selectedRole,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.driver),
                      ),
                    ],
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.08),

                  const SizedBox(height: 24),

                  // ── Fields ────────────────────────────────────────────────
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Name is required' : null,
                    decoration: _inputDecoration('Full Name', Icons.person_outline),
                  ).animate().fade(delay: 280.ms).slideY(begin: 0.08),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(v)) return 'Enter a valid email address';
                      return null;
                    },
                    decoration: _inputDecoration('Email', Icons.email_outlined),
                  ).animate().fade(delay: 360.ms).slideY(begin: 0.08),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Phone number is required'
                        : null,
                    decoration:
                        _inputDecoration('Phone Number', Icons.phone_android_outlined),
                  ).animate().fade(delay: 440.ms).slideY(begin: 0.08),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _handleSignup(),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Minimum 6 characters required'
                        : null,
                    decoration:
                        _inputDecoration('Password', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ).animate().fade(delay: 520.ms).slideY(begin: 0.08),

                  const SizedBox(height: 28),

                  // ── Sign Up Button ────────────────────────────────────────
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleSignup,
                    child: Text(
                      _selectedRole == UserRole.driver
                          ? 'CONTINUE TO DRIVER DETAILS'
                          : 'CREATE ACCOUNT',
                    ),
                  )
                      .animate()
                      .fade(delay: 600.ms)
                      .scale(begin: const Offset(0.97, 0.97)),

                  const SizedBox(height: 24),

                  // ── Divider ────────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ).animate().fade(delay: 700.ms),

                  const SizedBox(height: 20),

                  // ── Google Sign-In Button ──────────────────────────────────
                  _GoogleSignInButton(
                    isLoading: authProvider.isGoogleLoading,
                    onPressed:
                        authProvider.isLoading || authProvider.isGoogleLoading
                            ? null
                            : _handleGoogleSignIn,
                  ).animate().fade(delay: 800.ms).slideY(begin: 0.08),

                  // ── Google role hint ─────────────────────────────────────
                  if (!authProvider.isGoogleLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, size: 13, color: textLight),
                          const SizedBox(width: 6),
                          Text(
                            'Will sign in as ${_selectedRole == UserRole.driver ? "Driver" : "Cargo Owner"}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 850.ms),

                  const SizedBox(height: 28),

                  // ── Login link ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/login'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: appGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 900.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

// ─── Role Card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final UserRole selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == role;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? appGreen.withOpacity(0.08) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? appGreen : borderGray.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? appGreen : textGray,
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? appGreen : textGray,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Google Sign-In Button (shared widget) ─────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleSignInButton({this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          side: BorderSide(
            color: isLoading ? cs.outlineVariant : cs.outlineVariant.withOpacity(0.7),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4285F4),
                    ),
                  ),
                )
              : Row(
                  key: const ValueKey('idle'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GoogleLogo(),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        letterSpacing: 0.1,
                        fontFamily: 'Lexend',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Four-colour Google "G" logo drawn with Flutter primitives.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    canvas.drawCircle(
        Offset(cx, cy), r, Paint()..color = Colors.white);

    const gap = 2.0 * (3.14159265358979 / 180.0);
    const sweep = (3.14159265358979 / 2) - gap;

    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFFEA4335),
      const Color(0xFFFBBC05),
      const Color(0xFF34A853),
    ];

    final innerRect =
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.58);
    double startAngle = -3.14159265358979 / 2 + gap / 2;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.38;

    for (int i = 0; i < 4; i++) {
      arcPaint.color = colors[i];
      canvas.drawArc(innerRect, startAngle, sweep, false, arcPaint);
      startAngle += sweep + gap;
    }

    final crossbarY = cy + r * 0.04;
    canvas.drawRect(
      Rect.fromLTRB(cx - r * 0.05, crossbarY - r * 0.13,
          cx + r * 0.55, crossbarY + r * 0.13),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTRB(cx + r * 0.02, crossbarY - r * 0.13,
          cx + r * 0.55, crossbarY + r * 0.13),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
