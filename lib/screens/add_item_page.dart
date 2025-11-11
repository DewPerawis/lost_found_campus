// lib/screens/add_item_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddItemPage extends StatefulWidget {
  final String? docId;                       // ถ้าแก้ไขจะมี docId
  final Map<String, dynamic>? initialData;   // ข้อมูลเดิม (จาก MyPostPage)
  const AddItemPage({super.key, this.docId, this.initialData});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  // โทนสี
  static const Color _bg = Color(0xFFFFF3D6);
  static const Color _cardBg = Color(0xFFFFF7EF); // ใช้กับบล็อกหมายเหตุ
  static const Color _fieldFill = Colors.white;   // กล่องอินพุตให้ขาวชัด
  static const Color _border = Color.fromARGB(255, 243, 233, 223); // เส้นขอบปกติ
  static const double _radius = 14;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _status = 'lost';            // 'lost' | 'found'
  String? _imageUrl;                  // downloadURL บน Storage
  String? _imagePath;                 // path บน Storage (เผื่อลบ)

  bool _isSaving = false;
  bool _isUploadingImage = false;

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    if (d != null) {
      _titleCtrl.text = (d['title'] ?? '').toString();
      _placeCtrl.text = (d['place'] ?? '').toString();
      _descCtrl.text = (d['desc'] ?? '').toString();
      _status = (d['status'] ?? 'lost').toString().toLowerCase();
      final img = d['imageUrl'];
      if (img is String && img.isNotEmpty) _imageUrl = img;

      final p = d['imagePath'];
      if (p is String && p.isNotEmpty) _imagePath = p;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _placeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // เปลือกหุ้มเพื่อเพิ่มเงานุ่มๆ ให้ทุกกล่อง
  Widget _fieldShell(Widget child) {
    return Material(
      color: Colors.transparent,
      elevation: 2.5,
      shadowColor: Colors.black.withOpacity(.06),
      borderRadius: BorderRadius.circular(_radius),
      child: child,
    );
  }

  // Decoration ของอินพุต: ขอบชัด + เปลี่ยนสีเมื่อโฟกัส
  InputDecoration _decor(String hint) => InputDecoration(
        filled: true,
        fillColor: _fieldFill,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.brown.shade300),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: Colors.brown.shade500, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('กรุณาเข้าสู่ระบบใหม่อีกครั้ง');

      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'status': _status,
        'place': _placeCtrl.text.trim(),
        'desc': _descCtrl.text.trim(),
        'imageUrl': _imageUrl ?? '',
        if (_imagePath != null) 'imagePath': _imagePath,
      };

      final col = FirebaseFirestore.instance.collection('items');

      if (_isEdit) {
        await col.doc(widget.docId).update(data);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('บันทึกการแก้ไขแล้ว')));
        }
      } else {
        data['ownerUid'] = uid;
        data['createdAt'] = FieldValue.serverTimestamp();
        await col.add(data);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('สร้างโพสต์แล้ว')));
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==== เลือกรูปจากเครื่อง + อัปโหลดขึ้น Firebase Storage ====
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('ไม่พบผู้ใช้');

      final fileId = widget.docId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'items/$uid/$fileId.jpg';

      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(File(picked.path));

      final url = await ref.getDownloadURL();

      if (_imagePath != null && _imagePath != path) {
        try {
          await FirebaseStorage.instance.ref().child(_imagePath!).delete();
        } catch (_) {}
      }

      setState(() {
        _imageUrl = url;
        _imagePath = path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ลบรูป (พร้อมลบไฟล์ใน Storage ถ้ารู้ path)
  Future<void> _removeImage() async {
    if (_imageUrl == null || _imageUrl!.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบรูปภาพนี้?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      if (_imagePath != null && _imagePath!.isNotEmpty) {
        await FirebaseStorage.instance.ref().child(_imagePath!).delete();
      }
    } catch (_) {
    } finally {
      setState(() {
        _imageUrl = null;
        _imagePath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _isEdit ? 'EDIT ITEM' : 'ADD ITEM';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        centerTitle: true,
        title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // การ์ดรูปภาพ + ปุ่ม (ยกเงา + ขอบชัด)
                  Material(
                    color: Colors.white,
                    elevation: 3.5,
                    shadowColor: Colors.black.withOpacity(.08),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border, width: 1.2),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (_imageUrl != null && _imageUrl!.isNotEmpty)
                                ? Image.network(_imageUrl!, height: 190, fit: BoxFit.cover)
                                : Container(
                                    height: 190,
                                    color: Colors.grey.shade100,
                                    child: Icon(Icons.image_rounded, size: 48, color: Colors.brown.shade300),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: _isUploadingImage ? null : _pickImage,
                                icon: const Icon(Icons.image_rounded),
                                label: Text(_isUploadingImage ? 'กำลังอัปโหลด...' : 'เปลี่ยนรูป'),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: (_imageUrl == null || _imageUrl!.isEmpty || _isUploadingImage)
                                    ? null
                                    : _removeImage,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('ลบรูป'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ชื่อไอเท็ม
                  _fieldShell(
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: _decor('ชื่อไอเท็ม'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อไอเท็ม' : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // สถานะ
                  _fieldShell(
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: _decor('สถานะ'),
                      items: const [
                        DropdownMenuItem(value: 'lost', child: Text('lost')),
                        DropdownMenuItem(value: 'found', child: Text('found')),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'lost'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // สถานที่
                  _fieldShell(
                    TextFormField(
                      controller: _placeCtrl,
                      decoration: _decor('สถานที่'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // รายละเอียด
                  _fieldShell(
                    TextFormField(
                      controller: _descCtrl,
                      decoration: _decor('รายละเอียดเพิ่มเติม'),
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ปุ่มบันทึกให้เด่นขึ้น
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(.12),
                      ),
                      onPressed: (_isSaving || _isUploadingImage) ? null : _save,
                      child: Text(_isEdit ? 'บันทึกการแก้ไข' : 'บันทึก'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // หมายเหตุ
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border, width: 1),
                    ),
                    child: const Text(
                      'หมายเหตุ: คำสั่งอาจรอคิว ใช้เมนู : ที่หน้า My Post',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isSaving || _isUploadingImage)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
