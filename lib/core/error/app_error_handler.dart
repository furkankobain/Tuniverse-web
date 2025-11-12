import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';

/// App Error Handler
/// Centralized error handling with user-friendly messages
class AppErrorHandler {
  /// Handle error and show appropriate message
  static void handleError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    final errorInfo = _parseError(error);

    if (showSnackbar) {
      _showErrorSnackbar(
        context,
        title: errorInfo.title,
        message: errorInfo.message,
        icon: errorInfo.icon,
        onRetry: onRetry,
      );
    }

    debugPrint('❌ Error: ${errorInfo.technicalMessage}');
  }

  /// Show error dialog with details
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) async {
    final errorInfo = _parseError(error);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(errorInfo.icon, color: Colors.red),
            const SizedBox(width: 8),
            Text(errorInfo.title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorInfo.message),
            if (errorInfo.suggestion != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, 
                      color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorInfo.suggestion!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
        ],
      ),
    );
  }

  /// Parse error and return user-friendly info
  static ErrorInfo _parseError(dynamic error) {
    // Network errors
    if (error is SocketException) {
      return ErrorInfo(
        title: 'Bağlantı Hatası',
        message: 'İnternet bağlantınızı kontrol edin.',
        icon: Icons.wifi_off,
        type: ErrorType.network,
        suggestion: 'Wi-Fi veya mobil verinizin açık olduğundan emin olun.',
        technicalMessage: error.toString(),
      );
    }

    // Dio errors (HTTP)
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ErrorInfo(
            title: 'Zaman Aşımı',
            message: 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.',
            icon: Icons.access_time,
            type: ErrorType.timeout,
            suggestion: 'İnternet bağlantınız yavaş olabilir.',
            technicalMessage: error.toString(),
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return _parseHttpError(statusCode, error);

        case DioExceptionType.cancel:
          return ErrorInfo(
            title: 'İptal Edildi',
            message: 'İstek iptal edildi.',
            icon: Icons.cancel,
            type: ErrorType.cancelled,
            technicalMessage: error.toString(),
          );

        case DioExceptionType.connectionError:
          return ErrorInfo(
            title: 'Bağlantı Hatası',
            message: 'Sunucuya bağlanılamadı.',
            icon: Icons.signal_wifi_off,
            type: ErrorType.network,
            suggestion: 'İnternet bağlantınızı kontrol edin.',
            technicalMessage: error.toString(),
          );

        default:
          return ErrorInfo(
            title: 'Beklenmeyen Hata',
            message: 'Bir şeyler yanlış gitti.',
            icon: Icons.error_outline,
            type: ErrorType.unknown,
            technicalMessage: error.toString(),
          );
      }
    }

    // Firebase errors
    if (error.toString().contains('firebase')) {
      return ErrorInfo(
        title: 'Sunucu Hatası',
        message: 'Firebase bağlantısında sorun oluştu.',
        icon: Icons.cloud_off,
        type: ErrorType.server,
        suggestion: 'Lütfen daha sonra tekrar deneyin.',
        technicalMessage: error.toString(),
      );
    }

    // Spotify API errors
    if (error.toString().toLowerCase().contains('spotify')) {
      return ErrorInfo(
        title: 'Spotify Hatası',
        message: 'Spotify API\'sine erişilemedi.',
        icon: Icons.music_off,
        type: ErrorType.api,
        suggestion: 'Spotify bağlantınızı kontrol edin.',
        technicalMessage: error.toString(),
      );
    }

    // Auth errors
    if (error.toString().toLowerCase().contains('auth') ||
        error.toString().toLowerCase().contains('permission')) {
      return ErrorInfo(
        title: 'Yetkilendirme Hatası',
        message: 'Bu işlem için yetkiniz yok.',
        icon: Icons.lock,
        type: ErrorType.auth,
        suggestion: 'Lütfen tekrar giriş yapın.',
        technicalMessage: error.toString(),
      );
    }

    // Generic error
    return ErrorInfo(
      title: 'Hata Oluştu',
      message: 'Beklenmeyen bir hata oluştu.',
      icon: Icons.error_outline,
      type: ErrorType.unknown,
      suggestion: 'Lütfen uygulamayı yeniden başlatın.',
      technicalMessage: error.toString(),
    );
  }

  /// Parse HTTP status code errors
  static ErrorInfo _parseHttpError(int? statusCode, DioException error) {
    switch (statusCode) {
      case 400:
        return ErrorInfo(
          title: 'Geçersiz İstek',
          message: 'Gönderilen veri geçersiz.',
          icon: Icons.warning,
          type: ErrorType.validation,
          technicalMessage: error.toString(),
        );

      case 401:
        return ErrorInfo(
          title: 'Oturum Süresi Doldu',
          message: 'Lütfen tekrar giriş yapın.',
          icon: Icons.lock_clock,
          type: ErrorType.auth,
          suggestion: 'Kimlik doğrulamanız geçersiz.',
          technicalMessage: error.toString(),
        );

      case 403:
        return ErrorInfo(
          title: 'Erişim Engellendi',
          message: 'Bu içeriğe erişim yetkiniz yok.',
          icon: Icons.block,
          type: ErrorType.forbidden,
          technicalMessage: error.toString(),
        );

      case 404:
        return ErrorInfo(
          title: 'Bulunamadı',
          message: 'Aradığınız içerik bulunamadı.',
          icon: Icons.search_off,
          type: ErrorType.notFound,
          technicalMessage: error.toString(),
        );

      case 429:
        return ErrorInfo(
          title: 'Çok Fazla İstek',
          message: 'Lütfen biraz bekleyin ve tekrar deneyin.',
          icon: Icons.speed,
          type: ErrorType.rateLimit,
          suggestion: 'API limit aşıldı. 1-2 dakika bekleyin.',
          technicalMessage: error.toString(),
        );

      case 500:
      case 502:
      case 503:
        return ErrorInfo(
          title: 'Sunucu Hatası',
          message: 'Sunucu geçici olarak kullanılamıyor.',
          icon: Icons.dns,
          type: ErrorType.server,
          suggestion: 'Lütfen daha sonra tekrar deneyin.',
          technicalMessage: error.toString(),
        );

      default:
        return ErrorInfo(
          title: 'HTTP Hatası',
          message: 'Sunucu hatası: ${statusCode ?? "Bilinmeyen"}',
          icon: Icons.error,
          type: ErrorType.server,
          technicalMessage: error.toString(),
        );
    }
  }

  /// Show error snackbar with retry option
  static void _showErrorSnackbar(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: onRetry != null
            ? SnackBarAction(
                label: 'TEKRAR DENE',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show warning message
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Error Information Model
class ErrorInfo {
  final String title;
  final String message;
  final IconData icon;
  final ErrorType type;
  final String? suggestion;
  final String technicalMessage;

  ErrorInfo({
    required this.title,
    required this.message,
    required this.icon,
    required this.type,
    this.suggestion,
    required this.technicalMessage,
  });
}

/// Error Types
enum ErrorType {
  network,
  timeout,
  server,
  api,
  auth,
  validation,
  notFound,
  forbidden,
  rateLimit,
  cancelled,
  unknown,
}
