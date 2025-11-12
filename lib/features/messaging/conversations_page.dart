import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../shared/models/conversation.dart';
import '../../shared/models/spotify_activity.dart';
import '../../shared/services/messaging_service.dart';
import '../../shared/services/firebase_bypass_auth_service.dart';
import '../../shared/services/spotify_activity_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/skeleton_widgets.dart' as skeleton_widgets;
import '../../shared/services/error_handler_service.dart';
import '../../shared/widgets/error_state_widget.dart';
import 'chat_page.dart';
import 'user_search_page.dart';
import 'modern_conversations_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('en_US', null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE', 'en_US').format(timestamp);
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Forward to the modern conversations page so both routes show the same UI
    return const ModernConversationsPage();
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    String currentUserId,
    bool isDark,
  ) {
    final otherUserName = conversation.getOtherParticipantName(currentUserId);
    final otherUserAvatar = conversation.getOtherParticipantAvatar(currentUserId);
    final unreadCount = conversation.getUnreadCountForUser(currentUserId);
    final isTyping = conversation.isOtherUserTyping(currentUserId);
    final isPinned = conversation.pinnedBy?.contains(currentUserId) ?? false;
    final isMuted = conversation.mutedBy?.contains(currentUserId) ?? false;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(conversation: conversation),
          ),
        );
      },
      onLongPress: () {
        _showConversationOptions(context, conversation, currentUserId, isDark);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPinned
              ? (isDark ? Colors.grey[850] : Colors.grey[50])
              : (isDark ? AppTheme.backgroundColor : Colors.white),
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  backgroundImage: otherUserAvatar != null
                      ? NetworkImage(otherUserAvatar)
                      : null,
                  child: otherUserAvatar == null
                      ? Text(
                          otherUserName.isNotEmpty
                              ? otherUserName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Online indicator (placeholder)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey[900]! : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (isPinned) ...[
                              Icon(
                                Icons.push_pin,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                otherUserName,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMuted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.volume_off,
                                size: 14,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        _formatTimestamp(conversation.lastMessageTime),
                        style: TextStyle(
                          color: unreadCount > 0
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.grey[500] : Colors.grey[600]),
                          fontSize: 12,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isTyping
                              ? 'typing...'
                              : conversation.lastMessage ?? 'No messages',
                          style: TextStyle(
                            color: isTyping
                                ? AppTheme.primaryColor
                                : (unreadCount > 0
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark ? Colors.grey[400] : Colors.grey[600])),
                            fontSize: 14,
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                            fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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

  Widget _buildEmpty(bool isDark) {
    return EmptyStateWidget(
      title: 'Send Your First Message',
      description: 'Click the + button to start a chat with your friends',
      icon: Icons.chat_bubble_outline,
      actionButtonLabel: 'Start Chat',
      onActionPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UserSearchPage(),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(
    bool isDark,
    dynamic exception,
    VoidCallback onRetry,
  ) {
    return ErrorStateWidget(
      exception: exception,
      onRetry: onRetry,
      showRetryButton: true,
    );
  }

  void _loadConversations(String currentUserId) {
    // Trigger rebuild to retry loading conversations
    setState(() {});
  }

  Widget _buildNotLoggedIn(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sign In',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need to sign in to message',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildActivityNotes(bool isDark) {
    // TODO: Get following user IDs from a follow service
    final followingUserIds = <String>[]; // Placeholder

    if (followingUserIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.only(left: 8),
      child: StreamBuilder<List<SpotifyActivity>>(
        stream: SpotifyActivityService.getFollowingActivities(followingUserIds),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final activities = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityNote(activity, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityNote(SpotifyActivity activity, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          Stack(
            children: [
              // Album art circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activity.isCurrentlyListening
                        ? AppTheme.primaryColor
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                  image: activity.albumImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(activity.albumImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: activity.albumImageUrl == null
                    ? Icon(Icons.music_note, color: Colors.grey[400])
                    : null,
              ),
              // Playing indicator
              if (activity.isCurrentlyListening)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey[900]! : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              activity.statusText,
              style: TextStyle(
                color: activity.isCurrentlyListening
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 10,
                fontWeight: activity.isCurrentlyListening
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(
    BuildContext context,
    Conversation conversation,
    String currentUserId,
    bool isDark,
  ) {
    final isPinned = conversation.pinnedBy?.contains(currentUserId) ?? false;
    final isMuted = conversation.mutedBy?.contains(currentUserId) ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.grey[900] : Colors.white)?.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  ListTile(
                    leading: Icon(
                      isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    title: Text(
                      isPinned ? 'Unpin' : 'Pin',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await MessagingService.togglePinConversation(conversation.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isPinned ? 'Pinned removed' : 'Conversation pinned'),
                          ),
                        );
                      }
                    },
                  ),
                  
                  ListTile(
                    leading: Icon(
                      isMuted ? Icons.volume_up : Icons.volume_off,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    title: Text(
                      isMuted ? 'Unmute' : 'Mute',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (!isMuted) {
                        _showMuteOptions(context, conversation, isDark);
                      } else {
                        MessagingService.unmuteConversation(conversation.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mute removed')),
                        );
                      }
                    },
                  ),
                  
                  Divider(height: 1, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Delete Conversation',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Conversation'),
                          content: const Text(
                            'Are you sure you want to delete this conversation? '
                            'All messages will be permanently deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        final success = await MessagingService.deleteConversation(
                          conversation.id,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success ? 'Conversation deleted' : 'Failed to delete conversation',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMuteOptions(
    BuildContext context,
    Conversation conversation,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'How long would you like to mute this conversation?',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                ListTile(
                  title: Text(
                    '8 Hours',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await MessagingService.muteConversation(
                      conversation.id,
                      const Duration(hours: 8),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Muted for 8 hours')),
                      );
                    }
                  },
                ),
                
                ListTile(
                  title: Text(
                    '1 Week',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await MessagingService.muteConversation(
                      conversation.id,
                      const Duration(days: 7),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Muted for 1 week')),
                      );
                    }
                  },
                ),
                
                ListTile(
                  title: Text(
                    'Forever',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await MessagingService.muteConversation(
                      conversation.id,
                      null, // null means forever
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Permanently muted')),
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(bool isDark, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'An error occurred',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
