import 'package:flutter/material.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';

class ConnectedAccountsPage extends StatefulWidget {
  const ConnectedAccountsPage({super.key});

  @override
  State<ConnectedAccountsPage> createState() => _ConnectedAccountsPageState();
}

class _ConnectedAccountsPageState extends State<ConnectedAccountsPage> {
  bool _spotifyConnected = false;
  bool _appleMusicConnected = false;
  bool _googleConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _spotifyConnected = EnhancedSpotifyService.isConnected;
  }

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
          'Connected Accounts',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.blue[900]! : Colors.blue[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connect your music streaming accounts to sync your data and get better recommendations.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.blue[300] : Colors.blue[900],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Spotify
          _buildAccountCard(
            isDark: isDark,
            serviceName: 'Spotify',
            serviceIcon: Icons.music_note,
            serviceColor: const Color(0xFF1DB954),
            isConnected: _spotifyConnected,
            username: _spotifyConnected ? 'Connected' : null,
            onConnect: () => _connectSpotify(),
            onDisconnect: () => _disconnectSpotify(),
          ),

          const SizedBox(height: 16),

          // Apple Music
          _buildAccountCard(
            isDark: isDark,
            serviceName: 'Apple Music',
            serviceIcon: Icons.apple,
            serviceColor: const Color(0xFFFA243C),
            isConnected: _appleMusicConnected,
            username: _appleMusicConnected ? 'Connected' : null,
            onConnect: () => _showComingSoonDialog('Apple Music'),
            onDisconnect: () => _disconnectAccount('Apple Music', () {
              setState(() => _appleMusicConnected = false);
            }),
          ),

          const SizedBox(height: 16),

          // Google
          _buildAccountCard(
            isDark: isDark,
            serviceName: 'Google',
            serviceIcon: Icons.g_mobiledata,
            serviceColor: const Color(0xFF4285F4),
            isConnected: _googleConnected,
            username: _googleConnected ? 'Connected' : null,
            onConnect: () => _showComingSoonDialog('Google'),
            onDisconnect: () => _disconnectAccount('Google', () {
              setState(() => _googleConnected = false);
            }),
          ),

          const SizedBox(height: 24),

          // Benefits Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benefits of Connecting',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBenefit(
                  icon: Icons.sync,
                  text: 'Auto-sync your listening history',
                  isDark: isDark,
                ),
                _buildBenefit(
                  icon: Icons.recommend,
                  text: 'Get personalized recommendations',
                  isDark: isDark,
                ),
                _buildBenefit(
                  icon: Icons.playlist_play,
                  text: 'Import your playlists',
                  isDark: isDark,
                ),
                _buildBenefit(
                  icon: Icons.analytics,
                  text: 'View detailed analytics',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard({
    required bool isDark,
    required String serviceName,
    required IconData serviceIcon,
    required Color serviceColor,
    required bool isConnected,
    String? username,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isConnected
            ? Border.all(color: serviceColor, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: serviceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            serviceIcon,
            color: serviceColor,
            size: 28,
          ),
        ),
        title: Text(
          serviceName,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: isConnected
            ? Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: serviceColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    username ?? 'Connected',
                    style: TextStyle(
                      fontSize: 13,
                      color: serviceColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Text(
                'Not connected',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
        trailing: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isConnected
                ? OutlinedButton(
                    onPressed: onDisconnect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Disconnect'),
                  )
                : ElevatedButton(
                    onPressed: onConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: serviceColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Connect'),
                  ),
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFFFF5E5E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectSpotify() async {
    setState(() => _isLoading = true);

    try {
      final success = await EnhancedSpotifyService.authenticate();
      if (mounted) {
        setState(() {
          _spotifyConnected = success && EnhancedSpotifyService.isConnected;
          _isLoading = false;
        });
        
        if (_spotifyConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Spotify connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete Spotify authentication in the browser.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _disconnectSpotify() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        title: const Text('Disconnect Spotify'),
        content: const Text(
          'Are you sure you want to disconnect your Spotify account? Your synced data will remain, but new data won\'t be synced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              EnhancedSpotifyService.disconnect();
              setState(() => _spotifyConnected = false);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Spotify disconnected'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _disconnectAccount(String serviceName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        title: Text('Disconnect $serviceName'),
        content: Text(
          'Are you sure you want to disconnect your $serviceName account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$serviceName disconnected'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String serviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        title: Text('$serviceName Integration'),
        content: Text(
          '$serviceName integration is coming soon! We\'re working hard to bring you this feature.',
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
}
