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

/// Student Profile Screen
/// Allows students to view and edit their profile information
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _yearController = TextEditingController();

  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
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
              title: const Text('My Profile'),
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
    _collegeController.text = profile.collegeName ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
    _departmentController.text = profile.department ?? '';
    _yearController.text = profile.yearOfStudy ?? '';
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

            // Profile Photo Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.border,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (profile.profilePhotoUrl != null
                            ? NetworkImage(profile.profilePhotoUrl!)
                            : null) as ImageProvider?,
                    child: profile.profilePhotoUrl == null && _selectedImage == null
                        ? const Icon(Icons.person, size: 60, color: AppColors.textDisabled)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        icon: _isUploadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _isUploadingImage ? null : () => _pickImage(context, controller),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Full Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
              onChanged: (value) {
                controller.updateField(name: value);
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

            // College Name (Required)
            TextFormField(
              controller: _collegeController,
              decoration: const InputDecoration(
                labelText: 'College Name *',
                prefixIcon: Icon(Icons.school),
                hintText: 'Enter your college/institution name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'College name is required';
                }
                return null;
              },
              onChanged: (value) {
                controller.updateField(collegeName: value);
              },
            ),
            const SizedBox(height: 16),

            // Phone Number (Required)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone),
                hintText: 'Enter your phone number',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                // Basic phone validation (10 digits minimum)
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

            // Department
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(
                labelText: 'Department',
                prefixIcon: Icon(Icons.business),
                hintText: 'e.g., Computer Science, Mechanical Engineering',
              ),
              onChanged: (value) {
                controller.updateField(department: value);
              },
            ),
            const SizedBox(height: 16),

            // Year of Study
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year of Study',
                prefixIcon: Icon(Icons.calendar_today),
                hintText: 'e.g., 1st Year, 2nd Year, Final Year',
              ),
              onChanged: (value) {
                controller.updateField(yearOfStudy: value);
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

  Future<void> _pickImage(BuildContext context, ProfileController controller) async {
    final picker = ImagePicker();
    
    // Show option to choose from camera or gallery
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
        _selectedImage = File(pickedFile.path);
        _isUploadingImage = true;
      });

      // Upload image
      await controller.uploadProfilePhoto(_selectedImage!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully')),
      );

      setState(() {
        _isUploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isUploadingImage = false;
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: ${e.toString()}'),
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

