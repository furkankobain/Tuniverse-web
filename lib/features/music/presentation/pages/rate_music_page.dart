import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/models/music_rating.dart'; // Unused import
// import '../../../../shared/providers/music_rating_provider.dart'; // Unused import
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/services/music_rating_service.dart';
import '../../../../shared/widgets/star_rating_widget.dart';

class RateMusicPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> track;

  const RateMusicPage({
    super.key,
    required this.track,
  });

  @override
  ConsumerState<RateMusicPage> createState() => _RateMusicPageState();
}

class _RateMusicPageState extends ConsumerState<RateMusicPage> {
  late TextEditingController _reviewController;
  late List<String> _selectedTags;
  int _rating = 0;
  bool _isLoading = false;

  final List<String> _availableTags = [
    'favori',
    'sakin',
    'enerjik',
    'üzgün',
    'mutlu',
    'nostaljik',
    'romantik',
    'parti',
    'spor',
    'çalışma',
    'yolculuk',
    'yaz',
    'kış',
    'indie',
    'pop',
    'rock',
    'hip hop',
    'elektronik',
    'caz',
    'klasik',
  ];

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
    _selectedTags = [];
    
    // Check if track already has a rating
    _loadExistingRating();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRating() async {
    final trackId = widget.track['id'];
    if (trackId == null) return;
    
    final existingRating = await MusicRatingService.getRatingByTrackId(trackId);
    if (existingRating != null && mounted) {
      setState(() {
        _rating = existingRating.rating;
        _reviewController.text = existingRating.review ?? '';
        _selectedTags = List.from(existingRating.tags);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Music'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRating,
            child: Text(
              _isLoading ? 'Saving...' : 'Save',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Track Info Card
                _buildTrackInfoCard(),
                
                const SizedBox(height: 32),
                
                // Rating Section
                _buildRatingSection(),
                
                const SizedBox(height: 32),
                
                // Review Section
                _buildReviewSection(),
                
                const SizedBox(height: 32),
                
                // Tags Section
                _buildTagsSection(),
                
                const SizedBox(height: 32),
                
                // Save Button
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Album Art
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: widget.track['album_image'] != null
                  ? DecorationImage(
                      image: NetworkImage(widget.track['album_image']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: widget.track['album_image'] == null
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : null,
            ),
            child: widget.track['album_image'] == null
                ? const Icon(
                    Icons.music_note,
                    color: AppTheme.primaryColor,
                    size: 32,
                  )
                : null,
          ),
          
          const SizedBox(width: 16),
          
          // Track Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.track['name'] ?? 'Unknown Track',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.track['artists'] ?? 'Unknown Artist',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.track['album'] ?? 'Unknown Album',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Rating',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: StarRatingWidget(
            rating: _rating,
            interactive: true,
            size: 40,
            onRatingChanged: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _getRatingText(_rating),
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review (Optional)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _reviewController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Share your thoughts about this track...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Etiketler (Opsiyonel)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || _rating == 0 ? null : _saveRating,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _rating == 0 ? 'Puan seçin' : 'Puanlamayı Kaydet',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  Future<void> _saveRating() async {
    if (_rating == 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseService.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      await MusicRatingService.saveRating(
        trackId: widget.track['id'] ?? 'unknown_track',
        trackName: widget.track['name'] ?? 'Bilinmeyen Şarkı',
        artists: widget.track['artist'] ?? widget.track['artists'] ?? 'Bilinmeyen Sanatçı',
        albumName: widget.track['album'] ?? 'Bilinmeyen Albüm',
        albumImage: widget.track['image_url'] ?? widget.track['album_image'],
        rating: _rating,
        review: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
        tags: _selectedTags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Puanlama başarıyla kaydedildi!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Puanlama kaydedilemedi: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
