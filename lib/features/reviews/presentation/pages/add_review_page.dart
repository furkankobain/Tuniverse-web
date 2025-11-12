import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/services/feed_service.dart';
import '../../../../shared/services/admob_service.dart';

class AddReviewPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final String itemType; // 'track', 'album', or 'artist'

  const AddReviewPage({
    super.key,
    required this.item,
    required this.itemType,
  });

  @override
  ConsumerState<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends ConsumerState<AddReviewPage> with SingleTickerProviderStateMixin {
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;
  String? _selectedMood;
  final List<String> _selectedTags = [];
  String? _selectedGifUrl;
  late AnimationController _pulseController;
  
  final List<Map<String, dynamic>> _moods = [
    {'label': 'Energetic', 'emoji': '⚡', 'color': Color(0xFFFF6B6B)},
    {'label': 'Chill', 'emoji': '😌', 'color': Color(0xFF4ECDC4)},
    {'label': 'Happy', 'emoji': '😊', 'color': Color(0xFFFFD93D)},
    {'label': 'Melancholic', 'emoji': '🌧️', 'color': Color(0xFF6C5CE7)},
    {'label': 'Nostalgic', 'emoji': '🌅', 'color': Color(0xFFFF8C42)},
    {'label': 'Romantic', 'emoji': '❤️', 'color': Color(0xFFFF5E78)},
  ];
  
  final List<String> _availableTags = [
    'Masterpiece', 'Underrated', 'Overrated', 'Repeat Mode',
    'Lyrical Genius', 'Production 🔥', 'Instant Classic', 'Hidden Gem',
    'Summer Vibes', 'Night Drive', 'Workout Anthem', 'Study Music',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _customTagController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get _itemName => widget.item['name'] as String? ?? 'Unknown';
  
  String? get _itemImageUrl {
    if (widget.itemType == 'track') {
      final album = widget.item['album'] as Map<String, dynamic>?;
      final images = album?['images'] as List?;
      return images?.isNotEmpty == true ? images![0]['url'] as String? : null;
    } else {
      final images = widget.item['images'] as List?;
      return images?.isNotEmpty == true ? images![0]['url'] as String? : null;
    }
  }

  String get _itemSubtitle {
    if (widget.itemType == 'track' || widget.itemType == 'album') {
      final artists = widget.item['artists'] as List?;
      return artists?.isNotEmpty == true
          ? artists!.map((a) => a['name']).join(', ')
          : 'Unknown Artist';
    }
    return 'Artist';
  }
  
  String get _itemDuration {
    if (widget.itemType == 'track') {
      final durationMs = widget.item['duration_ms'] as int? ?? 0;
      final minutes = durationMs ~/ 60000;
      final seconds = (durationMs % 60000) ~/ 1000;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '';
  }
  
  String get _itemYear {
    if (widget.itemType == 'track') {
      final releaseDate = widget.item['album']?['release_date'] as String?;
      return releaseDate?.substring(0, 4) ?? '';
    } else if (widget.itemType == 'album') {
      final releaseDate = widget.item['release_date'] as String?;
      return releaseDate?.substring(0, 4) ?? '';
    }
    return '';
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticService.mediumImpact();

    try {
      final currentUser = FirebaseService.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final userData = userDoc.data() as Map<String, dynamic>?;
      final username = userData?['username'] ?? userData?['displayName'] ?? 'Anonymous';

      // Save review
      await FirebaseFirestore.instance.collection('reviews').add({
        'userId': currentUser.uid,
        'username': username,
        'itemId': widget.item['id'],
        'itemName': _itemName,
        'itemType': widget.itemType,
        'itemImageUrl': _itemImageUrl,
        'artistName': widget.itemType != 'artist' ? _itemSubtitle : null,
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
        'gifUrl': _selectedGifUrl,
        'mood': _selectedMood,
        'tags': _selectedTags,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      // Create activity for feed
      await FeedService.createActivity(
        type: 'review',
        contentId: widget.item['id'] as String,
        contentData: {
          'name': _itemName,
          'type': widget.itemType,
          'imageUrl': _itemImageUrl,
          'subtitle': _itemSubtitle,
        },
        reviewText: _reviewController.text.trim(),
        rating: _rating,
        isPublic: true,
      );

      if (mounted) {
        HapticService.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review posted successfully! 🎉'),
            backgroundColor: Color(0xFFFF5E5E),
          ),
        );
        
        // Show interstitial ad after successful post (non-blocking)
        AdMobService.showInterstitialAd();
        
        context.pop();
      }
    } catch (e) {
      print('Error submitting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ModernDesignSystem.darkBackground : ModernDesignSystem.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        elevation: 0,
        title: const Text('Write a Review'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitReview,
              child: const Text(
                'Post',
                style: TextStyle(
                  color: Color(0xFFFF5E5E),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated header
            Center(
              child: Column(
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF5E5E).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.rate_review, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share Your Experience',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your opinion matters to the community',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Enhanced Item card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        colors: [Colors.grey[850]!, Colors.grey[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.white, Colors.grey[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(0xFFFF5E5E).withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF5E5E).withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(widget.itemType == 'artist' ? 50 : 16),
                          image: _itemImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_itemImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _itemImageUrl == null
                            ? Icon(
                                widget.itemType == 'track'
                                    ? Icons.music_note
                                    : (widget.itemType == 'album' ? Icons.album : Icons.person),
                                color: Colors.grey[600],
                                size: 50,
                              )
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _itemName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _itemSubtitle,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.itemType.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.itemType == 'track' && (_itemDuration.isNotEmpty || _itemYear.isNotEmpty)) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.grey[800] : Colors.grey[100])!.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (_itemDuration.isNotEmpty)
                            _buildMetadataItem(Icons.access_time, 'Duration', _itemDuration, isDark),
                          if (_itemYear.isNotEmpty)
                            _buildMetadataItem(Icons.calendar_today, 'Year', _itemYear, isDark),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Rating section
            Text(
              'Your Rating',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          HapticService.lightImpact();
                          setState(() {
                            if (_rating == index + 1.0) {
                              _rating = index + 0.5;
                            } else {
                              _rating = index + 1.0;
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Stack(
                            children: [
                              Icon(
                                Icons.star_border,
                                color: const Color(0xFFFF5E5E),
                                size: 48,
                              ),
                              if (_rating > index)
                                ClipRect(
                                  clipper: _rating >= index + 1
                                      ? null
                                      : _HalfStarClipper(),
                                  child: Icon(
                                    Icons.star,
                                    color: const Color(0xFFFF5E5E),
                                    size: 48,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E5E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF5E5E),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_rating.toStringAsFixed(1)} / 5.0',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF5E5E),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),
            
            // Mood Selector
            Text(
              'How does it make you feel? 💭',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood['label'];
                return GestureDetector(
                  onTap: () {
                    HapticService.lightImpact();
                    setState(() {
                      _selectedMood = isSelected ? null : mood['label'] as String;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (mood['color'] as Color).withOpacity(0.2)
                          : (isDark ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? (mood['color'] as Color)
                            : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mood['emoji'] as String,
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          mood['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Review text with inspirational placeholder
            Text(
              'Share Your Story ✨',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What makes this special? What emotions does it evoke?',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _reviewController,
                  maxLines: 8,
                  maxLength: 500,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.itemType == 'track'
                        ? 'This track hits different because...\n\nThe lyrics remind me of...\n\nIt\'s perfect for...'
                        : 'What stood out to me most was...\n\nThis reminds me of...\n\nI\'d recommend it for...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      height: 1.5,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF5E5E),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 8),
                // GIF Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticService.lightImpact();
                      await _showGifPicker(isDark);
                    },
                    icon: const Icon(Icons.gif_box, size: 20),
                    label: const Text('Add GIF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      foregroundColor: Color(0xFFFF5E5E),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // Show selected GIF
                if (_selectedGifUrl != null) ...[
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _selectedGifUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticService.lightImpact();
                            setState(() => _selectedGifUrl = null);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Tags Section
            Text(
              'Add Tags 🏷️',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help others discover this ${widget.itemType}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 12),
            // Custom tag input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTagController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your own tag...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: Icon(Icons.tag, color: Color(0xFFFF5E5E), size: 20),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF5E5E),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty && _selectedTags.length < 10) {
                        HapticService.lightImpact();
                        setState(() {
                          _selectedTags.add(value.trim());
                          _customTagController.clear();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_customTagController.text.trim().isNotEmpty && _selectedTags.length < 10) {
                      HapticService.lightImpact();
                      setState(() {
                        _selectedTags.add(_customTagController.text.trim());
                        _customTagController.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF5E5E),
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Preset tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      HapticService.lightImpact();
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          if (_selectedTags.length < 10) {
                            _selectedTags.add(tag);
                          }
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                              )
                            : null,
                        color: isSelected ? null : (isDark ? Colors.grey[800] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Color(0xFFFF5E5E)
                              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                    ),
                  );
                }),
                // Show selected custom tags with delete option
                ..._selectedTags
                    .where((tag) => !_availableTags.contains(tag))
                    .map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            HapticService.lightImpact();
                            setState(() => _selectedTags.remove(tag));
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 32),
            
            // Recent Reviews from Community
            _buildRecentReviews(isDark),
            
            const SizedBox(height: 32),

            // Submit button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF5E5E).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Post Review',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showGifPicker(bool isDark) async {
    final TextEditingController searchController = TextEditingController();
    final gifUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.gif_box, color: Color(0xFFFF5E5E)),
            const SizedBox(width: 8),
            const Text('Add GIF'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Paste GIF URL from Giphy or Tenor...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF5E5E), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: Search for GIFs on Giphy.com or Tenor.com, copy the GIF link, and paste it here!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (searchController.text.trim().isNotEmpty) {
                Navigator.pop(context, searchController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF5E5E),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (gifUrl != null) {
      setState(() => _selectedGifUrl = gifUrl);
    }
  }

  Widget _buildMetadataItem(IconData icon, String label, String value, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Color(0xFFFF5E5E),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentReviews(bool isDark) {
    final trackId = widget.item['id'] as String?;
    if (trackId == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, color: Color(0xFFFF5E5E), size: 20),
            const SizedBox(width: 8),
            Text(
              'What Others Are Saying',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Recent reviews from the community',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where(widget.itemType == 'track' ? 'itemId' : 'itemId', isEqualTo: trackId)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: ColorFiltered(
                        colorFilter: isDark
                            ? const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcATop,
                              )
                            : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.dst,
                              ),
                        child: Lottie.asset(
                          'assets/animations/music_playing.json',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Be the first to share your thoughts! 🌟',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final reviews = snapshot.data!.docs.take(3).toList();
            
            return Column(
              children: reviews.map((doc) {
                final review = doc.data() as Map<String, dynamic>;
                final rating = (review['rating'] as num?)?.toDouble() ?? 0;
                final text = (review['reviewText'] as String?) ?? '';
                final mood = review['mood'] as String?;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Color(0xFFFF5E5E),
                            );
                          }),
                          if (mood != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF5E5E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                mood,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFF5E5E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text.length > 100 ? '${text.substring(0, 100)}...' : text,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// Custom clipper for half stars
class _HalfStarClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
