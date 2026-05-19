import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../features/profile/providers/profile_provider.dart';
import '../widgets/app_states.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _initControllers(ProfileProvider profileProvider) {
    if (_initialized) return;
    final user = profileProvider.currentUser;
    if (user == null) return;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber;
    _streetController.text = user.street ?? '';
    _cityController.text = user.city ?? '';
    _stateController.text = user.state ?? '';
    _postalCodeController.text = user.postalCode ?? '';
    _countryController.text = user.country ?? '';
    _initialized = true;
  }

  Future<void> _save(ProfileProvider profileProvider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final current = profileProvider.currentUser;
    if (current == null) {
      setState(() => _isSaving = false);
      return;
    }

    final updated = current.copyWith(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      street: _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
      country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
    );

    final success = await profileProvider.updateProfile(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackbar.showSuccess(context, 'Your personal data has been saved.');
      Navigator.pop(context);
    } else {
      AppSnackbar.showError(
        context,
        profileProvider.error ?? 'Could not save your data. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('Personal Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && !_initialized) {
            return const AppLoading(message: 'Loading your profile…');
          }

          _initControllers(profileProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Personal Details'),
                  const SizedBox(height: 12),
                  _FormCard(
                    children: [
                      _Field(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      _Field(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true, // email changes require re-auth
                        hint: 'Email cannot be changed here',
                      ),
                      _Field(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Phone number is required'
                                : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  _SectionLabel(label: 'Address'),
                  const SizedBox(height: 12),
                  _FormCard(
                    children: [
                      _Field(
                        controller: _streetController,
                        label: 'Street',
                        icon: Icons.home_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      _Field(
                        controller: _cityController,
                        label: 'City',
                        icon: Icons.location_city_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      _Field(
                        controller: _stateController,
                        label: 'Province / State',
                        icon: Icons.map_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      _Field(
                        controller: _postalCodeController,
                        label: 'Postal Code',
                        icon: Icons.local_post_office_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                      _Field(
                        controller: _countryController,
                        label: 'Country',
                        icon: Icons.public_outlined,
                        textInputAction: TextInputAction.done,
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _save(profileProvider),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('SAVE CHANGES'),
                    ),
                  ),

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

// ─── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textGray,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Form Card ────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: borderGray.withOpacity(0.4)),
      ),
      child: Column(children: children),
    );
  }
}

// ─── Field ────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final bool readOnly;
  final String? hint;
  final bool isLast;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.readOnly = false,
    this.hint,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: textGray),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  validator: validator,
                  readOnly: readOnly,
                  style: TextStyle(
                    fontSize: 14,
                    color: readOnly ? textGray : textDark,
                  ),
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    labelStyle:
                        const TextStyle(color: textGray, fontSize: 13),
                    hintStyle:
                        TextStyle(color: textGray.withOpacity(0.6), fontSize: 12),
                    errorStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 50),
      ],
    );
  }
}
