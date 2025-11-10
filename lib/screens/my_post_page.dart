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

    final query = FirebaseFirestore.instance
        .collection('items')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('MY POST')),
      bottomNavigationBar: const BottomHomeBar(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'เกิดข้อผิดพลาดในการโหลดโพสต์ของคุณ:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
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

              Future<void> deleteItem() async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('ลบโพสต์นี้?'),
                    content: const Text('การลบไม่สามารถย้อนกลับได้'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
                    ],
                  ),
                );
                if (ok != true) return;
                await FirebaseFirestore.instance.collection('items').doc(doc.id).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบโพสต์แล้ว')));
                }
              }

              void editItem() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddItemPage(
                      docId: doc.id,
                      initialData: {
                        'title': d['title'],
                        'place': d['place'],
                        'desc' : d['desc'],        // ← ใช้คีย์นี้
                        'imageUrl': d['imageUrl'],
                        'status': d['status'],
                      },
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  ItemTile(
                    title: (d['title'] ?? '') as String,
                    place: d['place'] as String?,
                    imageUrl: d['imageUrl'] as String?,
                    onTap: () {
                      final payload = <String, dynamic>{'id': doc.id, ...d};
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ItemDetailPage(data: payload)),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') editItem();
                        if (v == 'delete') deleteItem();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                        PopupMenuItem(value: 'delete', child: Text('ลบ')),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemPage()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
