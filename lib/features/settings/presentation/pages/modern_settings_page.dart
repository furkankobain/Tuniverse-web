import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/services/firebase_service.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/services/pro_status_service.dart';
import '../../../../shared/services/purchase_service.dart';
import '../../../pricing/pricing_page.dart';
import '../../../pricing/pro_plans_page.dart';

class ModernSettingsPage extends ConsumerStatefulWidget {
  const ModernSettingsPage({super.key});

  @override
  ConsumerState<ModernSettingsPage> createState() => _ModernSettingsPageState();
}

class _ModernSettingsPageState extends ConsumerState<ModernSettingsPage> {
  String _appVersion = '';
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _activitySharing = true;
  String _messagePrivacy = 'followers'; // everyone, followers, following
  bool _messageRequests = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() => _appVersion = packageInfo.version);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseService.auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).t('settings'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(AppLocalizations.of(context).t('account'), isDark),
          _buildSettingsList(
            isDark,
            [
              _buildSettingItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: currentUser?.displayName ?? 'Update your information',
                isDark: isDark,
                onTap: () => context.push('/edit-profile'),
              ),
              _buildSettingItem(
                icon: Icons.lock_outline,
                title: 'Privacy & Security',
                subtitle: 'Control your privacy',
                isDark: isDark,
                onTap: () => context.push('/privacy-security'),
              ),
              _buildSettingItem(
                icon: Icons.link,
                title: 'Connected Accounts',
                subtitle: EnhancedSpotifyService.isConnected 
                    ? 'Spotify connected' 
                    : 'Connect Spotify, Apple Music',
                isDark: isDark,
                onTap: () => context.push('/connected-accounts'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance', isDark),
          _buildSettingsList(
            isDark,
            [
              _buildThemeSelector(isDark),
              _buildLanguageSelector(isDark),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader(AppLocalizations.of(context).t('notifications'), isDark),
          _buildSettingsList(
            isDark,
            [
              _buildSwitchItem(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Get notified about activity',
                value: _pushNotifications,
                isDark: isDark,
                onChanged: (val) => setState(() => _pushNotifications = val),
              ),
              _buildSwitchItem(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Receive emails from Tuniverse',
                value: _emailNotifications,
                isDark: isDark,
                onChanged: (val) => setState(() => _emailNotifications = val),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Messages Section
          _buildSectionHeader('Messages', isDark),
          _buildSettingsList(
            isDark,
            [
              _buildMessagePrivacySelector(isDark),
              _buildSwitchItem(
                icon: Icons.mark_email_unread_outlined,
                title: 'Message Requests',
                subtitle: 'Approve messages from non-followers',
                value: _messageRequests,
                isDark: isDark,
                onChanged: (val) => setState(() => _messageRequests = val),
              ),
              _buildSettingItem(
                icon: Icons.block,
                title: 'Blocked Users',
                subtitle: 'Manage blocked accounts',
                isDark: isDark,
                onTap: () => context.push('/blocked-users'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Social Section
          _buildSectionHeader('Social', isDark),
          _buildSettingsList(
            isDark,
            [
              _buildSwitchItem(
                icon: Icons.share_outlined,
                title: 'Activity Sharing',
                subtitle: 'Share what you\'re listening to',
                value: _activitySharing,
                isDark: isDark,
                onChanged: (val) => setState(() => _activitySharing = val),
              ),
              _buildSettingItem(
                icon: Icons.people_outline,
                title: 'Friends & Followers',
                subtitle: 'Manage your connections',
                isDark: isDark,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Friends & Followers page coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Content Section
          _buildSectionHeader('Content', isDark),
          _buildSettingsList(
            isDark,
            [
              _buildSettingItem(
                icon: Icons.history,
                title: 'Listening History',
                subtitle: 'View your play history',
                isDark: isDark,
                onTap: () => context.push('/recently-played'),
              ),
              _buildSettingItem(
                icon: Icons.storage_outlined,
                title: 'Storage Management',
                subtitle: 'Manage app storage',
                isDark: isDark,
                onTap: () => context.push('/storage-management'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Premium Section
          _buildSectionHeader('Premium', isDark),
          _buildProCard(isDark),

          const SizedBox(height: 24),

          // About & Support Section
          _buildSectionHeader(AppLocalizations.of(context).t('about'), isDark),
          _buildSettingsList(
            isDark,
            [
              _buildSettingItem(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'Get support',
                isDark: isDark,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help Center coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.new_releases_outlined,
                title: 'Patch Notes',
                subtitle: 'What\'s new in Tuniverse',
                isDark: isDark,
                onTap: () {
                  _showPatchNotes(context, isDark);
                },
              ),
              _buildSettingItem(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Legal information',
                isDark: isDark,
                onTap: () => context.push('/terms'),
              ),
              _buildSettingItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we protect your data',
                isDark: isDark,
                onTap: () => context.push('/privacy'),
              ),
              _buildSettingItem(
                icon: Icons.star_outline,
                title: 'Rate Tuniverse',
                subtitle: 'Share your feedback',
                isDark: isDark,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your interest! Rating feature coming soon.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: _appVersion.isNotEmpty ? 'v$_appVersion' : 'Loading...',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader('Danger Zone', isDark),
          _buildSettingsList(
            isDark,
            [
              _buildSettingItem(
                icon: Icons.logout,
                title: 'Log Out',
                subtitle: 'Sign out of your account',
                isDark: isDark,
                textColor: Colors.red,
                onTap: () => _showLogoutDialog(context, isDark),
              ),
              _buildSettingItem(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                isDark: isDark,
                textColor: Colors.red,
                onTap: () => _showDeleteAccountDialog(context, isDark),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[600] : Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsList(bool isDark, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required bool isDark,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? (isDark ? Colors.white : Colors.black87),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                )
              : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white : Colors.black87,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    final themeMode = ref.watch(themeProvider);

    return ExpansionTile(
      leading: Icon(
        Icons.palette_outlined,
        color: isDark ? Colors.white : Colors.black87,
        size: 24,
      ),
      title: Text(
        AppLocalizations.of(context).t('theme'),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        themeMode == ThemeMode.dark ? 'Dark' : themeMode == ThemeMode.light ? 'Light' : 'System',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('Light'),
          value: ThemeMode.light,
          groupValue: themeMode,
          activeColor: AppTheme.primaryColor,
          onChanged: (val) {
            if (val != null) ref.read(themeProvider.notifier).setTheme(val);
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark'),
          value: ThemeMode.dark,
          groupValue: themeMode,
          activeColor: AppTheme.primaryColor,
          onChanged: (val) {
            if (val != null) ref.read(themeProvider.notifier).setTheme(val);
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('System'),
          value: ThemeMode.system,
          groupValue: themeMode,
          activeColor: AppTheme.primaryColor,
          onChanged: (val) {
            if (val != null) ref.read(themeProvider.notifier).setTheme(val);
          },
        ),
        // Pro Themes (Locked)
        ListTile(
          leading: const Icon(Icons.color_lens, color: Colors.amber),
          title: const Text('Ocean Blue'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('PRO', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
          onTap: () => _showProDialog(context, isDark),
        ),
        ListTile(
          leading: const Icon(Icons.color_lens, color: Colors.purple),
          title: const Text('Purple Haze'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('PRO', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
          onTap: () => _showProDialog(context, isDark),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    final currentLocale = ref.watch(languageProvider);
    final currentLanguage = currentLocale?.languageCode ?? 'en';

    return ExpansionTile(
      leading: Icon(
        Icons.language,
        color: isDark ? Colors.white : Colors.black87,
        size: 24,
      ),
      title: Text(
        AppLocalizations.of(context).t('language'),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        currentLanguage == 'en' ? 'English' : 'Türkçe',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      children: [
        RadioListTile<String>(
          title: const Row(
            children: [
              Text('🇬🇧', style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Text('English'),
            ],
          ),
          value: 'en',
          groupValue: currentLanguage,
          activeColor: AppTheme.primaryColor,
          onChanged: (val) {
            if (val != null) {
              ref.read(languageProvider.notifier).setLanguage(val);
            }
          },
        ),
        RadioListTile<String>(
          title: const Row(
            children: [
              Text('🇹🇷', style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Text('Türkçe'),
            ],
          ),
          value: 'tr',
          groupValue: currentLanguage,
          activeColor: AppTheme.primaryColor,
          onChanged: (val) {
            if (val != null) {
              ref.read(languageProvider.notifier).setLanguage(val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMessagePrivacySelector(bool isDark) {
    return ExpansionTile(
      leading: Icon(
        Icons.message_outlined,
        color: isDark ? Colors.white : Colors.black87,
        size: 24,
      ),
      title: Text(
        'Who can message me',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        _messagePrivacy == 'everyone' 
            ? 'Everyone' 
            : _messagePrivacy == 'followers' 
                ? 'Followers only' 
                : 'People I follow',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      children: [
        RadioListTile<String>(
          title: const Text('Everyone'),
          value: 'everyone',
          groupValue: _messagePrivacy,
          activeColor: AppTheme.primaryColor,
          onChanged: (val) {
            if (val != null) setState(() => _messagePrivacy = val);
          },
        ),
        RadioListTile<String>(
          title: const Text('Followers'),
          value: 'followers',
          groupValue: _messagePrivacy,
          activeColor: AppTheme.primaryColor,
          onChanged: (val) {
            if (val != null) setState(() => _messagePrivacy = val);
          },
        ),
        RadioListTile<String>(
          title: const Text('People I follow'),
          value: 'following',
          groupValue: _messagePrivacy,
          activeColor: AppTheme.primaryColor,
          onChanged: (val) {
            if (val != null) setState(() => _messagePrivacy = val);
          },
        ),
      ],
    );
  }

  Widget _buildProCard(bool isDark) {
    return FutureBuilder<bool>(
      future: ProStatusService.isProUser(),
      builder: (context, snapshot) {
        final isPro = snapshot.data ?? false;
        
        return FutureBuilder<Map<String, dynamic>>(
          future: ProStatusService.isProUser().then((isPro) async {
            if (!isPro) return {};
            // Firestore'dan subscription bilgisi al
            final user = FirebaseService.auth.currentUser;
            if (user == null) return {};
            return {}; // Subscription bilgisi
          }),
          builder: (context, subSnapshot) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPro 
                      ? [const Color(0xFF6200EA), const Color(0xFF9C27B0)]
                      : [const Color(0xFFFF5E5E), const Color(0xFFFF8E8E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPro ? '✅ PRO' : '⭐ PRO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isPro)
                        const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.lightGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPro ? 'You\'re a PRO member!' : 'Unlock Tuniverse Pro',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPro
                        ? '• All features unlocked\n• Ad-free experience\n• Premium themes\n• Early access to features'
                        : '• Premium themes\n• Ad-free experience\n• Advanced analytics\n• Early access to features',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (isPro)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await PurchaseService.initialize();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Restoring purchases...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Restore',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (isPro) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProPlansPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isPro ? 'Manage' : 'Upgrade Now',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseService.auth.signOut();
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion will be available in settings.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showProDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Premium Theme'),
        content: const Text(
          'This theme is available for Tuniverse Pro members. Upgrade to unlock premium themes and more!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showProSubscriptionDialog(context, isDark);
            },
            child: Text(
              'Upgrade',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showProSubscriptionDialog(BuildContext context, bool isDark) {
    final deviceLocale = Localizations.localeOf(context);
    final isTurkey = deviceLocale.countryCode?.toUpperCase() == 'TR';
    final appLanguage = ref.watch(languageProvider);
    final isTurkish = appLanguage?.languageCode == 'tr' ?? false;
    
    final monthlyPrice = isTurkey ? '₺49.99' : r'$4.99';
    final yearlyPrice = isTurkey ? '₺299.99' : r'$18.99';
    final adFreePrice = isTurkey ? '₺29.99' : r'$3.99';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text(isTurkish ? 'Tuniverse Pro' : 'Tuniverse Pro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isTurkish ? 'Planınızı seçin:' : 'Choose your plan:'),
            const SizedBox(height: 16),
            _buildPlanOption(
              isTurkish ? 'Aylık' : 'Monthly',
              '$monthlyPrice${isTurkish ? '/ay' : '/month'}',
              isDark,
              onTap: () => _purchaseProMonthly(context),
            ),
            const SizedBox(height: 8),
            _buildPlanOption(
              isTurkish ? 'Yıllık' : 'Yearly',
              '$yearlyPrice${isTurkish ? '/yıl' : '/year'}',
              isDark,
              badge: isTurkish ? '%63 Tasarruf' : '63% Save',
              onTap: () => _purchaseProAnnual(context),
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              isTurkish ? 'Sadece Reklamları Kaldır' : 'Ad-Free Only',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPlanOption(
              isTurkish ? 'Reklamslız' : 'Ad-Free',
              '$adFreePrice${isTurkish ? ' (Bir kerelik)' : ' (One-time)'}',
              isDark,
              onTap: () => _purchaseAdFree(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTurkish ? 'İptal' : 'Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _purchaseProMonthly(BuildContext context) async {
    final deviceLocale = Localizations.localeOf(context);
    final isTurkey = deviceLocale.countryCode?.toUpperCase() == 'TR';
    await PurchaseService.purchaseProduct(SkuIds.getProMonthlySku(isTurkey));
    if (mounted) Navigator.pop(context);
  }
  
  Future<void> _purchaseProAnnual(BuildContext context) async {
    final deviceLocale = Localizations.localeOf(context);
    final isTurkey = deviceLocale.countryCode?.toUpperCase() == 'TR';
    await PurchaseService.purchaseProduct(SkuIds.getProAnnualSku(isTurkey));
    if (mounted) Navigator.pop(context);
  }
  
  Future<void> _purchaseAdFree(BuildContext context) async {
    final deviceLocale = Localizations.localeOf(context);
    final isTurkey = deviceLocale.countryCode?.toUpperCase() == 'TR';
    await PurchaseService.purchaseProduct(SkuIds.getAdFreeSku(isTurkey));
    if (mounted) Navigator.pop(context);
  }

  Widget _buildPlanOption(String title, String price, bool isDark, {String? badge, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: onTap != null ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  void _showPatchNotes(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Patch Notes'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('🎉 Initial Release\n'
                  '• Modern Instagram-style design\n'
                  '• Direct messaging with reactions\n'
                  '• Now Playing activity feed\n'
                  '• Spotify integration\n'
                  '• Favorites & playlists\n'
                  '• Concert & event notifications\n'
                  '• Music news feed'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
