import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../core/theme/app_theme.dart';

/// Activity timeline widget showing chronological user activities
class ActivityTimeline extends StatefulWidget {
  final String userId;
  final int limit;

  const ActivityTimeline({
    super.key,
    required this.userId,
    this.limit = 20,
  });

  @override
  State<ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends State<ActivityTimeline> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _activities = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _loadActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('activities')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .limit(widget.limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      _lastDocument = snapshot.docs.last;

      final newActivities = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      setState(() {
        _activities.addAll(newActivities);
        _isLoading = false;
        if (snapshot.docs.length < widget.limit) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Aktivite Zaman Çizelgesi',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline
          if (_activities.isEmpty && !_isLoading)
            _buildEmptyState(isDark)
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _activities.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _activities.length) {
                    return _buildLoadingIndicator();
                  }

                  final activity = _activities[index];
                  final isLast = index == _activities.length - 1;

                  return _buildTimelineItem(
                    activity,
                    isDark,
                    isLast: isLast,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    Map<String, dynamic> activity,
    bool isDark, {
    bool isLast = false,
  }) {
    final type = activity['type'] as String? ?? 'unknown';
    final timestamp = activity['timestamp'] as Timestamp?;
    final data = activity['data'] as Map<String, dynamic>? ?? {};

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line
          Column(
            children: [
              _buildActivityIcon(type, isDark),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActivityContent(type, data, isDark),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 12,
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

  Widget _buildActivityIcon(String type, bool isDark) {
    IconData icon;
    Color color;

    switch (type) {
      case 'listen':
        icon = Icons.play_circle_filled;
        color = Colors.green;
        break;
      case 'rating':
        icon = Icons.star;
        color = Colors.orange;
        break;
      case 'comment':
        icon = Icons.comment;
        color = Colors.blue;
        break;
      case 'playlist':
        icon = Icons.playlist_add;
        color = Colors.purple;
        break;
      case 'follow':
        icon = Icons.person_add;
        color = Colors.pink;
        break;
      case 'like':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildActivityContent(
    String type,
    Map<String, dynamic> data,
    bool isDark,
  ) {
    String title;
    String? subtitle;

    switch (type) {
      case 'listen':
        title = '${data['trackName'] ?? 'Bilinmeyen Şarkı'} dinledi';
        subtitle = data['artistName'] as String?;
        break;
      case 'rating':
        final rating = data['rating'] ?? 0;
        title = '${data['trackName'] ?? 'Bir şarkıya'} $rating⭐ puan verdi';
        subtitle = data['artistName'] as String?;
        break;
      case 'comment':
        title = '${data['trackName'] ?? 'Bir şarkıya'} yorum yaptı';
        subtitle = data['comment'] as String?;
        break;
      case 'playlist':
        final action = data['action'] ?? 'created';
        title = action == 'created'
            ? '${data['playlistName'] ?? 'Yeni'} çalma listesi oluşturdu'
            : '${data['playlistName'] ?? 'Çalma listesini'} güncelledi';
        break;
      case 'follow':
        title = '${data['username'] ?? 'Birini'} takip etmeye başladı';
        break;
      case 'like':
        title = '${data['trackName'] ?? 'Bir şarkıyı'} beğendi';
        subtitle = data['artistName'] as String?;
        break;
      default:
        title = 'Bilinmeyen aktivite';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy', 'tr_TR').format(date);
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz aktivite yok',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
