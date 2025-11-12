import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/modern_design_system.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool useAnimation;
  final String? animationPath;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.useAnimation = true,
    this.animationPath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation or Icon
            if (useAnimation)
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  animationPath ?? 'assets/animations/empty_state.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      (iconColor ?? ModernDesignSystem.accentPurple).withOpacity(0.2),
                      (iconColor ?? ModernDesignSystem.accentPink).withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 70,
                  color: iconColor ?? ModernDesignSystem.accentPurple,
                ),
              ),
            const SizedBox(height: 32),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeXXL,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeM,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor ?? ModernDesignSystem.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty Favorites State
class EmptyFavoritesState extends StatelessWidget {
  final VoidCallback? onExplore;

  const EmptyFavoritesState({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.favorite_border,
      title: 'Henüz favori eklemedin',
      message: 'Beğendiğin şarkıları ve albümleri favorilere ekleyerek burada görebilirsin',
      actionText: onExplore != null ? 'Müzik Keşfet' : null,
      onAction: onExplore,
      iconColor: Colors.red,
    );
  }
}

/// Empty Playlist State
class EmptyPlaylistState extends StatelessWidget {
  final VoidCallback? onCreate;

  const EmptyPlaylistState({super.key, this.onCreate});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.queue_music,
      title: 'Playlist\'in boş',
      message: 'Bu playlist\'e şarkı ekleyerek dinlemeye başla',
      actionText: onCreate != null ? 'Şarkı Ekle' : null,
      onAction: onCreate,
    );
  }
}

/// Empty Search State
class EmptySearchState extends StatelessWidget {
  final String? searchQuery;

  const EmptySearchState({super.key, this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: searchQuery != null ? '"$searchQuery" bulunamadı' : 'Sonuç bulunamadı',
      message: 'Farklı anahtar kelimeler ile tekrar dene',
      iconColor: Colors.orange,
    );
  }
}

/// Empty Reviews State
class EmptyReviewsState extends StatelessWidget {
  final VoidCallback? onAddReview;

  const EmptyReviewsState({super.key, this.onAddReview});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.rate_review_outlined,
      title: 'Henüz inceleme yok',
      message: 'İlk incelemeyi sen yaz ve diğer kullanıcılarla düşüncelerini paylaş',
      actionText: onAddReview != null ? 'İnceleme Yaz' : null,
      onAction: onAddReview,
    );
  }
}

/// Empty Messages State
class EmptyMessagesState extends StatelessWidget {
  final VoidCallback? onStartChat;

  const EmptyMessagesState({super.key, this.onStartChat});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'Mesaj kutun boş',
      message: 'Arkadaşlarınla müzik hakkında sohbet et',
      actionText: onStartChat != null ? 'Sohbet Başlat' : null,
      onAction: onStartChat,
      iconColor: ModernDesignSystem.primaryGreen,
    );
  }
}

/// Empty Notifications State
class EmptyNotificationsState extends StatelessWidget {
  const EmptyNotificationsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.notifications_none,
      title: 'Bildirim yok',
      message: 'Yeni bildirimler burada görünecek',
      iconColor: ModernDesignSystem.accentYellow,
    );
  }
}

/// Empty Feed State
class EmptyFeedState extends StatelessWidget {
  final VoidCallback? onFindFriends;

  const EmptyFeedState({super.key, this.onFindFriends});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.dynamic_feed_outlined,
      title: 'Feed\'in boş',
      message: 'Arkadaşlarını takip ederek onların müzik aktivitelerini gör',
      actionText: onFindFriends != null ? 'Arkadaş Bul' : null,
      onAction: onFindFriends,
    );
  }
}

/// Error State
class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeXL,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            if (message != null)
              Text(
                message!,
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeM,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernDesignSystem.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Tekrar Dene',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No Connection State
class NoConnectionState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoConnectionState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.wifi_off,
                size: 60,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bağlantı yok',
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeXL,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'İnternet bağlantını kontrol et',
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeM,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Tekrar Dene',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
