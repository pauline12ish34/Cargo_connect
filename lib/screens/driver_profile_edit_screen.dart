import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/user_model.dart';
import '../core/repositories/user_repository.dart';
import '../providers/auth_provider.dart';
import '../mixins/image_picker_mixin.dart';
import '../widgets/app_states.dart';

class DriverProfileEditScreen extends StatefulWidget {
  const DriverProfileEditScreen({super.key});

  @override
  State<DriverProfileEditScreen> createState() => _DriverProfileEditScreenState();
}

class _DriverProfileEditScreenState extends State<DriverProfileEditScreen> with ImagePickerMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _driverLicenseNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleCapacityController = TextEditingController();
  
  // Address controllers
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  
  final UserRepository _userRepository = FirebaseUserRepository();
  
  bool _isLoading = false;
  UserModel? _user;
  
  // Document files
  File? _profileImage;
  File? _driverLicenseFile;
  File? _nationalIdFile;
  File? _vehicleRegistrationFile;
  File? _vehicleImageFile;
  
  // Individual document upload progress is rolled into _isLoading for now.

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _driverLicenseNumberController.dispose();
    _vehicleTypeController.dispose();
    _vehicleCapacityController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser != null) {
      try {
        // Fetch the latest user data from the database to ensure we have all fields
        final latestUser = await _userRepository.getUserById(currentUser.uid);
        final userToUse = latestUser ?? currentUser;
        
        setState(() {
          _user = userToUse;
          _nameController.text = userToUse.name;
          _phoneController.text = userToUse.phoneNumber;
          // Handle migration: check both fields for license number
          _driverLicenseNumberController.text = userToUse.driverLicenseNumber ?? userToUse.driverLicense ?? '';
          _vehicleTypeController.text = userToUse.vehicleType ?? '';
          _vehicleCapacityController.text = userToUse.vehicleCapacity ?? '';
          
          // Load address fields
          _streetController.text = userToUse.street ?? '';
          _cityController.text = userToUse.city ?? '';
          _stateController.text = userToUse.state ?? '';
          _postalCodeController.text = userToUse.postalCode ?? '';
          _countryController.text = userToUse.country ?? '';
        });
      } catch (e) {
        // Fallback to cached user data if database fetch fails
        setState(() {
          _user = currentUser;
          _nameController.text = currentUser.name;
          _phoneController.text = currentUser.phoneNumber;
          // Handle migration: check both fields for license number
          _driverLicenseNumberController.text = currentUser.driverLicenseNumber ?? currentUser.driverLicense ?? '';
          _vehicleTypeController.text = currentUser.vehicleType ?? '';
          _vehicleCapacityController.text = currentUser.vehicleCapacity ?? '';
          
          // Load address fields
          _streetController.text = currentUser.street ?? '';
          _cityController.text = currentUser.city ?? '';
          _stateController.text = currentUser.state ?? '';
          _postalCodeController.text = currentUser.postalCode ?? '';
          _countryController.text = currentUser.country ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Upload documents if selected
      Map<String, String> documentUpdates = {};
      
      if (_profileImage != null) {
        final url = await _userRepository.uploadProfileImage(currentUser.uid, _profileImage!);
        documentUpdates['profileImageUrl'] = url;
      }
      
      if (_driverLicenseFile != null) {
        final url = await _userRepository.uploadDocument(currentUser.uid, _driverLicenseFile!, 'driver_license');
        documentUpdates['driverLicense'] = url;
      }

      if (_nationalIdFile != null) {
        final url = await _userRepository.uploadDocument(currentUser.uid, _nationalIdFile!, 'national_id');
        documentUpdates['nationalId'] = url;
      }

      if (_vehicleRegistrationFile != null) {
        final url = await _userRepository.uploadDocument(currentUser.uid, _vehicleRegistrationFile!, 'vehicle_registration');
        documentUpdates['vehicleRegistration'] = url;
      }

      if (_vehicleImageFile != null) {
        final url = await _userRepository.uploadDocument(currentUser.uid, _vehicleImageFile!, 'vehicle_image');
        documentUpdates['vehicleImageUrl'] = url;
      }

      // Update basic profile information
      final updatedUser = currentUser.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        vehicleCapacity: _vehicleCapacityController.text.trim(),
        
        // Update address fields
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim(),
        
        // Migration: Clear old driverLicense field if it contains text (not a URL)
        driverLicense: (currentUser.driverLicense != null && 
                       !currentUser.driverLicense!.startsWith('http')) 
                       ? null : currentUser.driverLicense,
        
        updatedAt: DateTime.now(),
      );

      await _userRepository.updateUser(updatedUser);
      
      // Update documents if any were uploaded
      if (documentUpdates.isNotEmpty) {
        await _userRepository.updateUserWithDocuments(currentUser.uid, documentUpdates);
      }

      // Refresh auth provider with updated user
      await authProvider.refreshUserData();

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Your driver profile has been updated.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Could not update your profile. Please check your connection and try again.',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Driver Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showImagePickerDialog(
                          context,
                          onImageSelected: (file) {
                            setState(() {
                              _profileImage = file;
                            });
                          },
                        );
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!),
                          color: Colors.grey[100],
                        ),
                        child: _profileImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _user?.profileImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _user!.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change profile photo',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Basic Information
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _driverLicenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Driver License Number',
                  hintText: 'Enter your license number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your driver license number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Address Information
              const Text(
                'Address Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'Enter your street address',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State/Province',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        hintText: 'e.g., Rwanda',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Vehicle Information
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  hintText: 'e.g., Pickup Truck, Mini Truck, Large Truck',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _vehicleCapacityController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Capacity',
                  hintText: 'e.g., 1 ton, 5 tons',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Document Upload Section
              // const Text(
              //   'Required Documents',
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Text(
              //   'Upload your verification documents to complete your driver profile',
              //   style: TextStyle(
              //     color: Colors.grey[600],
              //     fontSize: 14,
              //   ),
              // ),
              // const SizedBox(height: 16),
              //
              // _buildDocumentUploadCard(
              //   title: 'Driver\'s License',
              //   description: 'Upload a clear photo of your valid driver\'s license',
              //   onTap: () {
              //     showDocumentPickerDialog(
              //       context,
              //       'Driver\'s License',
              //       onDocumentSelected: (file) {
              //         setState(() {
              //           _driverLicenseFile = file;
              //         });
              //       },
              //     );
              //   },
              //   isUploading: _driverLicenseUploading,
              //   currentUrl: _user?.driverLicense,
              //   selectedFile: _driverLicenseFile,
              // ),
              //
              // _buildDocumentUploadCard(
              //   title: 'National ID',
              //   description: 'Upload a clear photo of your national ID card',
              //   onTap: () {
              //     showDocumentPickerDialog(
              //       context,
              //       'National ID',
              //       onDocumentSelected: (file) {
              //         setState(() {
              //           _nationalIdFile = file;
              //         });
              //       },
              //     );
              //   },
              //   isUploading: _nationalIdUploading,
              //   currentUrl: _user?.nationalId,
              //   selectedFile: _nationalIdFile,
              // ),
              //
              // _buildDocumentUploadCard(
              //   title: 'Vehicle Registration',
              //   description: 'Upload your vehicle registration certificate',
              //   onTap: () {
              //     showDocumentPickerDialog(
              //       context,
              //       'Vehicle Registration',
              //       onDocumentSelected: (file) {
              //         setState(() {
              //           _vehicleRegistrationFile = file;
              //         });
              //       },
              //     );
              //   },
              //   isUploading: _vehicleRegistrationUploading,
              //   currentUrl: _user?.vehicleRegistration,
              //   selectedFile: _vehicleRegistrationFile,
              // ),
              //
              // _buildDocumentUploadCard(
              //   title: 'Vehicle Photo',
              //   description: 'Upload a clear photo of your vehicle',
              //   onTap: () {
              //     showDocumentPickerDialog(
              //       context,
              //       'Vehicle Photo',
              //       onDocumentSelected: (file) {
              //         setState(() {
              //           _vehicleImageFile = file;
              //         });
              //       },
              //     );
              //   },
              //   isUploading: _vehicleImageUploading,
              //   currentUrl: _user?.vehicleImageUrl,
              //   selectedFile: _vehicleImageFile,
              // ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
