// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import 'package:firebase_storage/firebase_storage.dart'; // ใช้ลบรูปที่แนบใน items (ยังจำเป็น)

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

  // ====== ตัวเลือกที่ให้มา ======
  static const List<String> faculties = [
    'ไม่ระบุ','Other','SI','RA','BM','PY','DT','NS','MT','PH','PT','VS','TM','SC','EN','LA','SH','EG','ICT','CRS','SS','RS'
  ];
  static const List<String> roles = ['ไม่ระบุ','Student','Teacher','Staff','Other'];

  // ====== Controllers ฟอร์มแก้ไข (ไม่มี email แล้ว) ======
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _selectedFaculty = faculties.first;
  String _selectedRole = roles.first;

  // เก็บ snapshot ล่าสุดไว้ ใช้ตอนเปิดชีต (หลีกเลี่ยงแก้ state ระหว่าง build)
  Map<String, dynamic> _lastUserData = const {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _newPwd2Ctrl.dispose();
    super.dispose();
  }

  // เติมค่าให้คอนโทรล/ดรอปดาวน์จาก data (เรียกตอนจะเปิดชีตเท่านั้น)
  void _hydrateFrom(Map<String, dynamic> data) {
    _nameCtrl.text = (data['name'] ?? '').toString();
    _contactCtrl.text = (data['contact'] ?? '').toString();

    final fac = (data['faculty'] ?? 'ไม่ระบุ').toString();
    final role = (data['role'] ?? 'ไม่ระบุ').toString();
    _selectedFaculty = _ensureInList(fac, faculties);
    _selectedRole = _ensureInList(role, roles);
  }

  String _ensureInList(String value, List<String> list) {
    if (value.isEmpty) return list.first;
    if (list.contains(value)) return value;
    return list.first; // กันค่าแปลกจากฐานข้อมูล
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    final uid = user!.uid;

    final newName = _nameCtrl.text.trim();
    final newContact = _contactCtrl.text.trim();
    final newFaculty = _selectedFaculty;
    final newRole = _selectedRole;

    setState(() => working = true);
    try {
      await fs.collection('users').doc(uid).set({
        'name': newName,
        'email': user!.email ?? '', // email อ่านอย่างเดียว
        'contact': newContact,
        'faculty': newFaculty,
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pop(); // ปิดชีตแก้ไข
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกโปรไฟล์แล้ว')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  // ====== เปลี่ยนรหัสผ่าน ======
  final _oldPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _newPwd2Ctrl = TextEditingController();
  bool _showOld = false, _showNew = false, _showNew2 = false;

  void _resetPasswordFields() {
    _oldPwdCtrl.clear();
    _newPwdCtrl.clear();
    _newPwd2Ctrl.clear();
    _showOld = _showNew = _showNew2 = false;
  }

  void _openChangePasswordSheet(BuildContext context) {
    _resetPasswordFields();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, top: 12,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                TextField(
                  controller: _oldPwdCtrl,
                  obscureText: !_showOld,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านเดิม',
                    prefixIcon: const Icon(Icons.lock_clock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_showOld ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setLocal(() => _showOld = !_showOld),
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPwdCtrl,
                  obscureText: !_showNew,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านใหม่',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setLocal(() => _showNew = !_showNew),
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPwd2Ctrl,
                  obscureText: !_showNew2,
                  decoration: InputDecoration(
                    labelText: 'ยืนยันรหัสผ่านใหม่',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_showNew2 ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setLocal(() => _showNew2 = !_showNew2),
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                  ),
                ),

                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: working ? null : () => _handleChangePassword(sheetContext: ctx),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('บันทึกรหัสผ่านใหม่'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleChangePassword({required BuildContext sheetContext}) async {
    if (user == null) return;

    // ปิดฟอร์มทันทีตามที่ต้องการ
    Navigator.of(sheetContext).pop();

    final mail   = user!.email ?? '';
    final oldPwd = _oldPwdCtrl.text;
    final newPwd1 = _newPwdCtrl.text;
    final newPwd2 = _newPwd2Ctrl.text;

    // เช็กกรอกครบ
    if (oldPwd.isEmpty || newPwd1.isEmpty || newPwd2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง')),
      );
      return;
    }

    // เช็กรหัสใหม่ตรงกัน
    if (newPwd1 != newPwd2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านใหม่และยืนยันไม่ตรงกัน')),
      );
      return;
    }

    // เช็กความยาวขั้นต่ำ
    if (newPwd1.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านใหม่ต้องอย่างน้อย 6 ตัวอักษร')),
      );
      return;
    }

    if (mail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บัญชีนี้ไม่มีอีเมลผูกไว้ ไม่สามารถเปลี่ยนรหัสผ่านได้')),
      );
      return;
    }

    setState(() => working = true);
    try {
      // re-auth ด้วยรหัสเดิม
      final cred = EmailAuthProvider.credential(email: mail, password: oldPwd);
      await user!.reauthenticateWithCredential(cred);

      // อัปเดตรหัสผ่านใหม่
      await user!.updatePassword(newPwd1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปลี่ยนรหัสผ่านเรียบร้อย')),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'wrong-password'        => 'รหัสผ่านเดิมไม่ถูกต้อง',
        'weak-password'         => 'รหัสผ่านใหม่ไม่ปลอดภัยพอ',
        'requires-recent-login' => 'โปรดเข้าสู่ระบบใหม่ก่อนเปลี่ยนรหัสผ่าน',
        _                       => e.message ?? 'เปลี่ยนรหัสผ่านไม่สำเร็จ',
      };
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


  void _openEditProfileSheet(BuildContext context) {
    // hydrate จาก snapshot ล่าสุด “ที่นี่” (หลัง build)
    _hydrateFrom(_lastUserData);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('แก้ไขโปรไฟล์', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                _FormField(
                  label: 'ชื่อ',
                  controller: _nameCtrl,
                  icon: Icons.badge_rounded,
                ),
                _FormField(
                  label: 'ติดต่อ',
                  controller: _contactCtrl,
                  icon: Icons.call_rounded,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFaculty, // ใช้ initialValue แทน value
                  items: faculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _selectedFaculty = v ?? faculties.first),
                  decoration: const InputDecoration(
                    labelText: 'คณะ (Faculty)',
                    prefixIcon: Icon(Icons.school_rounded),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),

                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedRole = v ?? roles.first),
                  decoration: const InputDecoration(
                    labelText: 'บทบาท (Role)',
                    prefixIcon: Icon(Icons.person_rounded),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),

                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: working ? null : _saveProfile,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('บันทึก'),
                ),
                const SizedBox(height: 8),
                Text(
                  'อีเมลอ่านได้อย่างเดียว • เปลี่ยนรหัสผ่านที่หน้าโปรไฟล์',
                  style: TextStyle(fontSize: 12, color: Colors.brown.shade500),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

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
            tooltip: 'แก้ไขโปรไฟล์',
            onPressed: working ? null : () => _openEditProfileSheet(context),
            icon: const Icon(Icons.edit_rounded),
          ),
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

              // เก็บ snapshot ล่าสุดไว้
              _lastUserData = data;

              final name    = (data['name'] ?? '').toString().trim();
              final email   = (data['email'] ?? user!.email ?? '').toString();
              final contact = (data['contact'] ?? 'None').toString();
              final faculty = (data['faculty'] ?? 'ไม่ระบุ').toString();
              final role    = (data['role'] ?? 'ไม่ระบุ').toString();

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
                            backgroundColor: AppTheme.peach.withValues(alpha: 0.25),
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

                    // Account zone
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
                          const Text('การจัดการข้อมูล', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),

                          FilledButton.tonalIcon(
                            onPressed: working ? null : () => _openChangePasswordSheet(context),
                            icon: const Icon(Icons.password_rounded),
                            label: const Text('เปลี่ยนรหัสผ่าน'),
                          ),
                          const SizedBox(height: 8),

                          FilledButton.tonalIcon(
                            onPressed: working ? null : () => _confirmDeleteAllItems(context),
                            icon: const Icon(Icons.delete_sweep_rounded),
                            label: const Text('ลบรายการ (Items) ทั้งหมดของฉัน'),
                          ),
                          const SizedBox(height: 8),

                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
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
              color: Colors.black.withValues(alpha: 0.08),
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
      // โปรเจ็กต์นี้ใช้ ownerUid เป็นมาตรฐาน
      await _deleteByField('ownerUid', uid);

      // เผื่อชื่อฟิลด์เก่า
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
          } catch (_) {/* ข้ามได้ */}
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
      await _deleteAllMyItems();
      await fs.collection('users').doc(uid).delete();
      await user!.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบบัญชีและข้อมูลทั้งหมดเรียบร้อย')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
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

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
        ),
      ),
    );
  }
}
