import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/services/queue_service.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalma Kuyruğu'),
        actions: [
          // Shuffle button
          ValueListenableBuilder<bool>(
            valueListenable: QueueService.shuffleNotifier,
            builder: (context, isShuffled, _) {
              return IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: isShuffled ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: () async {
                  await QueueService.toggleShuffle();
                },
                tooltip: 'Karıştır',
              );
            },
          ),
          // Repeat button
          ValueListenableBuilder<RepeatMode>(
            valueListenable: QueueService.repeatModeNotifier,
            builder: (context, repeatMode, _) {
              IconData icon;
              Color? color;
              
              switch (repeatMode) {
                case RepeatMode.off:
                  icon = Icons.repeat;
                  color = null;
                  break;
                case RepeatMode.all:
                  icon = Icons.repeat;
                  color = Theme.of(context).colorScheme.primary;
                  break;
                case RepeatMode.one:
                  icon = Icons.repeat_one;
                  color = Theme.of(context).colorScheme.primary;
                  break;
              }
              
              return IconButton(
                icon: Icon(icon, color: color),
                onPressed: () async {
                  await QueueService.cycleRepeatMode();
                },
                tooltip: 'Tekrar Modu',
              );
            },
          ),
          // Clear queue
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Kuyruğu Temizle'),
                  content: const Text('Tüm şarkıları kuyruktan kaldırmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                await QueueService.clearQueue();
              }
            },
            tooltip: 'Kuyruğu Temizle',
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: QueueService.queueNotifier,
        builder: (context, queue, _) {
          if (queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kuyruk Boş',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Çalmak için şarkı ekleyin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ValueListenableBuilder<int>(
            valueListenable: QueueService.currentIndexNotifier,
            builder: (context, currentIndex, _) {
              return ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: queue.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  await QueueService.reorderQueue(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final track = queue[index];
                  final isCurrentTrack = index == currentIndex;
                  final trackName = track['name'] as String? ?? 'Unknown';
                  final artists = track['artists'] as List?;
                  final artistName = artists?.isNotEmpty == true 
                      ? artists!.first['name'] as String? ?? 'Unknown'
                      : 'Unknown';
                  final albumImages = track['album']?['images'] as List?;
                  final imageUrl = albumImages?.isNotEmpty == true
                      ? albumImages!.first['url'] as String?
                      : null;

                  return ReorderableDragStartListener(
                    key: ValueKey('${track['id']}_$index'),
                    index: index,
                    child: Dismissible(
                      key: ValueKey('dismissible_${track['id']}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (isCurrentTrack) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Çalan şarkı kuyruktan kaldırılamaz'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return false;
                        }
                        return true;
                      },
                      onDismissed: (direction) async {
                        await QueueService.removeFromQueue(index);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$trackName kuyruktan kaldırıldı'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        color: isCurrentTrack 
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : null,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Drag handle
                              Icon(
                                Icons.drag_handle,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              // Album art
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.music_note),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.music_note),
                                        ),
                                      )
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.music_note),
                                      ),
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              if (isCurrentTrack) ...[
                                Icon(
                                  Icons.play_circle_filled,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  trackName,
                                  style: TextStyle(
                                    fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrentTrack 
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: !isCurrentTrack
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'play_next':
                                        await QueueService.removeFromQueue(index);
                                        await QueueService.playNext(track);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('$trackName sıradaki şarkı olarak ayarlandı'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                        break;
                                      case 'remove':
                                        await QueueService.removeFromQueue(index);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('$trackName kuyruktan kaldırıldı'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'play_next',
                                      child: Row(
                                        children: [
                                          Icon(Icons.skip_next),
                                          SizedBox(width: 12),
                                          Text('Sonraki Çal'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline),
                                          SizedBox(width: 12),
                                          Text('Kuyruktan Kaldır'),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          onTap: () async {
                            await QueueService.jumpToIndex(index);
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
