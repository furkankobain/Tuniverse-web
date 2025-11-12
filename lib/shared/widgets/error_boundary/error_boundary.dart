import 'package:flutter/material.dart';
import '../../services/crashlytics_service.dart';

/// Error boundary widget
/// Widget hatalarını yakalar ve güzel error UI gösterir
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    
    // Widget error handler'ı override et
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // Crashlytics'e gönder
      CrashlyticsService.logError(
        details.exception,
        details.stack,
        reason: 'Widget error caught by ErrorBoundary',
        fatal: false,
      );
      
      // State'i güncelle
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }
      
      // Orijinal handler'ı da çağır
      originalOnError?.call(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.errorBuilder?.call(_errorDetails!) ?? 
          _buildDefaultErrorWidget(context);
    }
    
    return widget.child;
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Error title
                Text(
                  'Bir şeyler ters gitti',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Error message
                Text(
                  'Üzgünüz, beklenmeyen bir hata oluştu. Sorun otomatik olarak bildirildi.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reload button
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorDetails = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5E5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Go home button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Ana Sayfa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5E5E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        side: const BorderSide(
                          color: Color(0xFFFF5E5E),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Debug info (only in debug mode)
                if (_errorDetails != null && const bool.fromEnvironment('dart.vm.product') == false) ...[
                  const SizedBox(height: 32),
                  ExpansionTile(
                    title: const Text(
                      'Teknik Detaylar',
                      style: TextStyle(fontSize: 12),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorDetails!.exceptionAsString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
