import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_home_bar.dart';

class ItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const ItemDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String? id = data['id'] as String?;

    Widget buildBody(Map<String, dynamic> d) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (d['imageUrl'] != null && (d['imageUrl'] as String).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(d['imageUrl'], height: 200, fit: BoxFit.cover),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, size: 48),
            ),
          const SizedBox(height: 16),
          Text('NAME: ${d['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('PLACE: ${d['place'] ?? '-'}'),
          Text('STATUS: ${d['status'] ?? '-'}'),
          Text('DATE: ${(d['createdAt']?.toDate()?.toString().split(" ").first) ?? "-"}'),
          const SizedBox(height: 12),
          const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(d['desc'] ?? '—'), // ← ใช้ desc
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, child: const Text('CONTACT')),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      bottomNavigationBar: const BottomHomeBar(),
      body: id == null
          ? buildBody(data)
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('items').doc(id).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return const Center(child: CircularProgressIndicator());
                }
                final d = snap.data!.data()!;
                return buildBody({'id': id, ...d});
              },
            ),
    );
  }
}
