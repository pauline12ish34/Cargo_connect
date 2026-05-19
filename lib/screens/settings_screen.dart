import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../core/repositories/user_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_states.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kPushKey = 'pref_push_notifications';
  static const _kEmailKey = 'pref_email_notifications';
  static const _kSmsKey = 'pref_sms_notifications';

  final UserRepository _userRepository = FirebaseUserRepository();
  bool _isUpdatingAvailability = false;
  bool _isAvailable = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _isAvailable = user.isAvailable ?? false;
    }
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotifications = prefs.getBool(_kPushKey) ?? true;
      _emailNotifications = prefs.getBool(_kEmailKey) ?? true;
      _smsNotifications = prefs.getBool(_kSmsKey) ?? false;
    });
  }

  Future<void> _saveNotificationPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _updateAvailability(bool value) async {
    setState(() => _isUpdatingAvailability = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      if (currentUser == null) throw Exception('No user logged in');

      final updatedUser = currentUser.copyWith(
        isAvailable: value,
        updatedAt: DateTime.now(),
      );
      await _userRepository.updateUser(updatedUser);
      await authProvider.refreshUserData();

      if (mounted) {
        setState(() => _isAvailable = value);
        AppSnackbar.showSuccess(
          context,
          value
              ? 'You are now online and available for jobs.'
              : 'You are now offline. You will not receive new job requests.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Could not update availability. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingAvailability = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appearance ─────────────────────────────────────────────────
            _SettingsSectionLabel(label: 'Appearance')
                .animate().fade(duration: 400.ms),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return _SettingsGroup(
                  children: [
                    _SwitchTile(
                      icon: themeProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Switch between light and dark theme',
                      value: themeProvider.isDarkMode,
                      onChanged: (v) => themeProvider.setDarkMode(v),
                    ),
                  ],
                );
              },
            ).animate().fade(delay: 50.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ── Driver Status ───────────────────────────────────────────────
            _SettingsSectionLabel(label: 'Driver Status')
                .animate().fade(delay: 100.ms),
            _SettingsGroup(
              children: [
                _SwitchTile(
                  icon: _isAvailable ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                  iconColor: _isAvailable ? appGreen : textGray,
                  title: 'Available for Jobs',
                  subtitle: _isAvailable
                      ? 'You will receive job notifications'
                      : 'You won\'t receive job notifications',
                  value: _isAvailable,
                  onChanged: _isUpdatingAvailability ? null : _updateAvailability,
                  trailing: _isUpdatingAvailability
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(appGreen)),
                        )
                      : null,
                ),
              ],
            ).animate().fade(delay: 150.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ── Notifications ───────────────────────────────────────────────
            _SettingsSectionLabel(label: 'Notifications')
                .animate().fade(delay: 200.ms),
            _SettingsGroup(
              children: [
                _SwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Instant alerts on your device',
                  value: _pushNotifications,
                  onChanged: (v) {
                    setState(() => _pushNotifications = v);
                    _saveNotificationPref(_kPushKey, v);
                    _showChangeSnackbar(v ? 'Push notifications enabled' : 'Push notifications disabled');
                  },
                ),
                _SwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Email Notifications',
                  subtitle: 'Job updates via email',
                  value: _emailNotifications,
                  onChanged: (v) {
                    setState(() => _emailNotifications = v);
                    _saveNotificationPref(_kEmailKey, v);
                    _showChangeSnackbar(v ? 'Email notifications enabled' : 'Email notifications disabled');
                  },
                ),
                _SwitchTile(
                  icon: Icons.sms_outlined,
                  title: 'SMS Notifications',
                  subtitle: 'Job alerts via SMS',
                  value: _smsNotifications,
                  isLast: true,
                  onChanged: (v) {
                    setState(() => _smsNotifications = v);
                    _saveNotificationPref(_kSmsKey, v);
                    _showChangeSnackbar(v ? 'SMS notifications enabled' : 'SMS notifications disabled');
                  },
                ),
              ],
            ).animate().fade(delay: 250.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ── Account ─────────────────────────────────────────────────────
            _SettingsSectionLabel(label: 'Account')
                .animate().fade(delay: 300.ms),
            _SettingsGroup(
              children: [
                _ActionTile(
                  icon: Icons.security_rounded,
                  title: 'Privacy & Security',
                  subtitle: 'Manage account security',
                  onTap: () => _comingSoon('Privacy & Security'),
                ),
                _ActionTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'Change app language',
                  onTap: () => _comingSoon('Language Settings'),
                  isLast: true,
                ),
              ],
            ).animate().fade(delay: 350.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ── App ─────────────────────────────────────────────────────────
            _SettingsSectionLabel(label: 'App')
                .animate().fade(delay: 400.ms),
            _SettingsGroup(
              children: [
                _ActionTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About CargoLink',
                  subtitle: 'Version 1.0.0',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'CargoLink Rwanda',
                    applicationVersion: '1.0.0',
                    applicationIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appGreenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_shipping_rounded,
                          size: 40, color: appGreen),
                    ),
                    children: [
                      const Text(
                        'Connecting cargo owners with reliable drivers across Rwanda.',
                        style: TextStyle(height: 1.6),
                      ),
                    ],
                  ),
                ),
                _ActionTile(
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  subtitle: 'Help us improve the app',
                  onTap: () => _comingSoon('Feedback'),
                ),
                _ActionTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Rate App',
                  subtitle: 'Rate CargoLink on the app store',
                  isLast: true,
                  onTap: () => _comingSoon('Rate App'),
                ),
              ],
            ).animate().fade(delay: 450.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ── Danger Zone ─────────────────────────────────────────────────
            _SettingsSectionLabel(label: 'Account Management', isDestructive: true)
                .animate().fade(delay: 500.ms),
            _SettingsGroup(
              children: [
                _ActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  titleColor: statusCancelled,
                  iconColor: statusCancelled,
                  isLast: true,
                  onTap: _confirmSignOut,
                ),
              ],
            ).animate().fade(delay: 550.ms).slideY(begin: 0.05),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _comingSoon(String feature) {
    AppSnackbar.showInfo(context, '$feature is coming soon. Stay tuned!');
  }

  void _showChangeSnackbar(String message) {
    AppSnackbar.showSuccess(context, message);
  }

  void _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: statusCancelled,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SettingsSectionLabel extends StatelessWidget {
  final String label;
  final bool isDestructive;

  const _SettingsSectionLabel({required this.label, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: isDestructive ? statusCancelled.withOpacity(0.8) : textGray,
        ),
      ),
    );
  }
}

// ─── Settings Group ───────────────────────────────────────────────────────────
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

// ─── Switch Tile ──────────────────────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? trailing;
  final bool isLast;

  const _SwitchTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? appGreen).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: iconColor ?? appGreen),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              trailing ??
                  Switch(
                    value: value,
                    onChanged: onChanged,
                  ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(cardBorderRadius))
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? appGreen).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 18, color: iconColor ?? appGreen),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor ?? Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: (iconColor ?? borderGray).withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
