import 'package:flutter/material.dart';
import 'dart:async';

/// Custom exception types
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => message;
}

class OfflineException implements Exception {
  final String message = 'İnternet bağlantınızı kontrol edin';
  
  @override
  String toString() => message;
}

/// Error handler service
class ErrorHandlerService {
  static String getErrorMessage(dynamic exception) {
    if (exception is NetworkException) {
      return 'Bağlantı hatası: ${exception.message}';
    } else if (exception is AuthException) {
      return 'Kimlik doğrulama hatası: ${exception.message}';
    } else if (exception is ApiException) {
      return _getApiErrorMessage(exception);
    } else if (exception is ValidationException) {
      return exception.message;
    } else if (exception is OfflineException) {
      return exception.message;
    } else if (exception is FormatException) {
      return 'Veri formatı hatası';
    } else if (exception is TimeoutException) {
      return 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';
    } else {
      return 'Bilinmeyen bir hata oluştu';
    }
  }

  static String _getApiErrorMessage(ApiException exception) {
    switch (exception.statusCode) {
      case 400:
        return 'Geçersiz istek: ${exception.message}';
      case 401:
        return 'Oturum süresi doldu. Lütfen giriş yapın.';
      case 403:
        return 'Bu işleme izniniz yok';
      case 404:
        return 'İstenen veriler bulunamadı';
      case 429:
        return 'Çok fazla istek gönderdiniz. Lütfen biraz bekleyin.';
      case 500:
        return 'Sunucu hatası. Lütfen daha sonra deneyin.';
      case 502:
      case 503:
      case 504:
        return 'Sunucu şu anda hizmet veremiyor. Lütfen daha sonra deneyin.';
      default:
        return 'İstek başarısız: ${exception.message}';
    }
  }

  static Future<void> showErrorSnackbar(
    BuildContext context,
    dynamic exception, {
    bool showRetryButton = true,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) async {
    final message = getErrorMessage(exception);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.red.shade600,
        action: showRetryButton && onRetry != null
            ? SnackBarAction(
                label: 'Tekrar Dene',
                onPressed: onRetry,
                textColor: Colors.white,
              )
            : null,
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic exception, {
    VoidCallback? onRetry,
  }) async {
    final message = getErrorMessage(exception);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Tekrar Dene'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

/// Utility extension for error handling
extension ErrorExtension on Object {
  String toErrorString() {
    return ErrorHandlerService.getErrorMessage(this);
  }
}