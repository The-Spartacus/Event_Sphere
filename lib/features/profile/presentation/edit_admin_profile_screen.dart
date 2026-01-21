import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/colors.dart';
import '../../../app/app_config.dart';
import '../data/user_profile_model.dart';
import '../logic/profile_controller.dart';
import '../data/profile_repository.dart';
import '../data/storage_service.dart';

class EditAdminProfileScreen extends StatefulWidget {
  const EditAdminProfileScreen({super.key});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final userId = authService.currentUserId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
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
          if (controller.profile != null && !controller.hasChanges) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeFields(controller.profile!);
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Admin Profile'),
              actions: [
                if (controller.hasChanges)
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: controller.isLoading ? null : () => _saveProfile(controller),
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
  }

  Widget _buildBody(BuildContext context, ProfileController controller) {
     if (controller.isLoading && controller.profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.profile == null) {
      return Center(child: Text(controller.error!));
    }
    
    final profile = controller.profile;
    if (profile == null) return const Center(child: Text('Profile not found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Profile Image Picker
             Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (profile.profilePhotoUrl != null
                            ? NetworkImage(profile.profilePhotoUrl!)
                            : null) as ImageProvider?,
                    child: (_selectedImage == null && profile.profilePhotoUrl == null)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
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
                            : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: _isUploadingImage ? null : () => _pickImage(context, controller),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (val) => controller.updateField(name: val),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              onChanged: (val) => controller.updateField(phoneNumber: val),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickImage(BuildContext context, ProfileController controller) async {
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
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _isUploadingImage = true;
      });

      await controller.uploadProfilePhoto(_selectedImage!);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
      
      setState(() => _isUploadingImage = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
    }
  }

  Future<void> _saveProfile(ProfileController controller) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await controller.saveProfile();
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
