import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/chat_service.dart';
import 'chat_page.dart';

class ItemDetailPage extends StatelessWidget {
  final String itemId;
  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Detail'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: AppTheme.cream,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('items').doc(itemId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (!snap.data!.exists) return const Center(child: Text('Item not found'));

          final data = snap.data!.data() as Map<String, dynamic>;
          final ownerUid = (data['ownerUid'] ?? '') as String;
          final title    = (data['title'] ?? '') as String;
          final place    = (data['place'] ?? data['location'] ?? '-') as String;
          final desc     = (data['description'] ?? data['desc'] ?? '-') as String;
          final status   = ((data['status'] ?? 'lost') as String).toLowerCase();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final imageUrl = (data['imageUrl'] ?? '') as String?; // item image (if any)

          final me = FirebaseAuth.instance.currentUser?.uid;

          // Load owner name from users/{uid}.displayName (fallback: 'Unknown user')
          final ownerFuture = FirebaseFirestore.instance.collection('users').doc(ownerUid).get();

          Color pillBg() =>
              status == 'found' ? const Color(0xFFE8F5F2) : const Color(0xFFFFE7CE);

          return FutureBuilder<DocumentSnapshot>(
            future: ownerFuture,
            builder: (context, ownerSnap) {
              String ownerName = 'Unknown user';
              if (ownerSnap.hasData && ownerSnap.data!.exists) {
                final u = ownerSnap.data!.data() as Map<String, dynamic>;
                ownerName = (u['displayName'] ?? u['name'] ?? 'Unknown user').toString();
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  // ===== Top image =====
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: (imageUrl != null && imageUrl.isNotEmpty)
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: Colors.white,
                              child: const Center(
                                child: Icon(Icons.image_not_supported_rounded, size: 48),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== Card: name / status / place / date =====
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Status pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: pillBg(),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: status == 'found' ? Colors.green : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (createdAt != null)
                                Text(
                                  '${createdAt.day.toString().padLeft(2, '0')}/'
                                  '${createdAt.month.toString().padLeft(2, '0')}/'
                                  '${createdAt.year}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title.isEmpty ? '-' : title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: Colors.black54),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  place,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== Description card =====
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Description',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(desc.isEmpty ? '-' : desc),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== Owner card + Chat button =====
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: cs.primary.withOpacity(.12),
                              child: Text(
                                (ownerName.isNotEmpty ? ownerName[0] : '?').toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: const Text('Owner',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(ownerName),
                          ),
                          const SizedBox(height: 8),
                          if (me != null && me != ownerUid)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                label: const Text('Chat with owner'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  final chatId = await ChatService.openOrCreateChat(
                                    uidA: me,
                                    uidB: ownerUid,
                                    itemId: itemId,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        chatId: chatId,
                                        otherUid: ownerUid, // display name mapping handled elsewhere
                                      ),
                                    ));
                                  }
                                },
                              ),
                            )
                          else
                            const Text('You are the owner of this post',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
