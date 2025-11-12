import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/modern_design_system.dart';
import '../../../shared/widgets/animations/enhanced_animations.dart';
import '../../../shared/widgets/ui/enhanced_components.dart';
import '../../../shared/services/app_rating_service.dart';

class AppRatingDialog extends ConsumerStatefulWidget {
  final bool isManual;

  const AppRatingDialog({
    super.key,
    this.isManual = false,
  });

  @override
  ConsumerState<AppRatingDialog> createState() => _AppRatingDialogState();
}

class _AppRatingDialogState extends ConsumerState<AppRatingDialog> {
  int _selectedRating = 0;
  bool _isLoading = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            EnhancedAnimations.fadeIn(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: ModernDesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: ModernDesignSystem.spacingL),
                  Text(
                    'MüzikBoxd\'ı Değerlendirin',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ModernDesignSystem.spacingS),
                  Text(
                    'Görüşleriniz bizim için çok değerli',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ModernDesignSystem.spacingXL),
            
            // Rating Stars
            EnhancedAnimations.scaleIn(
              child: _buildRatingStars(),
            ),
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Rating Text
            if (_selectedRating > 0) ...[
              EnhancedAnimations.fadeIn(
                child: Text(
                  _getRatingText(_selectedRating),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getRatingColor(_selectedRating),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: ModernDesignSystem.spacingM),
            ],
            
            // Comment Field (for low ratings)
            if (_selectedRating > 0 && _selectedRating < 4) ...[
              EnhancedAnimations.slideIn(
                child: TextFormField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Görüşleriniz (İsteğe bağlı)',
                    hintText: 'Nasıl iyileştirebiliriz?',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                      borderSide: BorderSide(color: ModernDesignSystem.primaryGreen, width: 2),
                    ),
                  ),
                ),
              ),
              SizedBox(height: ModernDesignSystem.spacingL),
            ],
            
            // Action Buttons
            EnhancedAnimations.fadeIn(
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= _selectedRating;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedRating = starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: EnhancedAnimations.hover(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  size: 48,
                  color: isSelected ? ModernDesignSystem.warning : ModernDesignSystem.textTertiary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Submit Button
        if (_selectedRating > 0) ...[
          EnhancedButton(
            text: _selectedRating >= 4 ? 'Play Store\'da Değerlendir' : 'Geri Bildirim Gönder',
            type: ButtonType.primary,
            fullWidth: true,
            isLoading: _isLoading,
            onPressed: _handleSubmit,
          ),
          SizedBox(height: ModernDesignSystem.spacingM),
        ],
        
        // Cancel/Dismiss Buttons
        Row(
          children: [
            if (!widget.isManual) ...[
              Expanded(
                child: EnhancedButton(
                  text: 'Daha Sonra',
                  type: ButtonType.outline,
                  onPressed: _handleDismiss,
                ),
              ),
              SizedBox(width: ModernDesignSystem.spacingM),
            ],
            Expanded(
              child: EnhancedButton(
                text: 'İptal',
                type: ButtonType.outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Çok Kötü';
      case 2:
        return 'Kötü';
      case 3:
        return 'Orta';
      case 4:
        return 'İyi';
      case 5:
        return 'Mükemmel';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return ModernDesignSystem.error;
      case 3:
        return ModernDesignSystem.warning;
      case 4:
      case 5:
        return ModernDesignSystem.success;
      default:
        return ModernDesignSystem.textPrimary;
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedRating == 0) return;

    setState(() => _isLoading = true);

    try {
      await AppRatingService.recordRatingSubmitted(_selectedRating);
      
      if (mounted) {
        Navigator.of(context).pop();
        
        if (_selectedRating >= 4) {
          // Yüksek puan - Play Store'a yönlendir
          await AppRatingService.openPlayStoreManually();
          
          EnhancedSnackbar.show(
            context,
            message: 'Play Store\'da değerlendirme yapıldı!',
            type: SnackbarType.success,
          );
        } else {
          // Düşük puan - Feedback sayfasına yönlendir
          _showFeedbackDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        EnhancedSnackbar.show(
          context,
          message: 'Bir hata oluştu, lütfen tekrar deneyin',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDismiss() async {
    await AppRatingService.recordRatingDismissed();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geri Bildirim'),
        content: const Text(
          'Görüşlerinizi bizimle paylaşmak ister misiniz? '
          'Böylece uygulamayı daha iyi hale getirebiliriz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Feedback sayfasına yönlendir
              Navigator.of(context).pushNamed('/feedback');
            },
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }
}

class AppRatingTrigger extends ConsumerWidget {
  final Widget child;
  final bool showOnAppLaunch;

  const AppRatingTrigger({
    super.key,
    required this.child,
    this.showOnAppLaunch = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showOnAppLaunch) {
        AppRatingService.showRatingDialogIfNeeded(context);
      }
    });

    return child;
  }
}

class AppRatingButton extends ConsumerWidget {
  final String text;
  final IconData? icon;

  const AppRatingButton({
    super.key,
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnhancedButton(
      text: text,
      icon: icon ?? Icons.star_outline,
      type: ButtonType.outline,
      onPressed: () => AppRatingService.showManualRatingDialog(context),
    );
  }
}
