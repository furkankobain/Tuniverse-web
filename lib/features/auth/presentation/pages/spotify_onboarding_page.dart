import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/widgets/ui/enhanced_components.dart';

class SpotifyOnboardingPage extends StatefulWidget {
  final Map<String, dynamic> spotifyProfile;
  final String userId;
  
  const SpotifyOnboardingPage({
    super.key,
    required this.spotifyProfile,
    required this.userId,
  });

  @override
  State<SpotifyOnboardingPage> createState() => _SpotifyOnboardingPageState();
}

class _SpotifyOnboardingPageState extends State<SpotifyOnboardingPage> {
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _importPlaylists = true;
  bool _importFavorites = true;

  @override
  void initState() {
    super.initState();
    
    final displayName = widget.spotifyProfile['display_name'] as String? ?? '';
    final username = _generateUsername(displayName);
    _profileImageUrl = widget.spotifyProfile['images']?[0]?['url'] as String?;
    
    _displayNameController = TextEditingController(text: displayName);
    _usernameController = TextEditingController(text: username);
    _bioController = TextEditingController(text: 'Music enthusiast 🎵');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String _generateUsername(String displayName) {
    final base = displayName.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return base.isEmpty ? 'user$timestamp' : '${base.length > 10 ? base.substring(0, 10) : base}$timestamp';
  }

  Future<void> _completeOnboarding() async {
    if (_displayNameController.text.trim().isEmpty) {
      _showError('Please enter a display name');
      return;
    }
    
    if (_usernameController.text.trim().isEmpty) {
      _showError('Please enter a username');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🎯 Saving onboarding data:');
      print('   - Display Name: ${_displayNameController.text.trim()}');
      print('   - Username: ${_usernameController.text.trim().toLowerCase()}');
      print('   - Bio: ${_bioController.text.trim()}');
      print('   - User ID: ${widget.userId}');
      
      // Update user document with customized data
      await FirebaseService.firestore
          .collection('users')
          .doc(widget.userId)
          .update({
        'displayName': _displayNameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
        'profileImageUrl': _profileImageUrl ?? '',
        'onboardingCompleted': true,
        'preferences': {
          'importPlaylists': _importPlaylists,
          'importFavorites': _importFavorites,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Onboarding data saved successfully!');

      if (mounted) {
        // Navigate to home
        context.go('/');
      }
    } catch (e) {
      print('❌ Error saving onboarding data: $e');
      _showError('Failed to complete setup: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ModernDesignSystem.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Welcome Header
              _buildHeader(isDark),
              
              const SizedBox(height: 40),
              
              // Profile Picture
              _buildProfilePicture(isDark),
              
              const SizedBox(height: 32),
              
              // Display Name
              _buildTextField(
                controller: _displayNameController,
                label: 'Display Name',
                hint: 'How others will see you',
                icon: Icons.person_outline,
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Username
              _buildTextField(
                controller: _usernameController,
                label: 'Username',
                hint: '@username',
                icon: Icons.alternate_email,
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Bio
              _buildTextField(
                controller: _bioController,
                label: 'Bio (Optional)',
                hint: 'Tell us about yourself',
                icon: Icons.notes,
                isDark: isDark,
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Import Options
              _buildImportOptions(isDark),
              
              const SizedBox(height: 32),
              
              // Continue Button
              _buildContinueButton(isDark),
              
              const SizedBox(height: 16),
              
              // Skip Button
              _buildSkipButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1DB954).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF1DB954),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Connected with Spotify',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve pulled your info from Spotify.\nFeel free to customize it!',
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture(bool isDark) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ModernDesignSystem.primaryGreen,
                  ModernDesignSystem.primaryGreen.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ModernDesignSystem.primaryGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _profileImageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _profileImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        size: 60,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 60,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ModernDesignSystem.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.black : Colors.white,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.music_note,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            prefixIcon: Icon(
              icon,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ModernDesignSystem.primaryGreen,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportOptions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import from Spotify',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildCheckboxTile(
          'Import my playlists',
          _importPlaylists,
          (value) => setState(() => _importPlaylists = value ?? false),
          isDark,
        ),
        _buildCheckboxTile(
          'Import my favorite tracks',
          _importFavorites,
          (value) => setState(() => _importFavorites = value ?? false),
          isDark,
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
    bool isDark,
  ) {
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: ModernDesignSystem.primaryGreen,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildContinueButton(bool isDark) {
    return EnhancedButton(
      text: 'Continue',
      type: ButtonType.primary,
      size: ButtonSize.large,
      fullWidth: true,
      isLoading: _isLoading,
      onPressed: _completeOnboarding,
    );
  }

  Widget _buildSkipButton(bool isDark) {
    return Center(
      child: TextButton(
        onPressed: () async {
          // Skip and mark onboarding as completed
          try {
            await FirebaseService.firestore
                .collection('users')
                .doc(widget.userId)
                .update({
              'onboardingCompleted': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            if (mounted) {
              context.go('/');
            }
          } catch (e) {
            print('Error skipping onboarding: $e');
          }
        },
        child: Text(
          'Skip for now',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
