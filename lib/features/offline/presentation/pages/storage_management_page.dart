import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/cache_optimization_service.dart';

class StorageManagementPage extends StatefulWidget {
  const StorageManagementPage({super.key});

  @override
  State<StorageManagementPage> createState() => _StorageManagementPageState();
}

class _StorageManagementPageState extends State<StorageManagementPage> {
  CacheStats _stats = CacheStats(imageSize: 0, dataSize: 0, totalSize: 0, itemCount: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await CacheOptimizationService.getCacheStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _clearCache(String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear $type?'),
        content: const Text('This will free up space but items will need to be downloaded again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (type == 'All Cache') {
        await CacheOptimizationService.clearAllCache();
      } else if (type == 'Image Cache') {
        await CacheOptimizationService.clearExpiredImageCache();
      } else if (type == 'Data Cache') {
        await CacheOptimizationService.clearDataCache();
      }
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$type cleared successfully')),
        );
      }
    }
  }

  Future<void> _optimizeCache() async {
    setState(() => _isLoading = true);
    await CacheOptimizationService.optimizeCache();
    _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache optimized successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage & Cache'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStorageCard(),
                const SizedBox(height: 16),
                _buildCacheCard('Image Cache', _stats.imageSizeFormatted, Icons.image),
                _buildCacheCard('Data Cache', _stats.dataSizeFormatted, Icons.data_usage),
                const SizedBox(height: 24),
                _buildActionButton(
                  'Optimize Cache',
                  'Remove old and unused items',
                  Icons.cleaning_services,
                  Colors.blue,
                  _optimizeCache,
                ),
                _buildActionButton(
                  'Clear Image Cache',
                  'Free up image storage',
                  Icons.image,
                  Colors.orange,
                  () => _clearCache('Image Cache'),
                ),
                _buildActionButton(
                  'Clear Data Cache',
                  'Clear cached data',
                  Icons.data_usage,
                  Colors.purple,
                  () => _clearCache('Data Cache'),
                ),
                _buildActionButton(
                  'Clear All Cache',
                  'Remove all cached data',
                  Icons.delete_forever,
                  Colors.red,
                  () => _clearCache('All Cache'),
                ),
              ],
            ),
    );
  }

  Widget _buildStorageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Color(0xFFFF5E5E)),
                const SizedBox(width: 8),
                const Text(
                  'Total Cache',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _stats.totalSizeFormatted,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${_stats.itemCount} items cached',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheCard(String title, String size, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF5E5E)),
        title: Text(title),
        trailing: Text(
          size,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
