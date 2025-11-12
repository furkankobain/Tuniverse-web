import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/music_list.dart';
import '../../../shared/models/collaborator.dart';
import '../../../shared/services/playlist_service.dart';
import '../../../shared/services/firebase_bypass_auth_service.dart';
import '../../../core/theme/app_theme.dart';

class ManageCollaboratorsBottomSheet extends StatefulWidget {
  final MusicList playlist;

  const ManageCollaboratorsBottomSheet({
    super.key,
    required this.playlist,
  });

  @override
  State<ManageCollaboratorsBottomSheet> createState() =>
      _ManageCollaboratorsBottomSheetState();
}

class _ManageCollaboratorsBottomSheetState
    extends State<ManageCollaboratorsBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(10)
          .get();

      final currentUserId = FirebaseBypassAuthService.currentUserId ?? '';
      final results = querySnapshot.docs
          .where((doc) =>
              doc.id != currentUserId &&
              doc.id != widget.playlist.userId &&
              !widget.playlist.collaborators.containsKey(doc.id))
          .map((doc) => {
                'id': doc.id,
                'username': doc.data()['username'] ?? '',
                'displayName': doc.data()['displayName'] ?? '',
                'photoURL': doc.data()['photoURL'],
              })
          .toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama hatası: $e')),
        );
      }
    }
  }

  Future<void> _addCollaborator(
    Map<String, dynamic> user,
    CollaboratorRole role,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await PlaylistService.addCollaborator(
        playlistId: widget.playlist.id,
        userId: user['id'],
        username: user['username'],
        displayName: user['displayName'],
        photoURL: user['photoURL'],
        role: role,
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kişi eklendi')),
        );
        _searchController.clear();
        _searchResults = [];
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kişi eklenirken hata oluştu')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _removeCollaborator(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaldır?'),
        content: const Text('Bu kişiyi playlist\'ten kaldırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await PlaylistService.removeCollaborator(
        playlistId: widget.playlist.id,
        collaboratorUserId: userId,
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kişi kaldırıldı')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kişi kaldırılırken hata oluştu')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _changeRole(String userId, CollaboratorRole newRole) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await PlaylistService.updateCollaboratorRole(
        playlistId: widget.playlist.id,
        collaboratorUserId: userId,
        newRole: newRole,
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol güncellendi')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol güncellenirken hata oluştu')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'İşbirlikçileri Yönet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kullanıcı ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Search Results
          if (_searchResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Arama Sonuçları',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              _searchResults.length,
              (index) => _buildSearchResultTile(_searchResults[index], isDark),
            ),
            const Divider(height: 32),
          ],

          // Current Collaborators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'İşbirlikçiler',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${widget.playlist.collaborators.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Collaborators List
          Expanded(
            child: widget.playlist.collaborators.isEmpty
                ? Center(
                    child: Text(
                      'Henüz işbirlikçi eklenmedi',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.playlist.collaborators.length,
                    itemBuilder: (context, index) {
                      final entry =
                          widget.playlist.collaborators.entries.elementAt(index);
                      return _buildCollaboratorTile(
                        entry.key,
                        entry.value,
                        isDark,
                      );
                    },
                  ),
          ),

          if (_isLoading)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> user, bool isDark) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
        backgroundImage:
            user['photoURL'] != null ? NetworkImage(user['photoURL']) : null,
        child: user['photoURL'] == null
            ? Text(
                user['displayName']?.isNotEmpty == true
                    ? user['displayName'][0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user['displayName'] ?? user['username'],
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '@${user['username']}',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: PopupMenuButton<CollaboratorRole>(
        icon: Icon(
          Icons.person_add,
          color: AppTheme.primaryColor,
        ),
        onSelected: (role) => _addCollaborator(user, role),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: CollaboratorRole.editor,
            child: Row(
              children: [
                const Icon(Icons.edit, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(CollaboratorRole.editor.displayName),
                    Text(
                      CollaboratorRole.editor.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: CollaboratorRole.viewer,
            child: Row(
              children: [
                const Icon(Icons.visibility, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(CollaboratorRole.viewer.displayName),
                    Text(
                      CollaboratorRole.viewer.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorTile(
    String userId,
    Collaborator collaborator,
    bool isDark,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
        backgroundImage: collaborator.photoURL != null
            ? NetworkImage(collaborator.photoURL!)
            : null,
        child: collaborator.photoURL == null
            ? Text(
                collaborator.displayName?.isNotEmpty == true
                    ? collaborator.displayName![0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        collaborator.displayName ?? collaborator.username,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@${collaborator.username}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getRoleColor(collaborator.role).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              collaborator.role.displayName,
              style: TextStyle(
                color: _getRoleColor(collaborator.role),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        itemBuilder: (context) => [
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 12),
                Text('Düzenleyici Yap'),
              ],
            ),
            onTap: () => _changeRole(userId, CollaboratorRole.editor),
          ),
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.visibility, size: 20),
                SizedBox(width: 12),
                Text('İzleyici Yap'),
              ],
            ),
            onTap: () => _changeRole(userId, CollaboratorRole.viewer),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('Kaldır', style: TextStyle(color: Colors.red)),
              ],
            ),
            onTap: () => _removeCollaborator(userId),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(CollaboratorRole role) {
    switch (role) {
      case CollaboratorRole.owner:
        return Colors.purple;
      case CollaboratorRole.editor:
        return Colors.green;
      case CollaboratorRole.viewer:
        return Colors.blue;
    }
  }
}
