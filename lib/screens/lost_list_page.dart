import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/item_tile.dart';
import '../widgets/bottom_home_bar.dart';
import 'item_detail_page.dart';
import 'find_item_page.dart';

class LostListPage extends StatelessWidget {
  const LostListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('items')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('LOST ITEM')),
      bottomNavigationBar: const BottomHomeBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีรายการ'));
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return ItemTile(
                title: (d['title'] ?? '') as String,
                place: d['place'] as String?,
                imageUrl: d['imageUrl'] as String?,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemDetailPage(data: d)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindItemPage())),
        label: const Text('Search / Filter'),
        icon: const Icon(Icons.search),
      ),
    );
  }
}

// // ตัวช่วยสั้น ๆ เพื่อใช้กับ ItemTile เดิม
// class _TileItem {
//   final String title;
//   final String? place;
//   final String? imageUrl;
//   _TileItem({required this.title, this.place, this.imageUrl});
// }
