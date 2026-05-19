import '../widgets/app_states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../constants.dart';

// Dismiss keyboard helper
void _dismissKeyboard(BuildContext context) =>
    FocusScope.of(context).unfocus();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _dismissKeyboard(context);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (mounted && authProvider.error != null) {
      AppSnackbar.showError(context, authProvider.error!);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _dismissKeyboard(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

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
            return const AppLoading(message: 'Signing in…');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Header ──────────────────────────────────────────────
                  Text('Welcome Back', style: welcomeTitleStyle.copyWith(color: cs.onSurface))
                      .animate()
                      .fade(duration: 400.ms)
                      .slideX(begin: -0.1),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to manage your shipments',
                    style: welcomeSubtitleStyle.copyWith(color: cs.onSurfaceVariant),
                  ).animate().fade(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 36),

                  // ── Email ────────────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                    decoration: _inputDecoration('Email', Icons.email_outlined),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.08),

                  const SizedBox(height: 16),

                  // ── Password ─────────────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    decoration: _inputDecoration('Password', Icons.lock_outline)
                        .copyWith(
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
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.08),

                  const SizedBox(height: 8),

                  // ── Forgot Password ───────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: appGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 400.ms),

                  const SizedBox(height: 16),

                  // ── Login Button ──────────────────────────────────────────
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    child: const Text('SIGN IN'),
                  )
                      .animate()
                      .fade(delay: 500.ms)
                      .scale(begin: const Offset(0.97, 0.97)),

                  const SizedBox(height: 28),

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
                  ).animate().fade(delay: 600.ms),

                  const SizedBox(height: 20),

                  // ── Google Sign-In Button ──────────────────────────────────
                  _GoogleSignInButton(
                    isLoading: authProvider.isGoogleLoading,
                    onPressed: authProvider.isLoading || authProvider.isGoogleLoading
                        ? null
                        : _handleGoogleSignIn,
                  ).animate().fade(delay: 700.ms).slideY(begin: 0.08),

                  const SizedBox(height: 36),

                  // ── Sign Up link ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: appGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 800.ms),

                  const SizedBox(height: 24),
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

// ─── Google Sign-In Button ────────────────────────────────────────────────────

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

/// Renders a four-colour Google "G" logo using Flutter primitives —
/// no external image assets required.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Clip to circle
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.clipPath(clipPath);

    // Background
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = Colors.white,
    );

    // Draw the four coloured arcs that form the "G"
    // Each arc spans 90° with a 2° gap for visual separation.
    const gap = 2.0 * (3.14159265358979 / 180.0);
    const sweep = (3.14159265358979 / 2) - gap;

    final colors = [
      const Color(0xFF4285F4), // Blue  — top-right
      const Color(0xFFEA4335), // Red   — bottom-right  (actual start: top)
      const Color(0xFFFBBC05), // Yellow — bottom-left
      const Color(0xFF34A853), // Green — top-left
    ];

    double startAngle = -3.14159265358979 / 2 + gap / 2; // Start at top

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.38;

    final innerRadius = r * 0.58;
    final innerRect =
        Rect.fromCircle(center: Offset(cx, cy), radius: innerRadius);

    for (int i = 0; i < 4; i++) {
      arcPaint.color = colors[i];
      canvas.drawArc(innerRect, startAngle, sweep, false, arcPaint);
      startAngle += sweep + gap;
    }

    // White cutout for the right side of the "G" crossbar
    final cutoutPaint = Paint()..color = Colors.white;
    final crossbarY = cy + r * 0.04;
    canvas.drawRect(
      Rect.fromLTRB(cx - r * 0.05, crossbarY - r * 0.13,
          cx + r * 0.55, crossbarY + r * 0.13),
      cutoutPaint,
    );

    // Blue fill for the crossbar
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTRB(cx + r * 0.02, crossbarY - r * 0.13,
          cx + r * 0.55, crossbarY + r * 0.13),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
