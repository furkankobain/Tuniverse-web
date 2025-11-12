import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../mood/presentation/pages/mood_detection_page.dart';
import '../../../player/presentation/pages/now_playing_animation_page.dart';
import '../../../help/help_and_faq_page.dart';
import '../../../subscription/presentation/pages/pro_membership_page.dart';
import '../../../../shared/services/pro_status_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/utils/set_user_pro.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final isPro = await ProStatusService.isProUser();
    if (mounted) {
      setState(() {
        _isPro = isPro;
      });
    }
  }

  void _handleProFeatureTap(String featureName) {
    if (!_isPro) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFFFFD700)),
              SizedBox(width: 8),
              Text('PRO Feature'),
            ],
          ),
          content: Text('$featureName is only available for PRO members.\n\nUpgrade to PRO to unlock this and many other premium features!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProMembershipPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              child: const Text('Upgrade to PRO'),
            ),
          ],
        ),
      );
    }
  }

  String t(BuildContext context, String key) => AppLocalizations.of(context).t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'more')),
        actions: [
          // Debug: Set Pro status button
          IconButton(
            onPressed: () async {
              await setUserAsPro();
              await _checkProStatus();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('You are now PRO! 🎉'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.bug_report, size: 20),
            tooltip: 'Set as Pro (Debug)',
          ),
          // PRO button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProMembershipPage(),
                  ),
                );
              },
              icon: Icon(
                _isPro ? Icons.check_circle : Icons.workspace_premium,
                color: const Color(0xFFFFD700),
                size: 20,
              ),
              label: Text(
                _isPro ? 'PRO' : 'Get PRO',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Premium features section
          _buildSection(
            context,
            title: '✨ Premium Features',
            items: [
              _MenuItem(
                icon: Icons.music_video,
                title: 'Music Rooms',
                subtitle: 'Join or create music listening rooms',
                color: const Color(0xFFFF5E5E),
                isProOnly: true,
                isDisabled: true,
                onTap: () => _handleProFeatureTap('Music Rooms'),
              ),
              _MenuItem(
                icon: Icons.groups,
                title: 'Community',
                subtitle: 'Connect with music lovers worldwide',
                color: Colors.purple,
                isDisabled: true,
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.leaderboard,
                title: 'Leaderboards',
                subtitle: 'Compete with other music lovers',
                color: Colors.green,
                onTap: () => context.push('/leaderboard'),
              ),
              _MenuItem(
                icon: Icons.quiz,
                title: 'Music Quiz',
                subtitle: 'Test your music knowledge and earn points',
                color: Colors.blue,
                onTap: () => context.push('/quiz'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...items.map((item) => _buildMenuItem(context, item)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return Opacity(
      opacity: (item.isDisabled ?? false) ? 0.5 : 1.0,
      child: ListTile(
        enabled: !(item.isDisabled ?? false),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.icon,
            color: item.color,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (item.isProOnly ?? false)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          item.subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: (item.isDisabled ?? false) ? null : item.onTap,
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool? isProOnly;
  final bool? isDisabled;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isProOnly,
    this.isDisabled,
  });
}
