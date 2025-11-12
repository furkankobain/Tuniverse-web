import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../shared/models/play_history.dart';
import '../../shared/services/spotify_service.dart';
import '../../core/theme/app_theme.dart';

class RecentlyPlayedPage extends StatefulWidget {
  const RecentlyPlayedPage({super.key});

  @override
  State<RecentlyPlayedPage> createState() => _RecentlyPlayedPageState();
}

class _RecentlyPlayedPageState extends State<RecentlyPlayedPage> {
  List<PlayHistory> _playHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _loadRecentlyPlayed();
  }

  Future<void> _loadRecentlyPlayed() async {
    setState(() => _isLoading = true);
    
    try {
      final tracks = await SpotifyService.getRecentlyPlayed(limit: 50);
      if (!mounted) return;
      
      setState(() {
        _playHistory = tracks.map((track) => PlayHistory.fromSpotify(track)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<PlayHistory> get _filteredHistory {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'today':
        return _playHistory.where((track) {
          return track.playedAt.day == now.day &&
                 track.playedAt.month == now.month &&
                 track.playedAt.year == now.year;
        }).toList();
      
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _playHistory.where((track) => track.playedAt.isAfter(weekAgo)).toList();
      
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        return _playHistory.where((track) => track.playedAt.isAfter(monthAgo)).toList();
      
      default:
        return _playHistory;
    }
  }

  Map<String, List<PlayHistory>> get _groupedByDate {
    final filtered = _filteredHistory;
    final Map<String, List<PlayHistory>> grouped = {};
    
    for (final track in filtered) {
      final dateKey = DateFormat('yyyy-MM-dd').format(track.playedAt);
      grouped.putIfAbsent(dateKey, () => []).add(track);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        title: Text(
          'Dinleme Geçmişi',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(isDark),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _playHistory.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildTimelineView(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tümü', 'all', isDark),
            const SizedBox(width: 12),
            _buildFilterChip('Bugün', 'today', isDark),
            const SizedBox(width: 12),
            _buildFilterChip('Bu Hafta', 'week', isDark),
            const SizedBox(width: 12),
            _buildFilterChip('Bu Ay', 'month', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz dinleme geçmişi yok',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Spotify\'da müzik dinlemeye başla!',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView(bool isDark) {
    final grouped = _groupedByDate;
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadRecentlyPlayed,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final tracks = grouped[dateKey]!;
          final date = DateTime.parse(dateKey);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(date, isDark),
              const SizedBox(height: 12),
              ...tracks.map((track) => _buildTrackCard(track, isDark)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, bool isDark) {
    final now = DateTime.now();
    final isToday = date.day == now.day && 
                     date.month == now.month && 
                     date.year == now.year;
    final isYesterday = date.day == now.day - 1 && 
                         date.month == now.month && 
                         date.year == now.year;
    
    String dateText;
    if (isToday) {
      dateText = 'Bugün';
    } else if (isYesterday) {
      dateText = 'Dün';
    } else {
      dateText = DateFormat('d MMMM yyyy', 'tr').format(date);
    }

    return Row(
      children: [
        Container(
          height: 1,
          width: 40,
          color: isDark ? Colors.grey[800] : Colors.grey[300],
        ),
        const SizedBox(width: 12),
        Text(
          dateText,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackCard(PlayHistory track, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/track-detail',
            arguments: {
              'trackId': track.trackId,
              'trackName': track.trackName,
              'artistName': track.artistName,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: track.albumImageUrl != null
                    ? Image.network(
                        track.albumImageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(isDark),
                      )
                    : _buildPlaceholderImage(isDark),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.trackName,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artistName,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          track.relativeTime,
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '• ${track.formattedDuration}',
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              IconButton(
                icon: Icon(Icons.more_vert, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                onPressed: () => _showTrackOptions(track, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: 24,
      ),
    );
  }

  void _showTrackOptions(PlayHistory track, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.note_add, color: isDark ? Colors.white : Colors.black87),
              title: Text('Not Ekle', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.favorite_border, color: isDark ? Colors.white : Colors.black87),
              title: Text('Favorilere Ekle', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.playlist_add, color: isDark ? Colors.white : Colors.black87),
              title: Text('Listeye Ekle', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.share, color: isDark ? Colors.white : Colors.black87),
              title: Text('Paylaş', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
