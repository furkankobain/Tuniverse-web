import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/analytics_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class ListeningClockPage extends StatefulWidget {
  const ListeningClockPage({super.key});

  @override
  State<ListeningClockPage> createState() => _ListeningClockPageState();
}

class _ListeningClockPageState extends State<ListeningClockPage> {
  Map<String, dynamic> _clockData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final hourlyData = await AnalyticsService.getListeningClock(currentUser.userId);
    setState(() {
      // Convert Map<int, int> to Map<String, dynamic>
      _clockData = {
        'hourlyData': hourlyData.map((key, value) => MapEntry(key.toString(), value)),
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listening Clock')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildClockVisualization(),
                  const SizedBox(height: 24),
                  _buildPeakHours(),
                  const SizedBox(height: 24),
                  _buildHourlyBreakdown(),
                ],
              ),
            ),
    );
  }

  Widget _buildClockVisualization() {
    final peakHour = _clockData['peakHour'] ?? 0;
    final peakCount = _clockData['peakCount'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.access_time, size: 80, color: Color(0xFFFF5E5E)),
            const SizedBox(height: 16),
            const Text(
              'Most Active Hour',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '${peakHour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$peakCount plays',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHours() {
    final hourlyData = _clockData['hourlyData'] as Map<String, dynamic>? ?? {};
    
    // Get top 3 hours
    final sortedHours = hourlyData.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    final top3 = sortedHours.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peak Listening Times',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...top3.asMap().entries.map((entry) {
              final index = entry.key;
              final hour = int.parse(entry.value.key);
              final count = entry.value.value as int;
              final medals = ['🥇', '🥈', '🥉'];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(medals[index], style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$count plays',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyBreakdown() {
    final hourlyData = _clockData['hourlyData'] as Map<String, dynamic>? ?? {};
    final maxCount = hourlyData.values.fold<int>(0, (max, val) => val > max ? val as int : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '24-Hour Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(24, (hour) {
              final count = hourlyData[hour.toString()] as int? ?? 0;
              final percentage = maxCount > 0 ? count / maxCount : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage,
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF5E5E),
                                    const Color(0xFFFF5E5E).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        count.toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
