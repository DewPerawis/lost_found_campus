import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/chat_service.dart';
import 'other_profile_page.dart';


class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUid;
  const ChatPage({super.key, required this.chatId, required this.otherUid});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatService.markAsRead(chatId: widget.chatId, currentUid: _uid);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    await ChatService.sendText(chatId: widget.chatId, text: txt, senderUid: _uid);
    _ctrl.clear();
  }

  String _fmtTime(DateTime? t) {
    if (t == null) return '';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final msgsQ = FirebaseFirestore.instance
        .collection('chats').doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<Map<String, dynamic>?>( 
      stream: ChatService.otherUserStream(widget.otherUid),
      builder: (context, userSnap) {
        final u = userSnap.data;
        final name = ChatService.displayNameFrom(u, fallback: widget.otherUid.substring(0, 8));
        final photo = ChatService.photoFrom(u);

        return Scaffold(
          backgroundColor: AppTheme.cream,
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OtherProfilePage(uid: widget.otherUid),
                        ),
                      );
                    },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.brown.shade200,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child: photo == null
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.w700))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Delete chat',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete this chat?'),
                      content: const Text('All messages will be permanently deleted for both participants'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ChatService.deleteChat(widget.chatId);
                    if (mounted) Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: msgsQ.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final m = docs[i].data() as Map<String, dynamic>;
                        final isMe = m['senderId'] == _uid;
                        final List readBy = List.from(m['readBy'] ?? []);
                        final createdAt = (m['createdAt'] as Timestamp?)?.toDate();

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe ?  const Color.fromARGB(255, 252, 211, 173) : const Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isMe ? 14 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 14),
                              ),
                              boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0,2))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['text'] ?? ''),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (createdAt != null)
                                      Text(_fmtTime(createdAt),
                                          style: const TextStyle(fontSize: 10, color: Color.fromARGB(136, 49, 47, 47))),
                                    const SizedBox(width: 6),
                                    if (isMe)
                                      Text(
                                        readBy.contains(widget.otherUid) ? 'Read' : 'Sent',
                                        style: const TextStyle(fontSize: 10, color: Color.fromARGB(136, 49, 47, 47)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  color: AppTheme.cream,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            filled: true,
                            fillColor: const Color.fromARGB(255, 255, 255, 255),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.send_rounded), onPressed: _send),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
