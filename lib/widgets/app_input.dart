import 'package:flutter/material.dart';

class AppInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? type;
  final int maxLines;
  final Widget? suffix; // ✅ เพิ่ม

  const AppInput({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.type,
    this.maxLines = 1,
    this.suffix, // ✅ เพิ่ม
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      maxLines: obscure ? 1 : maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: suffix, // ✅ เพิ่ม
      ),
    );
  }
}
