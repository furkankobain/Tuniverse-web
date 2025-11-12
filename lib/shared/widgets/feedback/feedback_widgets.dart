import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/modern_design_system.dart';
import '../../../shared/widgets/animations/enhanced_animations.dart';
import '../../../shared/widgets/ui/enhanced_components.dart';
import '../../../shared/widgets/responsive/responsive_layout.dart';
import '../../../shared/services/feedback_service.dart';

class FeedbackDialog extends ConsumerStatefulWidget {
  final String? initialType;
  final String? initialMessage;

  const FeedbackDialog({
    super.key,
    this.initialType,
    this.initialMessage,
  });

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedType = 'general';
  int _rating = 5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    color: ModernDesignSystem.primaryGreen,
                    size: ModernDesignSystem.iconL,
                  ),
                  SizedBox(width: ModernDesignSystem.spacingM),
                  Text(
                    'Geri Bildirim',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              SizedBox(height: ModernDesignSystem.spacingL),
              
              // Feedback Type
              Text(
                'Geri Bildirim Türü',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: ModernDesignSystem.spacingS),
              Wrap(
                spacing: ModernDesignSystem.spacingS,
                children: [
                  _buildTypeChip('general', 'Genel', Icons.chat_outlined),
                  _buildTypeChip('bug', 'Hata', Icons.bug_report_outlined),
                  _buildTypeChip('feature', 'Özellik', Icons.lightbulb_outline),
                  _buildTypeChip('rating', 'Değerlendirme', Icons.star_outline),
                ],
              ),
              
              SizedBox(height: ModernDesignSystem.spacingL),
              
              // Rating (only for rating type)
              if (_selectedType == 'rating') ...[
                Text(
                  'Uygulama Değerlendirmesi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ModernDesignSystem.spacingS),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _rating = index + 1),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: ModernDesignSystem.warning,
                        size: ModernDesignSystem.iconXL,
                      ),
                    );
                  }),
                ),
                SizedBox(height: ModernDesignSystem.spacingL),
              ],
              
              // Message
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen mesajınızı yazın';
                  }
                  if (value.trim().length < 10) {
                    return 'Mesaj en az 10 karakter olmalı';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: _getMessageLabel(),
                  hintText: _getMessageHint(),
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
                ),
              ),
              
              SizedBox(height: ModernDesignSystem.spacingL),
              
              // Email (optional)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-posta (İsteğe bağlı)',
                  hintText: 'Geri bildirim için',
                  prefixIcon: const Icon(Icons.email_outlined),
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
                ),
              ),
              
              SizedBox(height: ModernDesignSystem.spacingXL),
              
              // Submit Button
              Row(
                children: [
                  Expanded(
                    child: EnhancedButton(
                      text: 'İptal',
                      type: ButtonType.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: ModernDesignSystem.spacingM),
                  Expanded(
                    child: EnhancedButton(
                      text: 'Gönder',
                      type: ButtonType.primary,
                      isLoading: _isLoading,
                      onPressed: _handleSubmit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernDesignSystem.spacingM,
          vertical: ModernDesignSystem.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? ModernDesignSystem.primaryGreen
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          border: Border.all(
            color: isSelected 
                ? ModernDesignSystem.primaryGreen
                : ModernDesignSystem.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: ModernDesignSystem.iconS,
              color: isSelected 
                  ? Colors.white
                  : ModernDesignSystem.textSecondary,
            ),
            SizedBox(width: ModernDesignSystem.spacingXS),
            Text(
              label,
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeS,
                color: isSelected 
                    ? Colors.white
                    : ModernDesignSystem.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMessageLabel() {
    switch (_selectedType) {
      case 'bug':
        return 'Hata Açıklaması';
      case 'feature':
        return 'Özellik Talebi';
      case 'rating':
        return 'Yorum (İsteğe bağlı)';
      default:
        return 'Mesajınız';
    }
  }

  String _getMessageHint() {
    switch (_selectedType) {
      case 'bug':
        return 'Hatanın nasıl oluştuğunu açıklayın...';
      case 'feature':
        return 'Hangi özelliği eklemek istiyorsunuz?';
      case 'rating':
        return 'Uygulama hakkındaki düşünceleriniz...';
      default:
        return 'Mesajınızı yazın...';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await FeedbackService.submitFeedback(
        type: _selectedType,
        message: _messageController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        rating: _selectedType == 'rating' ? _rating : null,
      );

      if (result.isSuccess) {
        Navigator.of(context).pop();
        EnhancedSnackbar.show(
          context,
          message: 'Geri bildiriminiz başarıyla gönderildi!',
          type: SnackbarType.success,
        );
      } else {
        EnhancedSnackbar.show(
          context,
          message: 'Geri bildirim gönderilemedi',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      EnhancedSnackbar.show(
        context,
        message: 'Beklenmeyen bir hata oluştu',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class QuickFeedbackButton extends ConsumerWidget {
  final String type;
  final IconData icon;
  final String label;

  const QuickFeedbackButton({
    super.key,
    required this.type,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnhancedAnimations.hover(
      child: InkWell(
        onTap: () => _showFeedbackDialog(context),
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
        child: Container(
          padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ModernDesignSystem.iconM,
                color: ModernDesignSystem.primaryGreen,
              ),
              SizedBox(width: ModernDesignSystem.spacingS),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(initialType: type),
    );
  }
}

class FeedbackFloatingButton extends ConsumerWidget {
  const FeedbackFloatingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showFeedbackDialog(context),
      backgroundColor: ModernDesignSystem.primaryGreen,
      child: const Icon(
        Icons.feedback_outlined,
        color: Colors.white,
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const FeedbackDialog(),
    );
  }
}

class FeedbackPage extends ConsumerWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geri Bildirim'),
        centerTitle: true,
      ),
      body: ResponsivePadding(
        child: Column(
          children: [
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Header
            EnhancedAnimations.fadeIn(
              child: Container(
                padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
                decoration: BoxDecoration(
                  gradient: ModernDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXL),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.feedback_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: ModernDesignSystem.spacingM),
                    Text(
                      'Geri Bildiriminizi Paylaşın',
                      style: TextStyle(
                        fontSize: ModernDesignSystem.fontSizeXXL,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ModernDesignSystem.spacingS),
                    Text(
                      'Görüşleriniz bizim için çok değerli',
                      style: TextStyle(
                        fontSize: ModernDesignSystem.fontSizeM,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: ModernDesignSystem.spacingXL),
            
            // Quick Actions
            EnhancedAnimations.slideIn(
              child: Text(
                'Hızlı Geri Bildirim',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            SizedBox(height: ModernDesignSystem.spacingM),
            
            EnhancedAnimations.staggeredFadeIn(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: QuickFeedbackButton(
                        type: 'general',
                        icon: Icons.chat_outlined,
                        label: 'Genel',
                      ),
                    ),
                    SizedBox(width: ModernDesignSystem.spacingM),
                    Expanded(
                      child: QuickFeedbackButton(
                        type: 'bug',
                        icon: Icons.bug_report_outlined,
                        label: 'Hata',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ModernDesignSystem.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: QuickFeedbackButton(
                        type: 'feature',
                        icon: Icons.lightbulb_outline,
                        label: 'Özellik',
                      ),
                    ),
                    SizedBox(width: ModernDesignSystem.spacingM),
                    Expanded(
                      child: QuickFeedbackButton(
                        type: 'rating',
                        icon: Icons.star_outline,
                        label: 'Değerlendirme',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: ModernDesignSystem.spacingXL),
            
            // Detailed Feedback
            EnhancedAnimations.fadeIn(
              child: EnhancedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detaylı Geri Bildirim',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ModernDesignSystem.spacingM),
                    Text(
                      'Daha kapsamlı geri bildirim vermek için detaylı formu kullanın.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: ModernDesignSystem.spacingL),
                    EnhancedButton(
                      text: 'Detaylı Geri Bildirim',
                      type: ButtonType.primary,
                      fullWidth: true,
                      onPressed: () => _showFeedbackDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const FeedbackDialog(),
    );
  }
}
