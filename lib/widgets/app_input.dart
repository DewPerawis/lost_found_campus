import 'package:flutter/material.dart';

class AppInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? type;
  final int maxLines; // ✅ เพิ่มพารามิเตอร์นี้

  const AppInput({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.type,
    this.maxLines = 1, // ✅ ตั้งค่าเริ่มต้นเป็น 1 (single line)
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      maxLines: obscure ? 1 : maxLines, // ✅ ถ้าเป็น password บังคับให้ 1 line
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
