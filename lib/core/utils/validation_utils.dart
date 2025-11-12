class ValidationUtils {
  /// Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final username = value.trim();

    // Length check
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.length > 20) {
      return 'Username must be at most 20 characters';
    }

    // Character check: only alphanumeric, underscore, and dot
    final validChars = RegExp(r'^[a-zA-Z0-9_.]+$');
    if (!validChars.hasMatch(username)) {
      return 'Username can only contain letters, numbers, _ and .';
    }

    // No spaces
    if (username.contains(' ')) {
      return 'Username cannot contain spaces';
    }

    // No leading/trailing dots
    if (username.startsWith('.') || username.endsWith('.')) {
      return 'Username cannot start or end with a dot';
    }

    // No consecutive dots
    if (username.contains('..')) {
      return 'Username cannot contain consecutive dots';
    }

    return null; // Valid
  }

  /// Password validation with strength requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // Minimum length
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Maximum length for security
    if (value.length > 128) {
      return 'Password is too long (max 128 characters)';
    }

    // At least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // At least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // At least one number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Optional: At least one special character (recommended but not required)
    // Uncomment below to make special characters required
    // if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    //   return 'Password must contain at least one special character';
    // }

    return null; // Valid
  }

  /// Calculate password strength (0-4)
  /// 0: Very Weak, 1: Weak, 2: Fair, 3: Good, 4: Strong
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length bonus
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    // Cap at 4
    return strength > 4 ? 4 : strength;
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }

  /// Confirm password validation
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null; // Valid
  }

  /// Display name validation
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }

    final name = value.trim();

    if (name.length < 2) {
      return 'Display name must be at least 2 characters';
    }

    if (name.length > 50) {
      return 'Display name must be at most 50 characters';
    }

    return null; // Valid
  }

  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    // Basic email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }
}
