import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../../core/utils/result.dart';

class FirebaseBypassAuthService {
  static const String _usersKey = 'firebase_bypass_users';
  static const String _currentUserKey = 'firebase_bypass_current_user';
  
  // In-memory user storage
  static Map<String, UserData> _users = {};
  static UserData? _currentUser;

  // Initialize the service
  static Future<void> initialize() async {
    try {
      // Debug print'i kaldır - performans için
      
      // Load users from SharedPreferences
      await _loadUsers();
      
      // Debug print'i kaldır - performans için
    } catch (e) {
      // Debug print'i kaldır - performans için
    }
  }

  // Load users from SharedPreferences
  static Future<void> _loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson != null) {
        final Map<String, dynamic> usersMap = json.decode(usersJson);
        _users = usersMap.map((key, value) => MapEntry(key, UserData.fromJson(value)));
      }
      
      // Load current user
      final currentUserJson = prefs.getString(_currentUserKey);
      if (currentUserJson != null) {
        final userData = json.decode(currentUserJson);
        _currentUser = UserData.fromJson(userData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Error loading users: $e');
      }
    }
  }

  // Save users to SharedPreferences
  static Future<void> _saveUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = json.encode(_users.map((key, value) => MapEntry(key, value.toJson())));
      await prefs.setString(_usersKey, usersJson);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Error saving users: $e');
      }
    }
  }

  // Save current user
  static Future<void> _saveCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        await prefs.setString(_currentUserKey, json.encode(_currentUser!.toJson()));
      } else {
        await prefs.remove(_currentUserKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Error saving current user: $e');
      }
    }
  }

  // Sign up with email and password
  static Future<Result<String>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Starting sign up for $email');
      }

      // Check if email already exists
      if (_users.containsKey(email)) {
        if (kDebugMode) {
          print('FirebaseBypassAuthService: Email already exists');
        }
        return Result.failure('Bu e-posta adresi zaten kayıtlı');
      }

      // Check if username already exists
      for (var user in _users.values) {
        if (user.username == username.toLowerCase()) {
          if (kDebugMode) {
            print('FirebaseBypassAuthService: Username already exists');
          }
          return Result.failure('Bu kullanıcı adı zaten alınmış');
        }
      }

      // Create new user
      final userId = 'bypass_${DateTime.now().millisecondsSinceEpoch}';
      final userData = UserData(
        userId: userId,
        email: email,
        username: username.toLowerCase(),
        displayName: displayName,
        password: password, // In real app, this should be hashed
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _users[email] = userData;
      await _saveUsers();

      // Set current user to automatically log in after signup
      _currentUser = userData;
      await _saveCurrentUser();

      // **NEW: Save user to Firestore for search functionality**
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'userId': userId,
          'email': email,
          'username': username.toLowerCase(),
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'photoURL': null,
          'bio': null,
          'playlistCount': 0,
          'reviewCount': 0,
          'followersCount': 0,
          'followingCount': 0,
        });
        
        if (kDebugMode) {
          print('FirebaseBypassAuthService: User saved to Firestore');
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          print('FirebaseBypassAuthService: Firestore save error (non-critical): $firestoreError');
        }
      }

      if (kDebugMode) {
        print('FirebaseBypassAuthService: User created and logged in successfully: $userId');
      }

      return Result.success(userId);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Unexpected error in signUp: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Sign in with email or username
  static Future<Result<String>> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Starting sign in for $emailOrUsername');
      }

      String? email = emailOrUsername;
      
      // Check if input is username (not email format)
      if (!emailOrUsername.contains('@')) {
        // Find user by username
        for (var entry in _users.entries) {
          if (entry.value.username == emailOrUsername.toLowerCase()) {
            email = entry.key;
            break;
          }
        }
        
        if (email == null) {
          if (kDebugMode) {
            print('FirebaseBypassAuthService: Username not found');
          }
          return Result.failure('Kullanıcı bulunamadı');
        }
      }

      // Check if user exists and password matches
      if (!_users.containsKey(email)) {
        if (kDebugMode) {
          print('FirebaseBypassAuthService: Email not found');
        }
        return Result.failure('Kullanıcı bulunamadı');
      }

      final user = _users[email]!;
      if (user.password != password) {
        if (kDebugMode) {
          print('FirebaseBypassAuthService: Wrong password');
        }
        return Result.failure('Yanlış şifre');
      }

      // Update last login time
      user.lastLoginAt = DateTime.now();
      await _saveUsers();

      // Set current user
      _currentUser = user;
      await _saveCurrentUser();

      if (kDebugMode) {
        print('FirebaseBypassAuthService: Sign in successful: ${user.userId}');
      }

      return Result.success(user.userId);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Unexpected error in signIn: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Password reset (mock)
  static Future<Result<void>> resetPassword(String email) async {
    try {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Starting password reset for $email');
      }

      if (!_users.containsKey(email)) {
        if (kDebugMode) {
          print('FirebaseBypassAuthService: Email not found for password reset');
        }
        return Result.failure('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı');
      }

      if (kDebugMode) {
        print('FirebaseBypassAuthService: Password reset email sent to $email');
      }
      
      return Result.success(null);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Unexpected error in resetPassword: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Send email verification (mock)
  static Future<Result<void>> sendEmailVerification() async {
    try {
      if (_currentUser == null) {
        return Result.failure('Kullanıcı oturum açmamış');
      }

      if (_currentUser!.isEmailVerified) {
        return Result.failure('E-posta adresi zaten doğrulanmış');
      }

      // Generate verification code (in real app, this would be sent via email)
      final verificationCode = _generateVerificationCode();
      _currentUser!.emailVerificationCode = verificationCode;
      
      await _saveUsers();
      await _saveCurrentUser();

      if (kDebugMode) {
        print('FirebaseBypassAuthService: Email verification sent to ${_currentUser!.email}');
        print('FirebaseBypassAuthService: Verification code: $verificationCode');
      }
      
      return Result.success(null);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Unexpected error in sendEmailVerification: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Verify email with code
  static Future<Result<void>> verifyEmail(String verificationCode) async {
    try {
      if (_currentUser == null) {
        return Result.failure('Kullanıcı oturum açmamış');
      }

      if (_currentUser!.isEmailVerified) {
        return Result.failure('E-posta adresi zaten doğrulanmış');
      }

      if (_currentUser!.emailVerificationCode != verificationCode) {
        return Result.failure('Doğrulama kodu yanlış');
      }

      // Mark email as verified
      _currentUser!.isEmailVerified = true;
      _currentUser!.emailVerificationCode = null;
      
      await _saveUsers();
      await _saveCurrentUser();

      if (kDebugMode) {
        print('FirebaseBypassAuthService: Email verified successfully for ${_currentUser!.email}');
      }
      
      return Result.success(null);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Unexpected error in verifyEmail: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Generate verification code
  static String _generateVerificationCode() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.substring(random.length - 6);
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Signing out');
      }
      
      _currentUser = null;
      await _saveCurrentUser();
      
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseBypassAuthService: Sign out error: $e');
      }
    }
  }

  // Get current user
  static UserData? get currentUser => _currentUser;

  // Check if user is signed in
  static bool get isSignedIn => _currentUser != null;

  // Get current user ID
  static String? get currentUserId => _currentUser?.userId;

  // Stream of auth state changes (mock)
  static Stream<UserData?> get authStateChanges async* {
    yield _currentUser;
  }

  // Debug: Get all users
  static Map<String, UserData> get allUsers => Map.unmodifiable(_users);

  // Debug: Clear all users
  static Future<void> clearAllUsers() async {
    _users.clear();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove(_currentUserKey);
    if (kDebugMode) {
      print('FirebaseBypassAuthService: All users cleared');
    }
  }
}

// User data model
class UserData {
  final String userId;
  final String email;
  final String username;
  final String displayName;
  final String password; // In real app, this should be hashed
  final DateTime createdAt;
  DateTime lastLoginAt;
  bool isEmailVerified;
  String? emailVerificationCode;

  UserData({
    required this.userId,
    required this.email,
    required this.username,
    required this.displayName,
    required this.password,
    required this.createdAt,
    required this.lastLoginAt,
    this.isEmailVerified = false,
    this.emailVerificationCode,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['userId'],
      email: json['email'],
      username: json['username'],
      displayName: json['displayName'],
      password: json['password'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      emailVerificationCode: json['emailVerificationCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'username': username,
      'displayName': displayName,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'emailVerificationCode': emailVerificationCode,
    };
  }
}
