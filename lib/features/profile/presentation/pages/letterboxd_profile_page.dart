import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/profile_service.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';

class LetterboxdProfilePage extends StatefulWidget {
  const LetterboxdProfilePage({super.key});

  @override
  State<LetterboxdProfilePage> createState() => _LetterboxdProfilePageState();
}

class _LetterboxdProfilePageState extends State<LetterboxdProfilePage> {
  List<Map<String, dynamic>> _pinnedTracks = [];
  Map<String, int> _stats = {};
  String? _bio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    final pinnedTracks = await ProfileService.getPinnedTracks();
    final stats = await ProfileService.getStats();
    final bio = await ProfileService.getBio();

    if (mounted) {
      setState(() {
        _pinnedTracks = pinnedTracks;
        _stats = stats;
        _bio = bio;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseBypassAuthService.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: isDark
                ? ModernDesignSystem.darkBackground
                : ModernDesignSystem.lightBackground,
            title: Text(
              currentUser?.username ?? 'Profil',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),

          // Profile Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar (centered)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: ModernDesignSystem.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.transparent,
                        child: Text(
                          currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Name (centered)
                  Center(
                    child: Text(
                      currentUser?.displayName ?? 'Kullanıcı',
                      style: TextStyle(
                        fontSize: ModernDesignSystem.fontSizeXL,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row (centered)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat(
                        _stats['totalReviews'] ?? 0,
                        'Not',
                        isDark,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.2),
                      ),
                      _buildStat(
                        _stats['totalFavorites'] ?? 0,
                        'Favori',
                        isDark,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.2),
                      ),
                      _buildStat(
                        _stats['followers'] ?? 0,
                        'Takipçi',
                        isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bio (centered)
                  if (_bio != null && _bio!.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _bio!,
                          style: TextStyle(
                            fontSize: ModernDesignSystem.fontSizeM,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          _showEditBioDialog(context);
                        },
                        child: Text(
                          '+ Bio ekle',
                          style: TextStyle(
                            fontSize: ModernDesignSystem.fontSizeM,
                            color: ModernDesignSystem.primaryGreen,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Stats Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/listening-stats'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFFF5E5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.insights, size: 20),
                      label: const Text(
                        'Listening Stats',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickStatCard(
                          'Listening Time',
                          '${(_stats['totalListeningMinutes'] ?? 0) ~/ 60}h',
                          Icons.access_time,
                          const Color(0xFFFF5E5E),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickStatCard(
                          'This Week',
                          '${_stats['weeklyTracks'] ?? 12}',
                          Icons.trending_up,
                          const Color(0xFF5A5AFF),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickStatCard(
                          'Top Genre',
                          _stats['topGenre']?.toString() ?? 'Pop',
                          Icons.category,
                          const Color(0xFF00D9FF),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickStatCard(
                          'Avg Rating',
                          '${(_stats['avgRating'] ?? 4.2).toStringAsFixed(1)}⭐',
                          Icons.star,
                          const Color(0xFFFFB800),
                          isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/recently-played'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            Icons.history,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          label: Text(
                            'Geçmiş',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/playlists'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            Icons.queue_music,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          label: Text(
                            'Listeler',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/settings'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            Icons.edit,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          label: Text(
                            'Düzenle',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Pinned Tracks Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FAVORİ ŞARKILAR',
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeS,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  if (_pinnedTracks.isNotEmpty)
                    TextButton(
                      onPressed: () => context.push('/favorites'),
                      child: Text(
                        'Tümü',
                        style: TextStyle(
                          color: ModernDesignSystem.primaryGreen,
                          fontSize: ModernDesignSystem.fontSizeS,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Pinned Tracks Grid (2x2)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _pinnedTracks.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyPinnedTracks(isDark),
                  )
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _pinnedTracks.length) {
                          return _buildPinnedTrackCard(_pinnedTracks[index], isDark);
                        } else {
                          return _buildEmptyPinnedSlot(isDark);
                        }
                      },
                      childCount: 4,
                    ),
                  ),
          ),

          // Recent Notes Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Text(
                'SON NOTLAR',
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeS,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // Recent Reviews List
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ProfileService.getRecentReviews(limit: 5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyReviews(isDark),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildReviewCard(reviews[index], isDark);
                  },
                  childCount: reviews.length,
                ),
              );
            },
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(int value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeL,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeXS,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedTrackCard(Map<String, dynamic> track, bool isDark) {
    final album = track['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;

    return GestureDetector(
      onTap: () => context.push('/track-detail', extra: track),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: ModernDesignSystem.darkCard,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: ModernDesignSystem.darkCard,
                    child: const Icon(Icons.music_note, size: 48),
                  ),
                )
              : Container(
                  color: ModernDesignSystem.darkCard,
                  child: const Icon(Icons.music_note, size: 48),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyPinnedSlot(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? ModernDesignSystem.darkCard.withValues(alpha: 0.3)
            : ModernDesignSystem.lightCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          size: 32,
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildEmptyPinnedTracks(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Favori şarkılarını pin\'le',
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeM,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'En sevdiğin 4 şarkıyı profilinde göster',
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeS,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isDark) {
    final albumData = review['album'] as Map<String, dynamic>?;
    final images = albumData?['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;
    final rating = review['rating'] as double? ?? 0;
    final note = review['note'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? ModernDesignSystem.darkCard
            : ModernDesignSystem.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: ModernDesignSystem.darkCard,
                    child: const Icon(Icons.music_note),
                  ),
          ),

          const SizedBox(width: 16),

          // Review Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review['trackName'] as String? ?? 'Unknown Track',
                  style: TextStyle(
                    fontSize: ModernDesignSystem.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: ModernDesignSystem.accentYellow,
                    );
                  }),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeS,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.edit_note_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz not yazmadın',
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeM,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Şarkılara puan ver ve notlarını ekle',
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeS,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBioDialog(BuildContext context) {
    final controller = TextEditingController(text: _bio);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bio Düzenle'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 150,
          decoration: const InputDecoration(
            hintText: 'Bio yazın...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ProfileService.updateBio(controller.text);
              if (success && mounted) {
                setState(() => _bio = controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
