import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _privateAccount = false;
  bool _showActivity = true;
  bool _showPlayingNow = true;
  bool _allowTagging = true;
  bool _twoFactorAuth = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Account Privacy
          _buildSectionHeader('Account Privacy', isDark),
          _buildSettingsList(
            isDark,
            [
              _buildSwitchItem(
                icon: Icons.lock_outline,
                title: 'Private Account',
                subtitle: _privateAccount
                    ? 'Only approved followers can see your activity'
                    : 'Anyone can see your activity',
                value: _privateAccount,
                isDark: isDark,
                onChanged: (val) => setState(() => _privateAccount = val),
              ),
              _buildSwitchItem(
                icon: Icons.remove_red_eye_outlined,
                title: 'Show Activity Status',
                subtitle: 'Let others see when you\'re online',
                value: _showActivity,
                isDark: isDark,
                onChanged: (val) => setState(() => _showActivity = val),
              ),
              _buildSwitchItem(
                icon: Icons.music_note,
                title: 'Show Now Playing',
                subtitle: 'Share what you\'re currently listening to',
                value: _showPlayingNow,
                isDark: isDark,
                onChanged: (val) => setState(() => _showPlayingNow = val),
              ),
              _buildSwitchItem(
                icon: Icons.local_offer_outlined,
                title: 'Allow Tagging',
                subtitle: 'Others can tag you in their posts',
                value: _allowTagging,
                isDark: isDark,
                onChanged: (val) => setState(() => _allowTagging = val),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security
          _buildSectionHeader('Security', isDark),
          _buildSettingsList(
            isDark,
            [
              _buildSettingItem(
                icon: Icons.lock_reset,
                title: 'Change Password',
                subtitle: 'Update your password',
                isDark: isDark,
                onTap: () => _showChangePasswordDialog(context, isDark),
              ),
              _buildSwitchItem(
                icon: Icons.security,
                title: 'Two-Factor Authentication',
                subtitle: _twoFactorAuth ? 'Enabled' : 'Add extra security',
                value: _twoFactorAuth,
                isDark: isDark,
                onChanged: (val) {
                  setState(() => _twoFactorAuth = val);
                  if (val) {
                    _showTwoFactorSetupDialog(context, isDark);
                  }
                },
              ),
              _buildSettingItem(
                icon: Icons.devices,
                title: 'Active Sessions',
                subtitle: 'Manage your logged-in devices',
                isDark: isDark,
                onTap: () => _showActiveSessionsDialog(context, isDark),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data & Privacy
          _buildSectionHeader('Data & Privacy', isDark),
          _buildSettingsList(
            isDark,
            [
              _buildSettingItem(
                icon: Icons.download_outlined,
                title: 'Download Your Data',
                subtitle: 'Request a copy of your data',
                isDark: isDark,
                onTap: () => _showDownloadDataDialog(context, isDark),
              ),
              _buildSettingItem(
                icon: Icons.history,
                title: 'Clear Search History',
                subtitle: 'Remove all your search history',
                isDark: isDark,
                onTap: () => _showClearHistoryDialog(context, isDark),
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
      child: Column(children: items),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 24),
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
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400])
          : null,
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
      leading: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 24),
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
        activeColor: const Color(0xFFFF5E5E),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
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
                  content: Text('Password updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Update', style: TextStyle(color: Color(0xFFFF5E5E))),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorSetupDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Two-Factor Authentication'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Two-factor authentication adds an extra layer of security.'),
            SizedBox(height: 16),
            Text('You\'ll need to enter a code from your phone in addition to your password when logging in.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showActiveSessionsDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Active Sessions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSessionItem('Windows PC', 'Istanbul, Turkey', 'Active now', isDark),
            const Divider(height: 24),
            _buildSessionItem('iPhone 13', 'Istanbul, Turkey', '2 hours ago', isDark),
          ],
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

  Widget _buildSessionItem(String device, String location, String time, bool isDark) {
    return Row(
      children: [
        Icon(
          device.contains('PC') ? Icons.computer : Icons.phone_iphone,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '$location • $time',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDownloadDataDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Download Your Data'),
        content: const Text(
          'We\'ll prepare a copy of your Tuniverse data. This may take a few hours. You\'ll receive an email when it\'s ready.',
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
                  content: Text('Data download requested. Check your email.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Request', style: TextStyle(color: Color(0xFFFF5E5E))),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Clear Search History'),
        content: const Text('This will permanently delete your search history.'),
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
                  content: Text('Search history cleared!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
