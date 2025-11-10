import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_home_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class AddItemPage extends StatefulWidget { const AddItemPage({super.key}); @override State<AddItemPage> createState()=>_AddItemPageState(); }
class _AddItemPageState extends State<AddItemPage> {
  final name = TextEditingController();
  final location = TextEditingController();
  final desc = TextEditingController();
  String status = 'found';
  XFile? picked;
  bool loading = false;

  Future<void> _pick() async {
    picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    setState(() {});
  }

  Future<void> _submit() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรอกชื่อรายการก่อน')));
      return;
    }
    setState(()=>loading=true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = FirebaseFirestore.instance.collection('items').doc();
      String? imageUrl;
      if (picked != null) {
        final ref = FirebaseStorage.instance.ref('items/${doc.id}/main.jpg');
        await ref.putFile(File(picked!.path));
        imageUrl = await ref.getDownloadURL();
      }
      await doc.set({
        'title': name.text.trim(),
        'status': status, // 'lost' or 'found'
        'place': location.text.trim().isEmpty ? null : location.text.trim(),
        'desc': desc.text.trim().isEmpty ? null : desc.text.trim(),
        'imageUrl': imageUrl,
        'ownerUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('บันทึกล้มเหลว: $e')));
    } finally { if (mounted) setState(()=>loading=false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Add Item')),
      bottomNavigationBar: const BottomHomeBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GestureDetector(
            onTap: _pick,
            child: AspectRatio(
              aspectRatio: 16/9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12, borderRadius: BorderRadius.circular(16),
                  image: picked==null ? null
                    : DecorationImage(image: FileImage(File(picked!.path)), fit: BoxFit.cover),
                ),
                child: picked==null ? const Center(child: Text('Add Photo')) : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppInput(controller: name, hint: 'Name'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: status,
            items: const [
              DropdownMenuItem(value: 'found', child: Text('Found')),
              DropdownMenuItem(value: 'lost', child: Text('Lost')),
            ],
            onChanged: (v) => setState(() => status = v!),
            decoration: const InputDecoration(hintText: 'Status'),
          ),
          const SizedBox(height: 12),
          AppInput(controller: location, hint: 'Location'),
          const SizedBox(height: 12),
          TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(hintText: 'Description')),
          const SizedBox(height: 16),
          loading ? const Center(child: CircularProgressIndicator())
                  : AppButton(text: 'Submit', onPressed: _submit),
        ],
      ),
    );
  }
}
