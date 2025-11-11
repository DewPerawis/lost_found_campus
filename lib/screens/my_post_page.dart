import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_home_bar.dart';
import 'add_item_page.dart';
import 'item_detail_page.dart';

class MyPostPage extends StatefulWidget {
  const MyPostPage({super.key});

  @override
  State<MyPostPage> createState() => _MyPostPageState();
}

class _MyPostPageState extends State<MyPostPage> {
  final searchCtrl = TextEditingController();
  String filter = 'All';

  static const Color bg =  Color(0xFFFFF6DE);
  static const Color cardBg = Color(0xFFFFF7EF);
  static const Color pillLost = Color(0xFFFFE7CE);
  static const Color pillFound = Color(0xFFE8F5F2);

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final query = FirebaseFirestore.instance
        .collection('items')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        centerTitle: true,
        title: const Text('My Post', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      bottomNavigationBar: const BottomHomeBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemPage()));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add new post'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          final header = [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                controller: searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search my posts',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  _chip('All'),
                  _chip('Lost'),
                  _chip('Found'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ];

          if (snap.hasError) {
            return ListView(
              children: [
                ...header,
                _errorBox('เกิดข้อผิดพลาดในการโหลดโพสต์ของคุณ:\n${snap.error}'),
              ],
            );
          }
          if (!snap.hasData) {
            return ListView(
              children: [
                ...header,
                const SizedBox(height: 40),
                const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
              children: [
                ...header,
                _emptyState(context),
              ],
            );
          }

          // filter + search
          final q = searchCtrl.text.trim().toLowerCase();
          final filtered = docs.where((doc) {
            final d = doc.data();
            final status = (d['status'] ?? '').toString().toLowerCase();
            final title = (d['title'] ?? '').toString().toLowerCase();
            final okStatus = filter == 'All' || status == filter.toLowerCase();
            final okSearch = q.isEmpty || title.contains(q);
            return okStatus && okSearch;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
            itemCount: filtered.length + header.length,
            itemBuilder: (context, index) {
              // render header first
              if (index < header.length) return header[index];

              final doc = filtered[index - header.length];
              final d = doc.data();

              // actions that preserve your backend behavior
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
                        'desc': d['desc'],
                        'imageUrl': d['imageUrl'],
                        'status': d['status'],
                      },
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _postCard(
                  title: (d['title'] ?? '') as String,
                  place: d['place'] as String?,
                  status: (d['status'] ?? 'Lost') as String,
                  imageUrl: d['imageUrl'] as String?,
                  createdAt: (d['createdAt'] is Timestamp)
                      ? (d['createdAt'] as Timestamp).toDate()
                      : (d['createdAt'] as DateTime?),
                  onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ItemDetailPage(itemId: doc.id)),
                      );
                    },
                  onEdit: editItem,
                  onDelete: deleteItem,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------- UI bits ----------

  Widget _chip(String label) {
    final isSelected = filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => filter = label),
      selectedColor: Colors.white,
      backgroundColor: cardBg,
      labelStyle: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    );
  }

  Widget _postCard({
    required String title,
    required String status,
    String? place,
    String? imageUrl,
    DateTime? createdAt,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isFound = status.toLowerCase() == 'found';

    Widget statusPill() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isFound ? pillFound : pillLost,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isFound ? Icons.check_circle_rounded : Icons.search_rounded,
                  size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(status, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        );

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover)
                    : Container(
                        width: 70, height: 70, color: Colors.white,
                        child: const Icon(Icons.image_not_supported_rounded),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                        statusPill(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(place ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(_timeAgo(createdAt),
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                PopupMenuItem(value: 'delete', child: Text('ลบ')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          const Icon(Icons.folder_open_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('ยังไม่มีโพสต์ของคุณ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'สร้างโพสต์ Lost/Found แรกของคุณเพื่อให้เพื่อน ๆ ช่วยตามหาได้ง่ายขึ้น',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemPage()));
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add new post'),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: const Color(0xFFFFEAEA), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '-';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
