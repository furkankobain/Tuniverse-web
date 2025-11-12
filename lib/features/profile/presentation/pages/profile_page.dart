import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/services/enhanced_auth_service.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import '../../../../shared/widgets/adaptive_banner_ad_widget.dart';
import '../../../music/presentation/pages/my_ratings_page.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../widgets/profile_stats_dashboard.dart';
import '../../widgets/activity_timeline.dart';
import 'edit_profile_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context).t;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, ref),
            
            const SizedBox(height: 24),
            
            // Stats Section
            _buildStatsSection(context),
            
            const SizedBox(height: 24),
            
            // Enhanced Stats Dashboard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: StreamBuilder(
                stream: EnhancedAuthService.authStateChanges,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) return const SizedBox.shrink();
                  return ProfileStatsDashboard(
                    userId: user.uid,
                    isOwnProfile: true,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Activity Timeline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: SizedBox(
                height: 500,
                child: StreamBuilder(
                  stream: EnhancedAuthService.authStateChanges,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    if (user == null) return const SizedBox.shrink();
                    return ActivityTimeline(
                      userId: user.uid,
                      limit: 15,
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: Column(
                children: [
                  _buildMenuSection(context, t('library'), [
                    _buildMenuItem(
                      context,
                      icon: Icons.favorite,
                      title: t('liked_songs'),
                      subtitle: '89 ${t('songs')}',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.album,
                      title: t('my_albums'),
                      subtitle: '43 ${t('albums_count')}',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.playlist_play,
                      title: t('my_playlists'),
                      subtitle: '12 ${t('playlists_count')}',
                      onTap: () {},
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildMenuSection(context, t('activity'), [
                    _buildMenuItem(
                      context,
                      icon: Icons.history,
                      title: t('listening_history'),
                      subtitle: t('view_music_journey'),
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.star,
                      title: t('my_ratings'),
                      subtitle: t('all_music_ratings'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyRatingsPage(),
                        ),
                      ),
                    ),
      _buildMenuItem(
        context,
        icon: Icons.analytics,
        title: t('my_statistics'),
        subtitle: t('view_listening_stats'),
        onTap: () => Navigator.pushNamed(context, '/statistics'),
      ),
      _buildMenuItem(
        context,
        icon: Icons.settings,
        title: t('settings'),
        subtitle: t('manage_app_settings'),
        onTap: () => Navigator.pushNamed(context, '/settings'),
      ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildMenuSection(context, t('social'), [
                    _buildMenuItem(
                      context,
                      icon: Icons.people,
                      title: t('following'),
                      subtitle: '45 ${t('friends')}',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.group,
                      title: t('followers'),
                      subtitle: '128 ${t('followers_count')}',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.share,
                      title: t('share_profile'),
                      subtitle: t('invite_friends'),
                      onTap: () {},
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildMenuSection(context, t('settings'), [
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications,
                      title: t('notifications'),
                      subtitle: t('manage_notifications'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsPage(),
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.privacy_tip,
                      title: t('privacy'),
                      subtitle: t('control_your_data'),
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.help,
                      title: 'Help & Support',
                      subtitle: 'Get assistance',
                      onTap: () {},
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, ref),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Banner Ad
                  AdaptiveBannerAdWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.primaryColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              // Profile Picture with enhanced design
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white,
                  child: StreamBuilder(
                    stream: EnhancedAuthService.authStateChanges,
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return CircleAvatar(
                        radius: 52,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        child: Text(
                          (user?.displayName?.isNotEmpty == true)
                              ? user!.displayName![0].toUpperCase()
                              : 'M',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Name
              StreamBuilder(
                stream: EnhancedAuthService.authStateChanges,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) {
                    return const Text(
                      'Music Lover',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }
                  return FutureBuilder(
                    future: FirebaseService.getUserDocument(user.uid),
                    builder: (context, docSnapshot) {
                      if (!docSnapshot.hasData) {
                        return Text(
                          user.displayName ?? 'Music Lover',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        );
                      }
                      final userData = docSnapshot.data!.data() as Map<String, dynamic>?;
                      return Text(
                        userData?['displayName'] ?? user.displayName ?? 'Music Lover',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              // Username
              StreamBuilder(
                stream: EnhancedAuthService.authStateChanges,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '@musiclover',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return FutureBuilder(
                    future: FirebaseService.getUserDocument(user.uid),
                    builder: (context, docSnapshot) {
                      if (!docSnapshot.hasData) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '@${user.email?.split('@')[0] ?? 'musiclover'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      final userData = docSnapshot.data!.data() as Map<String, dynamic>?;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '@${userData?['username'] ?? user.email?.split('@')[0] ?? 'musiclover'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Streak Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '7 Day Streak',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• Keep it up!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bio
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Passionate about discovering new music and sharing my thoughts with the world. 🎵',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Edit Profile Button with modern design
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              title: 'Songs',
              value: '247',
              icon: Icons.music_note,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              title: 'Albums',
              value: '43',
              icon: Icons.album,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              title: 'Reviews',
              value: '23',
              icon: Icons.edit,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 20,
          color: AppTheme.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await EnhancedAuthService.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
