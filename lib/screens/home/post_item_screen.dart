import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_and_found_app/utils/permissions.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker_screen.dart';
import '../../services/imagekit_service.dart';
import '../../widgets/screen_header.dart';

class PostItemScreen extends StatefulWidget {
  @override
  _PostItemScreenState createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final ImagePicker _picker = ImagePicker();
  final ImageKitService _imageKitService = ImageKitService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<File> _selectedImages = [];
  bool _uploading = false;
  String _itemType = 'lost';
  String _category = 'Electronics';
  LatLng? _selectedLatLng;

  final List<String> _categories = [
    'Electronics',
    'Documents',
    'Accessories',
    'Bags',
    'Keys',
    'Clothing',
    'Books',
    'Other',
  ];

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
              'Add Photos',
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
                    _pickFromCamera();
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
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
      child: Container(
        width: 100,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final hasPermission = await PermissionHelper.requestCameraPermission();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera permission is required'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final hasPermission = await PermissionHelper.requestStoragePermission();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Storage permission is required'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      final List<XFile> images = await _picker.pickMultiImage(
        limit: 5 - _selectedImages.length,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadAndPostItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one image'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      List<Map<String, String>> uploadedImages =
          await _imageKitService.uploadMultipleImages(
        imageFiles: _selectedImages,
        folder: 'item_images',
      );

      if (uploadedImages.isEmpty) {
        throw Exception('Failed to upload images');
      }

      List<String> imageUrls =
          uploadedImages.map((img) => img['url']!).toList();
      List<String> fileIds =
          uploadedImages.map((img) => img['fileId']!).toList();

      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('items').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _category,
        'type': _itemType,
        'images': imageUrls,
        'imageFileIds': fileIds,
        'postedBy': user.uid,
        'postedByName': user.displayName ?? 'Anonymous',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'latitude': _selectedLatLng?.latitude,
        'longitude': _selectedLatLng?.longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item posted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Post Item',
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
            action: !_uploading
                ? TextButton(
                    onPressed: _uploadAndPostItem,
                    child: Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: _uploading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Uploading images and posting...',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated Sliding Segment Control
                          LayoutBuilder(builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            return Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedAlign(
                                    alignment: _itemType == 'lost'
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                    child: Container(
                                      width: (width / 2),
                                      height: 48,
                                      margin: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _buildAnimatedTypeSegment(
                                        label: 'Lost Item',
                                        value: 'lost',
                                        icon: Icons.search_off_rounded,
                                        selectedColor: const Color(0xFFFF8C7A),
                                      ),
                                      _buildAnimatedTypeSegment(
                                        label: 'Found Item',
                                        value: 'found',
                                        icon:
                                            Icons.check_circle_outline_rounded,
                                        selectedColor: const Color(0xFF43A047),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: 24),

                          _buildSectionLabel('Category'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _category,
                                isExpanded: true,
                                icon: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.keyboard_arrow_down_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                items: _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Row(
                                      children: [
                                        _getCategoryIcon(category),
                                        SizedBox(width: 12),
                                        Text(category),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => _category = value!),
                              ),
                            ),
                          ),

                          SizedBox(height: 24),

                          _buildSectionLabel('Details'),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'What was lost/found?',
                              hintText: 'e.g. Black iPhone 13 Pro',
                              prefixIcon: Icon(Icons.title_rounded,
                                  color: Colors.grey[400]),
                            ),
                            maxLength: 50,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter a title'
                                : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Where?',
                              hintText: 'e.g. Library, 2nd Floor',
                              prefixIcon: Icon(Icons.location_on_outlined,
                                  color: Colors.grey[400]),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.map,
                                    color: Theme.of(context).primaryColor),
                                onPressed: () async {
                                  final result = await Navigator.push<LatLng>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LocationPickerScreen(
                                        initialLocation: _selectedLatLng,
                                      ),
                                    ),
                                  );
                                  if (result != null) {
                                    setState(() {
                                      _selectedLatLng = result;
                                      // Optional: Reverse geocode to get address string
                                      // For now, keying in text is manual, map is for coordinates
                                    });
                                  }
                                },
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter a location'
                                : null,
                          ),
                          if (_selectedLatLng != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 4),
                              child: Text(
                                'Coordinate selected: ${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText:
                                  'Provide more details like color, scratches, or unique identifiers...',
                              alignLabelWithHint: true,
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 60),
                                child: Icon(Icons.description_outlined,
                                    color: Colors.grey[400]),
                              ),
                            ),
                            maxLines: 4,
                            maxLength: 500,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          SizedBox(height: 24),

                          _buildSectionLabel(
                              'Photos (${_selectedImages.length}/5)'),
                          if (_selectedImages.isNotEmpty) ...[
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length +
                                    (_selectedImages.length < 5 ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _selectedImages.length) {
                                    return GestureDetector(
                                      onTap: _showImageSourceSelection,
                                      child: Container(
                                        width: 100,
                                        margin: EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.3),
                                            style: BorderStyle.solid,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                Icons
                                                    .add_photo_alternate_rounded,
                                                color: primaryColor),
                                            SizedBox(height: 4),
                                            Text('Add',
                                                style: TextStyle(
                                                    color: primaryColor,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 120,
                                        margin: EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          image: DecorationImage(
                                            image: FileImage(
                                                _selectedImages[index]),
                                            fit: BoxFit.cover,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 16,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.close,
                                                color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ] else
                            GestureDetector(
                              onTap: _showImageSourceSelection,
                              child: Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.grey.shade300, width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.add_a_photo_rounded,
                                          size: 32, color: primaryColor),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tap to upload images',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      'Supports JPG, PNG (Max 5)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTypeSegment({
    required String label,
    required String value,
    required IconData icon,
    required Color selectedColor,
  }) {
    final isSelected = _itemType == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _itemType = value),
        child: Container(
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: Row(
              key: ValueKey(isSelected),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? selectedColor : Colors.grey[600],
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? selectedColor : Colors.grey[600],
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    switch (category) {
      case 'Electronics':
        icon = Icons.devices_other_rounded;
        break;
      case 'Documents':
        icon = Icons.description_rounded;
        break;
      case 'Accessories':
        icon = Icons.watch_rounded;
        break;
      case 'Bags':
        icon = Icons.shopping_bag_rounded;
        break;
      case 'Keys':
        icon = Icons.vpn_key_rounded;
        break;
      case 'Clothing':
        icon = Icons.checkroom_rounded;
        break;
      case 'Books':
        icon = Icons.menu_book_rounded;
        break;
      default:
        icon = Icons.category_rounded;
    }
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C5F6F),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
