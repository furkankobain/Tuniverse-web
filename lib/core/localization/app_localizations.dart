import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('tr', ''),
  ];

  Map<String, String> get _localizedStrings {
    return _translations[locale.languageCode] ?? _translations['en']!;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Shorthand
  String t(String key) => translate(key);

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // Common
      'app_name': 'Tuniverse',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'share': 'Share',
      'search': 'Search',
      'filter': 'Filter',
      'settings': 'Settings',
      'logout': 'Logout',
      'profile': 'Profile',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'skip': 'Skip',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'close': 'Close',
      
      // Navigation
      'home': 'Home',
      'discover': 'Discover',
      'library': 'Library',
      'messages': 'Messages',
      'more': 'More',
      'create': 'Create',
      
      // Auth
      'login': 'Log In',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password',
      'remember_me': 'Remember Me',
      'or': 'or',
      'continue_with_spotify': 'Continue with Spotify',
      'continue_with_google': 'Continue with Google',
      'no_account': 'Don\'t have an account? ',
      'have_account': 'Already have an account? ',
      
      // Home
      'welcome_back': 'Welcome Back',
      'new_releases': 'New Releases',
      'trending': 'Trending',
      'top_tracks': 'Top Tracks',
      'popular': 'Popular',
      'for_you': 'For You',
      
      // Discover
      'discover_music': 'Discover Music',
      'genres': 'Genres',
      'moods': 'Moods',
      'playlists': 'Playlists',
      'artists': 'Artists',
      'albums': 'Albums',
      'tracks': 'Tracks',
      
      // Library
      'your_library': 'Your Library',
      'liked_songs': 'Liked Songs',
      'saved_albums': 'Saved Albums',
      'following': 'Following',
      'history': 'History',
      
      // Messages
      'conversations': 'Conversations',
      'live_activity': 'Live Activity',
      'no_recent_activity': 'No recent activity',
      'now_playing': 'Now playing',
      
      // Profile
      'edit_profile': 'Edit Profile',
      'followers': 'Followers',
      'following_count': 'Following',
      'reviews': 'Reviews',
      'ratings': 'Ratings',
      
      // Music
      'play': 'Play',
      'pause': 'Pause',
      'next_track': 'Next',
      'previous_track': 'Previous',
      'add_to_library': 'Add to Library',
      'remove_from_library': 'Remove from Library',
      'add_to_playlist': 'Add to Playlist',
      
      // Reviews
      'write_review': 'Write a Review',
      'your_rating': 'Your Rating',
      'your_review': 'Your Review',
      'post_review': 'Post Review',
      'edit_review': 'Edit Review',
      
      // Settings
      'account': 'Account',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'theme': 'Theme',
      'language': 'Language',
      'about': 'About',
      'help': 'Help & Support',
      'terms': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',
      
      // Pro
      'get_pro': 'Get PRO',
      'upgrade_to_pro': 'Upgrade to PRO',
      'pro_features': 'PRO Features',
      'pro_member': 'PRO Member',
      'subscribe': 'Subscribe',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      
      // Errors
      'error_occurred': 'An error occurred',
      'network_error': 'Network error',
      'try_again': 'Try Again',
      'no_internet': 'No internet connection',
      
      // Home Page
      'good_morning': 'Good Morning',
      'good_afternoon': 'Good Afternoon',
      'good_evening': 'Good Evening',
      'recently_played': 'Recently Played',
      'recommended': 'Recommended',
      'new_releases': 'New Releases',
      'top_tracks': 'Top Tracks',
      'popular_albums': 'Popular Albums',
      
      // Discover
      'featured': 'Featured',
      'categories': 'Categories',
      'browse_all': 'Browse All',
      
      // Profile
      'my_profile': 'My Profile',
      'posts': 'Posts',
      'activity': 'Activity',
      'statistics': 'Statistics',
      'listening_time': 'Listening Time',
      
      // More
      'gamification': 'Gamification',
      'achievements': 'Achievements & Badges',
      'streaks': 'Streaks',
      'leaderboards': 'Leaderboards',
      'analytics': 'Analytics & Insights',
      'offline': 'Offline & Downloads',
      'collaboration': 'Collaboration',
      'events': 'Events & Concerts',
      'news': 'Music News',
      'discovery': 'Discovery',
      'personalization': 'Personalization',
      'help_support': 'Help & Support',
      
      // Common Actions
      'view_all': 'View All',
      'see_more': 'See More',
      'show_less': 'Show Less',
      'load_more': 'Load More',
      'refresh': 'Refresh',
      'sort_by': 'Sort By',
      'filter_by': 'Filter By',
      
      // More Page Items
      'view_your_achievements': 'View your achievements',
      'listening_streaks_stats': 'Listening streaks & stats',
      'global_friends_rankings': 'Global & friends rankings',
      'music_quiz': 'Music Quiz',
      'test_music_knowledge': 'Test your music knowledge',
      'weekly_challenges': 'Weekly Challenges',
      'complete_challenges': 'Complete challenges for rewards',
      'listening_clock': 'Listening Clock',
      'when_listen_most': 'When do you listen most?',
      'music_map': 'Music Map',
      'discover_by_location': 'Discover artists by location',
      'taste_profile': 'Taste Profile',
      'music_personality': 'Your music personality',
      'yearly_wrapped': 'Yearly Wrapped',
      'year_in_music': 'Your year in music',
      'friends_comparison': 'Friends Comparison',
      'compare_taste': 'Compare music taste',
      'downloaded_tracks': 'Downloaded Tracks',
      'manage_offline': 'Manage offline music',
      'storage_cache': 'Storage & Cache',
      'manage_storage': 'Manage app storage',
      'group_sessions': 'Group Sessions',
      'listen_together': 'Listen together in real-time',
      'music_rooms': 'Music Rooms',
      'join_rooms': 'Join live listening rooms',
      'upcoming_events': 'Upcoming Events',
      'concerts_near': 'Concerts & music events near you',
      'news_feed': 'News Feed',
      'latest_news': 'Latest music news & updates',
      'daily_mix': 'Daily Mix',
      'personalized_playlists': 'Personalized playlists',
      'release_radar': 'Release Radar',
      'new_from_favorites': 'New music from favorites',
      'decade_explorer': 'Decade Explorer',
      '60s_2020s_explorer': '60s-2020s music explorer',
      'genre_deep_dive': 'Genre Deep Dive',
      'explore_genres': 'Explore genres in depth',
      'mood_detection': 'Mood Detection',
      'ai_mood_analysis': 'AI mood analysis & playlist generation',
      'now_playing': 'Now Playing',
      'fullscreen_player': 'Full-screen music player with visualizer',
      'help_faq': 'Help & FAQ',
      'common_questions': 'Common questions and support',
      
      // Home Page Specific
      'search_placeholder': 'Search music, artists, albums...',
      'global_new_releases': 'Global New Releases',
      'popular_worldwide': 'Popular Worldwide',
      'popular_new_toggle': 'POPULAR',
      'new_toggle': 'NEW',
      'trending_this_week': 'Trending This Week',
      'community_reviews': 'Community Reviews',
      'add_comment': 'Add Comment',
      'write_comment': 'Write a comment...',
      'post_comment': 'Post Comment',
      'comment_added': 'Comment added',
      'no_reviews_yet': 'No reviews yet',
      'be_first_share': 'Be the first to share your thoughts!',
      'trending_now': 'Trending Now',
      'discover_whats_hot': 'Discover what\'s hot this week',
      'explore': 'Explore',
      'my_library': 'My Library',
      'stats': 'Stats',
      'discover_btn': 'Discover',
      'reviewed': 'reviewed',
      'connect_spotify_history': 'Connect Spotify to see your listening history',
      'could_not_load_track': 'Could not load track details',
      'quick_actions': 'Quick Actions',
      'comment': 'Comment',
      
      // Discover Page
      'trending': 'Trending',
      'hot_new_releases': 'Hot New Releases',
      'popular_this_week': 'Popular This Week',
      'top_lists': 'Top Lists',
      'top_250_albums': 'Top 250 Albums',
      'top_250_tracks': 'Top 250 Tracks',
      'top_250_artists': 'Top 250 Artists',
      'most_popular_albums': 'Most Popular Albums',
      'most_popular_artists': 'Most Popular Artists',
      'most_popular_tracks': 'Most Popular Tracks',
      'for_you': 'For You',
      'recommended': 'Recommended',
      'to_follow': 'To Follow',
      'community': 'Community',
      'trending_users': 'Trending Users',
      'explore_reviews': 'Explore Reviews',
      'explore_lists': 'Explore Lists',
      'lists_by_friends': 'Lists by Friends',
      
      // Profile Page
      'liked_songs': 'Liked Songs',
      'my_albums': 'My Albums',
      'my_playlists': 'Playlists',
      'listening_history': 'Listening History',
      'my_ratings': 'My Ratings',
      'my_statistics': 'My Statistics',
      'social': 'Social',
      'share_profile': 'Share Profile',
      'invite_friends': 'Invite friends',
      'songs': 'songs',
      'albums_count': 'albums',
      'playlists_count': 'playlists',
      'friends': 'friends',
      'followers_count': 'followers',
      'view_music_journey': 'View your music journey',
      'all_music_ratings': 'All your music ratings',
      'view_listening_stats': 'View your listening statistics',
      'manage_app_settings': 'Manage app settings',
      'manage_notifications': 'Manage your notifications',
      'control_your_data': 'Control your data',
      'edit': 'Edit',
      
      // Messages/Conversations Page
      'new_group': 'New group',
      'no_conversations': 'No conversations yet',
      'start_conversation': 'Start a conversation',
      'no_results': 'No results found',
      'yesterday': 'Yesterday',
      'typing': 'typing...',
      'new_message': 'New message',
      
      // Create Content Page
      'add_to_playlist': 'Add to Playlist',
      'create_new_playlist': 'Create New Playlist',
      'view_my_playlists': 'View My Playlists',
      'search_music': 'Search music, artists, albums...',
      'write_review': 'Write a Review',
      'create_playlist': 'Create Playlist',
      
      // Notifications
      'notif_new_notification': 'New Notification',
      'notif_new_music_recommendation': 'New Music Recommendation 🎵',
      'notif_new_album_released': 'New Album Released! 🎤',
      'notif_trending_track': 'Trending Track 🔥',
      'notif_rating_reminder': 'Don\'t Forget to Rate ⭐',
      'notif_followed_you': 'followed you',
      'notif_liked_your_review': 'liked your review',
      'notif_commented_on_review': 'commented on your review',
      'notif_mentioned_you': 'mentioned you',
      'notif_new_follower': 'New Follower',
      'notif_review_liked': 'Review Liked',
      'notif_new_comment': 'New Comment',
      'notif_achievement_unlocked': '🏆 Achievement Unlocked!',
      'notif_playlist_collaborated': 'added you to playlist',
      
      // Register Page
      'start_music_journey': 'Start your music journey',
      'display_name': 'Display Name',
      'your_name': 'Your name',
      'username': 'Username',
      'your_username': 'Your username',
      'confirm_password': 'Confirm Password',
      'reenter_password': 'Re-enter your password',
      'accept_terms': 'I agree to the ',
      'terms_of_service': 'Terms of Service',
      'and': ' and ',
      'privacy_policy': 'Privacy Policy',
      'create_account': 'Create Account',
      'already_have_account': 'Already have an account? ',
      'log_in': 'Log In',
      
      // Edit Profile
      'profile_photo': 'Profile Photo',
      'change_photo': 'Change Photo',
      'full_name': 'Full Name',
      'bio': 'Bio',
      'tell_about_yourself': 'Tell us about yourself',
      'website': 'Website',
      'your_website': 'Your website URL',
      'location': 'Location',
      'your_location': 'Your location',
      'save_changes': 'Save Changes',
      'profile_updated': 'Profile updated successfully',
      'please_enter_display_name': 'Please enter your display name',
      'display_name_min_2': 'Display name must be at least 2 characters',
      'please_enter_username': 'Please enter a username',
      'username_min_3': 'Username must be at least 3 characters',
      'username_only_alphanumeric': 'Username can only contain letters, numbers and underscores',
    },
    'tr': {
      // Common
      'app_name': 'Tuniverse',
      'loading': 'Yükleniyor...',
      'error': 'Hata',
      'success': 'Başarılı',
      'cancel': 'İptal',
      'save': 'Kaydet',
      'delete': 'Sil',
      'edit': 'Düzenle',
      'share': 'Paylaş',
      'search': 'Ara',
      'filter': 'Filtrele',
      'settings': 'Ayarlar',
      'logout': 'Çıkış Yap',
      'profile': 'Profil',
      'back': 'Geri',
      'next': 'İleri',
      'done': 'Tamam',
      'skip': 'Geç',
      'yes': 'Evet',
      'no': 'Hayır',
      'ok': 'Tamam',
      'close': 'Kapat',
      
      // Navigation
      'home': 'Ana Sayfa',
      'discover': 'Keşfet',
      'library': 'Kütüphane',
      'messages': 'Mesajlar',
      'more': 'Daha Fazla',
      'create': 'Oluştur',
      
      // Auth
      'login': 'Giriş Yap',
      'signup': 'Kayıt Ol',
      'email': 'E-posta',
      'password': 'Şifre',
      'forgot_password': 'Şifremi Unuttum',
      'remember_me': 'Beni Hatırla',
      'or': 'veya',
      'continue_with_spotify': 'Spotify ile Devam Et',
      'continue_with_google': 'Google ile Devam Et',
      'no_account': 'Hesabınız yok mu? ',
      'have_account': 'Zaten hesabınız var mı? ',
      
      // Home
      'welcome_back': 'Tekrar Hoş Geldin',
      'new_releases': 'Yeni Çıkanlar',
      'trending': 'Trendler',
      'top_tracks': 'En İyi Parçalar',
      'popular': 'Popüler',
      'for_you': 'Senin İçin',
      
      // Discover
      'discover_music': 'Müzik Keşfet',
      'genres': 'Türler',
      'moods': 'Ruh Hali',
      'playlists': 'Çalma Listeleri',
      'artists': 'Sanatçılar',
      'albums': 'Albümler',
      'tracks': 'Parçalar',
      
      // Library
      'your_library': 'Kütüphanem',
      'liked_songs': 'Beğenilen Şarkılar',
      'saved_albums': 'Kaydedilen Albümler',
      'following': 'Takip Ettiklerim',
      'history': 'Geçmiş',
      
      // Messages
      'conversations': 'Sohbetler',
      'live_activity': 'Canlı Aktivite',
      'no_recent_activity': 'Son aktivite yok',
      'now_playing': 'Şimdi çalıyor',
      
      // Profile
      'edit_profile': 'Profili Düzenle',
      'followers': 'Takipçi',
      'following_count': 'Takip',
      'reviews': 'İncelemeler',
      'ratings': 'Puanlar',
      
      // Music
      'play': 'Çal',
      'pause': 'Duraklat',
      'next_track': 'Sonraki',
      'previous_track': 'Önceki',
      'add_to_library': 'Kütüphaneye Ekle',
      'remove_from_library': 'Kütüphaneden Çıkar',
      'add_to_playlist': 'Çalma Listesine Ekle',
      
      // Reviews
      'write_review': 'İnceleme Yaz',
      'your_rating': 'Puanınız',
      'your_review': 'İncelemeniz',
      'post_review': 'İncelemeyi Paylaş',
      'edit_review': 'İncelemeyi Düzenle',
      
      // Settings
      'account': 'Hesap',
      'notifications': 'Bildirimler',
      'privacy': 'Gizlilik',
      'theme': 'Tema',
      'language': 'Dil',
      'about': 'Hakkında',
      'help': 'Yardım ve Destek',
      'terms': 'Kullanım Şartları',
      'privacy_policy': 'Gizlilik Politikası',
      
      // Pro
      'get_pro': 'PRO Al',
      'upgrade_to_pro': 'PRO\'ya Yükselt',
      'pro_features': 'PRO Özellikler',
      'pro_member': 'PRO Üye',
      'subscribe': 'Abone Ol',
      'monthly': 'Aylık',
      'yearly': 'Yıllık',
      
      // Errors
      'error_occurred': 'Bir hata oluştu',
      'network_error': 'Ağ hatası',
      'try_again': 'Tekrar Dene',
      'no_internet': 'İnternet bağlantısı yok',
      
      // Home Page
      'good_morning': 'Günaydın',
      'good_afternoon': 'İyi Günler',
      'good_evening': 'İyi Akşamlar',
      'recently_played': 'Son Çalınanlar',
      'recommended': 'Önerilenler',
      'new_releases': 'Yeni Çıkanlar',
      'top_tracks': 'En İyi Parçalar',
      'popular_albums': 'Popüler Albümler',
      
      // Discover
      'featured': 'Öne Çıkanlar',
      'categories': 'Kategoriler',
      'browse_all': 'Tümüne Göz At',
      
      // Profile
      'my_profile': 'Profilim',
      'posts': 'Gönderiler',
      'activity': 'Aktivite',
      'statistics': 'İstatistikler',
      'listening_time': 'Dinleme Süresi',
      
      // More
      'gamification': 'Oyunlaştırma',
      'achievements': 'Başarımlar ve Rozetler',
      'streaks': 'Seriler',
      'leaderboards': 'Sıralama Tablosu',
      'analytics': 'Analitik ve İçgörüler',
      'offline': 'Çevrimdışı ve İndirmeler',
      'collaboration': 'Işbirliği',
      'events': 'Etkinlikler ve Konserler',
      'news': 'Müzik Haberleri',
      'discovery': 'Keşif',
      'personalization': 'Kişiselleştirme',
      'help_support': 'Yardım ve Destek',
      
      // Common Actions
      'view_all': 'Tümünü Gör',
      'see_more': 'Daha Fazla',
      'show_less': 'Daha Az',
      'load_more': 'Daha Fazla Yükle',
      'refresh': 'Yenile',
      'sort_by': 'Sıralama',
      'filter_by': 'Filtrele',
      
      // More Page Items
      'view_your_achievements': 'Başarımlarınızı görün',
      'listening_streaks_stats': 'Dinleme serileri ve istatistikler',
      'global_friends_rankings': 'Küresel ve arkadaş sıralamaları',
      'music_quiz': 'Müzik Bilgi Yarışması',
      'test_music_knowledge': 'Müzik bilginizi test edin',
      'weekly_challenges': 'Haftalık Görevler',
      'complete_challenges': 'Ödüller için görevleri tamamlayın',
      'listening_clock': 'Dinleme Saati',
      'when_listen_most': 'En çok ne zaman dinliyorsunuz?',
      'music_map': 'Müzik Haritası',
      'discover_by_location': 'Sanatçıları konuma göre keşfedin',
      'taste_profile': 'Zevk Profili',
      'music_personality': 'Müzik kişiliğiniz',
      'yearly_wrapped': 'Yıllık Özet',
      'year_in_music': 'Yılınız müzikte',
      'friends_comparison': 'Arkadaş Karşılaştırması',
      'compare_taste': 'Müzik zevkini karşılaştır',
      'downloaded_tracks': 'İndirilen Parçalar',
      'manage_offline': 'Çevrimdışı müzikleri yönet',
      'storage_cache': 'Depolama ve Önbellek',
      'manage_storage': 'Uygulama depolamasını yönet',
      'group_sessions': 'Grup Oturumları',
      'listen_together': 'Gerçek zamanlı birlikte dinle',
      'music_rooms': 'Müzik Odaları',
      'join_rooms': 'Canlı dinleme odalarına katıl',
      'upcoming_events': 'Yakında Olan Etkinlikler',
      'concerts_near': 'Yakınınızdaki konserler ve etkinlikler',
      'news_feed': 'Haber Akışı',
      'latest_news': 'Son müzik haberleri ve güncellemeler',
      'daily_mix': 'Günlük Karışım',
      'personalized_playlists': 'Kişiselleştirilmiş çalma listeleri',
      'release_radar': 'Yeni Çıkanlar Radarı',
      'new_from_favorites': 'Favorilerden yeni müzik',
      'decade_explorer': 'On Yıl Keşfi',
      '60s_2020s_explorer': '60\'lardan 2020\'lere müzik keşfi',
      'genre_deep_dive': 'Tür Derinine Dalış',
      'explore_genres': 'Türleri derinlemesine keşfedin',
      'mood_detection': 'Ruh Hali Algılama',
      'ai_mood_analysis': 'YZ ruh hali analizi ve çalma listesi oluşturma',
      'now_playing': 'Şimdi Çalıyor',
      'fullscreen_player': 'Görselleştirici ile tam ekran müzik çalar',
      'help_faq': 'Yardım ve SSS',
      'common_questions': 'Sık sorulan sorular ve destek',
      
      // Home Page Specific
      'search_placeholder': 'Müzik, sanatçı, albüm ara...',
      'global_new_releases': 'Dünya Genelinde Yeni Çıkanlar',
      'popular_worldwide': 'Dünya Genelinde Popüler',
      'popular_new_toggle': 'POPÜLER',
      'new_toggle': 'YENİ',
      'trending_this_week': 'Bu Haftanın Trendleri',
      'community_reviews': 'Topluluk İncelemeleri',
      'add_comment': 'Yorum Ekle',
      'write_comment': 'Bir yorum yazın...',
      'post_comment': 'Yorumu Paylaş',
      'comment_added': 'Yorum eklendi',
      'no_reviews_yet': 'Henüz inceleme yok',
      'be_first_share': 'İlk paylaşan siz olun!',
      'trending_now': 'Şu An Trend',
      'discover_whats_hot': 'Bu haftanın en popülerlerini keşfet',
      'explore': 'Keşfet',
      'my_library': 'Kütüphanem',
      'stats': 'İstatistikler',
      'discover_btn': 'Keşfet',
      'reviewed': 'inceledi',
      'connect_spotify_history': 'Spotify\'ı bağlayın ve dinleme geçmişinizi görün',
      'could_not_load_track': 'Parça detayları yüklenemedi',
      'quick_actions': 'Hızlı İşlemler',
      'comment': 'Yorum',
      
      // Discover Page
      'trending': 'Trendler',
      'hot_new_releases': 'Sıcak Yeni Çıkanlar',
      'popular_this_week': 'Bu Haftanın Popülerleri',
      'top_lists': 'En İyi Listeler',
      'top_250_albums': 'En İyi 250 Albüm',
      'top_250_tracks': 'En İyi 250 Parça',
      'top_250_artists': 'En İyi 250 Sanatçı',
      'most_popular_albums': 'En Popüler Albümler',
      'most_popular_artists': 'En Popüler Sanatçılar',
      'most_popular_tracks': 'En Popüler Parçalar',
      'for_you': 'Senin İçin',
      'recommended': 'Önerilenler',
      'to_follow': 'Takip Et',
      'community': 'Topluluk',
      'trending_users': 'Trend Kullanıcılar',
      'explore_reviews': 'İncelemeleri Keşfet',
      'explore_lists': 'Listeleri Keşfet',
      'lists_by_friends': 'Arkadaşların Listeleri',
      
      // Profile Page
      'liked_songs': 'Beğenilen Şarkılar',
      'my_albums': 'Albümlerim',
      'my_playlists': 'Çalma Listelerim',
      'listening_history': 'Dinleme Geçmişi',
      'my_ratings': 'Puanlarım',
      'my_statistics': 'İstatistiklerim',
      'social': 'Sosyal',
      'share_profile': 'Profili Paylaş',
      'invite_friends': 'Arkadaşları davet et',
      'songs': 'şarkı',
      'albums_count': 'albüm',
      'playlists_count': 'çalma listesi',
      'friends': 'arkadaş',
      'followers_count': 'takipçi',
      'view_music_journey': 'Müzik yolculuğunuzu görün',
      'all_music_ratings': 'Tüm müzik puanlarınız',
      'view_listening_stats': 'Dinleme istatistiklerinizi görün',
      'manage_app_settings': 'Uygulama ayarlarını yönetin',
      'manage_notifications': 'Bildirimlerinizi yönetin',
      'control_your_data': 'Verilerinizi kontrol edin',
      'edit': 'Düzenle',
      
      // Messages/Conversations Page
      'new_group': 'Yeni grup',
      'no_conversations': 'Henüz sohbet yok',
      'start_conversation': 'Sohbet başlat',
      'no_results': 'Sonuç bulunamadı',
      'yesterday': 'Dün',
      'typing': 'yazıyor...',
      'new_message': 'Yeni mesaj',
      
      // Create Content Page
      'add_to_playlist': 'Çalma Listesine Ekle',
      'create_new_playlist': 'Yeni Çalma Listesi Oluştur',
      'view_my_playlists': 'Çalma Listelerimi Gör',
      'search_music': 'Müzik, sanatçı, albüm ara...',
      'write_review': 'İnceleme Yaz',
      'create_playlist': 'Çalma Listesi Oluştur',
      
      // Notifications
      'notif_new_notification': 'Yeni Bildirim',
      'notif_new_music_recommendation': 'Yeni Müzik Önerisi 🎵',
      'notif_new_album_released': 'Yeni Albüm Çıktı! 🎤',
      'notif_trending_track': 'Trend Şarkı 🔥',
      'notif_rating_reminder': 'Şarkıyı Puanlamayı Unutmayın ⭐',
      'notif_followed_you': 'seni takip etti',
      'notif_liked_your_review': 'incelemenizi beğendi',
      'notif_commented_on_review': 'incelemenize yorum yaptı',
      'notif_mentioned_you': 'senden bahsetti',
      'notif_new_follower': 'Yeni Takipçi',
      'notif_review_liked': 'İnceleme Beğenildi',
      'notif_new_comment': 'Yeni Yorum',
      'notif_achievement_unlocked': '🏆 Başarım Kazandınız!',
      'notif_playlist_collaborated': 'sizi çalma listesine ekledi',
      
      // Register Page
      'start_music_journey': 'Müzik yolculuğunuza başlayın',
      'display_name': 'Görünen Ad',
      'your_name': 'Adınız',
      'username': 'Kullanıcı Adı',
      'your_username': 'Kullanıcı adınız',
      'confirm_password': 'Şifreyi Onayla',
      'reenter_password': 'Şifrenizi tekrar girin',
      'accept_terms': 'Kabul ediyorum: ',
      'terms_of_service': 'Kullanım Şartları',
      'and': ' ve ',
      'privacy_policy': 'Gizlilik Politikası',
      'create_account': 'Hesap Oluştur',
      'already_have_account': 'Zaten hesabınız var mı? ',
      'log_in': 'Giriş Yap',
      
      // Edit Profile
      'profile_photo': 'Profil Fotoğrafı',
      'change_photo': 'Fotoğrafı Değiştir',
      'full_name': 'Tam Ad',
      'bio': 'Biyografi',
      'tell_about_yourself': 'Kendinizden bahsedin',
      'website': 'Web Sitesi',
      'your_website': 'Web sitenizin adresi',
      'location': 'Konum',
      'your_location': 'Konumunuz',
      'save_changes': 'Değişiklikleri Kaydet',
      'profile_updated': 'Profil başarıyla güncellendi',
      'please_enter_display_name': 'Lütfen görünen adınızı girin',
      'display_name_min_2': 'Görünen ad en az 2 karakter olmalıdır',
      'please_enter_username': 'Lütfen kullanıcı adı girin',
      'username_min_3': 'Kullanıcı adı en az 3 karakter olmalıdır',
      'username_only_alphanumeric': 'Kullanıcı adı sadece harf, sayı ve alt çizgi içerebilir',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
