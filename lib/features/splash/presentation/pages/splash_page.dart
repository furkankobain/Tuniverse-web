import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/theme/modern_design_system.dart';

// Simple splash for web
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // Skip onboarding on web
      if (kIsWeb) {
        context.go('/login');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      if (!onboardingCompleted) {
        context.go('/onboarding');
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            const Text('Tuniverse', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// ESKİ ANİMASYONLU SPLASH (Yedek)
/*
class SplashPageOld extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageOldState extends ConsumerState<SplashPageOld>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _navigateToNext();
  }

  void _initializeAnimations() {
    // Logo Animation Controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Text Animation Controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Progress Animation Controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Logo Scale Animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Logo Rotation Animation
    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Text Fade Animation
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Progress Animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    // Start logo animation
    _logoController.forward();
    
    // Start text animation after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
      }
    });
    
    // Start progress animation after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 4000));
    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      if (!onboardingCompleted) {
        context.go('/onboarding');
      } else {
        // Let GoRouter handle the navigation based on auth state
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? ModernDesignSystem.darkGradient
              : LinearGradient(
                  colors: [
                    ModernDesignSystem.lightBackground,
                    ModernDesignSystem.lightBackground.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Section
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Transform.rotate(
                              angle: _logoRotationAnimation.value * 0.1,
                              child: _buildLogo(isDark),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: ModernDesignSystem.spacingXL),
                      
                      // App Name
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textFadeAnimation.value,
                            child: _buildAppName(isDark),
                          );
                        },
                      ),
                      
                      SizedBox(height: ModernDesignSystem.spacingM),
                      
                      // Tagline
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textFadeAnimation.value,
                            child: _buildTagline(isDark),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Progress Section
              Padding(
                padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
                child: Column(
                  children: [
                    // Progress Bar
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: isDark 
                              ? ModernDesignSystem.darkBorder
                              : ModernDesignSystem.lightBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ModernDesignSystem.primaryGreen,
                          ),
                          minHeight: 4,
                        );
                      },
                    ),
                    
                    SizedBox(height: ModernDesignSystem.spacingM),
                    
                    // Loading Text
                    Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        color: isDark 
                            ? ModernDesignSystem.textOnDark.withValues(alpha: 0.7)
                            : ModernDesignSystem.textSecondary,
                        fontSize: ModernDesignSystem.fontSizeS,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/logos/app_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            return Container(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              child: const Center(
                child: Icon(Icons.music_note, size: 60, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppName(bool isDark) {
    return ShaderMask(
      shaderCallback: (bounds) => ModernDesignSystem.primaryGradient.createShader(bounds),
      child: Text(
        'Tuniverse',
        style: TextStyle(
          fontSize: ModernDesignSystem.fontSizeXXXL,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -1.0,
        ),
      ),
    );
  }

  Widget _buildTagline(bool isDark) {
    return Text(
      'Müzik deneyiminizi keşfedin',
      style: TextStyle(
        fontSize: ModernDesignSystem.fontSizeL,
        fontWeight: FontWeight.w500,
        color: isDark 
            ? ModernDesignSystem.textOnDark.withValues(alpha: 0.8)
            : ModernDesignSystem.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

// Alternative Splash with Particles
class ParticleSplashPage extends ConsumerStatefulWidget {
  const ParticleSplashPage({super.key});

  @override
  ConsumerState<ParticleSplashPage> createState() => _ParticleSplashPageState();
}

class _ParticleSplashPageState extends ConsumerState<ParticleSplashPage>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late List<AnimationController> _particleControllers;
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();
    _initializeParticleAnimations();
    _startAnimations();
  }

  void _initializeParticleAnimations() {
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _particleControllers = List.generate(
      _particleCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 2000 + (index * 100)),
        vsync: this,
      ),
    );
  }

  void _startAnimations() {
    _particleController.repeat();
    for (var controller in _particleControllers) {
      controller.repeat();
    }
    
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        // Let GoRouter handle the navigation based on auth state
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? ModernDesignSystem.darkGradient
              : LinearGradient(
                  colors: [
                    ModernDesignSystem.lightBackground,
                    ModernDesignSystem.lightBackground.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: Stack(
          children: [
            // Particles
            ...List.generate(_particleCount, (index) {
              return AnimatedBuilder(
                animation: _particleControllers[index],
                builder: (context, child) {
                  final animation = _particleControllers[index];
                  final offset = Offset(
                    (index * 50.0) % MediaQuery.of(context).size.width,
                    (animation.value * MediaQuery.of(context).size.height),
                  );
                  
                  return Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    child: Opacity(
                      opacity: 1.0 - animation.value,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            
            // Main Content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EnhancedAnimations.bounceIn(
                      child: _buildLogo(isDark),
                    ),
                    SizedBox(height: ModernDesignSystem.spacingXL),
                    EnhancedAnimations.fadeIn(
                      child: _buildAppName(isDark),
                    ),
                    SizedBox(height: ModernDesignSystem.spacingM),
                    EnhancedAnimations.fadeIn(
                      child: _buildTagline(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: ModernDesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXXL),
        boxShadow: [
          BoxShadow(
            color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.music_note,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAppName(bool isDark) {
    return ShaderMask(
      shaderCallback: (bounds) => ModernDesignSystem.primaryGradient.createShader(bounds),
      child: Text(
        'MusicShare',
        style: TextStyle(
          fontSize: ModernDesignSystem.fontSizeXXXL,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -1.0,
        ),
      ),
    );
  }

  Widget _buildTagline(bool isDark) {
    return Text(
      'Müzik deneyiminizi keşfedin',
      style: TextStyle(
        fontSize: ModernDesignSystem.fontSizeL,
        fontWeight: FontWeight.w500,
        color: isDark 
            ? ModernDesignSystem.textOnDark.withValues(alpha: 0.8)
            : ModernDesignSystem.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
*/
