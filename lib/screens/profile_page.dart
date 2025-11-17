// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import 'package:firebase_storage/firebase_storage.dart'; // used to delete attached images in items (still needed)

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

  // ====== Options provided ======
  static const List<String> faculties = [
    'Not Specified','Other','SI','RA','BM','PY','DT','NS','MT','PH','PT','VS','TM','SC','EN','LA','SH','EG','ICT','CRS','SS','RS'
  ];
  static const List<String> roles = ['Not Specified','Student','Teacher','Staff','Other'];

  // ====== Controllers for edit form (email is read-only) ======
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _selectedFaculty = faculties.first;
  String _selectedRole = roles.first;

  // store latest snapshot for use when opening sheets (avoid changing state during build)
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

  // populate controllers/dropdowns from data (call before opening sheet only)
  void _hydrateFrom(Map<String, dynamic> data) {
    _nameCtrl.text = (data['name'] ?? '').toString();
    _contactCtrl.text = (data['contact'] ?? '').toString();

    final fac = (data['faculty'] ?? 'Not Specified').toString();
    final role = (data['role'] ?? 'Not Specified').toString();
    _selectedFaculty = _ensureInList(fac, faculties);
    _selectedRole = _ensureInList(role, roles);
  }

  String _ensureInList(String value, List<String> list) {
    if (value.isEmpty) return list.first;
    if (list.contains(value)) return value;
    return list.first; // guard against unexpected values from database
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
        'email': user!.email ?? '', // email is read-only
        'contact': newContact,
        'faculty': newFaculty,
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pop(); // close edit sheet
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  // ====== Change password ======
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
                const Text('Change password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                TextField(
                  controller: _oldPwdCtrl,
                  obscureText: !_showOld,
                  decoration: InputDecoration(
                    labelText: 'Current password',
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
                    labelText: 'New password',
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
                    labelText: 'Confirm new password',
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
                  label: const Text('Save new password'),
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

    // close sheet immediately
    Navigator.of(sheetContext).pop();

    final mail   = user!.email ?? '';
    final oldPwd = _oldPwdCtrl.text;
    final newPwd1 = _newPwdCtrl.text;
    final newPwd2 = _newPwd2Ctrl.text;

    // check fields
    if (oldPwd.isEmpty || newPwd1.isEmpty || newPwd2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // check confirmation
    if (newPwd1 != newPwd2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirmation do not match')),
      );
      return;
    }

    // minimum length
    if (newPwd1.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }

    if (mail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This account has no email linked and cannot change password')),
      );
      return;
    }

    setState(() => working = true);
    try {
      // re-auth with old password
      final cred = EmailAuthProvider.credential(email: mail, password: oldPwd);
      await user!.reauthenticateWithCredential(cred);

      // update password
      await user!.updatePassword(newPwd1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'wrong-password'        => 'Current password is incorrect',
        'weak-password'         => 'New password is too weak',
        'requires-recent-login' => 'Please sign in again before changing password',
        _                       => e.message ?? 'Password change failed',
      };
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => working = false);
    }
  }


  void _openEditProfileSheet(BuildContext context) {
    // hydrate from the latest snapshot here (after build)
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
                const Text('Edit profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                _FormField(
                  label: 'Name',
                  controller: _nameCtrl,
                  icon: Icons.badge_rounded,
                ),
                _FormField(
                  label: 'Contact',
                  controller: _contactCtrl,
                  icon: Icons.call_rounded,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFaculty, // use initialValue instead of value
                  items: faculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _selectedFaculty = v ?? faculties.first),
                  decoration: const InputDecoration(
                    labelText: 'Faculty',
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
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.person_rounded),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),

                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: working ? null : _saveProfile,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email is read-only • Change password in Profile',
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
        body: Center(child: Text('Not logged in')),
      );
    }

    final uid = user!.uid;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: working ? null : () => _openEditProfileSheet(context),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Sign out',
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

              // store latest snapshot
              _lastUserData = data;

              final name    = (data['name'] ?? '').toString().trim();
              final email   = (data['email'] ?? user!.email ?? '').toString();
              final contact = (data['contact'] ?? 'None').toString();
              final faculty = (data['faculty'] ?? 'Not Specified').toString();
              final role    = (data['role'] ?? 'Not Specified').toString();

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
                    _InfoTile(icon: Icons.badge_rounded, label: 'Name', value: name.isEmpty ? 'Unknown' : name),
                    _InfoTile(icon: Icons.mail_rounded, label: 'Email', value: email),
                    _InfoTile(icon: Icons.call_rounded, label: 'Contact', value: contact),
                    _InfoTile(icon: Icons.school_rounded, label: 'Faculty', value: faculty),
                    _InfoTile(icon: Icons.person_rounded, label: 'Role', value: role),

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
                          const Text('Account management', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),

                          FilledButton.tonalIcon(
                            onPressed: working ? null : () => _openChangePasswordSheet(context),
                            icon: const Icon(Icons.password_rounded),
                            label: const Text('Change password'),
                          ),
                          const SizedBox(height: 8),

                          FilledButton.tonalIcon(
                            onPressed: working ? null : () => _confirmDeleteAllItems(context),
                            icon: const Icon(Icons.delete_sweep_rounded),
                            label: const Text('Delete all my items'),
                          ),
                          const SizedBox(height: 8),

                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: working ? null : () => _confirmDeleteAccount(context),
                            icon: const Icon(Icons.person_off_rounded),
                            label: const Text('Delete account permanently'),
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
        title: const Text('Confirm delete all items'),
        content: const Text(
          'Do you want to delete all items you created?\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm delete')),
        ],
      ),
    );
    if (ok == true) {
      await _deleteAllMyItems();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All your items have been deleted')),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final ok1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account permanently'),
        content: const Text(
          'Deleting your account will permanently remove your user data and all items.\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (ok1 != true) return;

    final ok2 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm again'),
        content: const Text('Are you 100% sure? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm permanent delete'),
          ),
        ],
      ),
    );
    if (ok2 == true) {
      await _deleteAccountCascade();
    }
  }

  /// Delete all user's items (supports fields ownerId or uid)
  Future<void> _deleteAllMyItems() async {
    if (user == null) return;
    final uid = user!.uid;
    final email = user!.email;

    setState(() => working = true);
    try {
      // this project uses ownerUid as standard
      await _deleteByField('ownerUid', uid);

      // in case of legacy field names
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

  /// helper: delete documents in items where field == value (batched)
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

      // delete image files (if imagePath) first
      for (final d in snap.docs) {
        final data = d.data();
        final path = (data['imagePath'] ?? '') as String;
        if (path.isNotEmpty) {
          try {
            await FirebaseStorage.instance.ref().child(path).delete();
          } catch (_) {/* ignore */}
        }
      }

      // then delete documents in batch
      final batch = fs.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      lastDoc = snap.docs.last;
      if (snap.docs.length < batchSize) break;
    }
  }

  /// delete everything for the user, then delete the account
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
        const SnackBar(content: Text('Account and all data deleted successfully')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      final msg = (e.code == 'requires-recent-login')
          ? 'Please sign in again before deleting the account (security requirement)'
          : (e.message ?? 'Account deletion failed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.redAccent),
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
