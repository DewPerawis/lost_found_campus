import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({
    super.key,
    this.docId,
    this.initialData,
  });

  /// ถ้ามี docId = โหมดแก้ไข
  final String? docId;
  final Map<String, dynamic>? initialData;

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final title = TextEditingController();
  final place = TextEditingController();
  final desc  = TextEditingController();
  final status = ValueNotifier<String>('found');

  File? selectedImageFile;      // รูปใหม่ที่เลือก (ถ้ามี)
  String? imageUrl;             // URL ปัจจุบันในเอกสาร (ถ้ามี)
  bool markRemoveImage = false; // โหมดแก้ไข: ถ้ากดลบรูป

  bool loading = false;
  bool get isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit && widget.initialData != null) {
      final d = widget.initialData!;
      title.text  = (d['title'] ?? '') as String;
      place.text  = (d['place'] ?? '') as String;
      desc.text   = (d['desc']  ?? '') as String;   // ใช้คีย์ 'desc'
      status.value = (d['status'] ?? 'found') as String;
      imageUrl    = d['imageUrl'] as String?;
    }
  }

  @override
  void dispose() {
    title.dispose();
    place.dispose();
    desc.dispose();
    status.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() {
      selectedImageFile = File(x.path);
      markRemoveImage = false; // เลือกใหม่ = ไม่ถือว่าลบแล้ว
    });
  }

  Future<String> _uploadImage(String docId) async {
    final storage = FirebaseStorage.instance; 
    final ref = storage.ref().child('items/$docId/main.jpg');
    await ref.putFile(
      selectedImageFile!,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();

    return url;
  }

  /// ลบรูปปัจจุบันใน Storage (ถ้าเป็นลิงก์ Storage จริง)
  Future<void> _deleteStorageImageIfAny() async {
    if (imageUrl != null &&
        imageUrl!.startsWith('https://firebasestorage.googleapis.com')) {
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl!).delete();
      } catch (_) {/* เงียบไว้ */}
    }
  }

  void _removeImageTapped() {
    setState(() {
      selectedImageFile = null;
      if (isEdit) markRemoveImage = true;
      imageUrl = null;
    });
  }

  Future<void> submit() async {
    if (loading) return;
    FocusScope.of(context).unfocus();

    if (title.text.trim().isEmpty) {
      _toast('กรุณาใส่ชื่อรายการ');
      return;
    }

    setState(() => loading = true);
    try {
      final col = FirebaseFirestore.instance.collection('items');

      if (isEdit) {
        // ---------- โหมดแก้ไข ----------
        final docId = widget.docId!;
        String? newUrl = imageUrl;

        if (markRemoveImage) {
          await _deleteStorageImageIfAny();
          newUrl = null;
        }
        if (selectedImageFile != null) {
          newUrl = await _uploadImage(docId); // เอกสารมีแล้ว → ผ่าน rules
        }

        await col.doc(docId).update({
          'title'    : title.text.trim(),
          'place'    : place.text.trim(),
          'desc'     : desc.text.trim(),
          'status'   : status.value,
          'imageUrl' : newUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _toast('บันทึกการแก้ไขแล้ว');

      } else {
        // ---------- โหมดสร้าง ----------
        final uid = FirebaseAuth.instance.currentUser!.uid;

        // 1) สร้างเอกสารก่อน (ตามกติกา Storage ต้องมี doc ก่อน)
        final docRef = col.doc();
        print('🧾 create doc id = ${docRef.id}, uid = $uid');
        await docRef.set({
          'title'    : title.text.trim(),
          'place'    : place.text.trim(),
          'desc'     : desc.text.trim(),
          'status'   : status.value,
          'imageUrl' : null,
          'ownerUid' : uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final snap = await docRef.get();
        print('🧾 ownerUid in Firestore = ${snap.data()?['ownerUid']}');

        // 2) อัปโหลดรูป (ถ้ามี) → แล้วค่อยอัปเดต imageUrl
        if (selectedImageFile != null) {
          try {
            final newUrl = await _uploadImage(docRef.id);
            await docRef.update({'imageUrl': newUrl});
          } on FirebaseException catch (e) {
            // ถ้าอัปโหลดภาพไม่ได้ ให้โพสต์ข้อความไปก่อน แต่แจ้งสาเหตุชัดเจน
            _toast('อัปโหลดรูปไม่สำเร็จ: ${e.message ?? 'permission denied'}');
          }
        }

        _toast('เพิ่มโพสต์แล้ว');
      }

      if (mounted) Navigator.pop(context);

    } on FirebaseException catch (e) {
      _toast(e.message ?? 'ไม่สามารถบันทึกได้');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final imgWidget = Builder(
      builder: (_) {
        if (selectedImageFile != null) {
          return Image.file(selectedImageFile!, height: 180, fit: BoxFit.cover);
        }
        if (imageUrl != null && imageUrl!.isNotEmpty) {
          return Image.network(imageUrl!, height: 180, fit: BoxFit.cover);
        }
        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.image, size: 48),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(isEdit ? 'EDIT ITEM' : 'ADD ITEM'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            imgWidget,
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.photo),
                  label: Text(isEdit ? 'เปลี่ยนรูป' : 'เลือกรูป'),
                ),
                const SizedBox(width: 8),
                if (imageUrl != null || selectedImageFile != null)
                  TextButton.icon(
                    onPressed: _removeImageTapped,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('ลบรูป'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            AppInput(controller: title, hint: 'Title'),
            const SizedBox(height: 12),

            // สถานะ
            ValueListenableBuilder<String>(
              valueListenable: status,
              builder: (_, v, __) => DropdownButtonFormField<String>(
                value: v,
                items: const [
                  DropdownMenuItem(value: 'lost',  child: Text('lost')),
                  DropdownMenuItem(value: 'found', child: Text('found')),
                ],
                onChanged: (x) => status.value = x ?? 'found',
                decoration: const InputDecoration(hintText: 'Status'),
              ),
            ),
            const SizedBox(height: 12),

            AppInput(controller: place, hint: 'Place'),
            const SizedBox(height: 12),
            AppInput(controller: desc, hint: 'Description', maxLines: 3),
            const SizedBox(height: 24),

            loading
                ? const Center(child: CircularProgressIndicator())
                : AppButton(
                    text: isEdit ? 'บันทึกการแก้ไข' : 'โพสต์',
                    onPressed: submit,
                  ),

            if (isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'หมายเหตุ: ถ้าต้องการลบ ใช้เมนู ⋮ ที่หน้า My Post',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
