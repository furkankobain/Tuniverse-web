# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Tuniverse is a Flutter-based music social network app inspired by Letterboxd, combining music discovery, reviews, and social features with Spotify and Last.fm integration.

**Tech Stack:**
- Flutter 3.9.2+ / Dart 3.9.2+
- Firebase (Firestore, Auth, Storage, Realtime Database)
- State Management: Riverpod
- Navigation: GoRouter
- APIs: Spotify, Last.fm, Genius (lyrics)

## Essential Commands

### Setup & Installation
```powershell
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific device
flutter run -d windows
flutter run -d chrome
```

### Code Quality
```powershell
# Analyze code (uses flutter_lints)
flutter analyze

# Run tests (if test suite exists)
flutter test

# Clean build artifacts
flutter clean
flutter pub get
```

### Building
```powershell
# Build APK
flutter build apk

# Build App Bundle
flutter build appbundle

# Build for Windows
flutter build windows
```

### Firebase Setup
Before running the app, follow instructions in `FIREBASE_SETUP.md`:
1. Deploy Firestore security rules from `firestore.rules`
2. Deploy Storage security rules from `storage.rules`
3. Enable Firestore and Realtime Database in Firebase Console

## Architecture

### Feature-Based Structure
```
lib/
├── core/              # Theme, constants, utilities
├── features/          # Feature modules (25+ features)
│   ├── auth/         # Authentication & signup
│   ├── messaging/    # DM system with real-time chat
│   ├── playlists/    # Playlist CRUD and management
│   ├── profile/      # User profiles and stats
│   ├── discover/     # Music discovery and recommendations
│   ├── search/       # Advanced search functionality
│   ├── social/       # Social feed and follow system
│   ├── music/        # Track/album/artist details
│   ├── reviews/      # Review and rating system
│   ├── favorites/    # Favorites management
│   ├── notifications/# In-app notifications
│   └── ...          # Other features (home, settings, diary, etc.)
└── shared/
    ├── models/       # Data models (Track, Album, User, etc.)
    ├── services/     # 49+ service files
    ├── providers/    # Riverpod providers
    └── widgets/      # Reusable UI components
```

### Service Layer Architecture

**Core Services** (lib/shared/services/):
- **enhanced_spotify_service.dart** (62KB) - Primary Spotify API integration with OAuth
- **spotify_service.dart** (21KB) - Core Spotify data fetching
- **recommendation_service.dart** (20KB) - Multi-source recommendations
- **messaging_service.dart** - Real-time DM system
- **playlist_service.dart** - Playlist CRUD operations
- **firebase_bypass_auth_service.dart** - Simplified auth (bypasses Firebase Auth)
- **lastfm_service.dart** - Artist info, similar tracks
- **genius_service.dart** - Lyrics integration
- **music_player_service.dart** - 30s preview playback
- **follow_service.dart** - Follow/unfollow with request system
- **notification_service.dart** - Local notifications
- **activity_service.dart** - Activity feed tracking

**New Advanced Services** (Nov 2, 2025):
- **gamification_service.dart** - Achievements (17), streaks, leaderboards, points system
- **music_quiz_service.dart** - 6 quiz types (Guess Song/Artist/Year/Genre/Album, Finish Lyrics)
- **analytics_service.dart** - Listening Clock, Music Map, Taste Profile, Yearly Wrapped, Friends Comparison
- **offline_service.dart** - Track downloads, offline queue, smart download
- **cache_optimization_service.dart** - Image & data caching with LRU eviction (100MB/50MB limits)
- **group_session_service.dart** - Real-time listening sessions, vote to skip, shared queue
- **personalized_discovery_service.dart** - Daily Mix & Release Radar generation
- **music_exploration_service.dart** - Decade Explorer (60s-2020s) & Genre Deep Dive
- **queue_service.dart** - Full playback queue with shuffle/repeat
- **audio_effects_service.dart** - Crossfade & Equalizer (21 presets)
- **sleep_timer_service.dart** - Auto-stop with multiple duration presets
- **social_interactions_service.dart** - Like system, comments, social sharing

### State Management Pattern
- Uses **Riverpod** for state management
- Providers located in `lib/shared/providers/`
- Services are typically stateless and called directly
- UI state managed through StatefulWidgets or Riverpod providers

### Navigation
- **GoRouter** for declarative routing
- Routes defined in `lib/main.dart`
- Auth redirect logic handles login/home navigation
- Deep linking supported for Spotify OAuth callback

## Key Architectural Decisions

### Authentication
- Currently uses `FirebaseBypassAuthService` (simplified auth without Firebase Auth)
- Multiple auth service implementations exist (enhanced, simple, mock, minimal)
- Authentication state checked via `FirebaseBypassAuthService.isSignedIn`

### Data Flow
1. **API Layer**: Services fetch from Spotify/Last.fm/Genius APIs
2. **Cache Layer**: `cache_service.dart` handles API response caching
3. **Firebase Layer**: Firestore for user data, reviews, playlists, messages
4. **UI Layer**: Riverpod providers + StatefulWidgets consume services

### Firebase Collections
- `users/` - User profiles and settings
- `reviews/` - Track/album reviews
- `playlists/` - User-created playlists
- `conversations/` - DM conversations
- `messages/` - Chat messages
- `notifications/` - In-app notifications
- `activities/` - Social feed activities
- `followRequests/` - Follow request system
- `group_sessions/` - Real-time listening sessions (NEW)
- `quizzes/` - Music quiz sessions and scores (NEW)
- `achievements/` - User achievement tracking (NEW)
- `listeningHistory/` - Analytics data collection (NEW)

### Spotify Integration
- OAuth flow: `/spotify-connect` → Spotify Auth → `/spotify-callback`
- Access tokens managed by `EnhancedSpotifyService`
- Token refresh handled automatically
- Playlist import from Spotify supported
- Currently playing/recently played tracking

## Important Files

- `lib/main.dart` - App entry point, routing configuration
- `lib/firebase_options.dart` - Firebase configuration
- `pubspec.yaml` - Dependencies and assets
- `FIREBASE_SETUP.md` - Firebase setup instructions
- `DEVELOPMENT_SUMMARY.md` - Detailed feature list (Phase 1: 100% complete)
- `README.md` - Full feature documentation in Turkish
- `WARP.md` - This file - Development guide for AI assistance

## Development Notes

### Linting
- Uses `flutter_lints` package
- `use_build_context_synchronously` rule disabled in `analysis_options.yaml`
- Run `flutter analyze` to check for issues

### Assets
- Images: `assets/images/`
- Icons: `assets/icons/`

### Common Patterns

**Service Usage:**
```dart
// Call services directly
final tracks = await SpotifyService.searchTracks(query);
final artist = await LastFmService.getArtistInfo(artistName);

// Recommendation service
final recs = await RecommendationService.getRecommendations(
  userId: userId,
  seedTracks: seedTracks,
);
```

**Firebase Operations:**
```dart
// Firestore queries
final snapshot = await FirebaseFirestore.instance
  .collection('playlists')
  .where('userId', isEqualTo: userId)
  .get();
```

**Riverpod Providers:**
```dart
// Watch theme mode
final themeMode = ref.watch(themeProvider);

// Read one-time
final theme = ref.read(themeProvider);
```

### Testing Strategy
- No comprehensive test suite currently exists
- When adding tests, focus on:
  - Service layer unit tests
  - Model serialization tests
  - Widget tests for reusable components

## Feature Status

**Phase 1: COMPLETE! (Nov 2, 2025)** 🎉

**Core Features (25/25):**
- ✅ Review & Rating System with 5-star ratings
- ✅ Spotify/Last.fm/Genius API integrations
- ✅ DM system with real-time messaging
- ✅ Follow system with public/private accounts
- ✅ Playlist CRUD with cover images
- ✅ Smart playlists (mood, genre, era-based)
- ✅ QR code sharing for playlists
- ✅ Music discovery and recommendations
- ✅ Social feed (activity tracking)
- ✅ Artist/Album detail pages
- ✅ Lyrics integration
- ✅ Audio features visualization
- ✅ 30s preview player
- ✅ Onboarding flow

**Advanced Features (18/18 UI + 9 Services):**
- ✅ **Gamification** - Achievements, Streaks, Leaderboards, Music Quiz, Challenges
- ✅ **Analytics** - Listening Clock, Music Map, Taste Profile, Yearly Wrapped, Friends Comparison
- ✅ **Offline & Performance** - Download tracks, Storage management, Cache optimization
- ✅ **Collaboration** - Group Sessions, Music Rooms, Vote to Skip, Shared Queue
- ✅ **Discovery** - Daily Mix, Release Radar, Decade Explorer, Genre Deep Dive
- ✅ **Audio** - Queue management, Crossfade, Equalizer (21 presets), Sleep Timer
- ✅ **Social** - Like system, Comments, Social sharing

**Phase 2: Next Priorities**
- ⏳ **Visual Enhancements** - Now Playing animations, Album color themes, Synced lyrics
- ⏳ **AI Features** - ML recommendations, Mood detection, Auto-Mix
- ⏳ **Notifications** - Push notifications (FCM), Daily digest
- ⏳ **Integrations** - Apple Music, YouTube Music, SoundCloud

See `README.md` for complete roadmap.

## Firebase Security

**Critical:** Before deploying to production:
1. Review and deploy `firestore.rules` for Firestore security
2. Review and deploy `storage.rules` for Storage security
3. Enable appropriate Firebase services (Firestore, Storage, Realtime Database)
4. Configure FCM for push notifications

Current rules enforce:
- Authenticated users can read/write their own data
- Public playlists visible to all
- Private playlists only visible to owner
- Conversation participants can read/write messages

## External API Keys

The app requires API keys/credentials for:
- **Spotify**: Client ID, Client Secret, Redirect URI (see `SPOTIFY_SETUP.md` if exists)
- **Last.fm**: API key for artist info and similar tracks
- **Genius**: API token for lyrics

These should be configured in environment/service files before running.

## Code Style

- Follow Flutter/Dart conventions
- Use `flutter_lints` recommended rules
- Prefer `final` over `var`
- Async operations use `async/await`
- Error handling with try-catch blocks
- Services use static methods for stateless operations
- Models use immutable classes (final fields)
- Consistent naming: `snake_case` for files, `camelCase` for variables, `PascalCase` for classes

## Windows Development

This project is currently being developed on Windows with PowerShell. When suggesting commands:
- Use PowerShell syntax (not bash)
- File paths use backslashes: `C:\Users\...\`
- Use `flutter` commands directly (Flutter is in PATH)
