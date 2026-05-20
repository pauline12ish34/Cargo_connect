import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/user_model.dart';
import '../core/repositories/user_repository.dart';
import '../providers/auth_provider.dart';
import '../mixins/image_picker_mixin.dart';
import '../constants.dart';

class CargoOwnerProfileEditScreen extends StatefulWidget {
  const CargoOwnerProfileEditScreen({super.key});

  @override
  State<CargoOwnerProfileEditScreen> createState() =>
      _CargoOwnerProfileEditScreenState();
}

class _CargoOwnerProfileEditScreenState
    extends State<CargoOwnerProfileEditScreen> with ImagePickerMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyTypeController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  final UserRepository _userRepository = FirebaseUserRepository();
  bool _isLoading = false;
  UserModel? _user;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _companyTypeController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      final latest = await _userRepository.getUserById(currentUser.uid);
      final user = latest ?? currentUser;
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _phoneController.text = user.phoneNumber;
        _companyNameController.text = user.companyName ?? '';
        _companyTypeController.text = user.companyType ?? '';
        _cityController.text = user.city ?? '';
        _countryController.text = user.country ?? '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);
    try {
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _userRepository.uploadProfileImage(_user!.uid, _profileImage!);
      }

      final updated = _user!.copyWith(
        profileImageUrl: profileImageUrl ?? _user!.profileImageUrl,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        companyName: _companyNameController.text.trim().isEmpty
            ? null
            : _companyNameController.text.trim(),
        companyType: _companyTypeController.text.trim().isEmpty
            ? null
            : _companyTypeController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
      );

      await _userRepository.updateUser(updated);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _isLoading && _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile picture
                    Center(
                      child: GestureDetector(
                        onTap: () => showImagePickerDialog(
                          context,
                          onImageSelected: (file) => setState(() => _profileImage = file),
                        ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: primaryGreen.withValues(alpha: 0.15),
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (_user?.profileImageUrl != null
                                      ? NetworkImage(_user!.profileImageUrl!) as ImageProvider
                                      : null),
                              child: (_profileImage == null && _user?.profileImageUrl == null)
                                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('Tap to change photo',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Personal Information'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Business Information'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name (optional)',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Company Type (optional)',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Retail, Manufacturing',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Location'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City (optional)',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country (optional)',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save Changes',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
