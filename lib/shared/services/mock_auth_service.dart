import 'package:flutter/foundation.dart';

import '../../core/utils/result.dart';

class MockAuthService {
  // Mock user data storage
  static final Map<String, Map<String, String>> _mockUsers = {};
  
  // Mock current user
  static String? _currentUserId;

  // Mock sign up - sadece local storage
  static Future<Result<String>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      if (kDebugMode) {
        print('MockAuthService: Starting mock sign up for $email');
      }

      // Check if email already exists
      if (_mockUsers.containsKey(email)) {
        if (kDebugMode) {
          print('MockAuthService: Email already exists');
        }
        return Result.failure('Bu e-posta adresi zaten kayıtlı');
      }

      // Check if username already exists
      for (var user in _mockUsers.values) {
        if (user['username'] == username.toLowerCase()) {
          if (kDebugMode) {
            print('MockAuthService: Username already exists');
          }
          return Result.failure('Bu kullanıcı adı zaten alınmış');
        }
      }

      // Create mock user
      final userId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
      _mockUsers[email] = {
        'userId': userId,
        'email': email,
        'username': username.toLowerCase(),
        'displayName': displayName,
        'password': password, // In real app, this should be hashed
      };

      if (kDebugMode) {
        print('MockAuthService: Mock user created successfully: $userId');
        print('MockAuthService: Total users: ${_mockUsers.length}');
      }

      return Result.success(userId);
    } catch (e) {
      if (kDebugMode) {
        print('MockAuthService: Unexpected error in signUp: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Mock sign in - sadece local storage
  static Future<Result<String>> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('MockAuthService: Starting mock sign in for $emailOrUsername');
      }

      String? email = emailOrUsername;
      
      // Check if input is username (not email format)
      if (!emailOrUsername.contains('@')) {
        // Find user by username
        for (var entry in _mockUsers.entries) {
          if (entry.value['username'] == emailOrUsername.toLowerCase()) {
            email = entry.key;
            break;
          }
        }
        
        if (email == null) {
          if (kDebugMode) {
            print('MockAuthService: Username not found');
          }
          return Result.failure('Kullanıcı bulunamadı');
        }
      }

      // Check if user exists and password matches
      if (!_mockUsers.containsKey(email)) {
        if (kDebugMode) {
          print('MockAuthService: Email not found');
        }
        return Result.failure('Kullanıcı bulunamadı');
      }

      final user = _mockUsers[email]!;
      if (user['password'] != password) {
        if (kDebugMode) {
          print('MockAuthService: Wrong password');
        }
        return Result.failure('Yanlış şifre');
      }

      _currentUserId = user['userId'];
      
      if (kDebugMode) {
        print('MockAuthService: Mock sign in successful: ${user['userId']}');
      }

      return Result.success(user['userId']!);
    } catch (e) {
      if (kDebugMode) {
        print('MockAuthService: Unexpected error in signIn: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Mock password reset
  static Future<Result<void>> resetPassword(String email) async {
    try {
      if (kDebugMode) {
        print('MockAuthService: Starting mock password reset for $email');
      }

      if (!_mockUsers.containsKey(email)) {
        if (kDebugMode) {
          print('MockAuthService: Email not found for password reset');
        }
        return Result.failure('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı');
      }

      if (kDebugMode) {
        print('MockAuthService: Mock password reset email sent to $email');
      }
      
      return Result.success(null);
    } catch (e) {
      if (kDebugMode) {
        print('MockAuthService: Unexpected error in resetPassword: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Mock sign out
  static Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('MockAuthService: Mock signing out');
      }
      _currentUserId = null;
      if (kDebugMode) {
        print('MockAuthService: Mock sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MockAuthService: Mock sign out error: $e');
      }
    }
  }

  // Get current user
  static String? get currentUserId => _currentUserId;

  // Check if user is signed in
  static bool get isSignedIn => _currentUserId != null;

  // Get user data
  static Map<String, String>? getCurrentUserData() {
    if (_currentUserId == null) return null;
    
    for (var user in _mockUsers.values) {
      if (user['userId'] == _currentUserId) {
        return user;
      }
    }
    return null;
  }

  // Mock auth state changes stream
  static Stream<String?> get authStateChanges async* {
    yield _currentUserId;
  }

  // Debug: Get all users (for testing)
  static Map<String, Map<String, String>> get allUsers => Map.unmodifiable(_mockUsers);

  // Debug: Clear all users (for testing)
  static void clearAllUsers() {
    _mockUsers.clear();
    _currentUserId = null;
    if (kDebugMode) {
      print('MockAuthService: All users cleared');
    }
  }
}
