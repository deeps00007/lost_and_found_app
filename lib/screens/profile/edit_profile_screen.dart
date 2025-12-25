import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/screen_header.dart';
import '../../services/imagekit_service.dart';
import '../../utils/permissions.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final User currentUser = FirebaseAuth.instance.currentUser!;

  final ImagePicker _picker = ImagePicker();
  final ImageKitService _imageKitService = ImageKitService();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _showImageSourceSelection() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Change Profile Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final hasPermission = await PermissionHelper.requestCameraPermission();
        if (!hasPermission) return;
      } else {
        final hasPermission = await PermissionHelper.requestStoragePermission();
        if (!hasPermission) return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      _nameController.text = data['name'] ?? '';
      _phoneController.text = data['phoneNumber'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl;

      // 1. Upload new image if selected
      if (_selectedImage != null) {
        final uploadedImage = await _imageKitService.uploadImage(
          imageFile: _selectedImage!,
          folder: 'profile_images',
        );
        if (uploadedImage != null) {
          photoUrl = uploadedImage['url'];
        }
      }

      // 2. Update Firestore
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      };

      if (photoUrl != null) {
        updateData['profilePicUrl'] = photoUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);

      // 3. Update Auth Profile
      await currentUser.updateDisplayName(_nameController.text.trim());
      if (photoUrl != null) {
        await currentUser.updatePhotoURL(photoUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Edit Profile',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceSelection,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (currentUser.photoURL != null
                                      ? CachedNetworkImageProvider(
                                          currentUser.photoURL!)
                                      : null) as ImageProvider?,
                              child: (_selectedImage == null &&
                                      currentUser.photoURL == null)
                                  ? Text(
                                      currentUser.displayName?[0]
                                              .toUpperCase() ??
                                          'U',
                                      style: TextStyle(
                                          fontSize: 40,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your name',
                      prefixIcon: Icons.person_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 32),
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _updateProfile,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
