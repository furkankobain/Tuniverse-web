import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/notification_provider.dart';
import '../../../../shared/services/notification_service.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final settingsNotifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              
              const SizedBox(height: 24),
              
              // Notification Toggle
              _buildNotificationToggle(ref),
              
              const SizedBox(height: 24),
              
              // Settings List
              _buildSettingsList(settings, settingsNotifier),
              
              const SizedBox(height: 24),
              
              // Test Notifications
              _buildTestNotifications(context),
              
              const SizedBox(height: 24),
              
              // Clear Notifications
              _buildClearNotifications(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bildirim Tercihleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hangi bildirimleri almak istediğinizi seçin',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(WidgetRef ref) {
    final isEnabled = ref.watch(notificationEnabledProvider);
    
    return Card(
      child: ListTile(
        leading: Icon(
          isEnabled ? Icons.notifications : Icons.notifications_off,
          color: isEnabled ? AppTheme.primaryColor : Colors.grey,
        ),
        title: const Text(
          'Bildirimleri Etkinleştir',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Tüm bildirimleri aç/kapat',
        ),
        trailing: Switch(
          value: isEnabled,
          onChanged: (value) {
            ref.read(notificationEnabledProvider.notifier).state = value;
          },
          activeThumbColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsList(
    NotificationSettings settings,
    NotificationSettingsNotifier notifier,
  ) {
    return Card(
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.music_note,
            title: 'Müzik Önerileri',
            subtitle: 'Yeni müzik önerileri hakkında bildirim al',
            value: settings.musicRecommendations,
            onChanged: notifier.toggleMusicRecommendations,
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.new_releases,
            title: 'Yeni Çıkanlar',
            subtitle: 'Favori sanatçılarınızın yeni albümlerini öğrenin',
            value: settings.newReleases,
            onChanged: notifier.toggleNewReleases,
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.trending_up,
            title: 'Trend Şarkılar',
            subtitle: 'Popüler olan şarkılar hakkında bildirim al',
            value: settings.trendingTracks,
            onChanged: notifier.toggleTrendingTracks,
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.star,
            title: 'Puanlama Hatırlatıcıları',
            subtitle: 'Dinlediğiniz şarkıları puanlamayı hatırlat',
            value: settings.ratingReminders,
            onChanged: notifier.toggleRatingReminders,
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.analytics,
            title: 'Haftalık Özet',
            subtitle: 'Haftalık dinleme istatistiklerinizi görün',
            value: settings.weeklyDigest,
            onChanged: notifier.toggleWeeklyDigest,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: (_) => onChanged(),
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildTestNotifications(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Bildirimleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Farklı bildirim türlerini test edin',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _testMusicRecommendation(),
                  icon: const Icon(Icons.music_note, size: 16),
                  label: const Text('Müzik Önerisi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testNewRelease(),
                  icon: const Icon(Icons.new_releases, size: 16),
                  label: const Text('Yeni Albüm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testTrendingTrack(),
                  icon: const Icon(Icons.trending_up, size: 16),
                  label: const Text('Trend Şarkı'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testRatingReminder(),
                  icon: const Icon(Icons.star, size: 16),
                  label: const Text('Puanlama'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearNotifications(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.clear_all,
          color: AppTheme.errorColor,
        ),
        title: const Text(
          'Tüm Bildirimleri Temizle',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.errorColor,
          ),
        ),
        subtitle: const Text('Tüm bildirimleri kaldır'),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        onTap: () => _showClearDialog(context),
      ),
    );
  }

  void _testMusicRecommendation() {
    NotificationService.showMusicRecommendation(
      trackName: 'Anti-Hero',
      artistName: 'Taylor Swift',
    );
  }

  void _testNewRelease() {
    NotificationService.showNewRelease(
      albumName: 'Midnights',
      artistName: 'Taylor Swift',
    );
  }

  void _testTrendingTrack() {
    NotificationService.showTrendingTrack(
      trackName: 'As It Was',
      artistName: 'Harry Styles',
    );
  }

  void _testRatingReminder() {
    NotificationService.showRatingReminder(
      trackName: 'Heat Waves',
      artistName: 'Glass Animals',
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimleri Temizle'),
        content: const Text('Tüm bildirimleri temizlemek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              NotificationService.clearAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm bildirimler temizlendi'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}
