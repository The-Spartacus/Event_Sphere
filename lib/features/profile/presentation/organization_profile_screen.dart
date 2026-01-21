import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/colors.dart';
import '../../../app/app_config.dart';
import '../data/user_profile_model.dart';
import '../logic/profile_controller.dart';
import '../data/profile_repository.dart';
import '../data/storage_service.dart';

/// Organization Profile Screen
/// Allows organizations to view and edit their profile information
class EditOrganizationProfileScreen extends StatefulWidget {
  const EditOrganizationProfileScreen({super.key});

  @override
  State<EditOrganizationProfileScreen> createState() => _EditOrganizationProfileScreenState();
}

class _EditOrganizationProfileScreenState extends State<EditOrganizationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  File? _selectedLogo;
  bool _isUploadingLogo = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final userId = authService.currentUserId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not authenticated')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) {
        final controller = ProfileController(
          repository: ProfileRepository(),
          storageService: StorageService(),
        );
        controller.loadProfile(userId);
        return controller;
      },
      child: Consumer<ProfileController>(
        builder: (context, controller, _) {
          // Initialize form fields when profile loads
          if (controller.profile != null && !controller.hasChanges) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeFields(controller.profile!);
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Organization Profile'),
              actions: [
                if (controller.hasChanges)
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: controller.isLoading ? null : () => _saveProfile(controller),
                    tooltip: 'Save Changes',
                  ),
              ],
            ),
            body: _buildBody(context, controller),
          );
        },
      ),
    );
  }

  void _initializeFields(UserProfileModel profile) {
    _nameController.text = profile.name;
    _phoneController.text = profile.phoneNumber ?? '';
    _websiteController.text = profile.officialWebsite ?? '';
    _descriptionController.text = profile.organizationDescription ?? '';
    _addressController.text = profile.address ?? '';
    _contactPersonController.text = profile.contactPersonName ?? '';
    _contactPhoneController.text = profile.contactPersonPhone ?? '';
  }

  Widget _buildBody(BuildContext context, ProfileController controller) {
    if (controller.isLoading && controller.profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(controller.error!, style: AppTextStyles.body),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final userId = context.read<AuthService>().currentUserId;
                if (userId != null) {
                  controller.loadProfile(userId);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final profile = controller.profile;
    if (profile == null) {
      return const Center(child: Text('Profile not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile completion indicator
            if (!profile.isComplete)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete your profile (${profile.completionPercentage}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Logo Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: _selectedLogo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_selectedLogo!, fit: BoxFit.cover),
                          )
                        : profile.logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(profile.logoUrl!, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.business, size: 60, color: AppColors.textDisabled),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        icon: _isUploadingLogo
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _isUploadingLogo ? null : () => _pickLogo(context, controller),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Verification Status (Read-only)
            if (profile.verified != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: profile.verified!
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: profile.verified!
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      profile.verified! ? Icons.verified : Icons.pending,
                      color: profile.verified!
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      profile.verified!
                          ? 'Verified Organization'
                          : 'Verification Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: profile.verified!
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            if (profile.verified != null) const SizedBox(height: 16),

            // Organization/Institute Name (Required)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Organization/Institute Name *',
                prefixIcon: Icon(Icons.business),
                hintText: 'Enter your organization name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Organization name is required';
                }
                return null;
              },
              onChanged: (value) {
                controller.updateField(
                  name: value,
                  organizationName: value,
                );
              },
            ),
            const SizedBox(height: 16),

            // Email (Read-only)
            TextFormField(
              initialValue: profile.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                enabled: false,
              ),
            ),
            const SizedBox(height: 16),

            // Phone Number (Required)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone),
                hintText: 'Enter organization phone number',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                if (value.length < 10) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
              onChanged: (value) {
                controller.updateField(phoneNumber: value);
              },
            ),
            const SizedBox(height: 16),

            // Official Website
            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Official Website',
                prefixIcon: Icon(Icons.language),
                hintText: 'https://www.example.com',
              ),
              onChanged: (value) {
                controller.updateField(officialWebsite: value);
              },
            ),
            const SizedBox(height: 16),

            // Organization Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Organization Description',
                prefixIcon: Icon(Icons.description),
                hintText: 'Describe your organization...',
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                controller.updateField(organizationDescription: value);
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                hintText: 'Enter organization address',
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                controller.updateField(address: value);
              },
            ),
            const SizedBox(height: 16),

            // Contact Person Name
            TextFormField(
              controller: _contactPersonController,
              decoration: const InputDecoration(
                labelText: 'Contact Person Name',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Name of the contact person',
              ),
              onChanged: (value) {
                controller.updateField(contactPersonName: value);
              },
            ),
            const SizedBox(height: 16),

            // Contact Person Phone
            TextFormField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Person Phone',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'Contact person phone number',
              ),
              onChanged: (value) {
                controller.updateField(contactPersonPhone: value);
              },
            ),
            const SizedBox(height: 24),

            // Last Updated
            if (profile.updatedAt != null)
              Text(
                'Last updated: ${DateFormat('MMM dd, yyyy • h:mm a').format(profile.updatedAt!)}',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: controller.hasChanges && !controller.isLoading
                    ? () => _saveProfile(controller)
                    : null,
                child: controller.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo(BuildContext context, ProfileController controller) async {
    final picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
      if (pickedFile == null) return;

      setState(() {
        _selectedLogo = File(pickedFile.path);
        _isUploadingLogo = true;
      });

      // Upload logo
      await controller.uploadOrganizationLogo(_selectedLogo!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization logo updated successfully')),
      );

      setState(() {
        _isUploadingLogo = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isUploadingLogo = false;
        _selectedLogo = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload logo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile(ProfileController controller) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await controller.saveProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

