import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import 'core/theme/app_theme.dart'; // Replaced with enhanced_theme.dart
import 'core/theme/enhanced_theme.dart';
import 'core/constants/app_constants.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/services/firebase_service.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/smart_notification_service.dart';
import 'shared/services/fcm_service.dart';
import 'shared/services/enhanced_spotify_service.dart';
import 'shared/services/enhanced_auth_service.dart';
import 'shared/services/simple_auth_service.dart';
import 'shared/services/firebase_bypass_auth_service.dart';
import 'shared/services/popular_tracks_seed_service.dart';
import 'shared/services/music_player_service.dart';
import 'shared/services/queue_service.dart';
import 'features/auth/presentation/pages/enhanced_login_page.dart';
import 'features/auth/presentation/pages/enhanced_signup_page.dart';
import 'features/auth/presentation/pages/spotify_connect_page.dart';
import 'features/auth/presentation/pages/spotify_callback_page.dart';
import 'features/home/presentation/pages/music_share_home_page.dart';
import 'features/discover/presentation/pages/discover_page.dart';
import 'features/discover/presentation/pages/discover_search_page.dart';
import 'features/discover/presentation/pages/discover_section_page.dart';
import 'features/discover/presentation/pages/genre_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/pages/letterboxd_profile_page.dart';
import 'features/profile/presentation/pages/modern_profile_page.dart';
import 'features/search/presentation/pages/advanced_search_page.dart';
import 'features/search/presentation/pages/modern_search_page.dart';
import 'features/search/presentation/pages/search_results_page.dart';
import 'features/statistics/presentation/pages/statistics_page.dart';
import 'features/statistics/presentation/pages/listening_stats_page.dart';
import 'features/music/presentation/pages/my_ratings_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/presentation/pages/modern_settings_page.dart';
import 'features/settings/presentation/pages/edit_profile_page.dart';
import 'features/settings/presentation/pages/privacy_security_page.dart';
import 'features/settings/presentation/pages/connected_accounts_page.dart';
import 'features/settings/presentation/pages/blocked_users_page.dart';
import 'features/activity/presentation/pages/activity_feed_page.dart';
import 'features/settings/presentation/pages/notification_settings_page.dart';
import 'shared/widgets/feedback/feedback_widgets.dart';
import 'features/legal/presentation/pages/terms_of_service_page.dart';
import 'features/legal/presentation/pages/privacy_policy_page.dart';
import 'shared/services/app_rating_service.dart';
import 'shared/services/crashlytics_service.dart';
import 'shared/services/firebase_analytics_service.dart';
import 'shared/services/connectivity_service.dart';
import 'shared/widgets/connectivity/connectivity_banner.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/social/presentation/pages/social_feed_page.dart';
import 'features/social/presentation/pages/user_profile_page.dart';
import 'features/diary/presentation/pages/music_diary_page.dart';
import 'features/lists/presentation/pages/music_lists_page.dart';
import 'features/reviews/presentation/pages/reviews_page.dart';
import 'features/reviews/presentation/pages/modern_reviews_page.dart';
import 'features/reviews/presentation/pages/review_detail_page.dart';
import 'features/music/presentation/pages/spotify_tracks_page.dart';
import 'features/music/presentation/pages/spotify_albums_page.dart';
// import 'features/music/presentation/pages/create_playlist_page.dart'; // Removed - using playlists version
import 'features/music/presentation/pages/turkey_top_tracks_page.dart';
import 'features/music/presentation/pages/turkey_top_albums_page.dart';
import 'features/music/presentation/pages/track_detail_page.dart';
import 'features/music/presentation/pages/artist_profile_page.dart';
import 'features/music/presentation/pages/album_detail_page.dart';
import 'features/favorites/presentation/pages/favorites_page.dart';
import 'features/recently_played/recently_played_page.dart';
import 'features/playlists/user_playlists_page.dart';
import 'features/playlists/create_playlist_page.dart';
import 'features/playlists/import_spotify_playlists_page.dart';
import 'features/playlists/playlist_detail_page.dart';
import 'features/playlists/playlist_loader_page.dart';
import 'features/playlists/discover_playlists_page.dart';
// import 'features/playlists/qr_scanner_page.dart';  // Not supported on web
import 'features/playlists/smart_playlists_page.dart';
import 'features/messaging/modern_conversations_page.dart';
import 'features/create/presentation/pages/create_content_page.dart';
import 'features/music/presentation/pages/queue_page.dart';
import 'shared/models/music_list.dart';
import 'shared/widgets/mini_player/mini_player.dart';
import 'features/more/presentation/pages/more_page.dart';
import 'features/collaboration/presentation/pages/group_sessions_page.dart';
import 'features/gamification/presentation/pages/achievements_page.dart';
import 'features/gamification/presentation/pages/streaks_page.dart';
import 'features/gamification/presentation/pages/leaderboards_page.dart';
import 'features/offline/presentation/pages/offline_tracks_page.dart';
import 'features/offline/presentation/pages/storage_management_page.dart';
import 'features/gamification/presentation/pages/music_quiz_page.dart';
import 'features/quiz/presentation/pages/quiz_main_page.dart';
import 'features/quiz/presentation/pages/guess_song_setup_page.dart';
import 'features/quiz/presentation/pages/guess_artist_setup_page.dart';
import 'features/quiz/presentation/pages/quiz_game_page.dart';
import 'features/quiz/presentation/pages/quiz_result_page.dart';
import 'features/quiz/presentation/pages/leaderboard_page.dart' as quiz_leaderboard;
import 'shared/models/quiz_question.dart';
import 'features/gamification/presentation/pages/weekly_challenges_page.dart';
import 'features/analytics/presentation/pages/listening_clock_page.dart';
import 'features/analytics/presentation/pages/music_map_page.dart';
import 'features/analytics/presentation/pages/taste_profile_page.dart';
import 'features/analytics/presentation/pages/yearly_wrapped_page.dart';
import 'features/analytics/presentation/pages/friends_comparison_page.dart';
import 'features/collaboration/presentation/pages/music_rooms_page.dart';
import 'features/collaboration/presentation/pages/group_session_detail_page.dart';
import 'features/discovery/presentation/pages/daily_mix_page.dart';
import 'package:app_links/app_links.dart';
import 'features/discovery/presentation/pages/release_radar_page.dart';
import 'features/discovery/presentation/pages/decade_explorer_page.dart';
import 'features/discovery/presentation/pages/genre_deep_dive_page.dart';
import 'features/events/presentation/pages/events_page.dart';
import 'features/events/presentation/pages/event_detail_page.dart';
import 'shared/models/event.dart';
import 'features/news/presentation/pages/news_feed_page.dart';
import 'features/news/presentation/pages/news_detail_page.dart';
import 'shared/models/news_article.dart';
import 'features/auth/presentation/pages/social_onboarding_page.dart';
// import 'features/developer/presentation/pages/crashlytics_test_page.dart';  // Not supported on web
// import 'package:flutter_native_splash/flutter_native_splash.dart';  // Web doesn't need splash
// import 'shared/services/admob_service.dart';  // Web doesn't support AdMob
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/language_provider.dart';
import 'core/utils/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Web doesn't need native splash
  // if (!kIsWeb) {
  //   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // }
  
  await FirebaseService.initialize();
  
  // Initialize Crashlytics (mobile only)
  if (!kIsWeb) {
    // await CrashlyticsService.initialize();
  }
  
  // Initialize Firebase Analytics
  await FirebaseAnalyticsService.initialize();
  
  // Initialize Connectivity Service
  await ConnectivityService.initialize();
  
  // Initialize Notifications (mobile only)
  if (!kIsWeb) {
    await NotificationService.initialize();
    await SmartNotificationService.initialize();
    await FCMService.initialize(
      onNotificationTap: (data) {
        // Handle notification tap navigation
      },
    );
  }
  
  // Initialize Enhanced Spotify Service
  await EnhancedSpotifyService.loadConnectionState();
  
  // Initialize Music Player Service
  await MusicPlayerService.initialize();
  
  // Initialize Queue Service
  await QueueService.initialize();
  
  // Initialize popular tracks seed (background, don't wait)
  PopularTracksSeedService.initializeSeed();
  
  // Initialize App Rating (mobile only)
  if (!kIsWeb) {
    // await AppRatingService.recordFirstLaunch();
  }
  
  // Initialize AdMob (mobile only)
  if (!kIsWeb) {
    // await AdMobService.initialize();
  }
  
  runApp(const ProviderScope(child: MusicShareApp()));
}

class MusicShareApp extends StatelessWidget {
  const MusicShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final locale = ref.watch(languageProvider);
        
        return MaterialApp.router(
          title: AppConstants.appName,
          theme: EnhancedTheme.lightTheme,
          darkTheme: EnhancedTheme.darkTheme,
          themeMode: themeMode,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
          builder: (context, child) => ConnectivityBanner(
            child: DeepLinkListener(child: child!),
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/login',  // Go directly to login on web
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      redirect: (context, state) => kIsWeb ? '/login' : null,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      redirect: (context, state) => kIsWeb ? '/login' : null,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const EnhancedLoginPage(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const EnhancedSignupPage(),
    ),
    GoRoute(
      path: '/spotify-callback',
      name: 'spotify-callback',
      builder: (context, state) {
        final code = state.uri.queryParameters['code'];
        final stateParam = state.uri.queryParameters['state'];
        final error = state.uri.queryParameters['error'];
        return SpotifyCallbackPage(
          code: code,
          state: stateParam,
          error: error,
        );
      },
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/profile-tab',
      name: 'profile-tab',
      builder: (context, state) => const MainNavigationPage(initialTab: 4),
    ),
        GoRoute(
          path: '/spotify-connect',
          name: 'spotify-connect',
          builder: (context, state) => const SpotifyConnectPage(),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const ModernSearchPage(),
        ),
        GoRoute(
          path: '/search-results',
          name: 'search-results',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return SearchResultsPage(
              query: extra['query'] as String,
              type: extra['type'] as String,
              results: extra['results'] as List<Map<String, dynamic>>,
            );
          },
        ),
        GoRoute(
          path: '/discover',
          name: 'discover',
          builder: (context, state) => const DiscoverPage(),
        ),
        GoRoute(
          path: '/discover-search',
          name: 'discover-search',
          builder: (context, state) => const DiscoverSearchPage(),
        ),
        GoRoute(
          path: '/discover-section/:type/:title',
          name: 'discover-section',
          builder: (context, state) {
            final type = state.pathParameters['type']!;
            final title = state.pathParameters['title']!;
            return DiscoverSectionPage(title: title, sectionType: type);
          },
        ),
        GoRoute(
          path: '/genre/:genre',
          name: 'genre',
          builder: (context, state) {
            final genre = state.pathParameters['genre']!;
            return GenrePage(genre: genre);
          },
        ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsPage(),
      ),
      GoRoute(
        path: '/listening-stats',
        name: 'listening-stats',
        builder: (context, state) => const ListeningStatsPage(),
      ),
      GoRoute(
        path: '/my-ratings',
        name: 'my-ratings',
        builder: (context, state) => const MyRatingsPage(),
      ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const SocialFeedPage(),
      ),
      GoRoute(
        path: '/diary',
        name: 'diary',
        builder: (context, state) => const MusicDiaryPage(),
      ),
      GoRoute(
        path: '/lists',
        name: 'lists',
        builder: (context, state) => const MusicListsPage(),
      ),
      GoRoute(
        path: '/reviews',
        name: 'reviews',
        builder: (context, state) => const ModernReviewsPage(),
      ),
      GoRoute(
        path: '/review/:reviewId',
        name: 'review-detail',
        builder: (context, state) {
          final reviewId = state.pathParameters['reviewId']!;
          final initialData = state.extra as Map<String, dynamic>?;
          return ReviewDetailPage(
            reviewId: reviewId,
            initialData: initialData,
          );
        },
      ),
      GoRoute(
        path: '/spotify-tracks',
        name: 'spotify-tracks',
        builder: (context, state) => const SpotifyTracksPage(),
      ),
      GoRoute(
        path: '/spotify-albums',
        name: 'spotify-albums',
        builder: (context, state) => const SpotifyAlbumsPage(),
      ),
      GoRoute(
        path: '/track-detail',
        name: 'track-detail',
        builder: (context, state) {
          final track = state.extra as Map<String, dynamic>;
          return TrackDetailPage(track: track);
        },
      ),
      GoRoute(
        path: '/turkey-top-tracks',
        name: 'turkey-top-tracks',
        builder: (context, state) => const TurkeyTopTracksPage(),
      ),
      GoRoute(
        path: '/turkey-top-albums',
        name: 'turkey-top-albums',
        builder: (context, state) => const TurkeyTopAlbumsPage(),
      ),
      GoRoute(
        path: '/artist-profile',
        name: 'artist-profile',
        builder: (context, state) {
          final artist = state.extra as Map<String, dynamic>;
          return ArtistProfilePage(artist: artist);
        },
      ),
      GoRoute(
        path: '/album-detail',
        name: 'album-detail',
        builder: (context, state) {
          final album = state.extra as Map<String, dynamic>;
          return AlbumDetailPage(album: album);
        },
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: '/queue',
        name: 'queue',
        builder: (context, state) => const QueuePage(),
      ),
      GoRoute(
        path: '/notification-settings',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/recently-played',
        name: 'recently-played',
        builder: (context, state) => const RecentlyPlayedPage(),
      ),
      GoRoute(
        path: '/playlists',
        name: 'playlists',
        builder: (context, state) => const UserPlaylistsPage(showBackButton: true),
      ),
      GoRoute(
        path: '/create-playlist',
        name: 'create-playlist',
        builder: (context, state) => const CreatePlaylistPage(),
      ),
      GoRoute(
        path: '/import-spotify-playlists',
        name: 'import-spotify-playlists',
        builder: (context, state) => const ImportSpotifyPlaylistsPage(),
      ),
      GoRoute(
        path: '/playlist-detail',
        name: 'playlist-detail',
        builder: (context, state) {
          final playlist = state.extra as MusicList;
          return PlaylistDetailPage(playlist: playlist);
        },
      ),
      GoRoute(
        path: '/playlist/:playlistId',
        name: 'playlist-by-id',
        builder: (context, state) {
          final playlistId = state.pathParameters['playlistId']!;
          return PlaylistLoaderPage(playlistId: playlistId);
        },
      ),
      // QR scanner not supported on web
      // GoRoute(
      //   path: '/qr-scanner',
      //   name: 'qr-scanner',
      //   builder: (context, state) => const QrScannerPage(),
      // ),
      GoRoute(
        path: '/smart-playlists',
        name: 'smart-playlists',
        builder: (context, state) => const SmartPlaylistsPage(),
      ),
      GoRoute(
        path: '/user-profile/:userId',
        name: 'user-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final username = state.uri.queryParameters['username'] ?? 'User';
          return UserProfilePage(
            userId: userId,
            username: username,
          );
        },
      ),
      GoRoute(
        path: '/user/:userId',
        name: 'user',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final username = state.uri.queryParameters['username'] ?? 'User';
          return UserProfilePage(
            userId: userId,
            username: username,
          );
        },
      ),
      GoRoute(
        path: '/conversations',
        name: 'conversations',
        builder: (context, state) => const ModernConversationsPage(),
      ),
    // More menu route
    GoRoute(
      path: '/more',
      name: 'more',
      builder: (context, state) => const MorePage(),
    ),
    // Group Sessions
    GoRoute(
      path: '/group-sessions',
      name: 'group-sessions',
      builder: (context, state) => const GroupSessionsPage(),
    ),
    // Gamification routes
    GoRoute(
      path: '/achievements',
      name: 'achievements',
      builder: (context, state) => const AchievementsPage(),
    ),
    GoRoute(
      path: '/streaks',
      name: 'streaks',
      builder: (context, state) => const StreaksPage(),
    ),
    GoRoute(
      path: '/leaderboards',
      name: 'leaderboards',
      builder: (context, state) => const LeaderboardsPage(),
    ),
    GoRoute(
      path: '/music-quiz',
      name: 'music-quiz',
      builder: (context, state) => const MusicQuizPage(),
    ),
    // New Quiz System Routes
    GoRoute(
      path: '/quiz',
      name: 'quiz',
      builder: (context, state) => const QuizMainPage(),
    ),
    GoRoute(
      path: '/quiz/guess-song-setup',
      name: 'quiz-guess-song-setup',
      builder: (context, state) => const GuessSongSetupPage(),
    ),
    GoRoute(
      path: '/quiz/guess-artist-setup',
      name: 'quiz-guess-artist-setup',
      builder: (context, state) => const GuessArtistSetupPage(),
    ),
    GoRoute(
      path: '/quiz/game',
      name: 'quiz-game',
      builder: (context, state) {
        final session = state.extra as QuizSession;
        return QuizGamePage(session: session);
      },
    ),
    GoRoute(
      path: '/quiz/result',
      name: 'quiz-result',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return QuizResultPage(
          session: data['session'] as QuizSession,
          score: data['score'] as int,
        );
      },
    ),
    GoRoute(
      path: '/leaderboard',
      name: 'leaderboard',
      builder: (context, state) => const quiz_leaderboard.LeaderboardPage(),
    ),
    GoRoute(
      path: '/weekly-challenges',
      name: 'weekly-challenges',
      builder: (context, state) => const WeeklyChallengesPage(),
    ),
    GoRoute(
      path: '/listening-clock',
      name: 'listening-clock',
      builder: (context, state) => const ListeningClockPage(),
    ),
    GoRoute(
      path: '/music-map',
      name: 'music-map',
      builder: (context, state) => const MusicMapPage(),
    ),
    GoRoute(
      path: '/taste-profile',
      name: 'taste-profile',
      builder: (context, state) => const TasteProfilePage(),
    ),
    GoRoute(
      path: '/yearly-wrapped',
      name: 'yearly-wrapped',
      builder: (context, state) => const YearlyWrappedPage(),
    ),
    GoRoute(
      path: '/friends-comparison',
      name: 'friends-comparison',
      builder: (context, state) => const FriendsComparisonPage(),
    ),
    GoRoute(
      path: '/offline-tracks',
      name: 'offline-tracks',
      builder: (context, state) => const OfflineTracksPage(),
    ),
    GoRoute(
      path: '/storage-management',
      name: 'storage-management',
      builder: (context, state) => const StorageManagementPage(),
    ),
    GoRoute(
      path: '/music-rooms',
      name: 'music-rooms',
      builder: (context, state) => const MusicRoomsPage(),
    ),
    GoRoute(
      path: '/group-session-detail',
      name: 'group-session-detail',
      builder: (context, state) {
        final sessionId = state.extra as String? ?? '';
        return GroupSessionDetailPage(sessionId: sessionId);
      },
    ),
    GoRoute(
      path: '/daily-mix',
      name: 'daily-mix',
      builder: (context, state) => const DailyMixPage(),
    ),
    GoRoute(
      path: '/release-radar',
      name: 'release-radar',
      builder: (context, state) => const ReleaseRadarPage(),
    ),
    GoRoute(
      path: '/decade-explorer',
      name: 'decade-explorer',
      builder: (context, state) => const DecadeExplorerPage(),
    ),
    GoRoute(
      path: '/genre-deep-dive',
      name: 'genre-deep-dive',
      builder: (context, state) => const GenreDeepDivePage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const ModernSettingsPage(),
    ),
    // Crashlytics test not supported on web
    // GoRoute(
    //   path: '/crashlytics-test',
    //   name: 'crashlytics-test',
    //   builder: (context, state) => const CrashlyticsTestPage(),
    // ),
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/privacy-security',
      name: 'privacy-security',
      builder: (context, state) => const PrivacySecurityPage(),
    ),
    GoRoute(
      path: '/connected-accounts',
      name: 'connected-accounts',
      builder: (context, state) => const ConnectedAccountsPage(),
    ),
    GoRoute(
      path: '/blocked-users',
      name: 'blocked-users',
      builder: (context, state) => const BlockedUsersPage(),
    ),
    GoRoute(
      path: '/activity',
      name: 'activity',
      builder: (context, state) => const ActivityFeedPage(),
    ),
    GoRoute(
      path: '/feedback',
      name: 'feedback',
      builder: (context, state) => const FeedbackPage(),
    ),
    GoRoute(
      path: '/terms',
      name: 'terms',
      builder: (context, state) => const TermsOfServicePage(),
    ),
    GoRoute(
      path: '/privacy',
      name: 'privacy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    // Events routes
    GoRoute(
      path: '/events',
      name: 'events',
      builder: (context, state) => const EventsPage(),
    ),
    GoRoute(
      path: '/event-detail',
      name: 'event-detail',
      builder: (context, state) {
        final event = state.extra as MusicEvent;
        return EventDetailPage(event: event);
      },
    ),
    // News routes
    GoRoute(
      path: '/news',
      name: 'news',
      builder: (context, state) => const NewsFeedPage(),
    ),
    GoRoute(
      path: '/news-detail',
      name: 'news-detail',
      builder: (context, state) {
        final article = state.extra as NewsArticle;
        return NewsDetailPage(article: article);
      },
    ),
  ],
);

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    print('🏗️ AuthWrapper building...');
    return StreamBuilder(
      stream: FirebaseService.auth.authStateChanges(),
      builder: (context, AsyncSnapshot authSnapshot) {
        print('🔐 Auth state changed: hasData=${authSnapshot.hasData}, data=${authSnapshot.data}');
        // Not logged in
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          print('❌ No auth data, showing login page');
          return const EnhancedLoginPage();
        }

        final user = authSnapshot.data;
        print('✅ User authenticated: ${user.uid}');
        
        // Listen to user document changes in Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseService.firestore
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userDoc = userSnapshot.data;
            if (userDoc != null && userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>?;
              final onboardingCompleted = data?['onboardingCompleted'] as bool? ?? true;
              final spotifyProfile = data?['spotifyProfile'] as Map<String, dynamic>?;
              final googleProfile = data?['googleProfile'] as Map<String, dynamic>?;
              final provider = data?['provider'] as String?;

              print('🔍 AuthWrapper check:');
              print('   - User ID: ${user.uid}');
              print('   - onboardingCompleted: $onboardingCompleted');
              print('   - provider: $provider');
              print('   - has spotifyProfile: ${spotifyProfile != null}');
              print('   - has googleProfile: ${googleProfile != null}');

              if (!onboardingCompleted) {
                if (spotifyProfile != null) {
                  print('✅ Showing Spotify onboarding page!');
                  return SocialOnboardingPage(
                    profile: spotifyProfile,
                    userId: user.uid,
                    provider: SocialProvider.spotify,
                  );
                } else if (googleProfile != null) {
                  print('✅ Showing Google onboarding page!');
                  return SocialOnboardingPage(
                    profile: googleProfile,
                    userId: user.uid,
                    provider: SocialProvider.google,
                  );
                }
              }
            }

            return const MainNavigationPage();
          },
        );
      },
    );
  }
}


class DeepLinkListener extends StatefulWidget {
  final Widget child;
  const DeepLinkListener({super.key, required this.child});
  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    try {
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) _handleUri(initialLink);
    } catch (_) {}
    appLinks.uriLinkStream.listen((uri) {
      if (!mounted || uri == null) return;
      _handleUri(uri);
    }, onError: (_) {});
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'tuniverse' && uri.host == 'callback') {
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];
      
      // Handle Spotify callback directly
      if (code != null && state != null) {
        _handleSpotifyCallback(code, state);
      }
    }
  }
  
  Future<void> _handleSpotifyCallback(String code, String state) async {
    try {
      final success = await EnhancedSpotifyService.handleAuthCallback(code, state);
      if (success) {
        print('Spotify authentication successful!');
        
        // Get Spotify user profile
        final spotifyProfile = await EnhancedSpotifyService.fetchUserProfile();
        if (spotifyProfile != null) {
          await _createFirebaseAccountFromSpotify(spotifyProfile);
        }
      } else {
        print('Spotify authentication failed');
      }
    } catch (e) {
      print('Error handling Spotify callback: $e');
    }
  }
  
  Future<void> _createFirebaseAccountFromSpotify(Map<String, dynamic> spotifyProfile) async {
    try {
      final email = spotifyProfile['email'] as String?;
      final displayName = spotifyProfile['display_name'] as String?;
      final profileImageUrl = spotifyProfile['images']?[0]?['url'] as String?;
      final spotifyId = spotifyProfile['id'] as String;
      
      if (email != null) {
        // Check if user already exists with Firebase Auth
        final currentUser = FirebaseService.auth.currentUser;
        if (currentUser == null) {
          // Generate a random password for Spotify-created accounts
          final randomPassword = _generateRandomPassword();
          
          bool accountExists = false;
          try {
            // Try to create a new account with email
            await FirebaseService.auth.createUserWithEmailAndPassword(
              email: email,
              password: randomPassword,
            );
          } catch (e) {
            if (e.toString().contains('email-already-in-use')) {
              accountExists = true;
              print('Account already exists with this email');
            } else {
              print('Account creation error: $e');
            }
          }
          
          // Check auth state directly (workaround for type cast bug)
          await Future.delayed(const Duration(milliseconds: 500));
          final newUser = FirebaseService.auth.currentUser;
          
          if (newUser != null) {
            if (!accountExists) {
              // Create comprehensive user document for new account
              try {
                await FirebaseService.firestore.collection('users').doc(newUser.uid).set({
                  'uid': newUser.uid,
                  'email': email,
                  'displayName': displayName ?? email.split('@')[0],
                  'username': _generateUsernameFromSpotify(spotifyId, displayName),
                  'profileImageUrl': profileImageUrl ?? '',
                  'bio': '',
                  'spotifyConnected': true,
                  'spotifyId': spotifyId,
                  'spotifyProfile': spotifyProfile,
                'totalSongsRated': 0,
                  'totalAlbumsRated': 0,
                  'totalReviews': 0,
                  'provider': 'spotify',
                  'onboardingCompleted': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              print('\u2705 Firebase account created from Spotify profile!');
                // Auth state will trigger AuthWrapper to check onboarding
              } catch (e) {
                print('Error creating Firestore document: $e');
              }
            }
          } else if (accountExists) {
            // Account exists but not signed in - find and update the user
            print('\u2139\ufe0f Account exists. User should sign in with their existing email/password first, then connect Spotify.');
          } else {
            print('\u274c Failed to create Firebase account');
          }
        } else {
          // User already exists and signed in, just update Spotify connection
          try {
            await FirebaseService.firestore.collection('users').doc(currentUser.uid).update({
              'spotifyConnected': true,
              'spotifyId': spotifyId,
              'spotifyProfile': spotifyProfile,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('Spotify connected to existing Firebase account');
          } catch (e) {
            print('Error updating Spotify connection: $e');
          }
        }
      }
    } catch (e) {
      print('Error creating Firebase account from Spotify: $e');
    }
  }
  
  String _generateUsernameFromSpotify(String spotifyId, String? displayName) {
    final base = displayName?.toLowerCase().replaceAll(' ', '').replaceAll(RegExp(r'[^a-z0-9]'), '') ?? spotifyId;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '${base.length > 10 ? base.substring(0, 10) : base}$timestamp';
  }
  
  String _generateRandomPassword() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'Spfy!$now@';
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MainNavigationPage extends riverpod.ConsumerStatefulWidget {
  final int initialTab;
  
  const MainNavigationPage({super.key, this.initialTab = 0});

  @override
  riverpod.ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends riverpod.ConsumerState<MainNavigationPage> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    
    // Pulse animation setup
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const MusicShareHomePage(),
    const DiscoverPage(),
    const CreateContentPage(),
    const ModernConversationsPage(),
    const ModernProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context) && !isDesktop;
    final user = FirebaseService.auth.currentUser;
    
    if (isDesktop) {
      // Desktop layout with sidebar
      return Scaffold(
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 280,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  // Logo
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Image.asset('assets/images/logos/logo.png', height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 40)),
                        const SizedBox(width: 12),
                        const Text(
                          'Tuniverse',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // User Profile
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E5E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                              child: user.photoURL == null ? const Icon(Icons.person) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ?? 'User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user.email ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Navigation items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildDesktopNavItem(context, Icons.home, AppLocalizations.of(context).t('home'), 0),
                        _buildDesktopNavItem(context, Icons.explore, AppLocalizations.of(context).t('discover'), 1),
                        _buildDesktopNavItem(context, Icons.add_circle, AppLocalizations.of(context).t('create'), 2),
                        _buildDesktopNavItem(context, Icons.chat_bubble_outline, AppLocalizations.of(context).t('messages'), 3),
                        _buildDesktopNavItem(context, Icons.person, AppLocalizations.of(context).t('profile'), 4),
                      ],
                    ),
                  ),
                  
                  // Footer
                  _buildDesktopFooter(context),
                ],
              ),
            ),
            
            // Content with max width
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: _pages[_currentIndex],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: const MiniPlayer(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Mobile layout with bottom navigation
    return Scaffold(
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: const MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        selectedItemColor: const Color(0xFFFF5E5E),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context).t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore),
            label: AppLocalizations.of(context).t('discover'),
          ),
          BottomNavigationBarItem(
            icon: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _currentIndex == 2 ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5E5E).withOpacity(0.4),
                          blurRadius: _currentIndex == 2 ? 8 : 12 * _pulseAnimation.value,
                          spreadRadius: _currentIndex == 2 ? 0 : 2 * (_pulseAnimation.value - 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
            label: AppLocalizations.of(context).t('create'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            label: AppLocalizations.of(context).t('messages'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context).t('profile'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDesktopNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFFF5E5E) : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF5E5E) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFFFF5E5E).withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () => setState(() => _currentIndex = index),
      ),
    );
  }
  
  Widget _buildDesktopFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => context.go('/terms'),
                child: Text(
                  'Terms',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/privacy'),
                child: Text(
                  'Privacy',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          Text(
            '© 2024 Tuniverse',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
