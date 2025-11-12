import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/services/firebase_service.dart';

class MessageRequestsPage extends StatelessWidget {
  const MessageRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseService.auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
      ),
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: uid == null
          ? const Center(child: Text('Giriş yapın'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('follow_requests')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'İstek yok',
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => Divider(color: isDark ? Colors.grey[900] : Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final requesterId = data['requesterId'] as String? ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      title: Text(requesterId, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                      subtitle: const Text('Follow request'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              // accept
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('followers')
                                  .doc(requesterId)
                                  .set({'userId': requesterId, 'timestamp': FieldValue.serverTimestamp()});
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('follow_requests')
                                  .doc(requesterId)
                                  .delete();
                            },
                            child: const Text('Accept'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('follow_requests')
                                  .doc(requesterId)
                                  .delete();
                            },
                            child: const Text('Ignore'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}