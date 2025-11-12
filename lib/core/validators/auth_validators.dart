class AuthValidators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi giriniz';
    }
    
    return null;
  }

  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kullanıcı adı gerekli';
    }
    
    if (value.length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalı';
    }
    
    if (value.length > 20) {
      return 'Kullanıcı adı en fazla 20 karakter olmalı';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Kullanıcı adı sadece harf, rakam ve _ içerebilir';
    }
    
    // Check for reserved words
    final reservedWords = ['admin', 'root', 'support', 'help', 'info', 'test', 'user', 'guest'];
    if (reservedWords.contains(value.toLowerCase())) {
      return 'Bu kullanıcı adı kullanılamaz';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    
    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalı';
    }
    
    if (value.length > 128) {
      return 'Şifre en fazla 128 karakter olmalı';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Şifre en az bir büyük harf içermeli';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Şifre en az bir küçük harf içermeli';
    }
    
    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Şifre en az bir rakam içermeli';
    }
    
    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Şifre en az bir özel karakter içermeli (!@#\$%^&* vb.)';
    }
    
    // Check for common passwords
    final commonPasswords = <String>[
      'password', '123456', 'password123', 'admin', 'qwerty',
      'letmein', 'welcome', 'monkey', '1234567890', 'password1',
      'şifre', '12345678', 'abc123', 'Password1', 'password12'
    ];
    
    if (commonPasswords.contains(value.toLowerCase())) {
      return 'Bu şifre çok yaygın kullanılıyor, lütfen daha güvenli bir şifre seçin';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }
    
    if (value != password) {
      return 'Şifreler eşleşmiyor';
    }
    
    return null;
  }

  // Display name validation
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Görünen ad gerekli';
    }
    
    if (value.length < 2) {
      return 'Görünen ad en az 2 karakter olmalı';
    }
    
    if (value.length > 50) {
      return 'Görünen ad en fazla 50 karakter olmalı';
    }
    
    // Check for inappropriate content (basic check)
    final inappropriateWords = ['admin', 'root', 'support'];
    if (inappropriateWords.contains(value.toLowerCase())) {
      return 'Bu ad kullanılamaz';
    }
    
    return null;
  }

  // Phone number validation (if needed)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', '').replaceAll('-', ''))) {
      return 'Geçerli bir telefon numarası giriniz';
    }
    
    return null;
  }

  // Real-time password strength checker
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;
    List<String> feedback = [];

    // Length check
    if (password.length >= 8) {
      score += 1;
    } else {
      feedback.add('En az 8 karakter');
    }

    if (password.length >= 12) {
      score += 1;
    }

    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    } else {
      feedback.add('Küçük harf ekle');
    }

    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    } else {
      feedback.add('Büyük harf ekle');
    }

    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    } else {
      feedback.add('Rakam ekle');
    }

    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      score += 1;
    } else {
      feedback.add('Özel karakter ekle');
    }

    // Pattern checks
    if (!password.contains(RegExp(r'(.)\1{2,}'))) {
      score += 1; // No repeated chars
    } else {
      feedback.add('Tekrarlayan karakterlerden kaçın');
    }

    if (!RegExp(r'(012|123|234|345|456|567|678|789|890)').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Ardışık sayılardan kaçın');
    }

    // Determine strength
    if (score >= 7) return PasswordStrength.veryStrong;
    if (score >= 5) return PasswordStrength.strong;
    if (score >= 3) return PasswordStrength.medium;
    if (score >= 1) return PasswordStrength.weak;
    return PasswordStrength.veryWeak;
  }

  // Validate login credentials
  static String? validateLoginEmail(String? value) {
    return validateEmail(value);
  }

  static String? validateLoginUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kullanıcı adı veya e-posta gerekli';
    }
    return null;
  }

  // Validate login password
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    return null;
  }
}

enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get displayName {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 'Çok Zayıf';
      case PasswordStrength.weak:
        return 'Zayıf';
      case PasswordStrength.medium:
        return 'Orta';
      case PasswordStrength.strong:
        return 'Güçlü';
      case PasswordStrength.veryStrong:
        return 'Çok Güçlü';
    }
  }

  double get progress {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 0.2;
      case PasswordStrength.weak:
        return 0.4;
      case PasswordStrength.medium:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
}
