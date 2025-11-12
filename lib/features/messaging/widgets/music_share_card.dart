import 'package:flutter/material.dart';
import '../../../shared/models/message.dart';
import '../../../core/theme/app_theme.dart';

class MusicShareCard extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MusicShareCard({
    super.key,
    required this.message,
    required this.isMe,
  });

  String get _shareType {
    switch (message.type) {
      case MessageType.track:
        return 'Şarkı';
      case MessageType.album:
        return 'Albüm';
      case MessageType.playlist:
        return 'Playlist';
      default:
        return '';
    }
  }

  IconData get _shareIcon {
    switch (message.type) {
      case MessageType.track:
        return Icons.music_note;
      case MessageType.album:
        return Icons.album;
      case MessageType.playlist:
        return Icons.playlist_play;
      default:
        return Icons.music_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metadata = message.metadata ?? {};

    final title = metadata['title'] ?? message.content;
    final artist = metadata['artist'] ?? metadata['creator'];
    final imageUrl = metadata['imageUrl'] ?? metadata['coverUrl'];
    final spotifyUrl = metadata['spotifyUrl'];
    final trackCount = metadata['trackCount'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.blue.shade50
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? Colors.blue.shade200
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _shareIcon,
                  size: 16,
                  color: isMe ? Colors.blue.shade700 : AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_shareType paylaşıldı',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Colors.blue.shade700 : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Content
          InkWell(
            onTap: spotifyUrl != null
                ? () {
                    // TODO: Open Spotify URL
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Spotify\'da aç: $spotifyUrl')),
                    );
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  // Cover Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          )
                        : _buildPlaceholderImage(),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (artist != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            artist,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (trackCount != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$trackCount şarkı',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Play Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        // TODO: Play music
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Çalınıyor...')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Spotify Badge
          if (spotifyUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Spotify\'da görüntüle',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _shareIcon,
        color: Colors.grey.shade500,
        size: 30,
      ),
    );
  }
}
