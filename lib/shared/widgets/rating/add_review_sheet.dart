import 'package:flutter/material.dart';
import '../../../core/theme/modern_design_system.dart';
import 'rating_widget.dart';

class AddReviewSheet extends StatefulWidget {
  final String albumName;
  final String? artistName;
  final double? initialRating;
  final String? initialReviewText;
  final Function(double rating, String reviewText) onSubmit;

  const AddReviewSheet({
    super.key,
    required this.albumName,
    this.artistName,
    this.initialRating,
    this.initialReviewText,
    required this.onSubmit,
  });

  @override
  State<AddReviewSheet> createState() => _AddReviewSheetState();

  static Future<void> show({
    required BuildContext context,
    required String albumName,
    String? artistName,
    double? initialRating,
    String? initialReviewText,
    required Function(double rating, String reviewText) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddReviewSheet(
        albumName: albumName,
        artistName: artistName,
        initialRating: initialRating,
        initialReviewText: initialReviewText,
        onSubmit: onSubmit,
      ),
    );
  }
}

class _AddReviewSheetState extends State<AddReviewSheet> {
  late double _rating;
  late TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0.0;
    _textController = TextEditingController(text: widget.initialReviewText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _rating == 0) {
      if (_rating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen bir rating seçin'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(_rating, _textController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İnceleme kaydedildi! ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Text(
                  widget.initialReviewText != null
                      ? 'İncelemeyi Düzenle'
                      : 'İnceleme Yaz',
                  style: TextStyle(
                    fontSize: ModernDesignSystem.fontSizeXXL,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // Album info
                Text(
                  widget.albumName,
                  style: TextStyle(
                    fontSize: ModernDesignSystem.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: ModernDesignSystem.accentPurple,
                  ),
                ),
                if (widget.artistName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.artistName!,
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeM,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Rating section
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Ratingin',
                        style: TextStyle(
                          fontSize: ModernDesignSystem.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RatingWidget(
                        initialRating: _rating,
                        onRatingChanged: (rating) => setState(() => _rating = rating),
                        size: 48,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Review text field
                Text(
                  'İnceleme (isteğe bağlı)',
                  style: TextStyle(
                    fontSize: ModernDesignSystem.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _textController,
                  maxLines: 6,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: ModernDesignSystem.fontSizeM,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Bu albüm hakkında düşüncelerini paylaş...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: isDark ? ModernDesignSystem.darkCard : ModernDesignSystem.lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                      borderSide: BorderSide(
                        color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                      borderSide: BorderSide(
                        color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                      borderSide: const BorderSide(
                        color: ModernDesignSystem.accentPurple,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    // Review text is optional, but if provided should have minimum length
                    if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
                      return 'İnceleme en az 10 karakter olmalı';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ModernDesignSystem.accentPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.initialReviewText != null ? 'Güncelle' : 'Kaydet',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(
                        color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                      ),
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
