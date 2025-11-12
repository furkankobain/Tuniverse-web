import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  List<Map<String, dynamic>> _results = [];
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    final query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('username')
        .startAt([q])
        .endAt(['${q}\uf8ff'])
        .limit(20);
    final snap = await query.get();
    setState(() {
      _results = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  Future<void> _createGroup() async {
    final uid = FirebaseService.auth.currentUser?.uid;
    if (uid == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedUserIds.isEmpty) return;

    setState(() => _creating = true);
    try {
      final members = <String>{uid, ..._selectedUserIds}.toList();
      final ref = FirebaseFirestore.instance.collection('group_chats').doc();
      await ref.set({
        'id': ref.id,
        'name': name,
        'memberIds': members,
        'admins': [uid],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTime': null,
      });
      if (mounted) Navigator.pop(context, ref.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grup oluşturulamadı: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Grup'),
        actions: [
          TextButton(
            onPressed: _creating ? null : _createGroup,
            child: const Text('Oluştur'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Grup adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Kullanıcı ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedUserIds.map((id) => Chip(
                label: Text(id),
                onDeleted: () => setState(() => _selectedUserIds.remove(id)),
              )).toList(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final u = _results[index];
                  final id = u['id'] as String;
                  final selected = _selectedUserIds.contains(id);
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(u['username'] ?? u['displayName'] ?? id),
                    subtitle: Text(u['email'] ?? ''),
                    trailing: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected ? AppTheme.primaryColor : (isDark ? Colors.grey[600] : Colors.grey[500]),
                    ),
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedUserIds.remove(id);
                        } else {
                          _selectedUserIds.add(id);
                        }
                      });
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
}