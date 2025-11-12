import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/models/conversation.dart';
import '../../shared/services/messaging_service.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/services/spotify_activity_service.dart';
import '../../shared/models/spotify_activity.dart';
import '../../shared/services/follow_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../social/presentation/pages/user_profile_page.dart';
import '../music/presentation/pages/track_detail_page.dart';
import '../../shared/widgets/empty_state_widget.dart';
import 'modern_chat_page.dart';
import 'user_search_page.dart';
import 'message_requests_page.dart';
import 'create_group_page.dart';

class ModernConversationsPage extends StatefulWidget {
  const ModernConversationsPage({super.key});

  @override
  State<ModernConversationsPage> createState() => _ModernConversationsPageState();
}

class _ModernConversationsPageState extends State<ModernConversationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<String> _followingIds = [];
  bool _loadingNotes = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  String? _uid() => FirebaseService.auth.currentUser?.uid;

  Future<void> _loadFollowing() async {
    final uid = _uid();
    if (uid == null) {
      setState(() {
        _followingIds = [];
        _loadingNotes = false;
      });
      return;
    }
    try {
      final list = await FollowService.getFollowing(uid);
      if (mounted) {
        setState(() {
          _followingIds = list;
          _loadingNotes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingNotes = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseService.auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),
            // Notes (Now Playing / Recently Played)
            _buildNowPlayingStories(isDark),
            // Conversations
            Expanded(
              child: currentUserId == null
                  ? _buildNotLoggedIn(isDark)
                  : StreamBuilder<List<Conversation>>(
                      stream: MessagingService.getConversations(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildLoadingSkeleton(isDark);
                        }

                        final conversations = snapshot.data ?? [];
                        
                        if (conversations.isEmpty && _searchQuery.isEmpty) {
                          return _buildEmptyState(isDark);
                        }

                        final filtered = _filterConversations(conversations, currentUserId);

                        if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                          return _buildNoResults(isDark);
                        }

                        return ListView.builder(
                          itemCount: filtered.length,
                          padding: const EdgeInsets.only(top: 8),
                          itemBuilder: (context, index) {
                            return _buildConversationTile(
                              filtered[index],
                              currentUserId,
                              isDark,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final displayName = FirebaseService.auth.currentUser?.displayName ??
        (FirebaseService.auth.currentUser?.email?.split('@').first ?? 'Messages');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: centered username, right: group add
          Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: AppLocalizations.of(context).t('new_group'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateGroupPage()),
                    );
                  },
                  icon: Icon(Icons.group_add, color: isDark ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Persistent search box
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).t('search'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingStories(bool isDark) {
    final userId = _uid();
    final ids = [if (userId != null) userId, ..._followingIds];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MessageRequestsPage()),
                    );
                  },
                  child: const Text('Requests'),
                ),
              ],
            ),
          ),
          // Notes row
          _loadingNotes || userId == null
              ? _buildNotesFallback(isDark)
              : StreamBuilder<List<SpotifyActivity>>(
                  stream: SpotifyActivityService.getFollowingActivities(ids),
                  builder: (context, snapshot) {
                    final allActivities = snapshot.data ?? [];
                    if (allActivities.isEmpty) return _buildNotesFallback(isDark);
                    
                    // Separate current user's activity and others
                    final myActivity = allActivities.where((a) => a.userId == userId).toList();
                    final othersActivities = allActivities.where((a) => a.userId != userId).toList();
                    
                    // Combine: My activity first, then others
                    final sortedActivities = [...myActivity, ...othersActivities];
                    
                    if (sortedActivities.isEmpty) return _buildNotesFallback(isDark);
                    
                    return SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sortedActivities.length,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final a = sortedActivities[index];
                          final isMe = a.userId == userId;
                          return _buildNotesAvatar(a, isDark, isCurrentUser: isMe);
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildNotesAvatar(SpotifyActivity activity, bool isDark, {bool isCurrentUser = false}) {
    final now = DateTime.now();
    final timeDiff = now.difference(activity.timestamp);
    final playing = activity.isPlaying && timeDiff.inMinutes < 2;
    final ringColor = playing ? AppTheme.primaryColor : (isDark ? Colors.grey[700]! : Colors.grey[400]!);
    final initials = activity.userId.isNotEmpty ? activity.userId[0].toUpperCase() : 'U';
    final caption = activity.trackName.isNotEmpty ? activity.trackName : '…';
    
    // Format timestamp
    String timeAgo;
    if (playing) {
      timeAgo = 'Now playing';
    } else if (timeDiff.inMinutes < 60) {
      timeAgo = '${timeDiff.inMinutes}m ago';
    } else if (timeDiff.inHours < 24) {
      timeAgo = '${timeDiff.inHours}h ago';
    } else {
      timeAgo = '${timeDiff.inDays}d ago';
    }

    void openActions() {
      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Open Profile'),
                  onTap: () async {
                    Navigator.pop(context);
                    final userSnap = await FirebaseFirestore.instance.collection('users').doc(activity.userId).get();
                    final username = (userSnap.data()?['username'] ?? userSnap.data()?['displayName'] ?? 'User') as String;
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(userId: activity.userId, username: username),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.music_note),
                  title: const Text('Open Track'),
                  onTap: () {
                    Navigator.pop(context);
                    final trackMap = {
                      'id': activity.trackId,
                      'name': activity.trackName,
                      'artists': [
                        {'name': activity.artistName}
                      ],
                      'album': {
                        'name': activity.albumName,
                        'images': [
                          if (activity.albumImageUrl != null) {'url': activity.albumImageUrl}
                        ],
                      },
                      'external_urls': {},
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrackDetailPage(track: trackMap),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: openActions,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: playing ? 3 : 2),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(activity.userId).snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final photo = (data?['profileImageUrl'] ?? data?['photoURL']) as String?;
                        if (photo != null && photo.isNotEmpty) {
                          return Image.network(photo, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _initialsAvatar(initials, isDark),
                          );
                        }
                        return _initialsAvatar(initials, isDark);
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Caption bubble like Instagram Notes
            Positioned(
              top: -6,
              left: -6,
              right: -6,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 90),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ringColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey[400]!).withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (!playing)
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: openActions,
          child: SizedBox(
            width: 72,
            child: Text(
              isCurrentUser ? 'You' : activity.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                color: isCurrentUser 
                    ? AppTheme.primaryColor 
                    : (isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesFallback(bool isDark) {
    // Show empty state when no activities are available
    return SizedBox(
      height: 116,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 32,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Follow friends to see what they\'re listening to',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[700] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialsAvatar(String initials, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[850] : Colors.grey[200],
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsRow(bool isDark) {
    final uid = _uid();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('follow_requests')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MessageRequestsPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C0C0C) : Colors.white,
              border: Border(
                bottom: BorderSide(color: isDark ? Colors.grey[900]! : Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.mail_outline, color: isDark ? Colors.white : Colors.black54),
                const SizedBox(width: 12),
                const Text('Requests', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black54),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpotifyActivityCard(SpotifyActivity activity, String timeText, bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activity.isPlaying
              ? AppTheme.primaryColor
              : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          width: activity.isPlaying ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // User info
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[850] : Colors.grey[200],
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your activity',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 10,
                        color: activity.isPlaying
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.grey[500] : Colors.grey[600]),
                        fontWeight: activity.isPlaying ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Track info
          Row(
            children: [
              Icon(
                activity.isPlaying ? Icons.music_note : Icons.history,
                size: 14,
                color: activity.isPlaying
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${activity.trackName} • ${activity.artistName}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv, String currentUserId, bool isDark) {
    final otherUserName = conv.getOtherParticipantName(currentUserId);
    final hasUnread = conv.getUnreadCountForUser(currentUserId) > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModernChatPage(
              conversationId: conv.id,
              otherUserId: conv.getOtherParticipantId(currentUserId),
              otherUserName: otherUserName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                  ),
                  child: Center(
                    child: Text(
                      otherUserName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                // Online indicator (TODO: add online status to Conversation model)
                /*
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D774),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF000000) : Colors.white,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
                */
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(conv.lastMessageTime),
                        style: TextStyle(
                          fontSize: 13,
                          color: hasUnread
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.grey[500] : Colors.grey[600]),
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.grey[500] : Colors.grey[600]),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              conv.getUnreadCountForUser(currentUserId) > 9 ? '9+' : '${conv.getUnreadCountForUser(currentUserId)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Conversation> _filterConversations(List<Conversation> conversations, String userId) {
    if (_searchQuery.isEmpty) return conversations;
    return conversations.where((conv) {
      final name = conv.getOtherParticipantName(userId).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEE').format(time);
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[850] : Colors.grey[200],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation to connect with friends',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserSearchPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Start Chatting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(bool isDark) {
    return EmptyStateWidget(
      title: 'No Results',
      description: 'No conversations found',
      icon: Icons.search_off,
    );
  }

  Widget _buildNotLoggedIn(bool isDark) {
    return EmptyStateWidget(
      title: 'Not Logged In',
      description: 'Please log in to see your messages',
      icon: Icons.login,
    );
  }
}
