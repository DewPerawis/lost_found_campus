import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/item_tile.dart';
import '../widgets/bottom_home_bar.dart';
import 'item_detail_page.dart';

class SearchResultPage extends StatelessWidget {
  final String? keyword;
  final String? status;   // 'lost' | 'found'
  final String? location;

  const SearchResultPage({super.key, this.keyword, this.status, this.location});

  Query<Map<String, dynamic>> _buildQuery() {
    var q = FirebaseFirestore.instance
        .collection('items')
        .orderBy('createdAt', descending: true);
    if (status != null && status!.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }
    if (location != null && location!.isNotEmpty) {
      q = q.where('place', isEqualTo: location);
    }
    return q;
  }

  @override
  Widget build(BuildContext context) {
    final q = _buildQuery();

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Search')),
      bottomNavigationBar: const BottomHomeBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.where((doc) {
            if (keyword == null || keyword!.trim().isEmpty) return true;
            final data = doc.data() as Map<String, dynamic>;
            final t = (data['title'] ?? '').toString().toLowerCase();
            return t.contains(keyword!.toLowerCase());
          }).toList();

          if (docs.isEmpty) return const Center(child: Text('ไม่พบผลลัพธ์'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ItemTile(
                title: (data['title'] ?? '') as String,
                place: data['place'] as String?,
                imageUrl: data['imageUrl'] as String?, // ✔ ใช้ key นี้ให้ตรงกับที่บันทึก
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemDetailPage(data: data)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
