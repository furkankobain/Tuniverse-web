import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/firebase_storage_service.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkController = TextEditingController();
  final _locationController = TextEditingController();
  
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isProfilePrivate = false;
  List<Map<String, dynamic>> _favoriteTracks = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _linkController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        print('📝 Loading user data: ${data.keys.toList()}');
        setState(() {
          _displayNameController.text = data['displayName'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _linkController.text = data['link'] ?? '';
          _locationController.text = data['location'] ?? '';
          // Try both field names for backwards compatibility
          _profileImageUrl = data['profileImageUrl'] ?? data['photoURL'];
          _isProfilePrivate = data['isPrivate'] ?? false;
        });
        
        // Load favorite tracks
        final favoritesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .where('type', isEqualTo: 'track')
            .limit(4)
            .get();
        
        if (mounted) {
          setState(() {
            _favoriteTracks = favoritesSnapshot.docs
                .map((doc) => {...doc.data(), 'docId': doc.id})
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    // Show options: Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
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
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return;

      // Upload to Firebase Storage
      final imageUrl = await FirebaseStorageService.uploadProfileImage(
        imagePath: image.path,
        userId: userId,
      );

      if (imageUrl != null) {
        setState(() => _profileImageUrl = imageUrl);
        
        // Update Firestore immediately with both field names
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
              'profileImageUrl': imageUrl,
              'photoURL': imageUrl, // Keep for backwards compatibility
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) {
        throw Exception('User session not found');
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'displayName': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'link': _linkController.text.trim(),
        'location': _locationController.text.trim(),
        'isPrivate': _isProfilePrivate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _usernameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.grey[800] : Colors.grey[300],
                              image: _profileImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 3,
                              ),
                            ),
                            child: _profileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  )
                                : null,
                          ),
                          if (_isUploadingImage)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingImage ? null : _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.grey[900]! : Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    
                    Text(
                    'Tap to change photo',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Display Name
                    _buildTextField(
                      controller: _displayNameController,
                      label: 'Display Name',
                      icon: Icons.badge_outlined,
                      hint: 'Your display name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Display name is required';
                        }
                        return null;
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Username
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email,
                      hint: 'username',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Bio
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      icon: Icons.notes,
                      hint: 'Describe your music taste...',
                      maxLines: 4,
                      maxLength: 250,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Link
                    _buildTextField(
                      controller: _linkController,
                      label: 'Website / Link',
                      icon: Icons.link,
                      hint: 'https://...',
                      keyboardType: TextInputType.url,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Location
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      hint: 'New York, USA',
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),

                    // Privacy Settings
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Private Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Only people you follow can see your profile',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isProfilePrivate,
                            onChanged: (value) {
                              setState(() => _isProfilePrivate = value);
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    
                    // Favorite Tracks Section
                    Text(
                      'Favorite Tracks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap on a track to change or add your favorites',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 4 Favorite Track Bars
                    ...List.generate(4, (index) => _buildFavoriteTrackBar(index, isDark)),

                    const SizedBox(height: 32),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Changes will be applied after you save your profile information.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.white,
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
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        counterStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          fontSize: 11,
        ),
      ),
    );
  }
  
  Widget _buildFavoriteTrackBar(int index, bool isDark) {
    final track = index < _favoriteTracks.length ? _favoriteTracks[index] : null;
    final trackName = track?['name'] as String?;
    final artists = track?['artists'] as List?;
    final artistName = artists != null && artists.isNotEmpty 
        ? artists.map((a) => a['name']).join(', ')
        : null;
    final album = track?['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty ? images.first['url'] as String? : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          // Navigate to search to select a track
          context.push('/search');
          
          // Show info snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Search for a track and add it to favorites'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: track != null 
                ? (isDark ? Colors.grey[850]!.withOpacity(0.5) : Colors.white.withOpacity(0.5))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: track != null
                  ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                  : (isDark ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[400]!.withOpacity(0.3)),
              width: 1.5,
              style: track != null ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              // Track number or album art
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: track != null
                      ? (isDark ? Colors.grey[800] : Colors.grey[200])
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: track == null
                      ? Border.all(
                          color: isDark ? Colors.grey[700]!.withOpacity(0.3) : Colors.grey[400]!.withOpacity(0.3),
                          width: 1,
                          style: BorderStyle.solid,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: track != null
                                ? AppTheme.primaryColor
                                : (isDark ? Colors.grey[600] : Colors.grey[400]),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Track info or placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trackName ?? 'Tap to add favorite track ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: trackName != null ? FontWeight.w600 : FontWeight.normal,
                        color: trackName != null
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.grey[500] : Colors.grey[500]),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (artistName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        artistName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Add icon
              Icon(
                trackName != null ? Icons.edit : Icons.add_circle_outline,
                color: trackName != null
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
