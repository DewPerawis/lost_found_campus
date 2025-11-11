import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final auth = FirebaseAuth.instance;
  final fs = FirebaseFirestore.instance;

  bool working = false;

  User? get user => auth.currentUser;

  @override
  Widget build(BuildContext context) {
    const bg = AppTheme.cream;
    const cardBg = Color(0xFFFFF7EF);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('ยังไม่เข้าสู่ระบบ')),
      );
    }

    final uid = user!.uid;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: working ? null : () async {
              await auth.signOut();
              if (!mounted) return;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: fs.collection('users').doc(uid).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snap.data?.data() ?? {};
              final name     = (data['name'] ?? '').toString().trim();
              final email    = (data['email'] ?? user!.email ?? '').toString();
              final contact  = (data['contact'] ?? 'None').toString();
              final faculty  = (data['faculty'] ?? 'ไม่ระบุ').toString();
              final role     = (data['role'] ?? 'ไม่ระบุ').toString();

              final avatarText = (name.isNotEmpty ? name : (email.isNotEmpty ? email : 'U'))
                  .trim()
                  .split(RegExp(r'\s+'))
                  .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
                  .take(2)
                  .join();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Column(
                  children: [
                    // Header card
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 18,
                            offset: Offset(0, 10),
                            color: Color(0x14000000),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.peach.withOpacity(0.25),
                            child: Text(
                              avatarText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? 'Unknown' : name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(email, style: TextStyle(color: Colors.brown.shade600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info list
                    _InfoTile(icon: Icons.badge_rounded, label: 'ชื่อ', value: name.isEmpty ? 'Unknown' : name),
                    _InfoTile(icon: Icons.mail_rounded, label: 'อีเมล', value: email),
                    _InfoTile(icon: Icons.call_rounded, label: 'ติดต่อ', value: contact),
                    _InfoTile(icon: Icons.school_rounded, label: 'คณะ (Faculty)', value: faculty),
                    _InfoTile(icon: Icons.person_rounded, label: 'บทบาท (Role)', value: role),

                    const SizedBox(height: 24),

                    // Danger zone
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE9DCCF)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'การจัดการข้อมูล',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: working ? null : () => _confirmDeleteAllItems(context),
                            icon: const Icon(Icons.delete_sweep_rounded),
                            label: const Text('ลบรายการ (Items) ทั้งหมดของฉัน'),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: working ? null : () => _confirmDeleteAccount(context),
                            icon: const Icon(Icons.person_off_rounded),
                            label: const Text('ลบบัญชีถาวร (พร้อมลบ Items ทั้งหมด)'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (working)
            Container(
              color: Colors.black.withOpacity(0.08),
              alignment: Alignment.center,
              child: const SizedBox(width: 36, height: 36, child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // ----------------- Confirmations & Actions -----------------

  Future<void> _confirmDeleteAllItems(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันการลบรายการทั้งหมด'),
        content: const Text(
          'คุณต้องการลบไอเท็มทั้งหมดที่คุณเคยสร้างจริงหรือไม่?\n'
          'การกระทำนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ยืนยันลบ')),
        ],
      ),
    );
    if (ok == true) {
      await _deleteAllMyItems();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบไอเท็มของคุณทั้งหมดแล้ว')),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final ok1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบบัญชีถาวร'),
        content: const Text(
          'การลบบัญชีจะลบข้อมูลผู้ใช้และไอเท็มทั้งหมดของคุณอย่างถาวร\n'
          'ต้องการดำเนินการต่อหรือไม่?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ไม่ใช่ตอนนี้')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ดำเนินการต่อ')),
        ],
      ),
    );
    if (ok1 != true) return;

    // double confirm
    final ok2 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันอีกครั้ง'),
        content: const Text('คุณแน่ใจ 100% แล้วใช่ไหม? การกระทำนี้ย้อนกลับไม่ได้จริง ๆ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยันลบถาวร'),
          ),
        ],
      ),
    );
    if (ok2 == true) {
      await _deleteAccountCascade();
    }
  }

  /// ลบไอเท็มทั้งหมดของผู้ใช้ (รองรับทั้งฟิลด์ ownerId หรือ uid)
  Future<void> _deleteAllMyItems() async {
    if (user == null) return;
    final uid = user!.uid;
    final email = user!.email;

    setState(() => working = true);
    try {
      // ✅ สำคัญที่สุด: โปรเจ็กต์นี้ใช้ ownerUid เป็นมาตรฐาน
      await _deleteByField('ownerUid', uid);

      // เผื่อมีของเก่าใช้ชื่อฟิลด์อื่น ๆ
      await _deleteByField('uid', uid);
      await _deleteByField('ownerId', uid);
      await _deleteByField('userId', uid);
      await _deleteByField('authorId', uid);
      await _deleteByField('createdByUid', uid);

      if (email != null && email.isNotEmpty) {
        await _deleteByField('email', email);
        await _deleteByField('createdBy', email);
        await _deleteByField('ownerEmail', email);
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }


  /// helper: ลบเอกสารทั้งหมดใน items ที่ field == value (แบบแบ่งชุด)
  Future<void> _deleteByField(String field, String value) async {
    const int batchSize = 300;
    Query<Map<String, dynamic>> base =
        fs.collection('items').where(field, isEqualTo: value).limit(batchSize);

    DocumentSnapshot? lastDoc;
    while (true) {
      Query<Map<String, dynamic>> q = base;
      if (lastDoc != null) q = q.startAfterDocument(lastDoc);

      final snap = await q.get();
      if (snap.docs.isEmpty) break;

      // ลบไฟล์รูป (ถ้ามี imagePath) ทีละตัวก่อน
      for (final d in snap.docs) {
        final data = d.data();
        final path = (data['imagePath'] ?? '') as String;
        if (path.isNotEmpty) {
          try {
            await FirebaseStorage.instance.ref().child(path).delete();
          } catch (_) {
            // ข้ามได้ถ้าลบไม่ได้
          }
        }
      }

      // แล้วค่อยลบเอกสารแบบ batch
      final batch = fs.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      lastDoc = snap.docs.last;
      if (snap.docs.length < batchSize) break;
    }
  }

  /// ลบทุกอย่างของผู้ใช้ แล้วลบบัญชี
  Future<void> _deleteAccountCascade() async {
    if (user == null) return;
    final uid = user!.uid;

    setState(() => working = true);
    try {
      // 1) ลบ items ทั้งหมดของผู้ใช้
      await _deleteAllMyItems();

      // 2) ลบเอกสารผู้ใช้
      await fs.collection('users').doc(uid).delete();

      // 3) ลบบัญชีจาก Auth (อาจต้อง re-auth ถ้า login เก่านาน)
      await user!.delete();

      // 4) กลับสู่จอแรก
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบบัญชีและข้อมูลทั้งหมดเรียบร้อย')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      // re-auth required
      final msg = (e.code == 'requires-recent-login')
          ? 'ต้องเข้าสู่ระบบใหม่ก่อนลบบัญชี (Security Requirement)'
          : (e.message ?? 'ลบบัญชีไม่สำเร็จ');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  /// ลบแบบแบ่งหน้า: ดึงทีละชุด สร้าง batch แล้ว commit ซ้ำจนหมด
  Future<void> _pagedBatchDelete(Query<Map<String, dynamic>> baseQuery) async {
    Query<Map<String, dynamic>> query = baseQuery;
    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = fs.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      // ถ้ามีมากกว่าที่ limit ดึงต่อ (ใช้ startAfterDocument)
      if (snap.docs.length < (query.parameters['limit'] as int? ?? 200)) break;
      query = baseQuery.startAfterDocument(snap.docs.last);
    }
  }
}

// ----------------- UI helpers -----------------

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
