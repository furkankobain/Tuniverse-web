import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/personalized_discovery_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class DailyMixPage extends StatefulWidget {
  const DailyMixPage({super.key});

  @override
  State<DailyMixPage> createState() => _DailyMixPageState();
}

class _DailyMixPageState extends State<DailyMixPage> {
  List<Map<String, dynamic>> _mixes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMixes();
  }

  Future<void> _loadMixes() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final mixes = await PersonalizedDiscoveryService.generateDailyMixes(currentUser.userId);
    setState(() {
      _mixes = mixes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Mix')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMixes,
              child: _mixes.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _mixes.length,
                      itemBuilder: (context, index) {
                        return _MixCard(mix: _mixes[index], index: index);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Mixes Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Listen to more music to get personalized mixes',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MixCard extends StatelessWidget {
  final Map<String, dynamic> mix;
  final int index;

  const _MixCard({required this.mix, required this.index});

  @override
  Widget build(BuildContext context) {
    final name = mix['name'] ?? 'Daily Mix ${index + 1}';
    final description = mix['description'] ?? 'Your personalized mix';
    final trackCount = (mix['tracks'] as List?)?.length ?? 0;

    final gradients = [
      [Colors.blue, Colors.purple],
      [Colors.orange, Colors.red],
      [Colors.green, Colors.teal],
      [Colors.pink, Colors.purple],
      [Colors.indigo, Colors.blue],
      [Colors.amber, Colors.orange],
    ];

    final gradient = gradients[index % gradients.length];

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening $name...')),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.queue_music, color: Colors.white, size: 32),
                const Spacer(),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$trackCount tracks',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
