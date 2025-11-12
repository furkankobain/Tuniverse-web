import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/theme/modern_design_system.dart';
import '../../../core/validators/auth_validators.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../shared/services/firebase_service.dart';
import '../../widgets/animations/enhanced_animations.dart';

class EnhancedPasswordField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool showStrengthIndicator;
  final VoidCallback? onChanged;

  const EnhancedPasswordField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.showStrengthIndicator = false,
    this.onChanged,
  });

  @override
  ConsumerState<EnhancedPasswordField> createState() => _EnhancedPasswordFieldState();
}

class _EnhancedPasswordFieldState extends ConsumerState<EnhancedPasswordField> {
  bool _obscureText = true;
  PasswordStrength _strength = PasswordStrength.veryWeak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          validator: widget.validator ?? ValidationUtils.validatePassword,
          onChanged: (value) {
            if (widget.showStrengthIndicator) {
              setState(() {
                _strength = AuthValidators.checkPasswordStrength(value);
              });
            }
            widget.onChanged?.call();
          },
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'Şifre',
            hintText: widget.hintText ?? 'Şifrenizi giriniz',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
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
        
        if (widget.showStrengthIndicator && widget.controller.text.isNotEmpty) ...[
          SizedBox(height: ModernDesignSystem.spacingS),
          _buildPasswordStrengthIndicator(),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color strengthColor;
    switch (_strength) {
      case PasswordStrength.veryWeak:
        strengthColor = ModernDesignSystem.error;
        break;
      case PasswordStrength.weak:
        strengthColor = ModernDesignSystem.warning;
        break;
      case PasswordStrength.medium:
        strengthColor = Colors.orange;
        break;
      case PasswordStrength.strong:
        strengthColor = Colors.lightBlue;
        break;
      case PasswordStrength.veryStrong:
        strengthColor = ModernDesignSystem.success;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Şifre Gücü',
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeS,
                color: isDark 
                    ? ModernDesignSystem.textOnDark.withValues(alpha: 0.7)
                    : ModernDesignSystem.textSecondary,
              ),
            ),
            Text(
              _strength.displayName,
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeS,
                fontWeight: FontWeight.w600,
                color: strengthColor,
              ),
            ),
          ],
        ),
        SizedBox(height: ModernDesignSystem.spacingXS),
        LinearProgressIndicator(
          value: _strength.progress,
          backgroundColor: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          minHeight: 4,
        ),
      ],
    );
  }
}

class EnhancedEmailField extends ConsumerWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool checkAvailability;

  const EnhancedEmailField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.checkAvailability = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: validator ?? AuthValidators.validateEmail,
      decoration: InputDecoration(
        labelText: labelText ?? 'E-posta',
        hintText: hintText ?? 'ornek@email.com',
        prefixIcon: const Icon(Icons.email_outlined),
        suffixIcon: checkAvailability ? const Icon(Icons.check_circle_outline) : null,
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
    );
  }
}

class EnhancedUsernameField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool checkAvailability;

  const EnhancedUsernameField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.checkAvailability = false,
  });

  @override
  ConsumerState<EnhancedUsernameField> createState() => _EnhancedUsernameFieldState();
}

class _EnhancedUsernameFieldState extends ConsumerState<EnhancedUsernameField> {
  bool _isChecking = false;
  bool _isAvailable = false;
  Timer? _debounce;
  String? _validationError;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          textInputAction: TextInputAction.next,
          validator: (value) {
            // First check basic validation
            final basicError = widget.validator ?? ValidationUtils.validateUsername;
            final error = basicError(value);
            if (error != null) return error;
            
            // Then check availability if enabled
            if (widget.checkAvailability && !_isAvailable && value != null && value.isNotEmpty) {
              return 'This username is already taken';
            }
            
            return null;
          },
          onChanged: widget.checkAvailability ? _checkUsernameAvailability : null,
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Kullanıcı Adı',
        hintText: widget.hintText ?? 'kullanici_adi',
        prefixIcon: const Icon(Icons.person_outline),
        suffixIcon: widget.checkAvailability ? _buildSuffixIcon() : null,
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
    if (_validationError != null) ...[
      const SizedBox(height: 4),
      Text(
        _validationError!,
        style: TextStyle(
          fontSize: 12,
          color: ModernDesignSystem.error,
        ),
      ),
    ],
  ],
);
  }

  Widget _buildSuffixIcon() {
    if (_isChecking) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    if (widget.controller.text.isEmpty) {
      return const Icon(Icons.info_outline);
    }
    
    return Icon(
      _isAvailable ? Icons.check_circle : Icons.cancel,
      color: _isAvailable ? ModernDesignSystem.success : ModernDesignSystem.error,
    );
  }

  void _checkUsernameAvailability(String username) async {
    // Cancel previous timer
    _debounce?.cancel();
    
    if (username.isEmpty) {
      setState(() {
        _isAvailable = false;
        _isChecking = false;
        _validationError = null;
      });
      return;
    }
    
    // Check basic validation first
    final basicError = ValidationUtils.validateUsername(username);
    if (basicError != null) {
      setState(() {
        _isAvailable = false;
        _isChecking = false;
        _validationError = basicError;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _validationError = null;
    });

    // Debounce: wait 500ms before checking
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final isAvailable = await FirebaseService.isUsernameAvailable(username);
        
        if (mounted) {
          setState(() {
            _isAvailable = isAvailable;
            _isChecking = false;
            _validationError = isAvailable ? null : 'Username is already taken';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isAvailable = false;
            _isChecking = false;
            _validationError = 'Error checking username';
          });
        }
      }
    });
  }
}

class SocialLoginButton extends ConsumerWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget button = Container(
      width: double.infinity,
      height: ModernDesignSystem.buttonHeightL,
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
        border: Border.all(
          color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
        ),
        boxShadow: ModernDesignSystem.subtleShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: ModernDesignSystem.iconM,
                    height: ModernDesignSystem.iconM,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Icon(
                    icon,
                    color: color,
                    size: ModernDesignSystem.iconM,
                  ),
                SizedBox(width: ModernDesignSystem.spacingM),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: ModernDesignSystem.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: isDark ? ModernDesignSystem.textOnDark : ModernDesignSystem.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isLoading) {
      button = EnhancedAnimations.hover(child: button);
    }

    return button;
  }
}

class AuthDivider extends ConsumerWidget {
  final String text;

  const AuthDivider({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingM),
          child: Text(
            text,
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeS,
              color: isDark 
                  ? ModernDesignSystem.textOnDark.withValues(alpha: 0.6)
                  : ModernDesignSystem.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
          ),
        ),
      ],
    );
  }
}

class PasswordRequirements extends ConsumerWidget {
  final String password;

  const PasswordRequirements({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final requirements = [
      _Requirement('En az 8 karakter', password.length >= 8),
      _Requirement('Büyük harf', password.contains(RegExp(r'[A-Z]'))),
      _Requirement('Küçük harf', password.contains(RegExp(r'[a-z]'))),
      _Requirement('Rakam', password.contains(RegExp(r'[0-9]'))),
      _Requirement('Özel karakter', password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
    ];

    return Container(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
        border: Border.all(
          color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Şifre Gereksinimleri',
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeS,
              fontWeight: FontWeight.w600,
              color: isDark ? ModernDesignSystem.textOnDark : ModernDesignSystem.textPrimary,
            ),
          ),
          SizedBox(height: ModernDesignSystem.spacingS),
          ...requirements.map((req) => _buildRequirementItem(req, isDark)),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(_Requirement requirement, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            requirement.isMet ? Icons.check_circle : Icons.circle_outlined,
            size: ModernDesignSystem.iconS,
            color: requirement.isMet 
                ? ModernDesignSystem.success 
                : isDark 
                    ? ModernDesignSystem.textOnDark.withValues(alpha: 0.4)
                    : ModernDesignSystem.textTertiary,
          ),
          SizedBox(width: ModernDesignSystem.spacingS),
          Text(
            requirement.text,
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeXS,
              color: requirement.isMet 
                  ? ModernDesignSystem.success 
                  : isDark 
                      ? ModernDesignSystem.textOnDark.withValues(alpha: 0.7)
                      : ModernDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Requirement {
  final String text;
  final bool isMet;

  _Requirement(this.text, this.isMet);
}
