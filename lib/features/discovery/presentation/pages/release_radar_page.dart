import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/personalized_discovery_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class ReleaseRadarPage extends StatefulWidget {
  const ReleaseRadarPage({super.key});

  @override
  State<ReleaseRadarPage> createState() => _ReleaseRadarPageState();
}

class _ReleaseRadarPageState extends State<ReleaseRadarPage> {
  List<Map<String, dynamic>> _releases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<void> _loadReleases() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final releases = await PersonalizedDiscoveryService.generateReleaseRadar(currentUser.userId);
    setState(() {
      _releases = releases;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Release Radar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReleases,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _releases.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _releases.length,
                  itemBuilder: (context, index) {
                    return _ReleaseCard(release: _releases[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.new_releases, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No New Releases', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Follow more artists to discover new music', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  final Map<String, dynamic> release;

  const _ReleaseCard({required this.release});

  @override
  Widget build(BuildContext context) {
    final name = release['name'] ?? 'Unknown';
    final artist = release['artist'] ?? 'Unknown Artist';
    final date = release['releaseDate'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.album, color: Colors.white, size: 30),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$artist${date.isNotEmpty ? ' • $date' : ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening $name...')),
          );
        },
      ),
    );
  }
}
