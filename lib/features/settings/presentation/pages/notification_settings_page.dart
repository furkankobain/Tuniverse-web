import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification Settings Page
/// Allows users to customize notification preferences
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Notification preferences
  bool _messagesEnabled = true;
  bool _followersEnabled = true;
  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _achievementsEnabled = true;
  bool _groupSessionsEnabled = true;
  bool _quizChallengesEnabled = true;
  
  // Sound and vibration
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // Do Not Disturb
  bool _dndEnabled = false;
  TimeOfDay _dndStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dndEnd = const TimeOfDay(hour: 8, minute: 0);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _messagesEnabled = prefs.getBool('notif_messages') ?? true;
      _followersEnabled = prefs.getBool('notif_followers') ?? true;
      _likesEnabled = prefs.getBool('notif_likes') ?? true;
      _commentsEnabled = prefs.getBool('notif_comments') ?? true;
      _achievementsEnabled = prefs.getBool('notif_achievements') ?? true;
      _groupSessionsEnabled = prefs.getBool('notif_group_sessions') ?? true;
      _quizChallengesEnabled = prefs.getBool('notif_quiz_challenges') ?? true;
      
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
      
      _dndEnabled = prefs.getBool('notif_dnd_enabled') ?? false;
      
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _dndStart : _dndEnd,
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _dndStart = time;
        } else {
          _dndEnd = time;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bildirim Ayarları')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification Types Section
          _buildSectionHeader('Bildirim Türleri', Icons.notifications_active),
          const SizedBox(height: 8),
          _buildNotificationTile(
            title: 'Mesajlar',
            subtitle: 'Yeni DM mesajları',
            icon: Icons.message,
            value: _messagesEnabled,
            onChanged: (value) {
              setState(() => _messagesEnabled = value);
              _savePreference('notif_messages', value);
            },
          ),
          _buildNotificationTile(
            title: 'Takipçiler',
            subtitle: 'Yeni takipçi ve takip istekleri',
            icon: Icons.person_add,
            value: _followersEnabled,
            onChanged: (value) {
              setState(() => _followersEnabled = value);
              _savePreference('notif_followers', value);
            },
          ),
          _buildNotificationTile(
            title: 'Beğeniler',
            subtitle: 'İnceleme ve playlist beğenileri',
            icon: Icons.favorite,
            value: _likesEnabled,
            onChanged: (value) {
              setState(() => _likesEnabled = value);
              _savePreference('notif_likes', value);
            },
          ),
          _buildNotificationTile(
            title: 'Yorumlar',
            subtitle: 'İncelemelerinize yapılan yorumlar',
            icon: Icons.comment,
            value: _commentsEnabled,
            onChanged: (value) {
              setState(() => _commentsEnabled = value);
              _savePreference('notif_comments', value);
            },
          ),
          _buildNotificationTile(
            title: 'Başarılar',
            subtitle: 'Yeni başarı ve rozet bildirimleri',
            icon: Icons.emoji_events,
            value: _achievementsEnabled,
            onChanged: (value) {
              setState(() => _achievementsEnabled = value);
              _savePreference('notif_achievements', value);
            },
          ),
          _buildNotificationTile(
            title: 'Grup Oturumları',
            subtitle: 'Davetler ve grup dinleme bildirimleri',
            icon: Icons.group,
            value: _groupSessionsEnabled,
            onChanged: (value) {
              setState(() => _groupSessionsEnabled = value);
              _savePreference('notif_group_sessions', value);
            },
          ),
          _buildNotificationTile(
            title: 'Quiz Meydan Okumaları',
            subtitle: 'Müzik yarışma davetiyeleri',
            icon: Icons.quiz,
            value: _quizChallengesEnabled,
            onChanged: (value) {
              setState(() => _quizChallengesEnabled = value);
              _savePreference('notif_quiz_challenges', value);
            },
          ),

          const SizedBox(height: 32),

          // Sound & Vibration Section
          _buildSectionHeader('Ses & Titreşim', Icons.volume_up),
          const SizedBox(height: 8),
          _buildNotificationTile(
            title: 'Bildirim Sesi',
            subtitle: 'Bildirim geldiğinde ses çal',
            icon: Icons.music_note,
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _savePreference('notif_sound', value);
            },
          ),
          _buildNotificationTile(
            title: 'Titreşim',
            subtitle: 'Bildirim geldiğinde titreşim',
            icon: Icons.vibration,
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
              _savePreference('notif_vibration', value);
            },
          ),

          const SizedBox(height: 32),

          // Do Not Disturb Section
          _buildSectionHeader('Rahatsız Etme', Icons.bedtime),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Rahatsız Etme Modu'),
                    subtitle: const Text('Belirli saatler arası bildirim alma'),
                    value: _dndEnabled,
                    onChanged: (value) {
                      setState(() => _dndEnabled = value);
                      _savePreference('notif_dnd_enabled', value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_dndEnabled) ...[
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeSelector(
                            context,
                            label: 'Başlangıç',
                            time: _dndStart,
                            onTap: () => _selectTime(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.arrow_forward),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeSelector(
                            context,
                            label: 'Bitiş',
                            time: _dndEnd,
                            onTap: () => _selectTime(context, false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Test Notification Button
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test bildirimi gönderildi! 🔔'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Test Bildirimi Gönder'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 16),

          // Info Card
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bildirimleri tamamen kapatmak için cihaz ayarlarından Tuniverse bildirimlerini devre dışı bırakabilirsiniz.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF5E5E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFFFF5E5E).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFFFF5E5E)),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTimeSelector(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
