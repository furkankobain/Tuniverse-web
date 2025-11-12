import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../shared/models/music_list.dart';
import '../../shared/services/playlist_service.dart';
import '../../shared/services/firebase_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/modern_design_system.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditPlaylistPage extends StatefulWidget {
  final MusicList playlist;

  const EditPlaylistPage({super.key, required this.playlist});

  @override
  State<EditPlaylistPage> createState() => _EditPlaylistPageState();
}

class _EditPlaylistPageState extends State<EditPlaylistPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isPublic;
  late List<String> _tags;
  bool _isUpdating = false;
  File? _selectedImage;
  String? _currentCoverUrl;
  bool _removeCurrentCover = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.playlist.title);
    _descriptionController = TextEditingController(text: widget.playlist.description ?? '');
    _isPublic = widget.playlist.isPublic;
    _tags = List.from(widget.playlist.tags);
    _currentCoverUrl = widget.playlist.coverImage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = source == ImageSource.gallery
        ? await FirebaseStorageService.pickImageFromGallery()
        : await FirebaseStorageService.pickImageFromCamera();

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _removeCurrentCover = false;
      });
    }
  }

  void _showImagePickerOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              leading: Icon(Icons.photo_library, color: isDark ? Colors.white : Colors.black87),
              title: Text('Galeriden Seç', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: isDark ? Colors.white : Colors.black87),
              title: Text('Fotoğraf Çek', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_selectedImage != null || _currentCoverUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Resmi Kaldır', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _removeCurrentCover = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePlaylist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      String? newCoverUrl = _currentCoverUrl;

      // Upload new cover if selected
      if (_selectedImage != null) {
        newCoverUrl = await FirebaseStorageService.uploadPlaylistCover(
          _selectedImage!,
          widget.playlist.id,
        );
      } else if (_removeCurrentCover) {
        newCoverUrl = null;
      }

      // Update playlist
      final success = await PlaylistService.updatePlaylist(
        playlistId: widget.playlist.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isPublic: _isPublic,
        tags: _tags,
        coverImage: newCoverUrl,
      );

      if (!mounted) return;

      setState(() => _isUpdating = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist güncellendi!')),
        );
        context.pop(true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncellenemedi')),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
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
          'Playlist Düzenle',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updatePlaylist,
              child: Text(
                'Kaydet',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover Image
            Center(
              child: GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : _currentCoverUrl != null && !_removeCurrentCover
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                              child: CachedNetworkImage(
                                imageUrl: _currentCoverUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.music_note,
                                  size: 80,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Cover',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'Give your music list a name',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add information about the playlist',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                ),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Privacy Toggle
            SwitchListTile(
              title: Text(
                'Public',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _isPublic
                    ? 'Everyone can see this playlist'
                    : 'Only you can see this playlist',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
              ),
              tileColor: isDark ? Colors.grey[850] : Colors.white,
            ),

            const SizedBox(height: 24),

            // Tags Section
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Current Tags
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    deleteIconColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(color: AppTheme.primaryColor),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // Add Tag
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Add tag',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                      ),
                    ),
                    onSubmitted: (value) {
                      _addTag(value.trim().toLowerCase());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
