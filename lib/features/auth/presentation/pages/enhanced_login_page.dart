import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../shared/widgets/auth/enhanced_auth_components.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../shared/widgets/animations/enhanced_animations.dart';
import '../../../../shared/widgets/responsive/responsive_layout.dart';
import '../../../../shared/widgets/ui/enhanced_components.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/google_sign_in_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/responsive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EnhancedLoginPage extends ConsumerStatefulWidget {
  const EnhancedLoginPage({super.key});

  @override
  ConsumerState<EnhancedLoginPage> createState() => _EnhancedLoginPageState();
}

class _EnhancedLoginPageState extends ConsumerState<EnhancedLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSpotifyLoading = false;
  bool _isGoogleLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Map<String, String> _texts(String languageCode) {
    return languageCode == 'tr' ? {
      'title': 'Tuniverse',
      'subtitle': 'Müzik deneyiminizi keşfedin',
      'emailLabel': 'E-posta veya Kullanıcı Adı',
      'emailHint': 'email@example.com veya kullanıcı adı',
      'passwordLabel': 'Şifre',
      'passwordHint': 'Şifrenizi girin',
      'rememberMe': 'Beni Hatırla',
      'forgotPassword': 'Şifremi Unuttum',
      'login': 'Giriş Yap',
      'or': 'veya',
      'continueSpotify': 'Spotify ile Devam Et',
      'continueGoogle': 'Google ile Devam Et',
      'noAccount': 'Hesabınız yok mu? ',
      'signup': 'Kayıt Ol',
      'openingSpotify': 'Spotify açılıyor...',
      'openingGoogle': 'Google açılıyor...',
    } : {
      'title': 'Tuniverse',
      'subtitle': 'Discover your music experience',
      'emailLabel': 'Email or Username',
      'emailHint': 'email@example.com or username',
      'passwordLabel': 'Password',
      'passwordHint': 'Enter your password',
      'rememberMe': 'Remember Me',
      'forgotPassword': 'Forgot Password',
      'login': 'Log In',
      'or': 'or',
      'continueSpotify': 'Continue with Spotify',
      'continueGoogle': 'Continue with Google',
      'noAccount': 'Don\'t have an account? ',
      'signup': 'Sign Up',
      'openingSpotify': 'Opening Spotify...',
      'openingGoogle': 'Opening Google...',
    };
  }

  late Map<String, String> texts;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(languageProvider);
    final languageCode = currentLocale?.languageCode ?? 'en';
    texts = _texts(languageCode);
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                    ),
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
                            
                            const SizedBox(height: ModernDesignSystem.spacingXL * 2),
                            
                            // Form
                            EnhancedAnimations.slideIn(
                              child: _buildForm(context, isDark),
                            ),
                            
                            const SizedBox(height: ModernDesignSystem.spacingL),
                            
                            // Social Login
                            EnhancedAnimations.fadeIn(
                              child: _buildSocialLogin(context, isDark),
                            ),
                            
                            const SizedBox(height: ModernDesignSystem.spacingM),
                            
                            // Signup Link
                            EnhancedAnimations.fadeIn(
                              child: _buildSignupLink(context, isDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Language selector
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    initialValue: languageCode,
                    onSelected: (value) {
                      ref.read(languageProvider.notifier).setLanguage(value);
                    },
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          languageCode == 'en' ? '🇬🇧' : '🇹🇷',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                      ],
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            Text('🇬🇧', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 12),
                            Text('English'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'tr',
                        child: Row(
                          children: [
                            Text('🇹🇷', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 12),
                            Text('Türkçe'),
                          ],
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
          texts['subtitle']!,
          style: TextStyle(
            fontSize: 15,
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
      padding: const EdgeInsets.all(ModernDesignSystem.spacingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email or Username
            TextFormField(
              controller: _emailOrUsernameController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validateLoginUsername,
              decoration: InputDecoration(
                labelText: texts['emailLabel']!,
                hintText: texts['emailHint']!,
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ModernDesignSystem.spacingM,
                  vertical: ModernDesignSystem.spacingM,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: AuthValidators.validateLoginPassword,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: texts['passwordLabel']!,
                hintText: texts['passwordHint']!,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ModernDesignSystem.spacingM,
                  vertical: ModernDesignSystem.spacingM,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Remem            // Remember Me & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: ModernDesignSystem.primaryGreen,
                      ),
                    ),
                    Text(
                      texts['rememberMe']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark 
                            ? ModernDesignSystem.textOnDark.withValues(alpha: 0.8)
                            : ModernDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    texts['forgotPassword']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: ModernDesignSystem.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Login Button
            EnhancedButton(
              text: texts['login']!,
              type: ButtonType.primary,
              size: ButtonSize.large,
              fullWidth: true,
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLogin(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark 
                    ? ModernDesignSystem.textOnDark.withValues(alpha: 0.2)
                    : ModernDesignSystem.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingM),
              child: Text(
                texts['or']!,
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeS,
                  color: isDark 
                      ? ModernDesignSystem.textOnDark.withValues(alpha: 0.6)
                      : ModernDesignSystem.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark 
                    ? ModernDesignSystem.textOnDark.withValues(alpha: 0.2)
                    : ModernDesignSystem.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Spotify Sign In Button
        _buildSocialButton(
          context: context,
          isDark: isDark,
          iconPath: 'assets/images/auth/spotify_icon.png',
          label: _isSpotifyLoading ? texts['openingSpotify']! : texts['continueSpotify']!,
          color: const Color(0xFF1DB954), // Spotify green
          onPressed: _isSpotifyLoading ? () {} : _handleSpotifySignIn,
        ),
        
        const SizedBox(height: 10),
        
        // Google Sign In Button
        _buildSocialButton(
          context: context,
          isDark: isDark,
          iconPath: 'assets/images/auth/google_icon.png',
          label: _isGoogleLoading ? texts['openingGoogle']! : texts['continueGoogle']!,
          color: const Color(0xFF4285F4), // Google blue
          onPressed: _isGoogleLoading ? () {} : _handleGoogleSignIn,
        ),
      ],
    );
  }
  
  Widget _buildSocialButton({
    required BuildContext context,
    required bool isDark,
    required String iconPath,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: color.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            SizedBox(width: ModernDesignSystem.spacingM),
            Text(
              label,
              style: const TextStyle(
                fontSize: ModernDesignSystem.fontSizeM,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupLink(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          texts['noAccount']!,
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeM,
            color: isDark 
                ? ModernDesignSystem.textOnDark.withValues(alpha: 0.7)
                : ModernDesignSystem.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/signup'),
          child: Text(
            texts['signup']!,
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cred = await FirebaseService.signInWithEmail(
        email: _emailOrUsernameController.text.trim(),
        password: _passwordController.text,
      );

      // Check auth state directly as backup
      final user = FirebaseService.auth.currentUser;
      
      if (user != null) {
        // Show success message
        if (mounted) {
          EnhancedSnackbar.show(
            context,
            message: 'Signed in successfully!',
            type: SnackbarType.success,
          );
          
          // Navigate to home page
          context.go('/');
        }
      } else if (cred != null) {
        // Credential exists but user null - wait a bit and check again
        await Future.delayed(const Duration(milliseconds: 500));
        final retryUser = FirebaseService.auth.currentUser;
        if (retryUser != null && mounted) {
          context.go('/');
        } else {
          _showErrorDialog('Authentication state error. Please try again.');
        }
      } else {
        _showErrorDialog('An error occurred during sign in');
      }
    } catch (e) {
      // Check if user is actually signed in despite error
      if (FirebaseService.auth.currentUser != null && mounted) {
        context.go('/');
      } else {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSpotifySignIn() async {
    if (_isSpotifyLoading) return; // Prevent double-click
    
    setState(() {
      _isSpotifyLoading = true;
    });
    
    try {
      // Start Spotify OAuth flow
      final success = await EnhancedSpotifyService.authenticate();
      
      if (!success && mounted) {
        EnhancedSnackbar.show(
          context,
          message: 'Failed to start Spotify authorization',
          type: SnackbarType.error,
        );
        setState(() {
          _isSpotifyLoading = false;
        });
      }
      // Success case: Browser will open, callback will handle login
      // Don't reset loading - let the callback handle it
    } catch (e) {
      if (mounted) {
        EnhancedSnackbar.show(
          context,
          message: 'Error during Spotify sign-in: ${e.toString()}',
          type: SnackbarType.error,
        );
        setState(() {
          _isSpotifyLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return; // Prevent double-click
    
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // Google Sign-In
      final userCredential = await GoogleSignInService.signInWithGoogle();
      
      // Check if user is actually signed in (credential might be null due to Firebase bug)
      final currentUser = FirebaseService.auth.currentUser;
      
      if (userCredential != null || currentUser != null) {
        // Başarılı giriş - AuthWrapper will handle onboarding
        if (mounted) {
          EnhancedSnackbar.show(
            context,
            message: 'Signed in with Google!',
            type: SnackbarType.success,
          );
          
          // Navigate to home (AuthWrapper will check onboarding)
          context.go('/');
        }
      } else {
        // Kullanıcı gerçekten iptal etti
        if (mounted) {
          EnhancedSnackbar.show(
            context,
            message: 'Google sign-in cancelled',
            type: SnackbarType.info,
          );
          setState(() {
            _isGoogleLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        EnhancedSnackbar.show(
          context,
          message: 'Error during Google sign-in: ${e.toString()}',
          type: SnackbarType.error,
        );
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    EnhancedDialog.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_reset,
              size: 64,
              color: ModernDesignSystem.primaryGreen,
            ),
            SizedBox(height: ModernDesignSystem.spacingL),
            Text(
              'Password Reset',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ModernDesignSystem.spacingM),
            Text(
              'Enter your email address to receive a password reset link.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ModernDesignSystem.spacingL),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: AuthValidators.validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            SizedBox(height: ModernDesignSystem.spacingXL),
            Row(
              children: [
                Expanded(
                  child: EnhancedButton(
                    text: 'Cancel',
                    type: ButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: ModernDesignSystem.spacingM),
                Expanded(
                  child: EnhancedButton(
                    text: 'Send',
                    onPressed: () => _handleForgotPassword(emailController.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword(String email) async {
    if (email.isEmpty) {
      EnhancedSnackbar.show(
        context,
        message: 'Please enter your email address',
        type: SnackbarType.error,
      );
      return;
    }

    try {
      await FirebaseService.resetPassword(email);
      
      Navigator.of(context).pop();
      EnhancedSnackbar.show(
        context,
        message: 'Password reset email sent',
          type: SnackbarType.success,
        );
    } catch (e) {
      _showErrorDialog('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    EnhancedDialog.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ModernDesignSystem.error,
            ),
            SizedBox(height: ModernDesignSystem.spacingL),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ModernDesignSystem.spacingM),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ModernDesignSystem.spacingXL),
            EnhancedButton(
              text: 'OK',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
