import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class OtherProfilePage extends StatelessWidget {
  final String uid;
  const OtherProfilePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    const bg = AppTheme.cream;
    const cardBg = Color(0xFFFFF7EF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('โปรไฟล์ผู้ใช้'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data?.data() ?? {};

          final name    = (data['name'] ?? '').toString().trim();
          final contact = (data['contact'] ?? 'None').toString();
          final faculty = (data['faculty'] ?? 'ไม่ระบุ').toString();
          final role    = (data['role'] ?? 'ไม่ระบุ').toString();

          final avatarText = (name.isNotEmpty ? name : 'U')
              .trim()
              .split(RegExp(r'\s+'))
              .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
              .take(2)
              .join();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            child: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(blurRadius: 18, offset: Offset(0, 10), color: Color(0x14000000)),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.peach.withOpacity(.25),
                        child: Text(
                          avatarText,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Unknown' : name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text('ผู้ใช้ในระบบ', style: TextStyle(color: Colors.brown.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _InfoTile(icon: Icons.badge_rounded,  label: 'ชื่อ',             value: name.isEmpty ? 'Unknown' : name),
                _InfoTile(icon: Icons.call_rounded,   label: 'ติดต่อ',          value: contact),
                _InfoTile(icon: Icons.school_rounded, label: 'คณะ (Faculty)',   value: faculty),
                _InfoTile(icon: Icons.person_rounded, label: 'บทบาท (Role)',    value: role),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9DCCF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.brown.shade400, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
