import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/music_list.dart';
import '../../shared/services/playlist_service.dart';
import 'playlist_detail_page.dart';

/// Loads a playlist by ID and navigates to detail page
/// Used for deep linking: musicshare://playlist/{playlistId}
class PlaylistLoaderPage extends StatefulWidget {
  final String playlistId;

  const PlaylistLoaderPage({super.key, required this.playlistId});

  @override
  State<PlaylistLoaderPage> createState() => _PlaylistLoaderPageState();
}

class _PlaylistLoaderPageState extends State<PlaylistLoaderPage> {
  bool _isLoading = true;
  String? _error;
  MusicList? _playlist;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    try {
      final playlist = await PlaylistService.getPlaylistById(widget.playlistId);
      
      if (!mounted) return;

      if (playlist != null) {
        setState(() {
          _playlist = playlist;
          _isLoading = false;
        });

        // Navigate to playlist detail after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            // Replace current route with playlist detail
            context.go('/', extra: playlist);
            context.push('/playlist-detail', extra: playlist);
          }
        });
      } else {
        setState(() {
          _error = 'Playlist bulunamadı';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Playlist yüklenirken hata oluştu';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Playlist yükleniyor...',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.home),
                        label: const Text('Ana Sayfaya Dön'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
