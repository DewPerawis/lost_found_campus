import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_home_bar.dart';
import '../widgets/item_tile.dart';
import 'add_item_page.dart';
import 'item_detail_page.dart';

class MyPostPage extends StatelessWidget {
  const MyPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // คิวรีนี้ต้องมี composite index: ownerUid ASC + createdAt DESC
    final query = FirebaseFirestore.instance
        .collection('items')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('MY POST')),
      bottomNavigationBar: const BottomHomeBar(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
          toFirestore: (value, _) => value,
        ).snapshots(),
        builder: (context, snap) {
          // — error: มักจะเป็น FAILED_PRECONDITION ต้องสร้าง index —
          if (snap.hasError) {
            final err = snap.error.toString();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'เกิดข้อผิดพลาดในการโหลดโพสต์ของคุณ\n\n'
                  '$err\n\n'
                  'ถ้าเห็นคำว่า FAILED_PRECONDITION หรือมีลิงก์ให้สร้าง Index '
                  'ให้เข้า Firebase Console ▸ Firestore Database ▸ Indexes แล้วสร้าง\n'
                  'Composite Index: ownerUid (ASC), createdAt (DESC).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // — loading —
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีโพสต์ของคุณ'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();

              return ItemTile(
                title: (d['title'] ?? '') as String,
                place: d['place'] as String?,
                imageUrl: d['imageUrl'] as String?,
                onTap: () {
                  // แนบ id ไปด้วยเผื่อหน้าอื่นต้องใช้
                  final payload = <String, dynamic>{'id': doc.id, ...d};
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ItemDetailPage(data: payload)),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
