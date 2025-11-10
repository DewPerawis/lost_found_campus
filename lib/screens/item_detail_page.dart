import 'package:flutter/material.dart';
import '../widgets/bottom_home_bar.dart';

class ItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const ItemDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      bottomNavigationBar: const BottomHomeBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(16),
              image: (data['imageUrl'] != null)
                  ? DecorationImage(
                      image: NetworkImage(data['imageUrl']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text('NAME: ${data['title'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('DATE: ${(data['createdAt']?.toDate()?.toString().split(" ").first) ?? "-"}'),
          const SizedBox(height: 12),
          const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(data['desc'] ?? '—'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, child: const Text('CONTACT')),
        ],
      ),
    );
  }
}
