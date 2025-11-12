import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/validation_utils.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  XFile? _imageFile;
  String? _currentProfileImageUrl;
  String? _originalUsername; // Store original username for comparison
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseService.getUserDocument(user.uid);
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            _nameController.text = data?['displayName'] ?? '';
            _usernameController.text = data?['username'] ?? '';
            _originalUsername = data?['username'] as String?; // Store original
            _bioController.text = data?['bio'] ?? '';
            _emailController.text = user.email ?? '';
            _currentProfileImageUrl = data?['profileImageUrl'] as String?;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseService.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Validate username
    final usernameError = ValidationUtils.validateUsername(_usernameController.text);
    if (usernameError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(usernameError),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Check username availability if changed
    final newUsername = _usernameController.text.trim().toLowerCase();
    if (newUsername != _originalUsername) {
      final isAvailable = await FirebaseService.isUsernameAvailable(
        newUsername,
        excludeUserId: user.uid,
      );
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This username is already taken'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      String? profileImageUrl;
      
      // Upload profile image if selected
      if (_imageFile != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');
          
          // Read file as bytes and upload using putData
          final bytes = await _imageFile!.readAsBytes();
          final uploadTask = storageRef.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          
          // Wait for upload to complete
          final snapshot = await uploadTask;
          
          // Get download URL
          profileImageUrl = await snapshot.ref.getDownloadURL();
          
          print('✅ Profile image uploaded: $profileImageUrl');
        } catch (e) {
          print('❌ Error uploading image: $e');
          throw Exception('Failed to upload profile image: $e');
        }
      }

      // Update Firestore user document
      final updateData = {
        'displayName': _nameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
      };
      
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }
      
      await FirebaseService.updateUserDocument(user.uid, updateData);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('profile_updated')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).t('edit_profile'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                AppLocalizations.of(context).t('save'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF5E5E),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF5E5E),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _imageFile != null
                          ? FutureBuilder<Uint8List>(
                              future: _imageFile!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                }
                                return const CircularProgressIndicator();
                              },
                            )
                          : _currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _currentProfileImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    ),
                                  ),
                                )
                              : Container(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E5E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.black : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: TextButton(
                onPressed: _pickImage,
                child: Text(
                  AppLocalizations.of(context).t('change_photo'),
                  style: const TextStyle(
                    color: Color(0xFFFF5E5E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Form Fields
            _buildTextField(
              controller: _nameController,
              label: AppLocalizations.of(context).t('display_name'),
              hint: AppLocalizations.of(context).t('your_name'),
              isDark: isDark,
              validator: (val) => val!.isEmpty ? AppLocalizations.of(context).t('please_enter_display_name') : null,
            ),

            const SizedBox(height: 20),

            _buildTextField(
              controller: _usernameController,
              label: AppLocalizations.of(context).t('username'),
              hint: AppLocalizations.of(context).t('your_username'),
              isDark: isDark,
              prefix: '@',
              validator: (val) {
                if (val!.isEmpty) return AppLocalizations.of(context).t('please_enter_username');
                if (val.contains(' ')) return AppLocalizations.of(context).t('username_only_alphanumeric');
                return null;
              },
            ),

            const SizedBox(height: 20),

            _buildTextField(
              controller: _bioController,
              label: AppLocalizations.of(context).t('bio'),
              hint: AppLocalizations.of(context).t('tell_about_yourself'),
              isDark: isDark,
              maxLines: 3,
              maxLength: 150,
            ),

            const SizedBox(height: 20),

            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Your email address',
              isDark: isDark,
              enabled: false,
              validator: (val) => val!.isEmpty ? 'Email is required' : null,
            ),

            const SizedBox(height: 32),

            // Additional Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Private Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your email address will not be visible to other users. Only your name, username, and bio are public.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    String? prefix,
    bool enabled = true,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            filled: true,
            fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF5E5E),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: TextStyle(
            fontSize: 15,
            color: enabled
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
        ),
      ],
    );
  }
}
