import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../shared/widgets/auth/enhanced_auth_components.dart';
import '../../../../shared/widgets/animations/enhanced_animations.dart';
import '../../../../shared/widgets/responsive/responsive_layout.dart';
import '../../../../shared/widgets/ui/enhanced_components.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/responsive.dart';

class EnhancedSignupPage extends ConsumerStatefulWidget {
  const EnhancedSignupPage({super.key});

  @override
  ConsumerState<EnhancedSignupPage> createState() => _EnhancedSignupPageState();
}

class _EnhancedSignupPageState extends ConsumerState<EnhancedSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _showPasswordRequirements = false;

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a1a), // Koyu gri
              Color(0xFF2a2a2a), // Orta gri
              Color(0xFF1f1f1f), // Koyu gri
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.isMobile(context) ? double.infinity : 480,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.isMobile(context) ? 24 : 48,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      EnhancedAnimations.fadeIn(
                        child: _buildHeader(context, isDark),
                      ),
                      
                      SizedBox(height: ModernDesignSystem.spacingXXL),
                      
                      // Form
                      EnhancedAnimations.slideIn(
                        child: _buildForm(context, isDark),
                      ),
                      
                      SizedBox(height: ModernDesignSystem.spacingXL),
                      
                      // Social Login
                      EnhancedAnimations.fadeIn(
                        child: _buildSocialLogin(context, isDark),
                      ),
                      
                      SizedBox(height: ModernDesignSystem.spacingXL),
                      
                      // Login Link
                      EnhancedAnimations.fadeIn(
                        child: _buildLoginLink(context, isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final logoSize = Responsive.isMobile(context) ? 120.0 : 150.0;
    return Column(
      children: [
        // Logo
        Image.asset(
          'assets/images/logos/app_icon.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
        
        const SizedBox(height: ModernDesignSystem.spacingM),
        
        // Title
        ShaderMask(
          shaderCallback: (bounds) => ModernDesignSystem.primaryGradient.createShader(bounds),
          child: Text(
            'Tuniverse',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          AppLocalizations.of(context).t('start_music_journey'),
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeM,
            color: isDark 
                ? ModernDesignSystem.textOnDark.withValues(alpha: 0.7)
                : ModernDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isDark) {
    return EnhancedCard(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email
            EnhancedEmailField(
              controller: _emailController,
              checkAvailability: true,
            ),
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Display Name
            TextFormField(
              controller: _displayNameController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context).t('please_enter_display_name');
                }
                if (value.trim().length < 2) {
                  return AppLocalizations.of(context).t('display_name_min_2');
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).t('display_name'),
                hintText: AppLocalizations.of(context).t('your_name'),
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? ModernDesignSystem.darkSurface
                    : ModernDesignSystem.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                  borderSide: BorderSide(color: ModernDesignSystem.primaryGreen, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                  borderSide: BorderSide(color: ModernDesignSystem.error, width: 2),
                ),
              ),
            ),
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Username
            EnhancedUsernameField(
              controller: _usernameController,
              checkAvailability: true,
            ),
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Password
            EnhancedPasswordField(
              controller: _passwordController,
              showStrengthIndicator: true,
              onChanged: () {
                setState(() {
                  _showPasswordRequirements = _passwordController.text.isNotEmpty;
                });
              },
            ),
            
            // Password Requirements
            if (_showPasswordRequirements) ...[
              SizedBox(height: ModernDesignSystem.spacingM),
              PasswordRequirements(password: _passwordController.text),
            ],
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Confirm Password
            EnhancedPasswordField(
              controller: _confirmPasswordController,
              labelText: AppLocalizations.of(context).t('confirm_password'),
              hintText: AppLocalizations.of(context).t('reenter_password'),
              validator: (value) => AuthValidators.validateConfirmPassword(
                value, 
                _passwordController.text,
              ),
            ),
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Terms and Conditions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms = value ?? false;
                    });
                  },
                  activeColor: ModernDesignSystem.primaryGreen,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _acceptTerms = !_acceptTerms;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: ModernDesignSystem.fontSizeS,
                            color: isDark 
                                ? ModernDesignSystem.textOnDark.withValues(alpha: 0.8)
                                : ModernDesignSystem.textSecondary,
                          ),
                          children: [
                            TextSpan(text: AppLocalizations.of(context).t('accept_terms')),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push('/terms'),
                                child: Text(
                                  AppLocalizations.of(context).t('terms_of_service'),
                                  style: TextStyle(
                                    color: ModernDesignSystem.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(text: AppLocalizations.of(context).t('and')),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push('/privacy'),
                                child: Text(
                                  AppLocalizations.of(context).t('privacy_policy'),
                                  style: TextStyle(
                                    color: ModernDesignSystem.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: ModernDesignSystem.spacingXL),
            
            // Sign Up Button
            EnhancedButton(
              text: AppLocalizations.of(context).t('create_account'),
              type: ButtonType.primary,
              size: ButtonSize.large,
              fullWidth: true,
              isLoading: _isLoading,
              onPressed: _acceptTerms ? _handleSignUp : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLogin(BuildContext context, bool isDark) {
    return const SizedBox.shrink(); // Remove social login entirely
  }

  Widget _buildLoginLink(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context).t('already_have_account'),
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeM,
            color: isDark 
                ? ModernDesignSystem.textOnDark.withValues(alpha: 0.7)
                : ModernDesignSystem.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text(
            AppLocalizations.of(context).t('log_in'),
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeM,
              fontWeight: FontWeight.w600,
              color: ModernDesignSystem.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      _showErrorDialog('Please accept the terms to continue');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('🚀 SIGNUP STARTING!');
    print('   displayName: ${_displayNameController.text.trim()}');
    print('   username: ${_usernameController.text.trim()}');
    print('   email: ${_emailController.text.trim()}');

    try {
      final credential = await FirebaseService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
      );
      
      print('🎉 SIGNUP COMPLETED!');
      print('   credential: $credential');
      print('   currentUser: ${FirebaseService.auth.currentUser?.uid}');

      if (credential != null || FirebaseService.auth.currentUser != null) {
        // Show success message
        if (mounted) {
          EnhancedSnackbar.show(
            context,
            message: 'Account created successfully!',
            type: SnackbarType.success,
          );
          
          // Navigate to home page
          context.go('/');
        }
      } else {
        _showErrorDialog('An error occurred during sign up');
      }
    } catch (e) {
      if (e is String) {
        _showErrorDialog(e);
      } else {
        _showErrorDialog('Unexpected error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Google and Apple Sign In methods removed

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: const Text(
          'Your account has been created. Please check your email to verify your address.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialogWithEmailVerification() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sign Up Successful!'),
        content: const Text(
          'Your account has been created successfully!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
