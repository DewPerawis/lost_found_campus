// lib/screens/lost_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_home_bar.dart';
import 'add_item_page.dart';
import 'item_detail_page.dart';
import '../theme.dart';

class LostListPage extends StatefulWidget {
  const LostListPage({super.key});

  @override
  State<LostListPage> createState() => _LostListPageState();
}

class _LostListPageState extends State<LostListPage> {
  final searchCtrl = TextEditingController();
  String filter = 'All';

  static const Color bg = AppTheme.cream;
  static const Color cardBg = Color(0xFFFFF7EF);
  static const Color pillLost = Color(0xFFFFE7CE);
  static const Color pillFound = Color(0xFFE8F5F2);

  List<BoxShadow> get _softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          spreadRadius: 4,
          offset: const Offset(0, 6),
        ),
      ];

  List<BoxShadow> get _tinyShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ];

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('items')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(.08),
        backgroundColor: bg,
        centerTitle: true,
        title: const Text('LOST ITEM', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: const BackButton(),
      ),
      bottomNavigationBar: const BottomHomeBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemPage()));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add your items'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          final header = [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Material(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(.06),
                borderRadius: BorderRadius.circular(16),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by name or place',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _chip('All'),
                  const SizedBox(width: 8),
                  _chip('Lost'),
                  const SizedBox(width: 8),
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
                _errorBox('เกิดข้อผิดพลาดในการโหลดรายการ:\n${snap.error}'),
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

          final s = searchCtrl.text.trim().toLowerCase();
          final docs = snap.data!.docs.where((e) {
            final d = e.data();
            final status = (d['status'] ?? '').toString().toLowerCase();
            final title = (d['title'] ?? '').toString().toLowerCase();
            final place = (d['place'] ?? '').toString().toLowerCase();

            final matchFilter = (filter == 'All') ||
                (filter == 'Lost' && status == 'lost') ||
                (filter == 'Found' && status == 'found');

            final matchSearch = s.isEmpty || title.contains(s) || place.contains(s);
            return matchFilter && matchSearch;
          }).toList();

          if (docs.isEmpty) {
            return ListView(
              children: [
                ...header,
                _emptyState(context),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: docs.length + header.length,
            itemBuilder: (_, i) {
              if (i < header.length) return header[i];

              final doc = docs[i - header.length];
              final d = doc.data();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _itemCard(
                  title: (d['title'] ?? '') as String,
                  status: (d['status'] ?? '') as String,
                  place: d['place'] as String?,
                  imageUrl: d['imageUrl'] as String?,
                  createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ItemDetailPage(itemId: doc.id)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===== UI helpers =====

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

  Widget _itemCard({
    required String title,
    required String status,
    String? place,
    String? imageUrl,
    DateTime? createdAt,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isFound = status.toLowerCase() == 'found';

    Widget statusPill() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isFound ? pillFound : pillLost,
            borderRadius: BorderRadius.circular(999),
            boxShadow: _tinyShadow,
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

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: _tinyShadow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(imageUrl, width: 96, height: 96, fit: BoxFit.cover)
                      : Container(
                          width: 96, height: 96, color: Colors.white,
                          child: const Icon(Icons.image_not_supported_rounded),
                        ),
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
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        statusPill(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if ((place ?? '').isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 16, color: cs.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              place!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Text(_timeAgo(createdAt),
                            style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ],
                ),
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
          Text(
            'No items match your criteria',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your search or switching filters',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemPage()));
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add your items'),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
