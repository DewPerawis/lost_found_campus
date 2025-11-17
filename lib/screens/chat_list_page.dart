// lib/screens/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import 'chat_page.dart';
import '../services/chat_service.dart';
// ⬇️ Add this line to use the Home tab
import '../widgets/bottom_home_bar.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastAt', descending: true);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
        backgroundColor: AppTheme.cream,
        elevation: 0,
      ),
      // ⬇️ Add Home button tab at the bottom
      bottomNavigationBar: const BottomHomeBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Failed to load chat list:\n${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No conversations yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final chatId = doc.id;

              final parts = (d['participants'] as List).cast<String>();
              final otherUid = parts.firstWhere((x) => x != uid, orElse: () => uid);

              final Map unread = d['unread'] ?? {};
              final myUnread = (unread[uid] ?? 0) as int;

              final lastMsg = (d['lastMessage'] ?? '') as String;
              final lastAt = (d['lastAt'] as Timestamp?)?.toDate();

              return StreamBuilder<Map<String, dynamic>?>(
                stream: ChatService.otherUserStream(otherUid),
                builder: (context, uSnap) {
                  final u = uSnap.data;
                  final name = ChatService.displayNameFrom(u, fallback: otherUid.substring(0, 8));
                  final photo = ChatService.photoFrom(u);

                  return Dismissible(
                    key: ValueKey(chatId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete this chat?'),
                          content: const Text('All messages will be permanently deleted for both participants'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ChatService.deleteChat(chatId);
                      }
                      // Do not dismiss immediately; wait for stream update instead
                      return false;
                    },
                    child: ListTile(
                      tileColor: const Color.fromARGB(255, 255, 254, 252),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.brown.shade200,
                        backgroundImage: photo != null ? NetworkImage(photo) : null,
                        child: photo == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(lastAt),
                            style: TextStyle(fontSize: 12, color: Colors.brown.shade400),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        lastMsg.isEmpty ? 'Start the conversation...' : lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: myUnread > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('$myUnread', style: const TextStyle(color: Colors.white)),
                            )
                          : const SizedBox.shrink(),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatPage(chatId: chatId, otherUid: otherUid),
                          ),
                        );
                      },
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
