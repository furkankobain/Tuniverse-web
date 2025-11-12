import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/widgets/ui/enhanced_components.dart';
import '../../../../shared/widgets/password_strength_indicator.dart';

enum SocialProvider { spotify, google }

class SocialOnboardingPage extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String userId;
  final SocialProvider provider;
  
  const SocialOnboardingPage({
    super.key,
    required this.profile,
    required this.userId,
    required this.provider,
  });

  @override
  State<SocialOnboardingPage> createState() => _SocialOnboardingPageState();
}

class _SocialOnboardingPageState extends State<SocialOnboardingPage> {
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  
  String? _profileImageUrl;
  String? _userEmail;
  bool _isLoading = false;
  bool _importPlaylists = true;
  bool _importFavorites = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    
    // Extract profile data based on provider
    final displayName = _extractDisplayName();
    final username = _generateUsername(displayName);
    _profileImageUrl = _extractPhotoUrl();
    _userEmail = _extractEmail();
    
    _displayNameController = TextEditingController(text: displayName);
    _usernameController = TextEditingController(text: username);
    _bioController = TextEditingController(text: 'Music enthusiast 🎵');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  String _extractDisplayName() {
    if (widget.provider == SocialProvider.spotify) {
      return widget.profile['display_name'] as String? ?? '';
    } else {
      // Google
      return widget.profile['displayName'] as String? ?? 
             widget.profile['email']?.toString().split('@')[0] ?? 
             'User';
    }
  }

  String? _extractPhotoUrl() {
    if (widget.provider == SocialProvider.spotify) {
      // Spotify images array
      final images = widget.profile['images'] as List?;
      if (images != null && images.isNotEmpty) {
        return images[0]['url'] as String?;
      }
      return null;
    } else {
      // Google photoURL
      return widget.profile['photoURL'] as String?;
    }
  }

  String? _extractEmail() {
    if (widget.provider == SocialProvider.spotify) {
      return widget.profile['email'] as String?;
    } else {
      return widget.profile['email'] as String?;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    // Validate display name
    final displayNameError = ValidationUtils.validateDisplayName(_displayNameController.text);
    if (displayNameError != null) {
      _showError(displayNameError);
      return;
    }
    
    // Validate username format
    final usernameError = ValidationUtils.validateUsername(_usernameController.text);
    if (usernameError != null) {
      _showError(usernameError);
      return;
    }
    
    // Check username availability
    final username = _usernameController.text.trim().toLowerCase();
    final isUsernameAvailable = await FirebaseService.isUsernameAvailable(username);
    if (!isUsernameAvailable) {
      _showError('This username is already taken. Please choose another one.');
      return;
    }

    // Validate password
    final password = _passwordController.text;
    final passwordError = ValidationUtils.validatePassword(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }
    
    // Confirm password match
    final confirmPassword = _confirmPasswordController.text;
    final confirmError = ValidationUtils.validateConfirmPassword(password, confirmPassword);
    if (confirmError != null) {
      _showError(confirmError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🎯 Saving onboarding data:');
      print('   - Display Name: ${_displayNameController.text.trim()}');
      print('   - Username: ${_usernameController.text.trim().toLowerCase()}');
      print('   - Bio: ${_bioController.text.trim()}');
      print('   - User ID: ${widget.userId}');
      print('   - Email: $_userEmail');
      print('   - Setting password: ${password.isNotEmpty}');
      
      // Link email+password credential (password is mandatory now)
      if (_userEmail != null) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final credential = EmailAuthProvider.credential(
              email: _userEmail!,
              password: password,
            );
            await user.linkWithCredential(credential);
            print('✅ Password linked to account successfully!');
            
            // Send email verification
            try {
              if (!user.emailVerified) {
                await user.sendEmailVerification();
                print('✅ Verification email sent to $_userEmail');
              }
            } catch (e) {
              print('⚠️ Warning: Could not send verification email: $e');
              // Don't block onboarding if email fails
            }
          }
        } catch (e) {
          print('⚠️ Error linking password: $e');
          // Continue with onboarding even if password linking fails
        }
      }
      
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
                label: 'Bio',
                hint: 'Tell us about yourself',
                icon: Icons.notes,
                isDark: isDark,
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Password Setup Section
              _buildPasswordSection(isDark),
              
              const SizedBox(height: 32),
              
              // Continue Button
              _buildContinueButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final providerName = widget.provider == SocialProvider.spotify ? 'Spotify' : 'Google';
    final providerColor = widget.provider == SocialProvider.spotify 
        ? const Color(0xFF1DB954) 
        : const Color(0xFF4285F4);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: providerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: providerColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: providerColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Connected with $providerName',
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
          'We\'ve pulled your info from $providerName.\nFeel free to customize it!',
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
    final providerIcon = widget.provider == SocialProvider.spotify 
        ? Icons.music_note 
        : Icons.g_mobiledata;
    
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
              child: Icon(
                providerIcon,
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

  Widget _buildPasswordSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Set Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Set a password to enable email login with: ${_userEmail ?? 'your email'}',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Password field
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter password (min 6 characters)',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
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
          ),
        ),
        const SizedBox(height: 12),
        
        // Confirm Password field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Re-enter password',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
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
