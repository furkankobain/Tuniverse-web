import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static void handleError(String error, BuildContext context) {
    _showErrorSnackBar(context, error);
    
    if (kDebugMode) {
      // print( // Debug log removed'Error: $error');
    }
  }
  
  static void handleException(Exception exception, BuildContext context) {
    final message = _getExceptionMessage(exception);
    _showErrorSnackBar(context, message);
    
    if (kDebugMode) {
      // print( // Debug log removed'Exception: $exception');
    }
  }
  
  static String _getExceptionMessage(Exception exception) {
    if (exception is FirebaseAuthException) {
      return _mapFirebaseAuthException(exception);
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
  
  static String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
  
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
